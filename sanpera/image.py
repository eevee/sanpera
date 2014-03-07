from __future__ import absolute_import
from __future__ import division

import contextlib

from sanpera._api import ffi, lib
from sanpera.color import RGBColor
from sanpera.exception import EmptyImageError
from sanpera.exception import MissingFormatError
from sanpera.exception import magick_raise
from sanpera.exception import magick_try
from sanpera.geometry import Rectangle
from sanpera.geometry import Size
from sanpera.geometry import origin
from sanpera.pixel_view import PixelView

def blank_image_info():
    return ffi.gc(
        lib.CloneImageInfo(ffi.NULL),
        lib.DestroyImageInfo)


def blank_magick_pixel():
    magick_pixel = ffi.new("MagickPixelPacket *")
    lib.GetMagickPixelPacket(ffi.NULL, magick_pixel)
    return magick_pixel


class ImageFrame(object):
    """Represents a single frame of an image (i.e. all the pixel data), and
    knows how to perform most operations on it.

    Frames are mutable and, like most objects in Python, are never copied
    implicitly.  It's perfectly valid to put the same frame in more than one
    `Image`, for example.  If you want a copy, ask for it explicitly with
    `ImageFrame.copy()`.
    """

    def __init__(self, _raw_frame):
        # This class has ultimate ownership of each Image pointer, so do the gc
        # stuff here.
        _frame = self._frame = ffi.gc(_raw_frame, lib.DestroyImage)

        # New frames need their filenames blanked, lest ImageMagick decide
        # to ignore our pleas and write to the same file
        _frame.filename[0] = b'\0'
        # ...yeah this too
        #_frame.magick[0] = b'\0'

        # Sometimes a new image's "page" is 0x0, which is totally bogus
        if _frame.page.width == 0 or _frame.page.height == 0:
            _frame.page.width = _frame.columns
            _frame.page.height = _frame.rows

        # TODO other page problems are possible, especially when adopting new frames
        # TODO possibly should keep the page size the same across all frames; makes no sense otherwise
        # TODO frames may also have different colorspace, matte, palette...  this is problematic

    def copy(self):
        """Returns a lazy copy of this frame.  Pixel data is not copied until
        either this or the new frame are modified.
        """
        # 0, 0 => size; 0x0 means to reuse the same pixel cache
        # 1 => orphan; clear the previous/next pointers, detach i/o stream
        with magick_try() as exc:
            cloned_frame = lib.CloneImage(self._frame, 0, 0, 1, exc.ptr)
            exc.check(cloned_frame == ffi.NULL)

        return type(self)(cloned_frame)

    ### Internal hackery

    def _fix_for_rgba_codec(self):
        # Older versions of ImageMagick spit out garbage for the alpha channel
        # when writing an alphaless image as "rgba".
        if not self._frame.matte:
            lib.SetImageAlphaChannel(self._frame, lib.OpaqueAlphaChannel)
            magick_raise(self._frame.exception)

    ### Frame properties

    @property
    def canvas(self):
        """Dimensions and offset of the drawable area of this frame, relative
        to the image's full size.
        """
        # TODO is it really relative to the image's full size?  what if the
        # frames disagree on what the "page" is?  it should be the first
        # frame's page, but we can't see that from here  :(
        return Rectangle(
            self._frame.page.x,
            self._frame.page.y,
            self._frame.page.x + self._frame.columns,
            self._frame.page.y + self._frame.rows,
        )

    @property
    def size(self):
        """Size of the frame, as a `Size`.  Shortcut for `frame.canvas.size`.
        """
        return Size(self._frame.columns, self._frame.rows)

    @property
    def has_canvas(self):
        """`True` iff this frame has a non-trivial virtual canvas; i.e.,
        `False` if the virtual canvas is the same size as the image and
        anchored at the origin.
        """
        return (
            self._frame.page.x != 0 or
            self._frame.page.y != 0 or
            self._frame.page.width != self._frame.columns or
            self._frame.page.height != self._frame.rows
        )

    @property
    def translucent(self):
        """`True` iff this frame has an alpha channel.

        You can assign to this attribute to toggle the alpha channel; note that
        if you set this to `True` and the frame did not previously have an
        alpha channel, an all-opaque one will be created.
        """
        return self._frame.matte == lib.MagickTrue

    @translucent.setter
    def translucent(self, value):
        if bool(value) == self.translucent:
            return

        if value:
            # Set the alpha channel
            lib.SetImageAlphaChannel(self._frame, lib.SetAlphaChannel)
        else:
            # Disable it
            lib.SetImageAlphaChannel(self._frame, lib.DeactivateAlphaChannel)

        magick_raise(self._frame.exception)

    ### Pixel access

    @property
    def pixels(self):
        return PixelView(self)

    ### Whole-frame manipulation

    # TODO perhaps a mutating version of this would be useful for painting
    def tiled(self, size):
        size = Size.coerce(size)

        new = Image.new(size)

        # TODO this returns a bool?
        lib.TextureImage(new._stack, self._frame)
        magick_raise(self._frame.exception)

        return new

    ### Color

    def replace_color(self, color, replacement, fuzz=0.):
        from_ = blank_magick_pixel()
        color._populate_magick_pixel(from_)
        from_.fuzz = fuzz

        to = blank_magick_pixel()
        replacement._populate_magick_pixel(to)
        to.fuzz = fuzz

        lib.OpaquePaintImage(self._frame, from_, to, lib.MagickFalse)



def _assert_is_frame(value):
    if not isinstance(value, ImageFrame):
        raise TypeError("expected ImageFrame, got {0!r}".format(value))


class Image(object):
    """An image.  Images contain no pixel data themselves; they're actually
    (mutable) sequences of `ImageFrame` objects.  Most list operations work on
    `Image`, though the contents must be frames.

    Working with single-frame images is slightly more tedious, as you must use
    ``image[0]`` to do interesting things to pixels, but this approach results
    in fewer surprises when your carefully-crafted image pipeline is suddenly
    fed a GIF.

    Image *metadata* remains on the `Image`; this includes the original file
    format, color mode (indexed or not), JPEG metadata, PNG comments, and the
    like.  Writing out an image makes a best effort to preserve all of this,
    even when writing out to a different format.  See `Image.write` for further
    details on how to control output.
    """

    ### Constructors (input)

    def __init__(self, _c_stack=None):
        """Create a new image with zero frames.  This is /probably/ not what
        you want; consider using `Image.new()` instead.
        """
        # The _c_stack argument is for internal use and is expected to be a
        # pointer to an Image.  Please don't dick around with it.
        # TODO: it's remotely possible to have a memory leak if a Python
        # exception happens BETWEEN the creation of the Image* and the call to
        # this function.  but i can only gc() pointers on the outside with
        # DestroyImageList, which I can't undo later when trying to split the
        # list into frames.  unclear what to do about this, if anything even
        # needs doing at all.
        if _c_stack is None:
            self._frames = []
        else:
            # Rather than rely on ImageMagick, internally store the frames as a
            # list of ImageFrame objects, each of which has ownership of its
            # pointer
            self._frames = self._image_list_to_frames(_c_stack)

    @classmethod
    def new(cls, size, fill=None):
        """Create a new image (with one frame) of the given size."""
        size = Size.coerce(size)

        image_info = blank_image_info()
        magick_pixel = blank_magick_pixel()

        if fill is None:
            # TODO need a way to explicitly create a certain color
            fill = RGBColor(0., 0., 0., 0.)

        fill._populate_magick_pixel(magick_pixel)

        ptr = lib.NewMagickImage(image_info, size.width, size.height, magick_pixel)
        magick_raise(ptr.exception)

        return cls(ptr)

    @classmethod
    def read(cls, filename):
        with open(filename, "rb") as fh:
            image_info = blank_image_info()
            image_info.file = ffi.cast("FILE *", fh)

            with magick_try() as exc:
                ptr = lib.ReadImage(image_info, exc.ptr)
                exc.check(ptr == ffi.NULL)

        return cls(ptr)

    # TODO: there's no way to read from an arbitrary python file-like, because
    # ImageMagick doesn't support streaming, and I'd rather not have the caller
    # believe there's some cool lazy API when I'd really just be buffering the
    # whole thing and then throwing it away.
    # there IS a workaround, sort of.  some platforms can make a FILE* that
    # reads data from callbacks: funopen on BSD, fopencookie on linux.  it
    # would be peachy-keen to use those when available, and fall back to
    # buffering on other unixes and windows.

    @classmethod
    def from_buffer(cls, buf):
        assert isinstance(buf, bytes)

        image_info = blank_image_info()
        with magick_try() as exc:
            ptr = lib.BlobToImage(image_info, buf, len(buf), exc.ptr)
            exc.check(ptr == ffi.NULL)

        return cls(ptr)

    @classmethod
    def from_magick(cls, name):
        """Passes a filename specifier directly to ImageMagick.

        This allows reading from any of the magic pseudo-formats, like
        `clipboard` and `null`.  Use with care with user input!
        """
        image_info = blank_image_info()

        # Make sure not to overflow the char[]
        # TODO maybe just error out when this happens
        image_info.filename = name.encode('ascii')[:lib.MaxTextExtent]

        with magick_try() as exc:
            ptr = lib.ReadImage(image_info, exc.ptr)
            exc.check(ptr == ffi.NULL)

        return cls(ptr)

    ### Output
    # XXX for all of these: check that the target format supports the number of images!
    # TODO support the wacky sprintf style of dumping images out i guess

    def write(self, filename, format=None):
        if not self._frames:
            raise EmptyImageError

        with open(filename, "wb") as fh:
            image_info = blank_image_info()
            image_info.file = ffi.cast("FILE *", fh)

            # Force writing to a single file
            image_info.adjoin = lib.MagickTrue

            if format:
                # If the caller provided an explicit format, pass it along
                # Make sure not to overflow the char[]
                # TODO maybe just error out when this happens
                image_info.magick = format.encode('ascii')[:lib.MaxTextExtent]
            elif self._frames[0]._frame.magick[0] == b'\0':
                # Uhoh; no format provided and nothing given by caller
                raise MissingFormatError
            # TODO detect format from filename if explicitly asked to do so

            with self._link_frames(self._frames) as ptr:
                lib.WriteImage(image_info, ptr)
                magick_raise(ptr.exception)

    def to_buffer(self, format=None):
        if not self._frames:
            raise EmptyImageError

        image_info = blank_image_info()
        length = ffi.new("size_t *")

        # Force writing to a single file
        image_info.adjoin = lib.MagickTrue

        # Stupid hack to fix a bug in the rgb codec
        if format == 'rgba':
            for frame in self._frames:
                frame._fix_for_rgba_codec()

        if format:
            # If the caller provided an explicit format, pass it along
            # Make sure not to overflow the char[]
            # TODO maybe just error out when this happens
            image_info.magick = format.encode('ascii')[:lib.MaxTextExtent]
        elif self._stack.magick[0] == b'\0':
            # Uhoh; no format provided and nothing given by caller
            raise MissingFormatError

        with magick_try() as exc:
            with self._link_frames(self._frames) as ptr:
                cbuf = ffi.gc(
                    lib.ImagesToBlob(image_info, ptr, length, exc.ptr),
                    lib.RelinquishMagickMemory)

        return ffi.buffer(cbuf, length[0])



    ### Sequence operations

    def _image_list_to_frames(self, images):
        # Given an Image* of presumably bare pointers, return a list of
        # ImageFrames.
        frames = []
        p = images

        while p:
            frames.append(ImageFrame(p))
            p = lib.GetNextImageInList(p)

        self._break_frame_pointers(frames)

        return frames

    def _break_frame_pointers(self, frames):
        # Given a list of ImageFrames, break the links between them, to prevent
        # having any unintended links get written out later -- or, worse, to
        # leave dangling pointers when frames are rearranged
        for frame in frames:
            frame._frame.previous = ffi.NULL
            frame._frame.next = ffi.NULL

            # Some ImageMagick codecs feel free to mess with this, which makes
            # lots of image operations then not work at all.  Charming!
            # TODO this should probably not be so blunt, so indexed images are
            # actually handled correctly...  when they're handled correctly at
            # all, hm.
            # TODO also, it appears ImageMagick doesn't set this correctly when
            # /loading/ an image, hence never having this as a problem before.
            frame._frame.storage_class = lib.DirectClass

    @contextlib.contextmanager
    def _link_frames(self, frames):
        # Temporarily add previous/next links to the list of frames, turning
        # them into an ImageList that ImageMagick will understand.
        # It's important to do this ONLY temporarily, lest we end up with
        # dangling pointers.
        # Yields a pointer to the head of the list.
        if not frames:
            yield ffi.NULL
            return

        pointers = [frame._frame for frame in frames]

        for one, two in zip(pointers, pointers[1:]):
            one.next = two
            two.previous = one

        pointers[0].previous = ffi.NULL
        pointers[-1].next = ffi.NULL

        try:
            yield pointers[0]
        finally:
            self._break_frame_pointers(frames)



    def __len__(self):
        return len(self._frames)

    def __bool__(self):
        return bool(self._frames)

    __nonzero__ = __bool__

    def __iter__(self):
        return iter(self._frames)

    def __getitem__(self, key):
        return self._frames[key]

    def __setitem__(self, key, value):
        _assert_is_frame(value)
        self._frames[key] = value

    # TODO stop mucking with ._frame so much and just add methods to Frame
    # TODO turn all this stuff into a single get/set slice interface?
    def append(self, value):
        """Appends a frame to the end of this image."""
        _assert_is_frame(value)
        self._frames.append(value)

    def extend(self, other):
        """Adds a sequence of frames (perhaps another `Image`) to the end of
        this image.
        """
        # The other sequence might be a generator, so avoid looping over it
        # twice
        append = self._frames.append
        for value in other:
            _assert_is_frame(value)
            append(value)


    ### Properties

    # TODO remove me
    @property
    def _stack(self):
        return self._frames[0]._frame

    # XXX this stuff is clearly broken

    # TODO critically important: how do these work with multiple images!
    # TODO read the convert usage a bit more carefully; there seems to be some deliberate difference in behavior between "bunch of images" and "bunch of frames".  for that matter, how DOES convert treat stuff like this?
    # TODO anyway, conclusion of that thought was that sticking frames onto other images should do more than just diddle pointers
    @property
    def original_format(self):
        return ffi.string(self._stack.magick)

    @property
    def size(self):
        """The image dimensions, as a `Size`.  Empty images have zero size.

        Some image formats support a canvas offset, in which case this value
        may not match the actual drawable area.  See `ImageFrame.canvas`.

        Note that multi-frame images don't have a notion of intrinsic size for
        the entire image, though particular formats may enforce that every
        frame be the same size.  If the image has multiple frames, this returns
        the size of the first frame, which is in line with most image-handling
        software.
        """

        if self._frames:
            _frame = self._frames[0]._frame
            # Note that this doesn't use .rows/.columns, as those are the size
            # of the pixel area.  The "page" is the size of the canvas, which
            # is the size of the image itself.
            # TODO the canvas might be different between different frames!  see
            # if this happens on load, try to preserve it with operations
            return Size(_frame.page.width, _frame.page.height)
        else:
            return Size(0, 0)

    @property
    def has_canvas(self):
        """Return `True` iff any frame has a canvas."""
        return any(f.has_canvas for f in self)

    @property
    def bit_depth(self):
        return self._stack.depth

    @bit_depth.setter
    def bit_depth(self, value):
        # TODO i'm increasingly inclined to think this should be read off the
        # image on read and written back to the top frame on write.
        self._frames[0]._frame.depth = value

    # TODO this will have to become a proxy thing for it to support assignment
    # TODO i am not a huge fan of this name, but 'metadata' is too expansive
    # TODO can the same property appear multiple times?  cf PNG text chunks
    # TODO this prefixing thing sucks as UI, and stuff like dates should be parsed
    @property
    def raw_properties(self):
        # TODO may need SyncImageProfiles() somewhere?  it updates EXIF res and
        # orientation
        ret = {}

        # This tricks IM into actually reading the EXIF properties...
        lib.GetImageProperty(self._stack, "exif:*")

        lib.ResetImagePropertyIterator(self._stack)
        while True:
            # XXX this only examines the top image uhoh.  do we care?  what
            # happens if i load a GIF; what does each frame say?  what happens
            # if i have multiple images with different props and save as one
            # image?
            prop = lib.GetNextImageProperty(self._stack)
            if prop == ffi.NULL:
                break

            ret[ffi.string(prop)] = ffi.string(lib.GetImageProperty(self._stack, prop))

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

        p = self._stack
        new_stack_ptr = ffi.new("Image **", ffi.NULL)

        if filter == 'box':
            c_filter = lib.BoxFilter
        else:
            c_filter = lib.UndefinedFilter

        target_width = size.width
        target_height = size.height
        ratio_width = target_width / (self._stack.page.width or self._stack.columns)
        ratio_height = target_height / (self._stack.page.height or self._stack.rows)

        while p:
            # Alrighty, so.  ResizeImage takes the given size as the new size
            # of the FRAME, rather than the CANVAS, which is almost certainly
            # not what anyone expects.  So do the math to fix this manually,
            # converting from canvas size to frame size.
            frame_width = int(p.columns * ratio_width + 0.5)
            frame_height = int(p.rows * ratio_height + 0.5)

            with magick_try() as exc:
                if c_filter == lib.BoxFilter:
                    # Use the faster ScaleImage in this special case
                    new_frame = lib.ScaleImage(
                        p, frame_width, frame_height, exc.ptr)
                else:
                    new_frame = lib.ResizeImage(
                        p, frame_width, frame_height,
                        c_filter, 1.0, exc.ptr)

            # TODO how do i do this correctly etc?  will it ever be non-null??
            #except Exception:
            #    lib.DestroyImage(new_frame)

            # ImageMagick uses new_size/old_size to compute the resized frame's
            # position.  But new_size has already been rounded, so for small
            # frames in a large image, the double rounding error can place the
            # new frame a noticable distance from where one might expect.  Fix
            # the canvas manually, too.
            new_frame.page.width = target_width
            new_frame.page.height = target_height
            new_frame.page.x = int(p.page.x * ratio_width + 0.5)
            new_frame.page.y = int(p.page.y * ratio_height + 0.5)

            lib.AppendImageToList(new_stack_ptr, new_frame)
            p = lib.GetNextImageInList(p)

        return type(self)(new_stack_ptr[0])

    def cropped(self, rect, preserve_canvas=False):
        rectinfo = rect.to_rect_info()

        p = self._stack
        new_stack_ptr = ffi.new("Image **", ffi.NULL)

        while p:
            with magick_try() as exc:
                new_frame = lib.CropImage(p, rectinfo, exc.ptr)

                # Only GC the first frame in the stack, since the others will be
                # in the same list and thus nuked automatically
                if new_stack_ptr == ffi.NULL:
                    new_frame = ffi.gc(new_frame, lib.DestroyImageList)

            lib.AppendImageToList(new_stack_ptr, new_frame)
            p = lib.GetNextImageInList(p)

        new = type(self)(new_stack_ptr[0])

        # Repage by default after a crop; not doing this is unexpected and
        # frankly insane.  Plain old `+repage` behavior would involve nuking
        # the page entirely, but that would screw up multiple frames; instead,
        # shift the canvas for every frame so the crop region's upper left
        # corner is the new origin, and fix the dimensions so every frame fits
        # (up to the size of the crop area, though ImageMagick should never
        # return an image bigger than the crop area...  right?)
        if not preserve_canvas:
            # ImageMagick actually behaves when the crop area extends out
            # beyond the origin, so don't fix the edges in that case
            # TODO this is complex enough that i should perhaps just do it
            # myself
            left_delta = max(rect.left, 0)
            top_delta = max(rect.top, 0)
            # New canvas should be the size of the overlap between the current
            # canvas and the crop area
            new_canvas = rect.intersection(self.size.at(origin))
            new_height = new_canvas.height
            new_width = new_canvas.width
            for frame in new:
                frame._frame.page.x -= left_delta
                frame._frame.page.y -= top_delta
                frame._frame.page.height = new_height
                frame._frame.page.width = new_width

        return new


    def coalesced(self):
        """Returns an image with each frame composited over previous frames."""
        with magick_try() as exc:
            new_image = ffi.gc(
                lib.CoalesceImages(self._stack, exc.ptr),
                lib.DestroyImageList)

        return type(self)(new_image)

    def optimized_for_animated_gif(self):
        """Returns an image with frames optimized for animated GIFs.

        Each frame will be compared with previous frames to shrink each frame
        as much as possible while preserving the results of the animation.
        """
        with magick_try() as exc:
            new_image = lib.OptimizeImageLayers(self._stack, exc.ptr)
        with magick_try() as exc:
            lib.OptimizeImageTransparency(new_image, exc.ptr)

        return type(self)(new_image)


# TODO does this belong here?  it IS a way to create an Image, i suppose
def gradient(size, from_color, to_color, image_cls=Image):
    image = image_cls.new(size)
    # TODO not sure i want draw imported globally
    from sanpera.draw import Brush
    brush = Brush(image[0])
    brush.gradient(from_color, to_color)
    return image


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
