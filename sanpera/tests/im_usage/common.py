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

import os
import os.path
import shlex
import shutil
import subprocess
import tempfile

from sanpera.image import Image
from sanpera.tests import util


class UsageContext(object):
    """Helper object."""
    def __init__(self):
        # Create a temporary directory
        self.tempdir = tempfile.mkdtemp()

        # Make all the builtin test images available
        root = util.data_root()
        # Windows needs a copy; no links
        link = os.symlink or shutil.copy
        for fn in os.listdir(root):
            link(
                os.path.join(root, fn),
                os.path.join(self.tempdir, fn),
            )

    def destroy(self):
        # TODO make a pytest option for skipping the destroy
        shutil.rmtree(self.tempdir)


    def compare(self, got, expected_name):
        expected = Image.read(os.path.join(self.tempdir, expected_name))
        got.write(os.path.join(self.tempdir, 'GOT-' + expected_name), format='miff')

        util.assert_identical(got, expected)

    def do_convert(self, func):
        """Run the given function's `convert` commands."""
        try:
            convert_commands = func.convert_commands
        except AttributeError:
            pass
        else:
            for command in convert_commands:
                words = shlex.split(command)
                subprocess.Popen(words, cwd=self.tempdir).wait()

def convert(*commands):
    """Decorator to associate some number of `convert` calls with a test.

    PLEASE use .miff for filenames!  GIFs will naturally lose color
    information, which sorta defeats the point of pixel-perfect unit tests.
    """
    def decorator(f):
        f.convert_commands = commands
        return f
    return decorator
