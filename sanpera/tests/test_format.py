"""Test format detection.

It's hard to test anything specific since this might run on any old system, but
let's go out on a limb and assume you have PNG and GIF support.
"""

from sanpera.format import image_formats

def test_format_metadata():
    png = image_formats['PNG']
    assert png.can_read
    assert png.can_write
    assert not png.supports_frames

    gif = image_formats['GIF']
    assert gif.can_read
    assert gif.can_write
    assert gif.supports_frames

    # "canvas" is a pseudo-format built into ImageMagick that can "read" a
    # solid color but obviously not write it
    canvas = image_formats['CANVAS']
    assert canvas.can_read
    assert not canvas.can_write
    assert not canvas.supports_frames
