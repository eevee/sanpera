"""Test identification of image properties."""

from sanpera.image import Image

from sanpera.tests import _util

def test_identify_size():
    img = Image.read(open(_util.find_source_image('eye.gif')))

    assert len(img) == 1, "one frame"
    assert img.original_format == 'GIF', "image is a gif"  # XXX this should be a magick format object
    assert img.size == (32, 32), "dimensions are 32x32"

    assert img.canvas.offset == (0, 0), "virtual canvas has no offset"
    assert not img.canvas.offset, "virtual canvas offset registers as false"
    assert img.canvas.size == (32, 32), "virtual canvas is 32x32"
    assert img.canvas.size == img.size, "virtual canvas size is image size"
    assert not img.has_canvas, "image isn't using a virtual canvas"
