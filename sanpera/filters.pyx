from cython.operator cimport preincrement as inc

from sanpera cimport c_api
from sanpera.color cimport BaseColor, RGBColor, _color_from_pixel
from sanpera.exception cimport MagickException, check_magick_exception
from sanpera.image cimport Image, ImageFrame

import sanpera.core

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

# XXX should this be named, um.  filter?  math?  process??

cdef class FilterState:
    cdef BaseColor _color

    property color:
        def __get__(self):
            return self._color



def evaluate(filter_function, *frames):
    for f in frames:
        <ImageFrame?> f

    # XXX how to handle frames of different sizes?  gravity?  scaling?  first
    # frame as the master?  hm

    cdef ImageFrame frame = frames[0]
    cdef MagickException exc = MagickException()

    # TODO does this create a blank image or actually duplicate the pixels??  docs say it actually copies with (0, 0) but the code just refs the same pixel cache?
    # TODO could use an inplace version for, e.g. the SVG-style compose operators
    # TODO also might want a different sized clone!
    cdef c_api.Image* new_frame = c_api.CloneImage(frame._frame, 0, 0, c_api.MagickTrue, exc.ptr)
    exc.check(new_frame == NULL)

    # TODO: set image to full-color.
    # TODO: work out how this works, how different colorspaces work, and waht the ImageType has to do with anything
    # QUESTION: this doesn't actually do anything.  how does it work?  does it leave indexes populated?  what happens if this isn't done?
    #  if (SetImageStorageClass(fx_image,DirectClass) == MagickFalse) {
    #      InheritException(exception,&fx_image->exception);
    #      fx_image=DestroyImage(fx_image);
    #      return((Image *) NULL);
    #    }

    cdef Image result = Image()
    c_api.AppendImageToList(&result._stack, new_frame)

    cdef c_api.CacheView* out_view = c_api.AcquireCacheView(result._stack)

    # TODO i need to be a list
    cdef c_api.CacheView* in_view = c_api.AcquireCacheView(frame._frame)

    cdef int x
    cdef int y

    cdef c_api.PixelPacket* q

    cdef RGBColor current_color
    cdef RGBColor ret

    cdef FilterState state = FilterState()

    for y in range(frame._frame.rows):

        q = c_api.GetCacheViewAuthenticPixels(out_view, 0, y, frame._frame.columns, 1, exc.ptr)
        # TODO check exception and q == NULL

        # TODO is this useful who knows
        #fx_indexes=GetCacheViewAuthenticIndexQueue(fx_view);

        for x in range(frame._frame.columns):
            # TODO per-channel things
            # TODO for usage: see line 1453

            #GetMagickPixelPacket(image,&pixel);
            #(void) InterpolateMagickPixelPacket(image,fx_info->view[i],image->interpolate, point.x,point.y,&pixel,exception);

            # Set up state object
            # TODO document that this is reused, or somethin
            state._color = _color_from_pixel(q)
            ret = filter_function(state)

            #q.red = c_api.ClampToQuantum(<c_api.MagickRealType> ret.c_struct.red * c_api.QuantumRange)
            #q.green = c_api.ClampToQuantum(<c_api.MagickRealType> ret.c_struct.green * c_api.QuantumRange)
            #q.blue = c_api.ClampToQuantum(<c_api.MagickRealType> ret.c_struct.blue * c_api.QuantumRange)
            ret._populate_pixel(q)

            # XXX this is actually black
            #  if (((channel & IndexChannel) != 0) && (fx_image->colorspace == CMYKColorspace)) {
            #      (void) FxEvaluateChannelExpression(fx_info[id],IndexChannel,x,y, &alpha,exception);
            #      SetPixelIndex(fx_indexes+x,ClampToQuantum((MagickRealType) QuantumRange*alpha));
            #    }

            inc(q)

        c_api.SyncCacheViewAuthenticPixels(in_view, exc.ptr)
        # TODO check exception, return value

    # XXX destroy in_view
    # XXX destroy out_view s

    result._post_init()
    return result

