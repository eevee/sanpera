from sanpera._api import ffi, lib

from sanpera.color import RGBColor
from sanpera.geometry import Size

def blank_image_info():
    return ffi.gc(
        lib.CloneImageInfo(ffi.NULL),
        lib.DestroyImageInfo)

def blank_magick_pixel():
    magick_pixel = ffi.new("MagickPixelPacket *")
    lib.GetMagickPixelPacket(ffi.NULL, magick_pixel)
    return magick_pixel



from contextlib import contextmanager
@contextmanager
def magick_exception_context():
    ctx = MagickExceptionContext()
    yield ctx
    ctx.check_self()

class MagickExceptionContext(object):
    def __init__(self):
        self.ptr = ffi.gc(
            lib.AcquireExceptionInfo(),
            lib.DestroyExceptionInfo)

    def check(self, condition):
        if not condition:
            return

        raise RuntimeError

    def check_self(self):
        if self.ptr.severity == lib.UndefinedException:
            return

        raise RuntimeError

    #def _examine_magick_exception


class ImageFrame(object):
    """Represents a single frame, and knows how to perform most operations on
    it.
    """

    ### setup, teardown
    # nb: even though this object acts merely as a view to a frame of an
    # existing Image, the frame might persist after the image is destroyed, so
    # we need to use refcounting

    def __init__(self, _raw_frame):
        lib.ReferenceImage(_raw_frame)
        self._frame = ffi.gc(_raw_frame, lib.DestroyImage)



class Image(object):
    """An image.  If you don't know what this is, you may be using the wrong
    library.
    """

    ### Constructors (input)

    def __init__(self, _c_stack=None):
        """Create a new image with zero frames.  This is /probably/ not what
        you want; consider using `Image.new()` instead.
        """
        # The _c_stack argument is for internal use and is expected to be a
        # wrapped GC'd pointer to an Image.  Please don't dick around with it.
        if _c_stack is None:
            self._stack = ffi.NULL
        else:
            # Blank out the filename so IM doesn't try to write to it later
            _c_stack.filename[0] = '\0'

            self._stack = _c_stack

        self._frames = []
        self._setup_frames()

        self._fix_page()

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

        ptr = ffi.gc(
            lib.NewMagickImage(image_info, size.width, size.height, magick_pixel),
            lib.DestroyImageList)
        check_magick_exception(ptr.exception)

        return cls(ptr)

    @classmethod
    def read(cls, filename):
        with open(filename, "rb") as fh:
            fd = fh.fileno()
            fileptr = lib.fdopen(fd, b"r")

            image_info = blank_image_info()

            with magick_exception_context() as exc:
                image_info.file = fileptr
                ptr = ffi.gc(
                    lib.ReadImage(image_info, exc.ptr),
                    lib.DestroyImageList)
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

        self = cls()

        image_info = blank_image_info()
        with magick_exception_context() as exc:
            ptr = lib.BlobToImage(image_info, ffi.cast("void *", ffi.cast("char *", buf)), len(buf), exc.ptr)
            exc.check(ptr == ffi.NULL)

        return cls(ptr)

    @classmethod
    def from_magick(cls, name):
        """Passes a filename specifier directly to ImageMagick.

        This allows reading from any of the magic pseudo-formats, like
        `clipboard` and `null`.  Use with care with user input!
        """
        image_info = blank_image_info()

        #libc_string.strncpy(image_info.filename, <char*>name, c_api.MaxTextExtent)
        image_info.filename = name

        with magick_exception_context() as exc:
            ptr = ffi.gc(
                lib.ReadImage(image_info, exc.ptr),
                lib.DestroyImageList)
            exc.check(ptr == ffi.NULL)

        # Blank out the magick format just in case ImageMagick decides to write
        # to it later
        ptr.magick[0] = '\0'

        return cls(ptr)

    def _setup_frames(self, start=None):
        # Shared by constructors to read the frame list out of the new image

        if start:
            p = start
        else:
            p = self._stack

        while p:
            self._frames.append(ImageFrame(p))
            p = lib.GetNextImageInList(p)

    def _fix_page(self):
        """Sometimes, the page is 0x0.  This is totally bogus.  Fix it."""
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
        # TODO just use len(self._frames)?
        return lib.GetImageListLength(self._stack)

    def __nonzero__(self):
        return self._stack != ffi.NULL

    def __iter__(self):
        return iter(self._frames)

    def __getitem__(self, key):
        return self._frames[key]

    # TODO
    #def __setitem__(self, key, value):


    ### Properties

    # TODO critically important: how do these work with multiple images!
    # TODO read the convert usage a bit more carefully; there seems to be some deliberate difference in behavior between "bunch of images" and "bunch of frames".  for that matter, how DOES convert treat stuff like this?
    # TODO anyway, conclusion of that thought was that sticking frames onto other images should do more than just diddle pointers
    @property
    def original_format(self):
        return ffi.string(self._stack.magick)

    @property
    def size(self):
        """The image dimensions, as a `Size`.  Empty images have zero size.

        Note that multi-frame images don't have a notion of intrinsic size for
        the entire image, though particular formats may enforce that every
        frame be the same size.  If the image has multiple frames, this returns
        the size of the first frame, which is in line with most image-handling
        software.
        """

        # Note that this doesn't use the rows+columns; the size of the
        # ENTIRE IMAGE is the size of the virtual canvas.
        # TODO the canvas might be different between different frames!  see
        # if this happens on load, try to preserve it with operations
        if self._stack == ffi.NULL:
            return Size(0, 0)

        return Size(self._stack.page.width, self._stack.page.height)
