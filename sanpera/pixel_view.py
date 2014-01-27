# TODO name of the wrapped c pointer is wildly inconsistent
# TODO i am probably leaking like a sieve here
# TODO MemoryErrors and other such things the cython docs advise
# TODO docstrings
# TODO expose more properties and whatever to python-land
# TODO threadsafety?
# TODO check boolean return values more often
# TODO really, really want to be able to dump out an image or info struct.  really.
from __future__ import print_function

from sanpera._api import ffi, lib
from sanpera.color import RGBColor
from sanpera.exception import magick_try
from sanpera.geometry import Vector

### Frame

class PixelViewPixel(object):
    """Transient pixel access object.  Can be used to examine and set a single
    pixel's color.
    """
    # Note that this stuff is only set by its consumer, PixelView
    def __init__(self):
        raise TypeError("PixelViewPixel cannot be instantiated directly")

    @property
    def color(self):
        # XXX this needs to do something special to handle non-rgba images
        if self._pixel == ffi.NULL:
            raise ValueError("Pixel has expired")
        array = ffi.new("double[]", 4)
        lib.sanpera_pixel_to_doubles(self._pixel, array)
        return RGBColor(*array)

    @color.setter
    def color(self, value):
        if self._pixel == ffi.NULL:
            raise ValueError("Pixel has expired")
        array = ffi.new("double[]", [value._red, value._green, value._blue, value._opacity])
        lib.sanpera_pixel_from_doubles(self._pixel, array)

    @property
    def point(self):
        return Vector(self._x, self._y)


def _cache_view_destructor(cache_view):
    with magick_try() as exc:
        # TODO bool return value as well
        lib.SyncCacheViewAuthenticPixels(cache_view, exc.ptr)
        lib.DestroyCacheView(cache_view)


class PixelView(object):
    """Can view and manipulate individual pixels of a frame."""

    def __init__(self, frame):
        self._frame = frame
        self._ptr = ffi.gc(
            lib.AcquireCacheView(frame._frame),
            _cache_view_destructor)

    def __getitem__(self, point):
        point = Vector.coerce(point)

        px = ffi.new("PixelPacket *")

        # TODO retval is t/f
        with magick_try() as exc:
            lib.GetOneCacheViewAuthenticPixel(self._ptr, point.x, point.y, px, exc.ptr)

        array = ffi.new("double[]", 4)
        lib.sanpera_pixel_to_doubles(px, array)
        return RGBColor(*array)

    def __setitem__(self, point, color):
        """Set a single pixel to a given color.

        This is "slow", in the sense that you probably don't want to do this to
        edit every pixel in an entire image.
        """
        point = Vector.coerce(point)
        rgb = color.rgb()

        # TODO retval is t/f
        with magick_try() as exc:
            # Surprise!  GetOneCacheViewAuthenticPixel doesn't actually respect
            # writes, even though the docs explicitly says it does.
            # So get a view of this single pixel instead.
            px = lib.GetCacheViewAuthenticPixels(
                self._ptr, point.x, point.y, 1, 1, exc.ptr)
            exc.check(px == ffi.NULL)

        array = ffi.new("double[]", [rgb._red, rgb._green, rgb._blue, rgb._opacity])
        lib.sanpera_pixel_from_doubles(px, array)
        #print(repr(ffi.buffer(ffi.cast("char*", ffi.cast("void*", px)), 16)[:]))

        with magick_try() as exc:
            assert lib.SyncCacheViewAuthenticPixels(self._ptr, exc.ptr)



    def __iter__(self):
        rect = self._frame.canvas

        pixel = PixelViewPixel.__new__(PixelViewPixel)
        # This is needed so that the pixel cannot exist after the view is
        # destroyed -- it's a wrapper around a bare pointer!
        pixel.owner = self

        for y in range(rect.top, rect.bottom):
            with magick_try() as exc:
                q = lib.GetCacheViewAuthenticPixels(self._ptr, rect.left, y, rect.width, 1, exc.ptr)
                # TODO check q for NULL

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
                        pixel._pixel = ffi.NULL

                    #ret = RoundToQuantum((MagickRealType) QuantumRange * ret)
                    # TODO opacity...

                    # XXX this is black for CMYK
                    #  if (((channel & IndexChannel) != 0) && (fx_image->colorspace == CMYKColorspace)) {
                    #      SetPixelIndex(fx_indexes+x,RoundToQuantum((MagickRealType) QuantumRange*alpha));
                    #    }

                    # Pointer increment
                    q += 1
            finally:
                # TODO check return value
                with magick_try() as exc:
                    assert lib.SyncCacheViewAuthenticPixels(self._ptr, exc.ptr)


