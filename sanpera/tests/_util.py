"""Test utilities only; no actual tests should appear in here!"""

import os.path

def find_source_image(path):
    """Return the absolute path to a test data image.

    These are located in `tests/data`.
    """
    return os.path.join(
        os.path.split(__file__)[0],
        'data',
        path,
    )

def assert_identical(img1, img2):
    """Compares two image objects and asserts that they represent the same
    semantic image.
    """
    # TODO compare more carefully: size, number of frames, image data, metadata?
    assert img1.size == img2.size
    assert img1.write_buffer() == img2.write_buffer()
