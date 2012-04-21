"""Simple unit tests for geometric helper classes."""

import sanpera.geometry as geom

import math

def test_vector_origin():
    vec = geom.Vector(0, 0)
    assert vec == geom.origin
    assert not vec
    assert vec.x == 0
    assert vec.y == 0

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

def test_rect_zero():
    assert geom.Rectangle(0, 0, 10, 10)
    assert not geom.Rectangle(5, 5, 5, 10)
    assert not geom.Rectangle(5, 10, 5, 5)
    assert geom.Rectangle(5, 5, 10, 10)

def test_rect_simple():
    rect = geom.Rectangle(0, 0, 3, 4)
