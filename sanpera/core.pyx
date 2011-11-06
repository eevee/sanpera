"""Compilation target for sanpera.

Compiling a multi-part library into separate modules with cython is awkard, so
instead, the C parts are carved up into .pxi files.  These are textually
included, not imported.
"""

cimport libc.string
cimport libc.stdio
from sanpera._magick_api cimport _blob, _constitute, _error, _image, _list, _magick, _resize
import atexit


### Miscellaneous externs not part of cython

cdef extern from "Python.h":
    char* Py_GetProgramFullPath()

cdef extern from "stdio.h":
    libc.stdio.FILE* fdopen(int fd, char *mode)


### Make sure to call the library's setup and teardown methods

_magick.InitializeMagick(Py_GetProgramFullPath())

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

cdef class RawFrame:
    """Wrapper around a C Image pointer.  Represents a single frame, and knows
    how to perform most operations on it.

    This class is immutable; operations return new images, and the underlying
    image struct is destroyed when refcount drops to zero.
    """

    cdef _image.Image* _img

    def __cinit__(self):
        self._img = NULL

    def __dealloc__(self):
        _image.DestroyImage(self._img)
        self._img = NULL

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
                self._img, columns, rows,
                _image.LanczosFilter, 1.0, &exc.exception)
            return _RawFrame_factory(new_image)

cdef RawFrame _RawFrame_factory(_image.Image* frame):
    # XXX note that this DOES NOT increase the refcount; we're assuming the
    # pointer comes from GM, so the refcount is already 1
    cdef RawFrame self = RawFrame.__new__(RawFrame)
    self._img = frame
    return self


cdef class Image:
    """Represents a stack of zero or more frames."""

    # XXX this could possibly use a real c array
    cdef list _frames

    def __cinit__(self):
        self._frames = []

    def __dealloc__(self):
        pass


    ### Sequence stuff

    def __len__(self):
        return len(self._frames)

    def __nonzero__(self):
        return bool(self._frames)

    # TODO getitem should return a new Image with one frame?  or something


    ### Constructors

    cdef _consume_image_list(self, _image.Image* image_list):
        while image_list != NULL:
            self._raw_append(image_list)
            _list.RemoveFirstImageFromList(&image_list)

    @classmethod
    def from_filename(type cls, bytes filename not None):
        # ReadImage does a lot of magick (ho ho!) with the filename, from
        # special "protocol" prefixes to extension detection to stdin to
        # piping.  So fuck all that and just open the damn file.
        return cls.from_file(open(filename))

    @classmethod
    def from_file(type cls, fileobj not None):
        # TODO check that fileobj is actually file-like and does fileno()
        # TODO check that fileobj is open with the right mode
        # TODO or just check the return value of fdopen or whatever.
        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(<_image.ImageInfo*>NULL)
        image_info.file = fdopen(fileobj.fileno(), "r")

        cdef _image.Image* image = NULL
        cdef ExceptionCatcher exc
        try:
            with ExceptionCatcher() as exc:
                image = _constitute.ReadImage(image_info, &exc.exception)
        finally:
            #image_info.file = NULL
            _image.DestroyImageInfo(image_info)

        cdef Image self = cls()
        self._consume_image_list(image)
        return self

    @classmethod
    def from_buffer(type cls, bytes buf not None):
        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(<_image.ImageInfo*>NULL)

        cdef _image.Image* image = NULL
        cdef ExceptionCatcher exc
        try:
            with ExceptionCatcher() as exc:
                image = _blob.BlobToImage(image_info, <void*><char*>buf, len(buf), &exc.exception)
        finally:
            _image.DestroyImageInfo(image_info)

        cdef Image self = cls()
        self._consume_image_list(image)
        return self


    ### cdef utilities

    cdef _raw_append(self, _image.Image* other):
        cdef RawFrame frame = _RawFrame_factory(other)
        self._frames.append(frame)

    cdef link_frames(self):
        # Set all the frames' prev/next pointers to make them into a correct
        # doubly-linked list.  Note that this effect can only be assumed to
        # persist for the duration of a single method call
        # TODO make me a method decorator?  can i do that?

        # TODO split me out
        cdef _image.Image* prev_image = NULL
        cdef RawFrame frame
        for frame in self._frames:
            frame._img.previous = prev_image
            if prev_image:
                prev_image.next = frame._img
            prev_image = frame._img
        prev_image.next = NULL



    def extend(self, Image other not None):
        # XXX this should return a new Image and have a better name
        self._frames.extend(other._frames)


    def resize(self, *a, **kw):
        cdef Image ret = Image()
        ret._frames = [frame.resize(*a, **kw) for frame in self._frames]
        return ret


    def write(self, bytes filename not None):
        # XXX what if there are no images

        # First fix up the image links
        self.link_frames()

        # Gimme a blank image_info
        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(NULL)
        image_info.adjoin = 1  # force writing a single file
        # XXX OH NO THIS IS AWFUL
        # XXX this relies on GraphicsMagick's filename parsing.  eh.
        cdef _image.Image* head_image = (<RawFrame>self._frames[0])._img
        cdef ExceptionCatcher exc
        with ExceptionCatcher() as exc:
            _constitute.WriteImages(image_info, head_image, filename, &exc.exception)

        _image.DestroyImageInfo(image_info)
