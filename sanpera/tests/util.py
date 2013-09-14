"""Test utilities only; no actual tests should appear in here!"""

import os.path

from sanpera.image import Image

### Fetching resources

def data_root():
    return os.path.join(
        os.path.split(__file__)[0],
        'data')

def find_image(path):
    """Return the absolute path to a test data image.

    These are located in `tests/data`.
    """
    return os.path.join(data_root(), path)

def get_image(path):
    """Return a test data image, as an `Image` object."""
    return Image.read(find_image(path))


### Particular assertions

def assert_identical(img1, img2):
    """Compares two image objects and asserts that they represent the same
    semantic image.
    """
    # TODO compare more carefully: size, number of frames, image data, metadata?
    assert img1.size == img2.size
    # TODO this is RGB because it stores no metadata whatsoever.  a better
    # solution would be an in-process comparison; for bonus points, show the
    # diff in some useful manner!
    img1.bit_depth = 8
    img2.bit_depth = 8
    buf1 = img1.to_buffer(format='rgba')
    buf2 = img2.to_buffer(format='rgba')
    assert buf1[:] == buf2[:]
