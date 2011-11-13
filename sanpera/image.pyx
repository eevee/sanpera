"""Image class and assorted helper classes.  This is where the magick happens.
"""

cimport libc.string as libc_string
cimport libc.stdio

from collections import namedtuple

from sanpera._magick_api cimport _blob, _common, _constitute, _exception, _image, _list, _log, _magick, _memory, _resize
from sanpera.exception cimport ExceptionCatcher


### Spare declarations

cdef extern from "stdio.h":
    libc.stdio.FILE* fdopen(int fd, char *mode)

# TODO name of the wrapped c pointer is wildly inconsistent
# TODO i am probably leaking like a sieve here
# TODO MemoryErrors and other such things the cython docs advise
# TODO docstrings
# TODO expose more properties and whatever to python-land
# TODO threadsafety?


### Little helpers

class Size(namedtuple('Size', ('width', 'height'))):
    __slots__ = ()
    # TODO must be ints, positive

class Point(namedtuple('Point', ('x', 'y'))):
    __slots__ = ()

class Offset(Point):
    __slots__ = ()

    def __nonzero__(self):
        return self.x or self.y

cdef class RectangleProxy:
    cdef _image.RectangleInfo* ptr
    cdef owner

    @property
    def width(self):
        return self.ptr.width

    @property
    def height(self):
        return self.ptr.height

    @property
    def x(self):
        return self.ptr.x

    @property
    def y(self):
        return self.ptr.y

    @property
    def size(self):
        return Size(self.ptr.width, self.ptr.height)

    @property
    def offset(self):
        return Offset(self.ptr.x, self.ptr.y)


### Frame

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
        # Sets the wrapped frame, discarding the old one if necessary.
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


### Image

cdef class Image:
    """An image.  If you don't know what this is, you may be using the wrong
    library.
    """

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

        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(NULL)
        cdef ExceptionCatcher exc
        try:
            with ExceptionCatcher() as exc:
                self._stack = _blob.BlobToImage(image_info, <void*><char*>buf, len(buf), &exc.exception)
        finally:
            _image.DestroyImageInfo(image_info)

        self._setup_frames()
        return self


    ### cdef utilities

    cdef _setup_frames(self, _image.Image* start = NULL):
        # Shared by constructors to read the frame list out of the new image
        assert not self._frames

        if not start:
            start = self._stack
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
        self._setup_frames(cloned_stack)

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


    ### Properties

    # TODO critically important: how do these work with multiple images!
    # TODO read the convert usage a bit more carefully; there seems to be some deliberate difference in behavior between "bunch of images" and "bunch of frames".  for that matter, how DOES convert treat stuff like this?
    # TODO anyway, conclusion of that thought was that sticking frames onto other images should do more than just diddle pointers
    @property
    def original_format(self):
        return self._stack.magick

    @property
    def size(self):
        return Size(self._stack.columns, self._stack.rows)

    @property
    def canvas(self):
        proxy = RectangleProxy()
        proxy.ptr = &self._stack.page
        proxy.owner = self

        return proxy

    @property
    def has_canvas(self):
        return (
            self._stack.page.x != 0 or
            self._stack.page.y != 0 or
            self._stack.page.width != self._stack.columns or
            self._stack.page.height != self._stack.rows)


    ### the good stuff

    def resize(self, int columns, int rows):
        # XXX size ought to be a tuple
        # TODO percents
        # TODO < > ^ ! ...
        # XXX should size be a geometry object or summat
        # TODO allow picking a filter
        # TODO allow messing with blur?

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
        cdef ExceptionCatcher exc

        try:
            image_info.adjoin = _common.MagickTrue  # force writing a single file
            image_info.file = fdopen(fileobj.fileno(), "w")

            with ExceptionCatcher() as exc:
                _constitute.WriteImage(image_info, self._stack)
                _exception.InheritException(&exc.exception, &self._stack.exception)
        finally:
            _image.DestroyImageInfo(image_info)

    def write_buffer(self):
        # TODO check that fileobj is file-like, does fileno(), does right mode, doesn't explode fdopen
        # XXX what if there are no images

        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(NULL)
        cdef void* cbuf = NULL
        cdef size_t length = 0
        cdef ExceptionCatcher exc
        cdef bytes buf

        try:
            image_info.adjoin = _common.MagickTrue  # force writing a single file
            #libc_string.strncpy(self._stack.magick, "GIF", 10)  # XXX ho ho what are you trying to pull

            with ExceptionCatcher() as exc:
                cbuf = _blob.ImageToBlob(image_info, self._stack, &length, &exc.exception)

            buf = (<unsigned char*> cbuf)[:length]
            _memory.RelinquishMagickMemory(cbuf)
            return buf
        finally:
            _image.DestroyImageInfo(image_info)
