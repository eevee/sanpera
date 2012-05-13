"""Tests based on the canvas creation section of the ImageMagick usage
examples.

See: http://www.imagemagick.org/Usage/canvas/
"""

from sanpera.color import Color
from sanpera.geometry import Size
from sanpera.image import Image, builtins
from sanpera.tests.im_usage.common import convert


### Solid Color Canvases

@convert('convert -size 100x100 canvas:khaki canvas_khaki.miff')
def test_khaki(ctx):
    img = Image.new((100, 100), fill=Color.parse('khaki'))
    ctx.compare(img, 'canvas_khaki.miff')

@convert('convert -size 100x100 xc:wheat canvas_wheat.miff')
def test_wheat(ctx):
    img = Image.new((100, 100), fill=Color.parse('wheat'))
    ctx.compare(img, 'canvas_wheat.miff')

@convert('convert canvas_khaki.miff -fill tomato -opaque khaki canvas_opaque.miff')
def test_khaki_to_tomato(ctx):
    img = Image.new((100, 100), fill=Color.parse('khaki'))
    img[0].replace_color(Color.parse('khaki'), Color.parse('tomato'))
    ctx.compare(img, 'canvas_opaque.miff')

@convert('convert rose: -crop 1x1+40+30 +repage -scale 100x100! canvas_pick.miff')
def test_rose_pixel(ctx):
    img = builtins.rose
    img = img.cropped(Size(1, 1).at((40, 30)))
    img = img.resized((100, 100), filter='box')
    ctx.compare(img, 'canvas_pick.miff')
