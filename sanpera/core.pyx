"""Compilation target for sanpera.

Compiling a multi-part library into separate modules with cython is awkard, so
instead, the C parts are carved up into .pxi files.  These are textually
included, not imported.
"""
import sys

cimport libc.string as libc_string
cimport libc.stdio
from sanpera._magick_api cimport _blob, _common, _constitute, _exception, _image, _list, _log, _magick, _memory, _resize
import atexit


### Miscellaneous externs not part of cython

cdef extern from "Python.h":
    char* Py_GetProgramFullPath()

cdef extern from "stdio.h":
    libc.stdio.FILE* fdopen(int fd, char *mode)


### Make sure to call the library's setup and teardown methods

_magick.MagickCoreGenesis(Py_GetProgramFullPath(), _common.MagickFalse)
# XXX THIS IS FUCKING AWESOME MAKE A THING TO TURN THIS ON
#_log.SetLogEventMask("all")

def _shutdown():
    _magick.MagickCoreTerminus()
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
        # Only feed me a newly-created frame!  NEVER pass in another
        # ImageFrame's frame!
        if self._frame:
            _image.DestroyImage(self._frame)

        self._frame = other
        _image.ReferenceImage(self._frame)

    def __init__(self):
        raise TypeError("RawFrames cannot be instantiated directly")



cdef ImageFrame _ImageFrame_factory(_image.Image* frame):
    cdef ImageFrame self = ImageFrame.__new__(ImageFrame)
    self._set_frame(frame)
    return self


cdef class Image:
    """A stack of zero or more frames."""

    cdef _image.Image* _stack
    cdef list _frames

    def __cinit__(self):
        self._stack = NULL
        self._frames = []

    def __dealloc__(self):
        if self._stack:
            _list.DestroyImageList(self._stack)
        self._stack = NULL


    ### Constructors (input)

    @classmethod
    def read(type cls, fileobj not None):
        cdef Image self = cls()

        # TODO check that fileobj is actually file-like and does fileno()
        # TODO check that fileobj is open with the right mode
        # TODO or just check the return value of fdopen or whatever.
        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(NULL)
        image_info.file = fdopen(fileobj.fileno(), "r")

        cdef ExceptionCatcher exc
        try:
            with ExceptionCatcher() as exc:
                self._stack = _constitute.ReadImage(image_info, &exc.exception)
        finally:
            _image.DestroyImageInfo(image_info)

        self._setup_frames()
        return self

    @classmethod
    def read_buffer(type cls, bytes buf not None):
        cdef Image self = cls()

        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(<_image.ImageInfo*>NULL)
        cdef ExceptionCatcher exc
        try:
            with ExceptionCatcher() as exc:
                self._stack = _blob.BlobToImage(image_info, <void*><char*>buf, len(buf), &exc.exception)
        finally:
            _image.DestroyImageInfo(image_info)

        self._setup_frames()
        return self


    ### cdef utilities

    cdef _setup_frames(self):
        # Shared by constructors to read the frame list out of the new image
        assert not self._frames

        cdef _image.Image* p = self._stack
        while p:
            self._frames.append(_ImageFrame_factory(p))
            p = _list.GetNextImageInList(p)


    ### Sequence operations

    def __len__(self):
        # TODO optimize/cache?
        return _list.GetImageListLength(self._stack)

    def __nonzero__(self):
        return self._stack != NULL

    def __iter__(self):
        cdef ImageFrame frame
        for frame in self._frames:
            yield frame

    def __getitem__(self, key):
        return self._frames[key]

    # TODO
    #def __setitem__(self, key, value):


    # TODO turn all this stuff into a single get/set slice interface?
    def append(self, ImageFrame other):
        """Appends a copy of the given frame to this image."""
        cdef _image.Image* cloned_frame
        cdef ExceptionCatcher exc
        with ExceptionCatcher() as exc:
            # 0, 0 => size; 0x0 means to reuse the same pixel cache
            # 1 => orphan; clear the previous/next pointers
            cloned_frame = _image.CloneImage(other._frame, 0, 0, 1, &exc.exception)

        _list.AppendImageToList(&self._stack, cloned_frame)
        self._frames.append(_ImageFrame_factory(cloned_frame))

    def extend(self, Image other not None):
        """Appends a copy of each of the given image's frames to this image."""
        cdef _image.Image* cloned_stack
        cdef ExceptionCatcher exc
        with ExceptionCatcher() as exc:
            cloned_stack = _list.CloneImageList(other._stack, &exc.exception)

        _list.AppendImageToList(&self._stack, cloned_stack)

        cdef _image.Image* p = cloned_stack
        while p:
            self._frames.append(_ImageFrame_factory(p))
            p = _list.GetNextImageInList(p)

    def consume(self, Image other not None):
        """Similar to `extend`, but also removes the frames from the other
        image, leaving it empty.  The advantage is that the frames don't need
        to be copied, so this is a little more efficient when loading many
        separate images and operating on them as a whole, as with `convert`.
        """
        _list.AppendImageToList(&self._stack, other._stack)
        self._frames.extend(other._frames)

        other._stack = NULL
        other._frames = []


    ### the good stuff

    # XXX starting to think that this stuff doesn't belong in ImageFrame, as
    # there's nothing too useful a caller can do with an unattached frame.  it
    # should just be a mutable view of a frame for pixel operations and
    # generally rearranging frames.

    def resize(self, int columns, int rows):
        # XXX size ought to be a tuple
        # TODO percents
        # TODO < > ^ ! ...
        # XXX should size be a geometry object or summat
        # TODO allow picking a filter
        # TODO allow messing with blur?

        # TODO do i need to destroy this?
        cdef Image new = self.__class__()
        cdef _image.Image* p = self._stack
        cdef _image.Image* new_frame
        cdef ExceptionCatcher exc

        while p:
            with ExceptionCatcher() as exc:
                new_frame = _resize.ResizeImage(
                    p, columns, rows,
                    _image.LanczosFilter, 1.0, &exc.exception)

            _list.AppendImageToList(&new._stack, new_frame)
            p = _list.GetNextImageInList(p)

        new._setup_frames()
        return new


    ### output
    # XXX for all of these: check that the target format supports the number of images!
    # TODO allow specifying the target format  B)
    # TODO support the wacky sprintf style of dumping images out i guess

    def write(self, fileobj not None):
        # TODO check that fileobj is file-like, does fileno(), does right mode, doesn't explode fdopen
        # XXX what if there are no images

        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(NULL)
        image_info.adjoin = _common.MagickTrue  # force writing a single file
        image_info.file = fdopen(fileobj.fileno(), "w")

        cdef ExceptionCatcher exc
        with ExceptionCatcher() as exc:
            # XXX the exception that gets set is in self._stack; oops
            _constitute.WriteImage(image_info, self._stack)
            #_exception.InheritException(exc.exception, self._stack.exception)?????

        _image.DestroyImageInfo(image_info)

    def write_buffer(self):
        # TODO check that fileobj is file-like, does fileno(), does right mode, doesn't explode fdopen
        # XXX what if there are no images

        # Gimme a blank image_info
        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(NULL)
        image_info.adjoin = _common.MagickTrue  # force writing a single file
        #libc_string.strncpy(self._stack.magick, "GIF", 10)  # XXX ho ho what are you trying to pull
        cdef void* cbuf = NULL
        cdef size_t length = 0
        cdef ExceptionCatcher exc
        with ExceptionCatcher() as exc:
            cbuf = _blob.ImageToBlob(image_info, self._stack, &length, &exc.exception)

        cdef bytes buf
        try:
            buf = (<unsigned char*> cbuf)[:length]
        finally:
            _memory.RelinquishMagickMemory(cbuf)

        # TODO leak ahoy
        _image.DestroyImageInfo(image_info)

        return buf
