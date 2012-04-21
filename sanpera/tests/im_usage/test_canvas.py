"""Tests based on the canvas creation section of the ImageMagick usage
examples.

See: http://www.imagemagick.org/Usage/canvas/
"""

import os.path

from sanpera.color import Color
from sanpera.geometry import Size
from sanpera.image import Image

from sanpera.tests.util import get_image
from sanpera.tests.im_usage.common import ImageOperationRegistry

canvas_tests = ImageOperationRegistry()


@canvas_tests.register('convert -size 100x100 canvas:khaki -strip OUT')
def canvas_khaki():
    return Image.new((100, 100), fill=Color.parse('khaki'))

@canvas_tests.register('convert -size 100x100 xc:wheat -strip OUT')
def canvas_wheat():
    return Image.new((100, 100), fill=Color.parse('wheat'))

# TODO this can't work: it relies on using the output of a previous test.
# please make this possible and restore the original command
#@canvas_tests.register('convert canvas_khaki.gif -fill tomato -opaque khaki canvas_opaque.gif')
@canvas_tests.register('convert -size 100x100 canvas:khaki -fill tomato -opaque khaki OUT')
def canvas_khaki_to_tomato():
    img = Image.new((100, 100), fill=Color.parse('khaki'))
    img.replace_color(Color.parse('khaki'), Color.parse('tomato'))
    return img

@canvas_tests.register('convert rose: -crop 1x1+40+30 +repage -scale 100x100! OUT')
def canvas_rose_pixel():
    img = Image.from_builtin('rose')
    img = img.crop(Size(1, 1).at((40, 30)))
    img = img.resize((100, 100))
    return img

# I am the actual test command  :)
test_canvas_command = canvas_tests.python_test_function()
