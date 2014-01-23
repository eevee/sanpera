"""Simple unit tests for geometric helper classes."""

import sanpera.geometry as geom

import math

def test_vector_origin():
    vec = geom.Vector(0, 0)
    assert vec == geom.origin
    assert not vec
    assert vec.x == 0
    assert vec.y == 0
    assert tuple(vec) == (0, 0)

def test_vector_simple():
    vec = geom.Vector(3, 4)
    assert vec
    assert vec.x == 3
    assert vec.y == 4
    assert vec.magnitude == 5.0
    assert vec.direction == math.atan2(-4, 3)

    assert vec == geom.Vector(3, 4)
    assert vec + 2 == geom.Vector(5, 6)
    assert vec - 2 == geom.Vector(1, 2)
    assert vec * 2 == geom.Vector(6, 8)

def test_size_zero():
    size = geom.Size(0, 0)
    assert size == geom.empty
    assert not size
    assert size.width == 0
    assert size.height == 0
    assert size.x == 0
    assert size.y == 0
    assert tuple(size) == (0, 0)


def test_size_fit_area():
    size = geom.Size(100, 100)
    assert size.fit_area(64) == geom.Size(8, 8)
    assert size.fit_area(64, downscale=False) == size
    assert size.fit_area(14400) == geom.Size(120, 120)
    assert size.fit_area(14400, upscale=False) == size

    size = geom.Size(200, 300)
    assert size.fit_area(100) == geom.Size(8, 12)
    assert size.fit_area(7) == geom.Size(2, 3)
    assert size.fit_area(8) == geom.Size(2, 4)
    assert size.fit_area(9) == geom.Size(3, 3)
    assert size.fit_area(10) == geom.Size(3, 3)
    assert size.fit_area(11) == geom.Size(2, 5)


def test_size_fit_inside():
    assert geom.Size(50, 50).fit_inside((10, 10)) == geom.Size(10, 10)
    assert geom.Size(50, 50).fit_inside((20, 10)) == geom.Size(10, 10)
    assert geom.Size(50, 50).fit_inside((10, 20)) == geom.Size(10, 10)
    assert geom.Size(50, 50).fit_inside((10, 10), upscale=False) == geom.Size(10, 10)
    assert geom.Size(50, 50).fit_inside((10, 10), downscale=False) == geom.Size(50, 50)

    assert geom.Size(50, 50).fit_inside((100, 100)) == geom.Size(100, 100)
    assert geom.Size(50, 50).fit_inside((200, 100)) == geom.Size(100, 100)
    assert geom.Size(50, 50).fit_inside((100, 200)) == geom.Size(100, 100)
    assert geom.Size(50, 50).fit_inside((100, 100), upscale=False) == geom.Size(50, 50)
    assert geom.Size(50, 50).fit_inside((100, 100), downscale=False) == geom.Size(100, 100)

    # Float rounding edge cases
    assert geom.Size(600, 398).fit_inside((120, 120)) == geom.Size(120, 79)
    assert geom.Size(398, 600).fit_inside((120, 120)) == geom.Size(79, 120)
    assert geom.Size(398, 398).fit_inside((120, 120)) == geom.Size(120, 120)

def test_size_fit_around():
    assert geom.Size(50, 50).fit_around((10, 10)) == geom.Size(10, 10)
    assert geom.Size(50, 50).fit_around((20, 10)) == geom.Size(20, 20)
    assert geom.Size(50, 50).fit_around((10, 20)) == geom.Size(20, 20)
    assert geom.Size(50, 50).fit_around((10, 10), upscale=False) == geom.Size(10, 10)
    assert geom.Size(50, 50).fit_around((10, 10), downscale=False) == geom.Size(50, 50)

    assert geom.Size(50, 50).fit_around((100, 100)) == geom.Size(100, 100)
    assert geom.Size(50, 50).fit_around((200, 100)) == geom.Size(200, 200)
    assert geom.Size(50, 50).fit_around((100, 200)) == geom.Size(200, 200)
    assert geom.Size(50, 50).fit_around((100, 100), upscale=False) == geom.Size(50, 50)
    assert geom.Size(50, 50).fit_around((100, 100), downscale=False) == geom.Size(100, 100)

    # Float rounding edge cases
    assert geom.Size(600, 398).fit_around((120, 120)) == geom.Size(180, 120)
    assert geom.Size(398, 600).fit_around((120, 120)) == geom.Size(120, 180)
    assert geom.Size(398, 398).fit_around((120, 120)) == geom.Size(120, 120)

def test_rect_zero():
    assert geom.Rectangle(0, 0, 10, 10)
    assert not geom.Rectangle(5, 5, 5, 10)
    assert not geom.Rectangle(5, 10, 5, 5)
    assert geom.Rectangle(5, 5, 10, 10)

def test_rect_simple():
    rect = geom.Rectangle(0, 0, 3, 4)
    assert rect.size == geom.Size(3, 4)
