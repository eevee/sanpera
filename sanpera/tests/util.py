"""Test utilities only; no actual tests should appear in here!"""

import os.path

from sanpera.image import Image

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


def assert_identical(img1, img2):
    """Compares two image objects and asserts that they represent the same
    semantic image.
    """
    # TODO compare more carefully: size, number of frames, image data, metadata?
    assert img1.size == img2.size
    assert img1.to_buffer() == img2.to_buffer()
