"""Common functionality for testing the ImageMagick usage examples.

Each testcase consists of a series of `convert` commands taken from the usage
documentation, followed by a section of Python code meant to replicate the same
effect.  A registry class and decorator are defined in this module to help
define testcases more readably.

Besides comparing the `convert` output against the Python code, a parallel set
of test modules (sanpera.tests.command) compares the `convert` output against
sanpera's own implementation of `convert`.

Look at some of the actual modules to see how this works.
"""

import subprocess

import pytest

from sanpera.image import Image
from sanpera.tests import _util

class ImageOperationRegistry(object):
    """Registers a list of `convert` commands and corresponding Python
    functions.
    """

    def __init__(self):
        self.operations = []

    def register(self, command):
        """Use me like this:

            @registry.register('convert foo.png bar.png')
            def python_code():
                return Image(...)
        """
        def decorator(func):
            self.operations.append((
                command,
                func,
            ))

            return func

        return decorator

    def python_test_function(self):
        """Generate a test function that will run every test in the registry
        against the Python code.  You have to do this for py.test to see your
        tests.
        """
        decorator = pytest.mark.parametrize(
            ('command', 'function'),
            self.operations)
        return decorator(self._generic_python_test_function)

    # TODO cache the created file, instead of creating it for both the python and command tests?
    # TODO this sorely needs a better way to specify the location of the temporary output file
    # TODO fix the finding of input files both in Python and below, too.
    @staticmethod
    def _generic_python_test_function(command, function):
        """Template for `python_test_function`."""

        # Run the command to get the expected output
        words = command.split()
        subprocess.Popen(words, cwd='sanpera/tests/data/im_usage/resize').wait()
        expected = Image.read(open('/tmp/output.gif'))

        # Run the Python code
        actual = function()

        # Compare
        _util.assert_identical(expected, actual)
