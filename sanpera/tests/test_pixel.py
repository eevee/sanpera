"""Does individual pixel access/manipulation work?"""

from sanpera.color import RGBColor
from sanpera.geometry import Vector
from sanpera.image import Image

from sanpera.tests import util

def test_pixel_iter():
    """Does iterating over pixels appear to work?"""
    img = Image.read(util.find_image('terminal.gif'))
    pixel_iter = iter(img[0].pixels)

    white = RGBColor(1., 1., 1.)

    px = next(pixel_iter)
    assert px.point == Vector(0, 0)
    assert px.color == white

    px = next(pixel_iter)
    assert px.point == Vector(1, 0)
    assert px.color == white

def test_pixel_get():
    """Does random pixel inspection work?"""
    img = Image.read(util.find_image('terminal.gif'))
    assert img[0].pixels[11, 6] == RGBColor(1., 0., 0.)

# TODO: implement, test pixel assignment (both iter and random)
