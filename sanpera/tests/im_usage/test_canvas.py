"""Tests based on the canvas creation section of the ImageMagick usage
examples.

See: http://www.imagemagick.org/Usage/canvas/
"""

import os.path

from sanpera.image import Image, Size
from sanpera.tests.util import get_image
from sanpera.tests.im_usage.common import ImageOperationRegistry

canvas_tests = ImageOperationRegistry()


@canvas_tests.register('convert -size 100x100 canvas:khaki -strip OUT')
def canvas_kanki():
    return Image.new((100, 100), fill='khaki')


# I am the actual test command  :)
test_canvas_command = canvas_tests.python_test_function()
