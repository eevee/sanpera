"""Test identification of image properties."""

from sanpera.geometry import Size, Vector
from sanpera.image import Image

from sanpera.tests import util

def test_identify_size():
    img = Image.read(util.find_image('eye.gif'))

    assert len(img) == 1, "one frame"
    assert img.original_format == b'GIF', "image is a gif"  # XXX this should be a magick format object
    assert img.size == Size(32, 32), "dimensions are 32x32"

    frame = img[0]
    assert frame.canvas.position == Vector(0, 0), "virtual canvas has no offset"
    assert not frame.canvas.position, "virtual canvas offset registers as false"
    assert frame.canvas.size == Size(32, 32), "virtual canvas is 32x32"
    assert frame.canvas.size == img.size, "virtual canvas size is image size"
    assert not frame.has_canvas, "frame isn't using a virtual canvas"
    assert not img.has_canvas, "image isn't using a virtual canvas"
