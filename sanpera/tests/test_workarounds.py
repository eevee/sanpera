"""Tests for fixes for broken-ass ImageMagick features."""

from sanpera.geometry import Size, Vector
from sanpera.tests.util import get_image

def test_multi_frame_resize():
    """ImageMagick doesn't handle resizing correctly when a virtual canvas is
    involved.  Make sure we fixed it.
    """

    img = get_image('anim_bgnd.gif')

    # Original dimensions
    assert img.size == Size(100, 100)
    assert img[0].size == Size(32, 32)
    assert img[0].canvas.position == Vector(5, 10)
    assert img[1].size == Size(32, 32)
    assert img[1].canvas.position == Vector(35, 30)
    assert img[2].size == Size(32, 32)
    assert img[2].canvas.position == Vector(62, 50)
    assert img[3].size == Size(32, 32)
    assert img[3].canvas.position == Vector(10, 55)

    img = img.resized(img.size * 0.5)

    # Resized dimensions -- reduced by half
    assert img.size == Size(50, 50)
    assert img[0].size == Size(16, 16)
    assert img[0].canvas.position == Vector(2, 5)
    assert img[1].size == Size(16, 16)
    assert img[1].canvas.position == Vector(17, 15)
    assert img[2].size == Size(16, 16)
    assert img[2].canvas.position == Vector(31, 25)
    assert img[3].size == Size(16, 16)
    assert img[3].canvas.position == Vector(5, 27)
