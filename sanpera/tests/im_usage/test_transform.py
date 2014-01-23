"""Tests based on the transformation section of the ImageMagick usage examples.

See: http://www.imagemagick.org/Usage/transform/
"""

from sanpera.color import RGBColor
from sanpera.color import GrayColor
from sanpera.constants import Channel
from sanpera.image import Image, builtins, gradient
from sanpera.filters import image_filter
from sanpera.tests.im_usage.common import convert


### Art-like transformations

# TODO

### Computer vision transformations

# TODO

### Shade 3D highlighting

# TODO

### Using FX, the DIY image operator

# FX basic usage

@convert('convert -size 64x64 xc:black -channel blue -fx 1/2 fx_navy.miff')
def test_fx_navy(ctx):
    img = Image.new((64, 64), fill=RGBColor(0., 0., 0.))
    gray = RGBColor(0.5, 0.5, 0.5)
    img = image_filter(lambda *a: gray)(*img, channel=Channel.blue)
    ctx.compare(img, 'fx_navy.miff')


@convert('convert -size 64x64 gradient:black-white -channel blue,green -fx 0 fx_red.miff')
def test_fx_red(ctx):
    #img = Image.new((64, 64))  # TODO make the gradient, oops
    black = RGBColor(0., 0., 0.)
    white = RGBColor(1., 1., 1.)
    img = gradient((64, 64), black, white)
    img = image_filter(lambda *a: black)(*img, channel=Channel.blue | Channel.green)
    ctx.compare(img, 'fx_red.miff')


@convert('convert rose: -fx "u*1.5" fx_rose_brighten.miff')
def test_fx_rose_brighten(ctx):
    img = builtins.rose
    img = image_filter(lambda px: px.color * 1.5)(*img)
    ctx.compare(img, 'fx_rose_brighten.miff')

# TODO more...

### Evaluate and function, freeform channel modifiers

## Evaluate, simple math operations
# Note that there's no special "-evaluate", etc. operator, because we
# automatically optimize these.

@convert('convert rose: -evaluate set 50% rose_set_gray.miff')
def test_rose_set_gray(ctx):
    img = builtins.rose
    img = image_filter(lambda px: GrayColor(0.5))(*img)
    ctx.compare(img, 'rose_set_gray.miff')


@convert('convert rose: -evaluate divide 2 -evaluate add 25% rose_decontrast.miff')
def test_rose_decontrast(ctx):
    img = builtins.rose
    # -evaluate clamps after every operation
    img = image_filter(lambda px: (px.color * 0.5).clamped() + 0.25)(*img)
    ctx.compare(img, 'rose_decontrast.miff')


@convert('convert rose: -evaluate multiply 2 -evaluate subtract 25% rose_contrast.miff')
def test_rose_contrast(ctx):
    img = builtins.rose
    # -evaluate clamps after every operation
    img = image_filter(lambda px: (px.color * 2).clamped() - 0.25)(*img)
    ctx.compare(img, 'rose_contrast.miff')


@convert('convert rose: -evaluate subtract 12.5% -evaluate multiply 2 rose_contrast2.miff')
def test_rose_contrast2(ctx):
    img = builtins.rose
    # -evaluate clamps after every operation
    img = image_filter(lambda px: (px.color - 0.125).clamped() * 2)(*img)
    ctx.compare(img, 'rose_contrast2.miff')


#convert rose: -alpha set  -channel A -evaluate divide 2   rose_transparent.png

#  convert rose: -channel R  -evaluate multiply .2 \
#                          -channel G  -evaluate multiply .5 \
#                          -channel B  -evaluate multiply .3 \
#                          +channel -separate \
#                          -background black -compose plus -flatten grey_253.png

## Evaluate math functions

# TODO

### Mathematics on gradients

# TODO
