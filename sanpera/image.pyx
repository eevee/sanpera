"""Image class and assorted helper classes.  This is where the magick happens.
"""
from __future__ import division

cimport cpython.exc
from cython.operator cimport preincrement as inc
cimport libc.string as libc_string
cimport libc.stdio

from collections import namedtuple

from sanpera cimport c_api
from sanpera.color cimport Color
from sanpera.geometry cimport Size, Rectangle, Vector
from sanpera.exception cimport MagickException, check_magick_exception

from sanpera.exception import EmptyImageError, MissingFormatError

# TODO name of the wrapped c pointer is wildly inconsistent
# TODO i am probably leaking like a sieve here
# TODO MemoryErrors and other such things the cython docs advise
# TODO docstrings
# TODO expose more properties and whatever to python-land
# TODO threadsafety?
# TODO check boolean return values more often
# TODO really, really want to be able to dump out an image or info struct.  really.


### Little helpers

cdef class RectangleProxy:
    cdef c_api.RectangleInfo* ptr
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
        return Vector(self.ptr.x, self.ptr.y)


### Frame

cdef class ImageFrame:
    """Represents a single frame, and knows how to perform most operations on
    it.
    """

    ### setup, teardown
    # nb: even though this object acts merely as a view to a frame of an
    # existing Image, the frame might persist after the image is destroyed, so
    # we need to use refcounting

    cdef c_api.Image* _frame

    def __cinit__(self):
        self._frame = NULL

    def __dealloc__(self):
        if self._frame:
            c_api.DestroyImage(self._frame)
        self._frame = NULL

    cdef _set_frame(self, c_api.Image* other):
        # Sets the wrapped frame, discarding the old one if necessary.
        # Only feed me a newly-created frame!  NEVER pass in another
        # ImageFrame's frame!
        if self._frame:
            c_api.DestroyImage(self._frame)

        self._frame = other
        c_api.ReferenceImage(self._frame)

    def __init__(self):
        raise TypeError("RawFrames cannot be instantiated directly")

    @property
    def size(self):
        return Size(self._frame.columns, self._frame.rows)


cdef ImageFrame _ImageFrame_factory(c_api.Image* frame):
    cdef ImageFrame self = ImageFrame.__new__(ImageFrame)
    self._set_frame(frame)
    return self


### Image

cdef class Image:
    """An image.  If you don't know what this is, you may be using the wrong
    library.
    """

    cdef c_api.Image* _stack
    cdef list _frames

    def __cinit__(self):
        self._stack = NULL
        self._frames = []

    def __dealloc__(self):
        if self._stack:
            c_api.DestroyImageList(self._stack)
        self._stack = NULL


    ### Constructors (input)

    def __init__(self):
        """Create a new image with zero frames.  This is /probably/ not what
        you want; consider using `Image.new()` instead.
        """
        pass

    @classmethod
    def new(type cls, size not None, *, Color fill=None):
        """Create a new image (with one frame) of the given size."""
        size = Size.coerce(size)

        cdef Image self = cls()
        cdef c_api.ImageInfo* image_info = c_api.CloneImageInfo(NULL)
        cdef MagickException exc = MagickException()

        try:
            if fill is None:
                # TODO need a way to explicitly create a certain color
                fill = Color.parse('#00000000')

            self._stack = c_api.NewMagickImage(image_info, size.width, size.height, &fill.c_struct)
            check_magick_exception(&self._stack.exception)
        finally:
            c_api.DestroyImageInfo(image_info)

        self._setup_frames()
        return self

    @classmethod
    def read(type cls, bytes filename not None):
        cdef libc.stdio.FILE* fh = libc.stdio.fopen(<char*>filename, "rb")
        if fh == NULL:
            cpython.exc.PyErr_SetFromErrnoWithFilename(IOError, filename)

        cdef c_api.ImageInfo* image_info = c_api.CloneImageInfo(NULL)
        cdef MagickException exc = MagickException()
        cdef int ret

        cdef Image self = cls()

        try:
            # Force reading from this file descriptor
            image_info.file = fh

            self._stack = c_api.ReadImage(image_info, exc.ptr)
            exc.check()

            # Blank out the filename so IM doesn't try to write to it later
            self._stack.filename[0] = <char>0
        finally:
            c_api.DestroyImageInfo(image_info)

            ret = libc.stdio.fclose(fh)
            if ret != 0:
                cpython.exc.PyErr_SetFromErrnoWithFilename(IOError, filename)

        self._setup_frames()
        return self

    @classmethod
    def from_buffer(type cls, bytes buf not None):
        cdef c_api.ImageInfo* image_info = c_api.CloneImageInfo(NULL)
        cdef MagickException exc = MagickException()

        cdef Image self = cls()

        try:
            self._stack = c_api.BlobToImage(image_info, <void*><char*>buf, len(buf), exc.ptr)
            exc.check()

            # Blank out the filename so IM doesn't try to write to it later --
            # yes, this is from an in-memory buffer, but sometimes IM will
            # write it to a tempfile to read it
            self._stack.filename[0] = <char>0
        finally:
            c_api.DestroyImageInfo(image_info)

        self._setup_frames()
        return self

    @classmethod
    def from_magick(type cls, bytes name not None):
        """Passes a filename specifier directly to ImageMagick.

        This allows reading from any of the magic pseudo-formats, like
        `clipboard` and `null`.  Use with care with user input!
        """
        cdef c_api.ImageInfo* image_info = c_api.CloneImageInfo(NULL)
        cdef MagickException exc = MagickException()

        cdef Image self = cls()

        try:
            libc_string.strncpy(image_info.filename, <char*>name, c_api.MaxTextExtent)

            self._stack = c_api.ReadImage(image_info, exc.ptr)
            exc.check()

            # Blank out the filename and format so IM doesn't try to write them
            # later
            self._stack.filename[0] = <char>0
            self._stack.magick[0] = <char>0
        finally:
            c_api.DestroyImageInfo(image_info)

        self._setup_frames()
        return self


    ### Output
    # XXX for all of these: check that the target format supports the number of images!
    # TODO support the wacky sprintf style of dumping images out i guess

    def write(self, bytes filename not None, bytes format=None):
        if self._stack == NULL:
            raise EmptyImageError

        cdef libc.stdio.FILE* fh = libc.stdio.fopen(<char*>filename, "wb")
        if fh == NULL:
            cpython.exc.PyErr_SetFromErrnoWithFilename(IOError, filename)

        cdef c_api.ImageInfo* image_info = c_api.CloneImageInfo(NULL)
        cdef int ret

        try:
            # Force writing to this file descriptor
            image_info.file = fh

            # Force writing to a single file
            image_info.adjoin = c_api.MagickTrue

            if format:
                # If the caller provided an explicit format, pass it along
                libc_string.strncpy(image_info.magick, <char*>format, c_api.MaxTextExtent)
            elif self._stack.magick[0] == <char>0:
                # Uhoh; no format provided and nothing given by caller
                raise MissingFormatError
            # TODO detect format from filename if explicitly asked to do so

            c_api.WriteImage(image_info, self._stack)
            check_magick_exception(&self._stack.exception)
        finally:
            c_api.DestroyImageInfo(image_info)

            ret = libc.stdio.fclose(fh)
            if ret != 0:
                cpython.exc.PyErr_SetFromErrnoWithFilename(IOError, filename)

    def to_buffer(self, bytes format=None):
        if self._stack == NULL:
            raise EmptyImageError

        cdef c_api.ImageInfo* image_info = c_api.CloneImageInfo(NULL)
        cdef MagickException exc = MagickException()
        cdef size_t length = 0
        cdef void* cbuf = NULL
        cdef bytes buf

        try:
            # Force writing to a single file
            image_info.adjoin = c_api.MagickTrue

            if format:
                # If the caller provided an explicit format, pass it along
                libc_string.strncpy(image_info.magick, <char*>format, c_api.MaxTextExtent)
            elif self._stack.magick[0] == <char>0:
                # Uhoh; no format provided and nothing given by caller
                raise MissingFormatError

            cbuf = c_api.ImageToBlob(image_info, self._stack, &length, exc.ptr)
            exc.check()

            buf = (<unsigned char*> cbuf)[:length]
            c_api.RelinquishMagickMemory(cbuf)
            return buf
        finally:
            c_api.DestroyImageInfo(image_info)


    ### cdef utilities

    cdef _setup_frames(self, c_api.Image* start = NULL):
        # Shared by constructors to read the frame list out of the new image
        assert not self._frames

        cdef c_api.Image* p

        if start:
            p = start
        else:
            p = self._stack

        while p:
            self._frames.append(_ImageFrame_factory(p))
            p = c_api.GetNextImageInList(p)


    ### Sequence operations

    def __len__(self):
        # TODO optimize/cache?
        return c_api.GetImageListLength(self._stack)

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
        cdef c_api.Image* cloned_frame
        cdef MagickException exc = MagickException()

        # 0, 0 => size; 0x0 means to reuse the same pixel cache
        # 1 => orphan; clear the previous/next pointers
        cloned_frame = c_api.CloneImage(other._frame, 0, 0, 1, exc.ptr)
        exc.check()

        c_api.AppendImageToList(&self._stack, cloned_frame)
        self._frames.append(_ImageFrame_factory(cloned_frame))

    def extend(self, Image other not None):
        """Appends a copy of each of the given image's frames to this image."""
        cdef c_api.Image* cloned_stack
        cdef MagickException exc = MagickException()

        cloned_stack = c_api.CloneImageList(other._stack, exc.ptr)
        exc.check()

        c_api.AppendImageToList(&self._stack, cloned_stack)
        self._setup_frames(cloned_stack)

    def consume(self, Image other not None):
        """Similar to `extend`, but also removes the frames from the other
        image, leaving it empty.  The advantage is that the frames don't need
        to be copied, so this is a little more efficient when loading many
        separate images and operating on them as a whole, as with `convert`.
        """
        c_api.AppendImageToList(&self._stack, other._stack)
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
        """The image dimensions, as a `Size`.

        Note that multi-frame images don't have a notion of intrinsic size for
        the entire image, though particular formats may enforce that every
        frame be the same size.  If the image has multiple frames, this returns
        the size of the first frame, which is in line with most image-handling
        software.
        """
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

    property bit_depth:
        def __get__(self):
            return self._stack.depth

        def __set__(self, unsigned long depth):
            self._stack.depth = depth

    # TODO this will have to become a proxy thing for it to support assignment
    # TODO i am not a huge fan of this name, but 'metadata' is too expansive
    # TODO can the same property appear multiple times?  cf PNG text chunks
    # TODO this prefixing thing sucks as UI, and stuff like dates should be parsed
    @property
    def raw_properties(self):
        cdef char* prop = NULL
        cdef dict ret = {}

        # TODO may need SyncImageProfiles() somewhere?  it updates EXIF res and
        # orientation

        # This tricks IM into actually reading the EXIF properties...
        c_api.GetImageProperty(self._stack, "exif:*")

        c_api.ResetImagePropertyIterator(self._stack)
        while True:
            # XXX this only examines the top image uhoh.  do we care?  what
            # happens if i load a GIF; what does each frame say?  what happens
            # if i have multiple images with different props and save as one
            # image?
            prop = c_api.GetNextImageProperty(self._stack)
            if prop == NULL:
                break

            ret[<bytes>prop] = <bytes>c_api.GetImageProperty(self._stack, prop)

        return ret


    ### The good stuff: physical changes
    # TODO these are more complicated for multi-frame images.
    # - if a frame isn't the size of the image, it shouldn't resize blindly to
    #   the given size
    # - cropping likewise needs to affect the stack as a whole
    # ...or does IM do this already?  what's the diff between the resize functions?

    def resize(self, size, filter=None):
        size = Size.coerce(size)

        # TODO allow picking a filter
        # TODO allow messing with blur?

        cdef Image new = self.__class__()
        cdef c_api.Image* p = self._stack
        cdef c_api.Image* new_frame
        cdef MagickException exc = MagickException()

        cdef c_api.FilterTypes c_filter = c_api.UndefinedFilter
        if filter == 'box':
            c_filter = c_api.BoxFilter

        while p:
            try:
                if c_filter == c_api.BoxFilter:
                    # Use the faster ScaleImage in this special case
                    new_frame = c_api.ScaleImage(
                        p, size.width, size.height, exc.ptr)
                else:
                    new_frame = c_api.ResizeImage(
                        p, size.width, size.height,
                        c_filter, 1.0, exc.ptr)

                exc.check()
            except Exception:
                c_api.DestroyImage(new_frame)

            c_api.AppendImageToList(&new._stack, new_frame)
            p = c_api.GetNextImageInList(p)

        new._setup_frames()
        return new

    # TODO i don't really like this argspec.  need a Rectangle class and
    # accessors for common ops?
    def crop(self, Rectangle rect):
        cdef Image new = self.__class__()
        cdef c_api.Image* p = self._stack
        cdef c_api.Image* new_frame
        cdef c_api.RectangleInfo rectinfo = rect.to_rect_info()
        cdef MagickException exc = MagickException()

        while p:
            try:
                new_frame = c_api.CropImage(p, &rectinfo, exc.ptr)
                exc.check()
            except Exception:
                c_api.DestroyImage(new_frame)

            # Always repage after a crop; not doing this is unexpected and
            # frankly insane
            # TODO how necessary is this?  should it be done for frames?
            new_frame.page.x = 0
            new_frame.page.y = 0
            new_frame.page.width = 0
            new_frame.page.height = 0

            c_api.AppendImageToList(&new._stack, new_frame)
            p = c_api.GetNextImageInList(p)

        new._setup_frames()
        return new

    # TODO i should probably live on Frame
    def tile(self, size):
        size = Size.coerce(size)

        cdef Image new = self.new(size)

        # TODO this returns a bool?
        c_api.TextureImage(new._stack, self._stack)
        check_magick_exception(&self._stack.exception)

        return new


    ### The good stuff: color
    # TODO these are really methods on frames, not images

    def replace_color(self, Color color, Color replacement,
            *, float fuzz = 0.0):

        color.c_struct.fuzz = fuzz
        replacement.c_struct.fuzz = fuzz

        c_api.OpaquePaintImage(self._stack, &color.c_struct, &replacement.c_struct,
            c_api.MagickFalse)


# TODO this should probably not live in cython
class BuiltinRegistry(object):
    # XXX possibly spruce this up a bit to work better with other kinds of
    # builtin enumerables

    @classmethod
    def create(cls, *names):
        def decorator(f):
            obj = cls(f, names)
            obj.__doc__ = f.__doc__
            return obj
        return decorator

    def __init__(self, factory, names):
        self._factory = factory
        self._names = frozenset(names)

    def __getattr__(self, key):
        if key not in self._names:
            raise AttributeError

        return self._factory(key)

    def __iter__(self):
        return self._names

# There is, conveniently, no way to get a list of built-in images or patterns
# out of ImageMagick.  So, er, here are manual lists.
@BuiltinRegistry.create('granite', 'logo', 'netscape', 'rose', 'wizard')
def builtins(name):
    return Image.from_magick('magick:' + name)

@BuiltinRegistry.create(
    'bricks', 'checkerboard', 'circles', 'crosshatch', 'crosshatch30',
    'crosshatch45', 'fishscales',
    'gray0', 'gray5', 'gray10', 'gray15', 'gray20', 'gray25', 'gray30',
    'gray35', 'gray40', 'gray45', 'gray50', 'gray55', 'gray60', 'gray65',
    'gray70', 'gray75', 'gray80', 'gray85', 'gray90', 'gray95', 'gray100',
    'hexagons', 'horizontal', 'horizontal2', 'horizontal3', 'horizontalsaw',
    'hs_bdiagonal', 'hs_cross', 'hs_diagcross', 'hs_fdiagonal',
    'hs_horizontal', 'hs_vertical', 'left30', 'left45', 'leftshingle',
    'octagons', 'right30', 'right45', 'rightshingle', 'smallfishscales',
    'vertical', 'vertical2', 'vertical3', 'verticalbricks',
    'verticalleftshingle', 'verticalrightshingle', 'verticalsaw',
)
def patterns(name):
    return Image.from_magick('pattern:' + name)
