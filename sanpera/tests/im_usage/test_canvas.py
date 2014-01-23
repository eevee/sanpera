"""Tests based on the canvas creation section of the ImageMagick usage
examples.

See: http://www.imagemagick.org/Usage/canvas/
"""

from sanpera.color import RGBColor
from sanpera.geometry import Size
from sanpera.image import Image, builtins
from sanpera.filters import Colorize, image_filter
from sanpera.tests.im_usage.common import convert
from sanpera.tests.util import get_image


### Solid Color Canvases

# Direct Generation

@convert('convert -size 100x100 canvas:khaki canvas_khaki.miff')
def test_khaki(ctx):
    img = Image.new((100, 100), fill=RGBColor.parse('khaki'))
    ctx.compare(img, 'canvas_khaki.miff')

@convert('convert -size 100x100 xc:wheat canvas_wheat.miff')
def test_wheat(ctx):
    img = Image.new((100, 100), fill=RGBColor.parse('wheat'))
    ctx.compare(img, 'canvas_wheat.miff')

@convert('convert canvas_khaki.miff -fill tomato -opaque khaki canvas_opaque.miff')
def test_khaki_to_tomato(ctx):
    img = Image.new((100, 100), fill=RGBColor.parse('khaki'))
    img[0].replace_color(RGBColor.parse('khaki'), RGBColor.parse('tomato'))
    ctx.compare(img, 'canvas_opaque.miff')

@convert('convert rose: -crop 1x1+40+30 +repage -scale 100x100! canvas_pick.miff')
def test_rose_pixel(ctx):
    img = builtins.rose
    img = img.cropped(Size(1, 1).at((40, 30)))
    img = img.resized((100, 100), filter='box')
    ctx.compare(img, 'canvas_pick.miff')

# Overlay a Specific Color

@convert('convert test.png +matte -fill Sienna -colorize 100% color_colorize.miff')
def test_color_colorize(ctx):
    img = get_image('test.png')
    img[0].translucent = False
    img = Colorize(RGBColor.parse('sienna'), 1.0)(*img)
    ctx.compare(img, 'color_colorize.miff')

@convert('convert test.png -alpha Opaque +level-colors Chocolate color_levelc.miff')
def test_color_levelc(ctx):
    raise NotImplementedError

@convert('convert test.png -alpha Off -sparse-color Voronoi "0,0 Peru" color_sparse.miff')
def test_color_sparse(ctx):
    raise NotImplementedError

@convert('convert test.png -fill Tan -draw "color 0,0 reset" color_reset.miff')
def test_color_reset(ctx):
    raise NotImplementedError

@convert('convert test.png -background Wheat -compose Dst -flatten color_flatten.miff')
def test_color_flatten(ctx):
    raise NotImplementedError

@convert('convert test.png -background LemonChiffon -compose Dst -extent 100x100   color_extent.miff')
def test_color_extent(ctx):
    raise NotImplementedError

@convert('convert test.png -bordercolor Khaki -compose Dst -border 0   color_border.miff')
def test_color_border(ctx):
    raise NotImplementedError

@convert('convert test.png +matte -fx Gold  color_fx_constant.miff')
def test_color_fx_constant(ctx):
    gold = RGBColor.parse('gold')

    @image_filter
    def gold_filter(self, *a):
        return gold

    img = get_image('test.png')
    img[0].translucent = False
    img = gold_filter(*img)
    ctx.compare(img, 'color_fx_constant.miff')

@convert('convert test.png +matte -fx "Gold*.7" color_fx_math.miff')
def test_color_fx_math(ctx):
    gold = RGBColor.parse('gold')

    @image_filter
    def gold_filter(self, *a):
        return gold * 0.7

    img = get_image('test.png')
    img[0].translucent = False
    img = gold_filter(*img)
    ctx.compare(img, 'color_fx_math.miff')

@convert('convert test.png -matte -fill #FF000040 -draw "color 0,0 reset" color_semitrans.miff')
def test_color_semitrans(ctx):
    raise NotImplementedError

# Other Canvas Techniques


### Gradients of Colors



### Sparse Points of Color



### Plasma Images



### Random Images



### Tiled Canvases
