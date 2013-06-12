"""Tests for fixes for broken-ass ImageMagick features."""

from sanpera.geometry import Rectangle, Size, Vector
from sanpera.tests.util import get_image

def check_original_dimensions(img):
    assert img.size == Size(100, 100)
    assert img[0].size == Size(32, 32)
    assert img[0].canvas.position == Vector(5, 10)
    assert img[1].size == Size(32, 32)
    assert img[1].canvas.position == Vector(35, 30)
    assert img[2].size == Size(32, 32)
    assert img[2].canvas.position == Vector(62, 50)
    assert img[3].size == Size(32, 32)
    assert img[3].canvas.position == Vector(10, 55)

def test_multi_frame_resize():
    """ImageMagick doesn't handle resizing correctly when a virtual canvas is
    involved.  Make sure we fixed it.
    """

    img = get_image('anim_bgnd.gif')

    # Original dimensions
    check_original_dimensions(img)

    img = img.resized(img.size * 0.5)

    # Resized dimensions -- reduced by half
    assert img.size == Size(50, 50)
    assert img[0].size == Size(16, 16)
    assert img[0].canvas.position == Vector(3, 5)
    assert img[1].size == Size(16, 16)
    assert img[1].canvas.position == Vector(18, 15)
    assert img[2].size == Size(16, 16)
    assert img[2].canvas.position == Vector(31, 25)
    assert img[3].size == Size(16, 16)
    assert img[3].canvas.position == Vector(5, 28)

# TODO what about resizing or cropping frames in-place

def test_multi_frame_crop_repage():
    """ImageMagick's usual crop-plus-repage dance (which we emulate) doesn't
    quite work with multi-frame images, so we do slightly more clever math.
    """

    img = get_image('anim_bgnd.gif')

    # Original dimensions
    check_original_dimensions(img)

    canvas = Rectangle(0, 0, *img.size)
    img = img.cropped(canvas)

    # "Cropped" dimensions -- exactly the same
    check_original_dimensions(img)
