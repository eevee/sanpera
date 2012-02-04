"""Tests based on the resizing/scaling section of the ImageMagick usage
examples.

See: http://www.imagemagick.org/Usage/resize/
"""

import os.path

from sanpera.image import Image, Size

from sanpera.tests import _util

def get_image(filename):
    path = _util.find_source_image(os.path.join('im_usage/resize', filename))
    return Image.read(open(path))

def test_resize_basic():
    # convert dragon.gif -resize 64x64 resize_dragon.gif
    img = get_image('dragon.gif')
    result = img.resize(img.size.fit_inside((64, 64)))
    _util.assert_identical(result, get_image('resize_dragon.gif'))

    # convert terminal.gif -resize 64x64 resize_terminal.gif
    img = get_image('terminal.gif')
    result = img.resize(img.size.fit_inside((64, 64)))
    _util.assert_identical(result, get_image('resize_terminal.gif'))

def test_resize_squish():
    # convert dragon.gif -resize 64x64\! exact_dragon.gif
    img = get_image('dragon.gif')
    result = img.resize((64, 64))
    _util.assert_identical(result, get_image('exact_dragon.gif'))

    # convert terminal.gif -resize 64x64\! exact_terminal.gif
    img = get_image('terminal.gif')
    result = img.resize((64, 64))
    _util.assert_identical(result, get_image('exact_terminal.gif'))

def test_resize_shrink():
    # convert dragon.gif -resize 64x64\> shrink_dragon.gif
    img = get_image('dragon.gif')
    result = img.resize(img.size.fit_inside((64, 64), upscale=False))
    _util.assert_identical(result, get_image('shrink_dragon.gif'))

    # convert terminal.gif -resize 64x64\> shrink_terminal.gif
    img = get_image('terminal.gif')
    result = img.resize(img.size.fit_inside((64, 64), upscale=False))
    _util.assert_identical(result, get_image('shrink_terminal.gif'))

def test_resize_enlarge():
    # convert dragon.gif -resize 64x64\< enlarge_dragon.gif
    img = get_image('dragon.gif')
    result = img.resize(img.size.fit_inside((64, 64), downscale=False))
    _util.assert_identical(result, get_image('enlarge_dragon.gif'))

    # convert terminal.gif -resize 64x64\< enlarge_terminal.gif
    img = get_image('terminal.gif')
    result = img.resize(img.size.fit_inside((64, 64), downscale=False))
    _util.assert_identical(result, get_image('enlarge_terminal.gif'))

def test_resize_fill():
    # convert dragon.gif -resize 64x64\^ fill_dragon.gif
    img = get_image('dragon.gif')
    result = img.resize(img.size.fit_around((64, 64)))
    _util.assert_identical(result, get_image('fill_dragon.gif'))

    # convert terminal.gif -resize 64x64\^ fill_terminal.gif
    img = get_image('terminal.gif')
    result = img.resize(img.size.fit_around((64, 64)))
    _util.assert_identical(result, get_image('fill_terminal.gif'))
