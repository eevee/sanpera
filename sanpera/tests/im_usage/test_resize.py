"""Tests based on the resizing/scaling section of the ImageMagick usage
examples.

See: http://www.imagemagick.org/Usage/resize/
"""

import os.path

from sanpera.image import Image, Size
from sanpera.tests import _util
from sanpera.tests.im_usage.common import ImageOperationRegistry

def get_image(filename):
    path = _util.find_source_image(os.path.join('im_usage/resize', filename))
    return Image.read(open(path))

resize_tests = ImageOperationRegistry()


@resize_tests.register('convert dragon.gif -resize 64x64 /tmp/output.gif')
def resize_dragon_basic():
    img = get_image('dragon.gif')
    return img.resize(img.size.fit_inside((64, 64)))

@resize_tests.register('convert terminal.gif -resize 64x64 /tmp/output.gif')
def resize_terminal_basic():
    img = get_image('terminal.gif')
    return img.resize(img.size.fit_inside((64, 64)))


@resize_tests.register('convert dragon.gif -resize 64x64! /tmp/output.gif')
def resize_dragon_squish():
    img = get_image('dragon.gif')
    return img.resize((64, 64))

@resize_tests.register('convert terminal.gif -resize 64x64! /tmp/output.gif')
def resize_terminal_squish():
    img = get_image('terminal.gif')
    return img.resize((64, 64))


@resize_tests.register('convert dragon.gif -resize 64x64> /tmp/output.gif')
def resize_dragon_shrink():
    img = get_image('dragon.gif')
    return img.resize(img.size.fit_inside((64, 64), upscale=False))

@resize_tests.register('convert terminal.gif -resize 64x64> /tmp/output.gif')
def resize_terminal_shrink():
    img = get_image('terminal.gif')
    return img.resize(img.size.fit_inside((64, 64), upscale=False))


@resize_tests.register('convert dragon.gif -resize 64x64< /tmp/output.gif')
def resize_dragon_enlarge():
    img = get_image('dragon.gif')
    return img.resize(img.size.fit_inside((64, 64), downscale=False))

@resize_tests.register('convert terminal.gif -resize 64x64< /tmp/output.gif')
def resize_terminal_enlarge():
    img = get_image('terminal.gif')
    return img.resize(img.size.fit_inside((64, 64), downscale=False))


@resize_tests.register('convert dragon.gif -resize 64x64^ /tmp/output.gif')
def resize_dragon_fill():
    img = get_image('dragon.gif')
    return img.resize(img.size.fit_around((64, 64)))

@resize_tests.register('convert terminal.gif -resize 64x64^ /tmp/output.gif')
def resize_terminal_fill():
    img = get_image('terminal.gif')
    return img.resize(img.size.fit_around((64, 64)))


# I am the actual test command  :)
test_resize_command = resize_tests.python_test_function()
