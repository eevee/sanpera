"""Image filters: operations on entire images at once.

A filter is merely a callable that accepts some number of frames and returns a
new image with a single frame:

    new_image = some_filter(*old_image)

Note the use of ``*`` to flatten the image into its frames.

The API for filters is not particularly rigid.  Some filters may require a
particular number of frames; some may have additional requirements, e.g., that
the frames are all the same size.  Many filters also accept keyword arguments:

channel::
    Restrict the filter to the given channel (a `sanpera.constants.Channel`),
    and leave the others unchanged.  Multiple channels may be bitwise-ORed
    together.

However, filters whose behavior can itself be adjusted are generally expressed
as factories rather than as extra arguments to the filter function itself.  For
example, the `Colorize` filter is used as:

    new_image = Colorize(red, 0.5)(*old_image)

You can also write your own custom filters in Python.  See the `image_filter`
decorator.
"""
# TODO more docs

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from functools import partial

from sanpera._api import ffi, lib
from sanpera.color import BaseColor
from sanpera.exception import magick_try
from sanpera.image import Image
from sanpera.image import ImageFrame

# TODO, some major remaining issues:
# - need wrappers for more imagemagick filters
# - be more sure that compiled filters won't, say, segfault.  for one, detect
#   when the stack can overflow!
# - need to expand the acceleration more, and more delicately auto-detect when
#   it should work -- probably be more strict when guessing and kinda lax when
#   asked explicitly?
# - accelerated filters are a bit stupid with multiple channels and that would
#   be nice to fix
# - implement more of the -fx API:
#   - neighborhood pixels (TODO how to restrict the range...?)
#   - support multiple input frames
#   - math operations
#   - channel hijinks?
# - unclear exactly what the output should be, especially when doing only one
#   channel.  probably a color.
# - write some example python implementations of existing filters, e.g. simple
#   resizing/compositing.  or maybe Usage has some already as -fx expressions

# - make tests run both C and Python filters, where possible
# - consider writing a PIL compat layer, and/or being PEP whatever compatible


# ------------------------------------------------------------------------------
# Built-in filters, i.e., filters provided fairly directly by ImageMagick that
# operate on an entire image at a time.
# Non-library code should probably not be creating these.

class _builtin_image_filter(object):
    def __init__(self, impl):
        self.impl = impl

    def __call__(self, *frames, **kwargs):
        return Image(self.impl(*frames, **kwargs))

    def __get__(self, owner, cls):
        # Support being attached to a method like __call__; this is basically
        # what instancemethod.__get__ does
        if owner is None:
            return self

        return partial(self, owner)


class Colorize(object):
    def __init__(self, color, amount):
        self._color = color.rgb()
        self._amount = amount

    @_builtin_image_filter
    def __call__(self, frame, **kwargs):
        channel = kwargs.get('channel', lib.DefaultChannels)
        # This is incredibly stupid, but yes, ColorizeImage only accepts a
        # string for the opacity.
        opacity = str(self._amount * 100.).encode('ascii') + b"%"

        color = ffi.new("PixelPacket *")
        self._color._populate_pixel(color)

        with magick_try() as exc:
            # TODO what if this raises but doesn't return NULL
            # TODO in general i need to figure out when i use gc and do it
            # consistently
            return lib.ColorizeImage(frame._frame, opacity, color[0], exc.ptr)


# ------------------------------------------------------------------------------
# DWIM filter compiler: tries C, falls back to Python if it doesn't compile.

def image_filter(impl):
    try:
        return compiled_image_filter(impl)
    except Exception:
        return python_image_filter(impl)


# ------------------------------------------------------------------------------
# Python filter support; works a lot like -fx, running a function once for
# every pixel in the image.  Not particularly speedy, but super flexible.
# TODO docs

class FilterState(object):
    """Current state of filter execution.  Contains information about the
    current pixel, neighboring pixels, etc.

    Do NOT keep instances of this class around; as a minor optimization, the
    same state object is reused for every pixel.
    """
    @property
    def color(self):
        return self._color


class python_image_filter(object):
    def __init__(self, impl):
        self.impl = impl

    def __call__(self, *frames, **kwargs):
        channel = kwargs.get('channel', lib.DefaultChannels)
        # TODO force_python should go away and this should become a wrapper for
        # evaluate_python

        # We're gonna be using this a lot, so let's cast it to a C int just
        # once (and get the error early if it's a bogus type)
        c_channel = ffi.cast('ChannelType', channel)

        # TODO any gc concerns in this?
        for f in frames:
            assert isinstance(f, ImageFrame)

        # XXX how to handle frames of different sizes?  gravity?  scaling?  first
        # frame as the master?  hm
        frame = frames[0]

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
                ret = self.impl(state)

                #q.red = c_api.RoundToQuantum(<c_api.MagickRealType> ret.c_struct.red * c_api.QuantumRange)
                #q.green = c_api.RoundToQuantum(<c_api.MagickRealType> ret.c_struct.green * c_api.QuantumRange)
                #q.blue = c_api.RoundToQuantum(<c_api.MagickRealType> ret.c_struct.blue * c_api.QuantumRange)
                # TODO black, opacity?
                # TODO seems like this should apply to any set of channels, but
                # IM's -fx only understands RGB

                # TODO this is a little invasive, but given that this inner
                # loop runs for every fucking pixel, i'd like to avoid method
                # calls as much as possible.  even that rgb() can add up
                rgb = ret.rgb()
                lib.sanpera_pixel_from_doubles_channel(q, rgb._array, c_channel)

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


# ------------------------------------------------------------------------------
# Compiled filter support.  Uses operator overloading hackery to convert the
# filter function to a list of bytecode ops that operate on a stack, then
# evaluates the whole thing in C.
# The result is sure faster than Python, and actually faster than -fx.

def op_(op, **kwargs):
    ret = dict(
        op=op,
        color=ffi.NULL,
        number=0.,
    )

    ret.update(**kwargs)
    return ret


def op_source_color():
    return op_(lib.SANPERA_OP_LOAD_SOURCE_COLOR)


def op_number(value):
    return dict(
        op=lib.SANPERA_OP_LOAD_NUMBER,
        color=ffi.NULL,
        number=ffi.cast("double", value),
    )


def op_color(color):
    _color = ffi.new("PixelPacket *")
    color._populate_pixel(_color)

    return dict(
        op=lib.SANPERA_OP_LOAD_COLOR,
        color=_color,
        number=0.,
    )


class FilterCompiler(object):
    def __init__(self, type='pixel', ops=None):
        self.type = type
        if ops:
            self.ops = ops
        else:
            self.ops = []

    @classmethod
    def _finalize(cls, compiler):
        if isinstance(compiler, cls):
            ops = compiler.ops
        elif isinstance(compiler, (int, long, float)):
            ops = [op_number(compiler)]
        elif isinstance(compiler, BaseColor):
            ops = [op_color(compiler)]
        else:
            raise TypeError

        return ops + [op_(lib.SANPERA_OP_DONE)]

    @property
    def color(self):
        assert self.type == 'pixel'
        return FilterCompiler('color', self.ops + [op_source_color()])

    def __mul__(self, other):
        assert self.type in ('color', 'number')

        if isinstance(other, FilterCompiler):
            assert other.type in ('color', 'number')
            ops = self.ops + other.ops
        elif isinstance(other, (int, long, float)):
            ops = self.ops + [op_number(other)]
        else:
            return NotImplemented

        return FilterCompiler('number', ops + [op_(lib.SANPERA_OP_MULTIPLY)])

    def __add__(self, other):
        assert self.type in ('color', 'number')

        if isinstance(other, FilterCompiler):
            assert other.type in ('color', 'number')
            ops = self.ops + other.ops
        elif isinstance(other, (int, long, float)):
            ops = self.ops + [op_number(other)]
        else:
            return NotImplemented

        return FilterCompiler('number', ops + [op_(lib.SANPERA_OP_ADD)])


    def clamped(self):
        # TODO .clamped() only actually works on colors, not numbers
        assert self.type in ('color', 'number')
        return FilterCompiler('color', self.ops + [op_(lib.SANPERA_OP_CLAMP)])


class compiled_image_filter(object):
    def __init__(self, impl):
        # This will throw all kinds of exceptions if the function can't be
        # compiled
        # TODO wrap them?
        # Pass a dummy state object into the callable to try to compile it
        compiler = FilterCompiler()
        output = impl(compiler)
        # The output might be a constant, which we can definitely do super
        # fast; ask the compiler class to figure it out
        self.compiled_steps = FilterCompiler._finalize(output)

    def __call__(self, *frames, **kwargs):
        channel = kwargs.get('channel', lib.DefaultChannels)
        c_channel = ffi.cast('ChannelType', channel)

        steps = ffi.new("sanpera_evaluate_step[]", self.compiled_steps)
        c_frames = ffi.new("Image *[]", [f._frame for f in frames] + [ffi.NULL])

        with magick_try() as exc:
            new_frame = ffi.gc(
                lib.sanpera_evaluate_filter(c_frames, steps, c_channel, exc.ptr),
                lib.DestroyImageList)

        return Image(new_frame)
