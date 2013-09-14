from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from sanpera._api import ffi, lib
from sanpera.color import BaseColor
from sanpera.color import RGBColor
from sanpera.exception import magick_try
from sanpera.image import Image
from sanpera.image import ImageFrame

# ALRIGHT JACKASS let's sort this mess out.
# PROBLEMS:
# - need to be able to use imagemagick filters as they are
# - need to be able to write new filters in cython
# - need to be able to write new filters in python
# - need to be able to accelerate python filters, via overloading
# MO PROBLEMS:
# - need to apply to entire image at once
# - need to apply /the same fucking filter/ to one channel at a time (or in
# parallel)
# OPERATIONS:
# - current pixel color (might be grayscale for per-channel!)
# - neighborhood pixel colors (TODO how to restrict the range?  or do i at
# all?)
# - stuff from math (sin, cos, ...)
# OUTPUT:
# should it return a color?  how does IM do this uhoh
# WRINKLES:
# - apply a filter to multiple frames at once, accessed by index
# -

class BuiltinFilter(object):
    """Exposes a filter that already has a fast C implementation."""
    def _implementation(self, frame):
        raise NotImplementedError


class ColorizeFilter(BuiltinFilter):
    def __init__(self, color, amount):
        self._color = color.rgb()
        self._amount = amount

    def _implementation(self, frame):
        # This is incredibly stupid, but yes, ColorizeImage only accepts a
        # string for the opacity.
        opacity = bytes(self._amount * 100.) + b"%"

        color = ffi.new("PixelPacket *")
        self._color._populate_pixel(color)

        with magick_try() as exc:
            # TODO what if this raises but doesn't return NULL
            return lib.ColorizeImage(frame, opacity, color[0], exc.ptr)


class FilterState(object):
    @property
    def color(self):
        return self._color


def evaluate(filter_function, *frames):
    # TODO any gc concerns in this?
    for f in frames:
        assert isinstance(f, ImageFrame)

    # XXX how to handle frames of different sizes?  gravity?  scaling?  first
    # frame as the master?  hm
    frame = frames[0]

    if isinstance(filter_function, BuiltinFilter):
        new_stack = filter_function._implementation(frame._frame)
        return Image(new_stack)

    # TODO does this create a blank image or actually duplicate the pixels??  docs say it actually copies with (0, 0) but the code just refs the same pixel cache?
    # TODO could use an inplace version for, e.g. the SVG-style compose operators
    # TODO also might want a different sized clone!
    with magick_try() as exc:
        new_stack = lib.CloneImage(frame._frame, 0, 0, lib.MagickTrue, exc.ptr)
        exc.check(new_stack == ffi.NULL)

    # TODO: set image to full-color.
    # TODO: work out how this works, how different colorspaces work, and waht the ImageType has to do with anything
    # QUESTION: this doesn't actually do anything.  how does it work?  does it leave indexes populated?  what happens if this isn't done?
    #  if (SetImageStorageClass(fx_image,DirectClass) == MagickFalse) {
    #      InheritException(exception,&fx_image->exception);
    #      fx_image=DestroyImage(fx_image);
    #      return((Image *) NULL);
    #    }

    out_view = lib.AcquireCacheView(new_stack)

    # TODO i need to be a list
    in_view = lib.AcquireCacheView(frame._frame)

    state = FilterState()

    for y in range(frame._frame.rows):

        with magick_try() as exc:
            q = lib.GetCacheViewAuthenticPixels(out_view, 0, y, frame._frame.columns, 1, exc.ptr)
            exc.check(q == ffi.NULL)

        # TODO is this useful who knows
        #fx_indexes=GetCacheViewAuthenticIndexQueue(fx_view);

        for x in range(frame._frame.columns):
            # TODO per-channel things
            # TODO for usage: see line 1453

            #GetMagickPixelPacket(image,&pixel);
            #(void) InterpolateMagickPixelPacket(image,fx_info->view[i],image->interpolate, point.x,point.y,&pixel,exception);

            # Set up state object
            # TODO document that this is reused, or somethin
            state._color = BaseColor._from_pixel(q)
            ret = filter_function(state)

            #q.red = c_api.RoundToQuantum(<c_api.MagickRealType> ret.c_struct.red * c_api.QuantumRange)
            #q.green = c_api.RoundToQuantum(<c_api.MagickRealType> ret.c_struct.green * c_api.QuantumRange)
            #q.blue = c_api.RoundToQuantum(<c_api.MagickRealType> ret.c_struct.blue * c_api.QuantumRange)
            ret._populate_pixel(q)

            # XXX this is actually black
            #  if (((channel & IndexChannel) != 0) && (fx_image->colorspace == CMYKColorspace)) {
            #      (void) FxEvaluateChannelExpression(fx_info[id],IndexChannel,x,y, &alpha,exception);
            #      SetPixelIndex(fx_indexes+x,RoundToQuantum((MagickRealType) QuantumRange*alpha));
            #    }

            q += 1  # q++

        with magick_try() as exc:
            lib.SyncCacheViewAuthenticPixels(in_view, exc.ptr)
            # TODO check exception, return value

    # XXX destroy in_view
    # XXX destroy out_view s

    return Image(new_stack)
