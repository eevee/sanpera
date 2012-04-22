"""Tests based on the resizing/scaling section of the ImageMagick usage
examples.

See: http://www.imagemagick.org/Usage/resize/
"""

import os.path

import pytest

from sanpera.image import Image
from sanpera.tests.util import get_image
from sanpera.tests.im_usage.common import ImageOperationRegistry

resize_tests = ImageOperationRegistry()


### "Resizing Images"

@resize_tests.register('convert dragon.gif -resize 64x64 OUT')
def resize_dragon_basic():
    img = get_image('dragon.gif')
    return img.resize(img.size.fit_inside((64, 64)))

@resize_tests.register('convert terminal.gif -resize 64x64 OUT')
def resize_terminal_basic():
    img = get_image('terminal.gif')
    return img.resize(img.size.fit_inside((64, 64)))


@resize_tests.register('convert dragon.gif -resize 64x64! OUT')
def resize_dragon_squish():
    img = get_image('dragon.gif')
    return img.resize((64, 64))

@resize_tests.register('convert terminal.gif -resize 64x64! OUT')
def resize_terminal_squish():
    img = get_image('terminal.gif')
    return img.resize((64, 64))


@resize_tests.register('convert dragon.gif -resize 64x64> OUT')
def resize_dragon_shrink():
    img = get_image('dragon.gif')
    return img.resize(img.size.fit_inside((64, 64), upscale=False))

@resize_tests.register('convert terminal.gif -resize 64x64> OUT')
def resize_terminal_shrink():
    img = get_image('terminal.gif')
    return img.resize(img.size.fit_inside((64, 64), upscale=False))


@resize_tests.register('convert dragon.gif -resize 64x64< OUT')
def resize_dragon_enlarge():
    img = get_image('dragon.gif')
    return img.resize(img.size.fit_inside((64, 64), downscale=False))

@resize_tests.register('convert terminal.gif -resize 64x64< OUT')
def resize_terminal_enlarge():
    img = get_image('terminal.gif')
    return img.resize(img.size.fit_inside((64, 64), downscale=False))


@resize_tests.register('convert dragon.gif -resize 64x64^ OUT')
def resize_dragon_fill():
    img = get_image('dragon.gif')
    return img.resize(img.size.fit_around((64, 64)))

@resize_tests.register('convert terminal.gif -resize 64x64^ OUT')
def resize_terminal_fill():
    img = get_image('terminal.gif')
    return img.resize(img.size.fit_around((64, 64)))


@resize_tests.register('convert dragon.gif -resize 64x64^ -gravity center -extent 64x64 OUT')
@pytest.mark.xfail
def resize_dragon_fill_crop():
    img = get_image('dragon.gif')
    img = img.resize(img.size.fit_around((64, 64)))
    # XXX extent???

@resize_tests.register('convert terminal.gif -resize 64x64^ -gravity center -extent 64x64 OUT')
@pytest.mark.xfail
def resize_terminal_fill_crop():
    img = get_image('terminal.gif')
    img = img.resize(img.size.fit_around((64, 64)))
    # XXX extent???


@resize_tests.register('convert dragon.gif -resize 50% OUT')
def resize_dragon_half():
    img = get_image('dragon.gif')
    return img.resize(img.size * 0.5)

@resize_tests.register('convert terminal.gif -resize 50% OUT')
def resize_terminal_half():
    img = get_image('terminal.gif')
    return img.resize(img.size * 0.5)


# A note on these tests: old ImageMagick truncates the new dimensions, recent
# ImageMagick rounds.  Size.fit_area is more clever than either of these, so
# the `emulate` flag exists just to make these tests pixel-perfect.  Also note
# that this means these tests will fail on ImageMagick before 6.7.5.
@resize_tests.register('convert dragon.gif -resize 4096@ OUT')
def resize_dragon_pixel():
    img = get_image('dragon.gif')
    return img.resize(img.size.fit_area(4096, emulate=True))

@resize_tests.register('convert terminal.gif -resize 4096@ OUT')
def resize_terminal_pixel():
    img = get_image('terminal.gif')
    return img.resize(img.size.fit_area(4096, emulate=True))


# And these guys have no direct equivalent, because if you want to resize an
# image at read time, you can just do so.
@resize_tests.register('convert dragon.gif[64x64] OUT')
def resize_dragon_read():
    img = get_image('dragon.gif')
    return img.resize(img.size.fit_inside((64, 64)))

@resize_tests.register('convert terminal.gif[64x64] OUT')
def resize_terminal_read():
    img = get_image('terminal.gif')
    return img.resize(img.size.fit_inside((64, 64)))

# I am the actual test command  :)
test_resize_command = resize_tests.python_test_function()
