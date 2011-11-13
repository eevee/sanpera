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
