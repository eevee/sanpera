"""Image class and assorted helper classes.  This is where the magick happens.
"""
from __future__ import division

from cpython cimport bool
cimport cpython.exc
from cython.operator cimport preincrement as inc
cimport libc.string as libc_string
cimport libc.stdio

from collections import namedtuple

from sanpera cimport c_api
from sanpera.color cimport RGBColor, _double_to_quantum, _quantum_to_double
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


### Frame

cdef class PixelViewPixel:
    """Transient pixel access object.  Can be used to examine and set a single
    pixel's color.
    """
    # Note that this stuff is only set by its consumer, PixelView
    cdef c_api.PixelPacket* _pixel
    cdef PixelView owner
    cdef int _x
    cdef int _y

    def __init__(self):
        raise TypeError("PixelViewPixel cannot be instantiated directly")

    property color:
        # XXX this needs to do something special to handle non-rgba images
        def __get__(self):
            if self._pixel == NULL:
                raise ValueError("Pixel has expired")
            return RGBColor(
                _quantum_to_double(self._pixel.red),
                _quantum_to_double(self._pixel.green),
                _quantum_to_double(self._pixel.blue),
                # ImageMagick thinks opacity is transparency
                1.0 - _quantum_to_double(self._pixel.opacity))

        def __set__(self, RGBColor value):
            if self._pixel == NULL:
                raise ValueError("Pixel has expired")
            self._pixel.red = _double_to_quantum(value._red)
            self._pixel.green = _double_to_quantum(value._green)
            self._pixel.blue = _double_to_quantum(value._blue)
            # ImageMagick thinks opacity is transparency
            self._pixel.opacity = _double_to_quantum(1.0 - value._opacity)

    property point:
        def __get__(self):
            return Vector(self._x, self._y)

cdef class PixelView:
    """Can view and manipulate individual pixels of a frame."""

    cdef c_api.CacheView* _ptr
    cdef ImageFrame _frame

    def __cinit__(self):
        self._frame = None
        self._ptr = NULL

    def __init__(self, ImageFrame frame not None):
        self._frame = frame
        self._ptr = c_api.AcquireCacheView(frame._frame)

    def __dealloc__(self):
        cdef MagickException exc = MagickException()

        if self._ptr:
            c_api.SyncCacheViewAuthenticPixels(self._ptr, exc.ptr)
            c_api.DestroyCacheView(self._ptr)
        self._ptr = NULL

        # Only risk raising an exception AFTER clearing the pointer!
        exc.check()

    def __getitem__(self, point):
        point = Vector.coerce(point)

        cdef MagickException exc = MagickException()
        cdef c_api.PixelPacket px

        # TODO retval is t/f
        c_api.GetOneCacheViewAuthenticPixel(self._ptr, point.x, point.y, &px, exc.ptr)
        exc.check()

        return RGBColor(
            _quantum_to_double(px.red),
            _quantum_to_double(px.green),
            _quantum_to_double(px.blue),
            # ImageMagick thinks opacity is transparency
            1.0 - _quantum_to_double(px.opacity))




    #def iter(self, Rectangle rect = None):
    def __iter__(self):
        rect = self._frame.canvas

        cdef int rows = self._frame._frame.rows
        cdef int columns = self._frame._frame.columns

        cdef int x
        cdef int y

        cdef MagickException exc = MagickException()

        cdef c_api.PixelPacket* q

        cdef PixelViewPixel pixel = PixelViewPixel.__new__(PixelViewPixel)
        pixel.owner = self

        for y in range(rect.top, rect.bottom):
            q = c_api.GetCacheViewAuthenticPixels(self._ptr, rect.left, y, rect.width, 1, exc.ptr)
            # TODO check q for NULL
            exc.check()

            # TODO is this useful who knows
            #fx_indexes=GetCacheViewAuthenticIndexQueue(fx_view);

            try:
                for x in range(rect.left, rect.right):
                    # TODO this probably needs to do something else for indexed
                    try:
                        # TODO rather than /always/ reusing the same pixel
                        # object, only reuse it if it's detected as only having
                        # one refcnt left  :)
                        pixel._pixel = q
                        pixel._x = x
                        pixel._y = y
                        yield pixel
                    finally:
                        pixel._pixel = NULL

                    #ret = ClampToQuantum((MagickRealType) QuantumRange * ret)
                    # TODO opacity...

                    # XXX this is black for CMYK
                    #  if (((channel & IndexChannel) != 0) && (fx_image->colorspace == CMYKColorspace)) {
                    #      SetPixelIndex(fx_indexes+x,ClampToQuantum((MagickRealType) QuantumRange*alpha));
                    #    }

                    inc(q)
            finally:
                # TODO check return value
                c_api.SyncCacheViewAuthenticPixels(self._ptr, exc.ptr)
                exc.check()


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

    property canvas:
        """Dimensions and offset of the drawable area of this frame, relative
        to the image's full size.
        """
        def __get__(self):
            return Rectangle(
                self._frame.page.x,
                self._frame.page.y,
                self._frame.page.x + self._frame.columns,
                self._frame.page.y + self._frame.rows,
            )

    property size:
        """Size of the frame, as a `Size`.  Shortcut for `frame.canvas.size`.
        """
        def __get__(self):
            return Size(self._frame.columns, self._frame.rows)

    property has_canvas:
        """Returns `True` if this frame has a non-trivial virtual canvas; i.e.,
        returns `False` if the virtual canvas is the same size as the image and
        anchored at the origin.
        """
        def __get__(self):
            return (
                self._frame.page.x != 0 or
                self._frame.page.y != 0 or
                self._frame.page.width != self._frame.columns or
                self._frame.page.height != self._frame.rows
            )

    property translucent:
        """`True` if this frame has an alpha channel.

        You can assign to this attribute to toggle the alpha channel; note that
        if you set this to `True` and the frame did not previously have an
        alpha channel, an all-opaque one will be created.
        """
        def __get__(self):
            return self._frame.matte == c_api.MagickTrue

        def __set__(self, bool value not None):
            if value == self.translucent:
                return

            if value:
                # Set the alpha channel
                c_api.SetImageAlphaChannel(self._frame, c_api.SetAlphaChannel)
            else:
                # Disable it
                c_api.SetImageAlphaChannel(self._frame, c_api.DeactivateAlphaChannel)

            check_magick_exception(&self._frame.exception)

    ### Pixel access

    @property
    def pixels(self):
        return PixelView(self)

    ### Whole-frame manipulation

    # TODO perhaps a mutating version of this would be useful for painting
    def tiled(self, size):
        size = Size.coerce(size)

        cdef Image new = Image.new(size)

        # TODO this returns a bool?
        c_api.TextureImage(new._stack, self._frame)
        check_magick_exception(&self._frame.exception)

        return new

    ### Color

    def replace_color(self, RGBColor color, RGBColor replacement,
            *, float fuzz = 0.0):

        cdef c_api.MagickPixelPacket from_
        color._populate_magick_pixel(&from_)
        from_.c_struct.fuzz = fuzz

        cdef c_api.MagickPixelPacket to
        replacement._populate_magick_pixel(&to)
        to.c_struct.fuzz = fuzz

        c_api.OpaquePaintImage(self._frame, &from_, &to, c_api.MagickFalse)


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
    def new(type cls, size not None, *, RGBColor fill=None):
        """Create a new image (with one frame) of the given size."""
        size = Size.coerce(size)

        cdef Image self = cls()
        cdef c_api.ImageInfo* image_info = c_api.CloneImageInfo(NULL)
        cdef c_api.MagickPixelPacket magick_pixel

        try:
            if fill is None:
                # TODO need a way to explicitly create a certain color
                fill = RGBColor.parse('#00000000')

            fill._populate_magick_pixel(&magick_pixel)

            self._stack = c_api.NewMagickImage(image_info, size.width, size.height, &magick_pixel)
            check_magick_exception(&self._stack.exception)
        finally:
            c_api.DestroyImageInfo(image_info)

        self._post_init()
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

        self._post_init()
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

        self._post_init()
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

        self._post_init()
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

            # Stupid hack to fix a bug in the rgb codec
            if format == 'rgba' and not self._stack.matte:
                c_api.SetImageAlphaChannel(self._stack, c_api.OpaqueAlphaChannel)
                check_magick_exception(&self._stack.exception)

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

    cdef _post_init(self):
        """Do some setup that only needs doing after a stack of images has been
        loaded.

        Please don't forget to call me.  :)
        """
        self._setup_frames()
        self._fix_page()

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

    cdef _fix_page(self):
        """Sometimes, the page is 0x0.  This is totally bogus.  Fix it."""
        cdef ImageFrame frame
        cdef c_api.Image* c_frame

        for frame in self._frames:
            c_frame = frame._frame
            if c_frame.page.width == 0 or c_frame.page.height == 0:
                c_frame.page.width = c_frame.columns
                c_frame.page.height = c_frame.rows

        # TODO other page problems are possible, especially when adopting new frames
        # TODO possibly should keep the page size the same across all frames; makes no sense otherwise
        # TODO frames may also have different colorspace, matte, palette...  this is problematic
        # TODO should this live on ImageFrame perhaps?


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

    property size:
        """The image dimensions, as a `Size`.  Empty images have zero size.

        Note that multi-frame images don't have a notion of intrinsic size for
        the entire image, though particular formats may enforce that every
        frame be the same size.  If the image has multiple frames, this returns
        the size of the first frame, which is in line with most image-handling
        software.
        """

        def __get__(self):
            # Note that this doesn't use the rows+columns; the size of the
            # ENTIRE IMAGE is the size of the virtual canvas.
            # TODO the canvas might be different between different frames!  see
            # if this happens on load, try to preserve it with operations
            if self._stack == NULL:
                return Size(0, 0)

            return Size(self._stack.page.width, self._stack.page.height)

    property has_canvas:
        """Returns `True` iff any frame has a canvas."""
        def __get__(self):
            return any(f.has_canvas for f in self)

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

    def resized(self, size, filter=None):
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
                raise

            c_api.AppendImageToList(&new._stack, new_frame)
            p = c_api.GetNextImageInList(p)

        new._post_init()
        return new

    def cropped(self, Rectangle rect, *, bool preserve_canvas not None=False):
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
                raise

            # Repage by default after a crop; not doing this is unexpected and
            # frankly insane
            # TODO how necessary is this?  should it be done for frames?
            if not preserve_canvas:
                new_frame.page.x = 0
                new_frame.page.y = 0
                new_frame.page.width = 0
                new_frame.page.height = 0

            c_api.AppendImageToList(&new._stack, new_frame)
            p = c_api.GetNextImageInList(p)

        new._post_init()
        return new


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
