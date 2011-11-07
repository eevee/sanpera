"""Compilation target for sanpera.

Compiling a multi-part library into separate modules with cython is awkard, so
instead, the C parts are carved up into .pxi files.  These are textually
included, not imported.
"""
import sys

cimport libc.string as libc_string
cimport libc.stdio
from sanpera._magick_api cimport _blob, _constitute, _error, _image, _list, _log, _magick, _memory, _resize
import atexit


### Miscellaneous externs not part of cython

cdef extern from "Python.h":
    char* Py_GetProgramFullPath()

cdef extern from "stdio.h":
    libc.stdio.FILE* fdopen(int fd, char *mode)


### Make sure to call the library's setup and teardown methods

_magick.InitializeMagick(Py_GetProgramFullPath())
# XXX THIS IS FUCKING AWESOME MAKE A THING TO TURN THIS ON
#_log.SetLogEventMask("all")

def _shutdown():
    _magick.DestroyMagick()
atexit.register(_shutdown)


### Includes

# Error handling; primarily ExceptionCatcher
include "exceptions.pxi"



# TODO better exception handling /by far/; less ugly and more enforced -- use `with exception_handler() as exception`?
# TODO read docs carefully for when exception might be populated
# TODO these module names are unwieldy, and too much stuff called Image
# TODO no way to inspect an image or image-info
# TODO i am probably leaking like a sieve here
# TODO MemoryErrors and other such things the cython docs advise
# TODO docstrings
# TODO expose more properties and whatever to python-land
# TODO disallow Nones in more places probably
# TODO threadsafety?

cdef class ImageFrame:
    """Represents a single frame, and knows how to perform most operations on
    it.
    """

    ### setup, teardown
    # nb: even though this object acts merely as a view to a frame of an
    # existing Image, the frame might persist after the image is destroyed, so
    # we need to use refcounting

    cdef _image.Image* _frame

    def __cinit__(self):
        self._frame = NULL

    def __dealloc__(self):
        if self._frame:
            _image.DestroyImage(self._frame)
        self._frame = NULL

    cdef _set_frame(self, _image.Image* other):
        if self._frame:
            _image.DestroyImage(self._frame)

        _image.ReferenceImage(other)
        self._frame = other

    def __init__(self):
        raise TypeError("RawFrames cannot be instantiated directly")


    def resize(self, int columns, int rows):
        # XXX size ought to be a tuple
        # TODO percents
        # TODO < > ^ ! ...
        # XXX should size be a geometry object or summat
        # TODO allow picking a filter
        # TODO allow messing with blur?

        # TODO better way to check for exceptions
        # TODO do i need to destroy this?
        cdef _image.Image* new_image = NULL
        cdef ExceptionCatcher exc
        with ExceptionCatcher() as exc:
            new_image = _resize.ResizeImage(
                self._frame, columns, rows,
                _image.LanczosFilter, 1.0, &exc.exception)
            return _ImageFrame_factory(new_image)

cdef ImageFrame _ImageFrame_factory(_image.Image* frame):
    cdef ImageFrame self = ImageFrame.__new__(ImageFrame)
    self._set_frame(frame)
    return self


cdef class Image:
    """Represents a stack of zero or more frames."""

    cdef _image.Image* _stack

    def __cinit__(self):
        self._stack = NULL

    def __dealloc__(self):
        pass


    ### Sequence stuff

    def __len__(self):
        # TODO optimize/cache?
        return _list.GetImageListLength(self._stack)

    def __nonzero__(self):
        return self._stack != NULL

    # TODO getitem should return a Frame


    ### Constructors

    @classmethod
    def from_filename(type cls, bytes filename not None):
        # ReadImage does a lot of magick (ho ho!) with the filename, from
        # special "protocol" prefixes to extension detection to stdin to
        # piping.  So fuck all that and just open the damn file.
        return cls.from_file(open(filename))

    @classmethod
    def from_file(type cls, fileobj not None):
        cdef Image self = cls()

        # TODO check that fileobj is actually file-like and does fileno()
        # TODO check that fileobj is open with the right mode
        # TODO or just check the return value of fdopen or whatever.
        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(<_image.ImageInfo*>NULL)
        image_info.file = fdopen(fileobj.fileno(), "r")

        cdef ExceptionCatcher exc
        try:
            with ExceptionCatcher() as exc:
                self._stack = _constitute.ReadImage(image_info, &exc.exception)
        finally:
            #image_info.file = NULL
            _image.DestroyImageInfo(image_info)

        return self

    @classmethod
    def from_buffer(type cls, bytes buf not None):
        cdef Image self = cls()
        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(<_image.ImageInfo*>NULL)

        cdef ExceptionCatcher exc
        try:
            with ExceptionCatcher() as exc:
                self._stack = _blob.BlobToImage(image_info, <void*><char*>buf, len(buf), &exc.exception)
        finally:
            _image.DestroyImageInfo(image_info)

        return self


    ### cdef utilities

    cdef _raw_append(self, _image.Image* other):
        # Only use for unique image pointers that won't be in any other list!
        _list.AppendImageToList(&self._stack, other)


    ### listy interface

    def __iter__(self):
        # TODO cache me, or just keep me around in the first place
        cdef _image.Image* p = self._stack
        while p:
            yield _ImageFrame_factory(p)
            p = _list.GetNextImageInList(p)


    # TODO getitem.  setitem?


    def append(self, ImageFrame other not None):
        cdef _image.Image* cloned_frame
        cdef ExceptionCatcher exc
        with ExceptionCatcher() as exc:
            # 0, 0 => size; 0x0 means to reuse the same pixel cache
            # 1 => orphan; clear the previous/next pointers
            cloned_frame = _image.CloneImage(other._frame, 0, 0, 1, &exc.exception)
        _list.AppendImageToList(&self._stack, cloned_frame)

    def extend(self, Image other not None):
        # TODO i am still regretful about this; it requires a lot of copying
        # for the simple example of opening files, stacking them together, and
        # then saving the stack.  otoh does it really matter?
        cdef _image.Image* cloned_stack
        cdef ExceptionCatcher exc
        with ExceptionCatcher() as exc:
            cloned_stack = _list.CloneImageList(other._stack, &exc.exception)
        _list.AppendImageToList(&self._stack, cloned_stack)


    ### the good stuff

    # XXX this is inconsistent; appending and extending modify in-place, but
    # resizing returns a new thing.  or is that not inconsistent since Python
    # list manip tends to work the same way?
    def resize(self, int columns, int rows):
        cdef Image new = Image()
        cdef ImageFrame frame
        for frame in self:
            new.append(frame.resize(columns, rows))

        return new


    ### output
    # XXX for all of these: check that the target format supports the number of images!
    # TODO allow specifying the target format  B)
    # TODO support the wacky sprintf style of dumping images out i guess

    def write(self, bytes filename not None):
        # XXX what if there are no images

        # Gimme a blank image_info
        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(NULL)
        image_info.adjoin = 1  # force writing a single file

        cdef ExceptionCatcher exc
        with ExceptionCatcher() as exc:
            _constitute.WriteImages(image_info, self._stack, filename, &exc.exception)

        _image.DestroyImageInfo(image_info)

    def write_file(self, fileobj not None):
        # TODO check that fileobj is file-like, does fileno(), does right mode, doesn't explode fdopen
        # XXX what if there are no images

        # First fix up the image links
        self.link_frames()

        # Gimme a blank image_info
        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(NULL)
        image_info.adjoin = 1  # force writing a single file
        image_info.file = fdopen(fileobj.fileno(), "w")
        cdef ExceptionCatcher exc
        with ExceptionCatcher() as exc:
            # XXX the exception that gets set is in self._stack; oops
            _constitute.WriteImage(image_info, self._stack)

        _image.DestroyImageInfo(image_info)

    def to_buffer(self):
        # TODO check that fileobj is file-like, does fileno(), does right mode, doesn't explode fdopen
        # XXX what if there are no images

        # Gimme a blank image_info
        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(NULL)
        image_info.adjoin = 1  # force writing a single file
        #libc_string.strncpy(head_image.magick, "gif", 10)  # XXX ho ho what are you trying to pull
        cdef ExceptionCatcher exc
        cdef void* cbuf = NULL
        cdef size_t length = 0
        with ExceptionCatcher() as exc:
            cbuf = _blob.ImageToBlob(image_info, self._stack, &length, &exc.exception)

        cdef bytes buf
        try:
            buf = (<unsigned char*> cbuf)[:length]
        finally:
            pass
            _memory.MagickFree(cbuf)

        # TODO leak ahoy
        _image.DestroyImageInfo(image_info)

        return buf
