"""Tests based on the resizing/scaling section of the ImageMagick usage
examples.

See: http://www.imagemagick.org/Usage/resize/
"""

import pytest

from sanpera.image import patterns
from sanpera.tests.util import get_image
from sanpera.tests.im_usage.common import convert


### Resizing Images

@convert('convert dragon.gif -resize 64x64 resize_dragon.miff')
def test_resize_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resize(img.size.fit_inside((64, 64)))
    ctx.compare(img, 'resize_dragon.miff')

@convert('convert terminal.gif -resize 64x64 resize_terminal.miff')
def test_resize_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resize(img.size.fit_inside((64, 64)))
    ctx.compare(img, 'resize_terminal.miff')


@convert('convert dragon.gif -resize 64x64! exact_dragon.miff')
def test_exact_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resize((64, 64))
    ctx.compare(img, 'exact_dragon.miff')

@convert('convert terminal.gif -resize 64x64! exact_terminal.miff')
def test_exact_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resize((64, 64))
    ctx.compare(img, 'exact_terminal.miff')


@convert('convert dragon.gif -resize 64x64> shrink_dragon.miff')
def test_shrink_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resize(img.size.fit_inside((64, 64), upscale=False))
    ctx.compare(img, 'shrink_dragon.miff')

@convert('convert terminal.gif -resize 64x64> shrink_terminal.miff')
def test_shrink_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resize(img.size.fit_inside((64, 64), upscale=False))
    ctx.compare(img, 'shrink_terminal.miff')


# Mentioned in the Usage docs, but not with examples.  Doing it anyway!
@convert('convert dragon.gif -resize 64x64< embiggen_dragon.miff')
def test_embiggen_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resize(img.size.fit_inside((64, 64), downscale=False))
    ctx.compare(img, 'embiggen_dragon.miff')

@convert('convert terminal.gif -resize 64x64< embiggen_terminal.miff')
def test_embiggen_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resize(img.size.fit_inside((64, 64), downscale=False))
    ctx.compare(img, 'embiggen_terminal.miff')


@convert('convert dragon.gif -resize 64x64^ fill_dragon.miff')
def test_fill_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resize(img.size.fit_around((64, 64)))
    ctx.compare(img, 'fill_dragon.miff')

@convert('convert terminal.gif -resize 64x64^ fill_terminal.miff')
def test_fill_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resize(img.size.fit_around((64, 64)))
    ctx.compare(img, 'fill_terminal.miff')


@convert('convert dragon.gif -resize 64x64^ -gravity center -extent 64x64 fill_crop_dragon.miff')
@pytest.mark.xfail
def test_fill_crop_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resize(img.size.fit_around((64, 64)))
    # XXX extent???
    ctx.compare(img, 'fill_crop_dragon.miff')

@convert('convert terminal.gif -resize 64x64^ -gravity center -extent 64x64 fill_crop_terminal.miff')
@pytest.mark.xfail
def test_fill_crop_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resize(img.size.fit_around((64, 64)))
    # XXX extent???
    ctx.compare(img, 'fill_crop_terminal.miff')


@convert('convert dragon.gif -resize 50% half_dragon.miff')
def test_half_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resize(img.size * 0.5)
    ctx.compare(img, 'half_dragon.miff')

@convert('convert terminal.gif -resize 50% half_terminal.miff')
def test_half_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resize(img.size * 0.5)
    ctx.compare(img, 'half_terminal.miff')


# A note on these tests: old ImageMagick truncates the new dimensions, recent
# ImageMagick rounds.  Size.fit_area is more clever than either of these, so
# the `emulate` flag exists just to make these tests pixel-perfect.  Also note
# that this means these tests will fail on ImageMagick before 6.7.5.
@convert('convert dragon.gif -resize 4096@ pixel_dragon.miff')
def test_pixel_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resize(img.size.fit_area(4096, emulate=True))
    ctx.compare(img, 'pixel_dragon.miff')

@convert('convert terminal.gif -resize 4096@ pixel_terminal.miff')
def test_pixel_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resize(img.size.fit_area(4096, emulate=True))
    ctx.compare(img, 'pixel_terminal.miff')


# And these guys have no direct equivalent, because if you want to resize an
# image at read time, you can just do so.
@convert('convert dragon.gif[64x64] read_dragon.miff')
def test_read_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resize(img.size.fit_inside((64, 64)))
    ctx.compare(img, 'read_dragon.miff')

@convert('convert terminal.gif[64x64] read_terminal.miff')
def test_read_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resize(img.size.fit_inside((64, 64)))
    ctx.compare(img, 'read_terminal.miff')


### Other Resize Operators

@convert(
    'convert -size 150x60 xc: -draw "line 0,59 149,0" line_orig.miff',
    'convert line_orig.miff  -sample 50x20  line_sample.miff',
)
@pytest.mark.xfail
def test_line_sample(ctx):
    raise NotImplementedError

# XXX this +repage is not in the original line, but it works around what i
# consider to be a legit bug in imagemagick when using -size
#@convert('convert -size 8x8 pattern:CrossHatch30 -scale 1000% OUT')
@convert('convert -size 8x8 pattern:CrossHatch30 +repage -scale 1000% scale_crosshatch.miff')
def test_scale_crosshatch(ctx):
    img = patterns.crosshatch30.tile((8, 8))
    img = img.resize(img.size * 10, filter='box')
    ctx.compare(img, 'scale_crosshatch.miff')

@convert('convert pattern:gray50 scale_gray_norm.miff')
def test_scale_gray_norm(ctx):
    img = patterns.gray50
    ctx.compare(img, 'scale_gray_norm.miff')

@convert('convert pattern:gray50 -scale 36 scale_gray_mag.miff')
def test_scale_gray_mag(ctx):
    img = patterns.gray50.resize((36, 36), filter='box')
    ctx.compare(img, 'scale_gray_mag.miff')
