"""Test ImageMagick feature detection.

It's hard to test anything specific since this might run on any old system, but
let's go out on a limb and assume you have such amenities as PNG and GIF
support.
"""

from sanpera.imagemagick import IMAGE_FORMATS

def test_format_metadata():
    png = IMAGE_FORMATS['png']
    assert png.can_read
    assert png.can_write
    assert not png.supports_frames

    gif = IMAGE_FORMATS['gif']
    assert gif.can_read
    assert gif.can_write
    assert gif.supports_frames

    # "canvas" is a pseudo-format built into ImageMagick that can "read" a
    # solid color but obviously not write it
    canvas = IMAGE_FORMATS['canvas']
    assert canvas.can_read
    assert not canvas.can_write
    assert not canvas.supports_frames
