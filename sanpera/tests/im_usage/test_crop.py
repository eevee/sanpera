"""Tests based on the resizing/scaling section of the ImageMagick usage
examples.

See: http://www.imagemagick.org/Usage/crop/
"""

from sanpera.geometry import Size
from sanpera.image import builtins
from sanpera.tests.im_usage.common import convert


### Crop

@convert('convert rose: rose.miff')
def test_rose(ctx):
    img = builtins.rose
    ctx.compare(img, 'rose.miff')

@convert('convert rose: -crop 40x30+10+10 crop.miff')
def test_crop(ctx):
    img = builtins.rose.cropped(Size(40, 30).at((10, 10)), preserve_canvas=True)
    ctx.compare(img, 'crop.miff')

@convert('convert rose: -crop 40x30+40+30 crop_br.miff')
def test_crop_br(ctx):
    img = builtins.rose.cropped(Size(40, 30).at((40, 30)), preserve_canvas=True)
    ctx.compare(img, 'crop_br.miff')

@convert('convert rose: -crop 40x30-10-10 crop_tl.miff')
def test_crop_tl(ctx):
    img = builtins.rose.cropped(Size(40, 30).at((-10, -10)), preserve_canvas=True)
    ctx.compare(img, 'crop_tl.miff')

@convert('convert rose: -crop 90x60-10-10 crop_all.miff')
def test_crop_all(ctx):
    img = builtins.rose.cropped(Size(90, 60).at((-10, -10)), preserve_canvas=True)
    ctx.compare(img, 'crop_all.miff')

@convert('convert rose: -crop 40x30+90+60 crop_miss.miff')
def test_crop_miss(ctx):
    img = builtins.rose.cropped(Size(40, 30).at((90, 60)), preserve_canvas=True)
    ctx.compare(img, 'crop_miss.miff')
