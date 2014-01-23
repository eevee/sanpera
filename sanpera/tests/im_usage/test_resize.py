"""Tests based on the resizing/scaling section of the ImageMagick usage
examples.

See: http://www.imagemagick.org/Usage/resize/
"""

import pytest

from sanpera.image import patterns
from sanpera.imagemagick import VERSION
from sanpera.tests.util import get_image
from sanpera.tests.im_usage.common import convert


### Resizing Images

@convert('convert dragon.gif -resize 64x64 resize_dragon.miff')
def test_resize_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resized(img.size.fit_inside((64, 64)))
    ctx.compare(img, 'resize_dragon.miff')

@convert('convert terminal.gif -resize 64x64 resize_terminal.miff')
def test_resize_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resized(img.size.fit_inside((64, 64)))
    ctx.compare(img, 'resize_terminal.miff')


@convert('convert dragon.gif -resize 64x64! exact_dragon.miff')
def test_exact_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resized((64, 64))
    ctx.compare(img, 'exact_dragon.miff')

@convert('convert terminal.gif -resize 64x64! exact_terminal.miff')
def test_exact_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resized((64, 64))
    ctx.compare(img, 'exact_terminal.miff')


@convert('convert dragon.gif -resize 64x64> shrink_dragon.miff')
def test_shrink_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resized(img.size.fit_inside((64, 64), upscale=False))
    ctx.compare(img, 'shrink_dragon.miff')

@convert('convert terminal.gif -resize 64x64> shrink_terminal.miff')
def test_shrink_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resized(img.size.fit_inside((64, 64), upscale=False))
    ctx.compare(img, 'shrink_terminal.miff')


# Mentioned in the Usage docs, but not with examples.  Doing it anyway!
@convert('convert dragon.gif -resize 64x64< embiggen_dragon.miff')
def test_embiggen_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resized(img.size.fit_inside((64, 64), downscale=False))
    ctx.compare(img, 'embiggen_dragon.miff')

@convert('convert terminal.gif -resize 64x64< embiggen_terminal.miff')
def test_embiggen_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resized(img.size.fit_inside((64, 64), downscale=False))
    ctx.compare(img, 'embiggen_terminal.miff')


@convert('convert dragon.gif -resize 64x64^ fill_dragon.miff')
def test_fill_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resized(img.size.fit_around((64, 64)))
    ctx.compare(img, 'fill_dragon.miff')

@convert('convert terminal.gif -resize 64x64^ fill_terminal.miff')
def test_fill_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resized(img.size.fit_around((64, 64)))
    ctx.compare(img, 'fill_terminal.miff')


@convert('convert dragon.gif -resize 64x64^ -gravity center -extent 64x64 fill_crop_dragon.miff')
@pytest.mark.xfail
def test_fill_crop_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resized(img.size.fit_around((64, 64)))
    # XXX extent???
    ctx.compare(img, 'fill_crop_dragon.miff')

@convert('convert terminal.gif -resize 64x64^ -gravity center -extent 64x64 fill_crop_terminal.miff')
@pytest.mark.xfail
def test_fill_crop_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resized(img.size.fit_around((64, 64)))
    # XXX extent???
    ctx.compare(img, 'fill_crop_terminal.miff')


@convert('convert dragon.gif -resize 50% half_dragon.miff')
def test_half_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resized(img.size * 0.5)
    ctx.compare(img, 'half_dragon.miff')

@convert('convert terminal.gif -resize 50% half_terminal.miff')
def test_half_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resized(img.size * 0.5)
    ctx.compare(img, 'half_terminal.miff')


# Note that ImageMagick's @ calculation was buggy between 6.7.6ish and 6.8.6-5.
# Hence, these tests are skipped in that range.  (Alas, getting the patch level
# is nontrivial.)
skipif_bad_area = pytest.mark.skipif(
    (6, 7, 3) < VERSION < (6, 8, 7),
    reason="Buggy @ calculation")

@convert('convert dragon.gif -resize 4096@ pixel_dragon.miff')
@skipif_bad_area
def test_pixel_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resized(img.size.fit_area(4096))
    ctx.compare(img, 'pixel_dragon.miff')

@convert('convert terminal.gif -resize 4096@ pixel_terminal.miff')
@skipif_bad_area
def test_pixel_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resized(img.size.fit_area(4096))
    ctx.compare(img, 'pixel_terminal.miff')


# And these guys have no direct equivalent, because if you want to resize an
# image at read time, you can just do so.
@convert('convert dragon.gif[64x64] read_dragon.miff')
def test_read_dragon(ctx):
    img = get_image('dragon.gif')
    img = img.resized(img.size.fit_inside((64, 64)))
    ctx.compare(img, 'read_dragon.miff')

@convert('convert terminal.gif[64x64] read_terminal.miff')
def test_read_terminal(ctx):
    img = get_image('terminal.gif')
    img = img.resized(img.size.fit_inside((64, 64)))
    ctx.compare(img, 'read_terminal.miff')


### Other Resize Operators

@convert(
    'convert -size 150x60 xc: -draw "line 0,59 149,0" line_orig.miff',
    'convert line_orig.miff  -sample 50x20  line_sample.miff',
)
@pytest.mark.xfail
def test_line_sample(ctx):
    raise NotImplementedError

@convert('convert -size 8x8 pattern:CrossHatch30 -scale 1000% scale_crosshatch.miff')
def test_scale_crosshatch(ctx):
    img = patterns.crosshatch30[0].tiled((8, 8))
    img = img.resized(img.size * 10, filter='box')
    ctx.compare(img, 'scale_crosshatch.miff')

@convert('convert pattern:gray50 scale_gray_norm.miff')
def test_scale_gray_norm(ctx):
    img = patterns.gray50
    ctx.compare(img, 'scale_gray_norm.miff')

@convert('convert pattern:gray50 -scale 36 scale_gray_mag.miff')
def test_scale_gray_mag(ctx):
    img = patterns.gray50.resized((36, 36), filter='box')
    ctx.compare(img, 'scale_gray_mag.miff')

@convert('convert rose: -scale 25% -scale 70x46! rose_pixelated.miff')
def test_rose_pixelated(ctx):
    raise NotImplementedError

@convert('convert -size 50x50 xc: -draw "line 0,49 49,0" line_orig2.miff')
def test_line_orig2(ctx):
    raise NotImplementedError

@convert('convert line_orig2.miff -resize 80x80 line_resize.miff')
def test_line_resize(ctx):
    raise NotImplementedError

@convert('convert line_orig2.miff -adaptive-resize 80x80 line_adaptive.miff')
def test_line_adaptive(ctx):
    raise NotImplementedError

# Liquid Rescale

@convert('convert logo: -resize 50% -trim +repage logo_trimmed.miff')
def test_logo_trimmed(ctx):
    raise NotImplementedError

@convert('convert logo_trimmed.miff -liquid-rescale 75x100%!  logo_lqr.miff')
def test_logo_lqr(ctx):
    raise NotImplementedError

@convert('convert logo_trimmed.miff -sample 75x100%! logo_sample.miff')
def test_logo_sample(ctx):
    raise NotImplementedError

@convert('convert logo_trimmed.miff -liquid-rescale 130x100%! logo_lqr_expand.miff')
def test_logo_lqr_expand(ctx):
    raise NotImplementedError

# Distort Resize

@convert('convert rose: -matte -virtual-pixel transparent +distort SRT ".9,0" +repage rose_distort_scale.miff')
def test_rose_distort_scale(ctx):
    raise NotImplementedError

@convert('convert rose: -matte -virtual-pixel transparent +distort SRT "0,0 .9 0 .5,0" +repage  rose_distort_shift.miff')
def test_rose_distort_shift(ctx):
    raise NotImplementedError

@convert('convert rose_distort_shift.miff -crop 15x15+0+0 +repage -scale 600% rose_distort_shift_mag.miff')
def test_rose_distort_shift_mag(ctx):
    raise NotImplementedError

@convert('convert rose: -filter Lanczos -resize 300x rose_resize.miff')
def test_rose_resize(ctx):
    raise NotImplementedError

@convert('convert rose: -filter Lanczos -distort Resize 300x rose_distort.miff')
def test_rose_distort(ctx):
    raise NotImplementedError
