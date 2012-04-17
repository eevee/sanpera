"""Utility classes to represent size, position, and other dimensional
properties of images.
"""
from __future__ import division

from collections import namedtuple

# TODO cdef class to speed up the math?
class Size(namedtuple('Size', ('width', 'height'))):
    """I represent a width and a height: a rectangle on a plane with no
    particular position.
    """

    __slots__ = ()

    ### Constructors

    def __init__(self, *a, **kw):
        super(Size, self).__init__(*a, **kw)

        # TODO check for ints...?
        # XXX is zero-width allowed?
        if self.width <= 0:
            raise TypeError("Size requires a positive width")
        if self.height <= 0:
            raise TypeError("Size requires a positive height")

    @classmethod
    def coerce(cls, value):
        """Turn a value into a `Size`.  This allows functions to require a size
        argument, without forcing users to construct trivial `Size` objects.

        `value` may either be an existing `Size` instance or an iterable of
        width and height.
        """
        # Don't do anything to existing Size objects
        if isinstance(value, cls):
            return value

        return cls(*value)

    ### Special methods

    def __repr__(self):
        return "<{cls} width={width} height={height}>".format(
            cls=self.__class__.__name__,
            width=self.width,
            height=self.height)

    def __nonzero__(self):
        """Sizes are only truey if they have a width or height."""
        return self.width and self.height

    def __mul__(self, factor):
        return type(self)(self.width * factor, self.height * factor)

    ### Helpful math

    def fit_inside(self, other, upscale=True, downscale=True):
        """Scale this Size proportionally to fit within the given bounds.
        Useful for creating thumbnails.

        Set `upscale` or `downscale` to `False` to prevent resizing in either
        direction.
        """
        return self._fit(other, minmax=max, upscale=upscale, downscale=downscale)

    def fit_around(self, other, upscale=True, downscale=True):
        """Scale this Size proportionally to surround the given bounds.

        Set `upscale` or `downscale` to `False` to prevent resizing in either
        direction.
        """
        return self._fit(other, minmax=min, upscale=upscale, downscale=downscale)

    def _fit(self, other, minmax, upscale=True, downscale=True):
        """Implementation for `fit_inside` and `fit_around`."""

        other = type(self).coerce(other)

        if not upscale and (
                self.width < other.width and self.height < other.height):
            return self

        if not downscale and (
                self.width > other.width and self.height > other.height):
            return self

        ratio = minmax((
            self.width / other.width,
            self.height / other.height))

        return type(self)(
            int(self.width / ratio),
            int(self.height / ratio),
        )


class Point(namedtuple('Point', ('x', 'y'))):
    """I'm a point in a boundless two-dimensional Cartesian plane."""
    __slots__ = ()

    def __init__(self, *a, **kw):
        super(Point, self).__init__(*a, **kw)

        # TODO check for ints...?

    @classmethod
    def coerce(cls, value):
        if isinstance(value, cls):
            return value

        return cls(*value)


    ### Operators

    def __add__(self, other):
        cls = type(self)

        if isinstance(other, int):
            return cls(x=self.x + other, y=self.y + other)
        if isinstance(other, Offset):
            return cls(x=self.x + other.x, y=self.y + other.y)

        return NotImplemented

    def __mul__(self, other):
        cls = type(self)

        if isinstance(other, int):
            return cls(x=self.x * other, y=self.y * other)

        return NotImplemented

origin = Point(0, 0)

Offset = Point
zero = Offset(0, 0)


class Rectangle(namedtuple('Rectangle', ('x1', 'y1', 'x2', 'y2'))):
    def __init__(self, p1, p2):
        # XXX assert tl, br
        super(Rectangle, self).__init__(
            x1=min(p1.x, p2.x),
            y1=min(p1.y, p2.y),
            x2=max(p1.x, p2.x),
            y2=max(p1.y, p2.y),
        )


    @property
    def size(self):
        return Size(width=self.x2 - self.x1, height=self.y2 - self.y1)

    @property
    def position(self):
        return Point(self.x1, self.y1)

    def __nonzero__(self):
        return self.x1 != self.x2 and self.y1 != self.y2

    def __eq__(self, other):
        if isinstance(other, Rectangle):
            return (
                self.x1 == other.x1 and
                self.x2 == other.x2 and
                self.y1 == other.y1 and
                self.y2 == other.y2
            )

        return NotImplemented

    def __contains__(self, other):
        if isinstance(other, Rectangle):
            return (
                self.x1 <= other.x1 and
                self.y1 <= other.y1 and
                self.x2 >= other.x2 and
                self.y2 >= other.y2
            )
        if isinstance(other, Point):
            return (self.x1 <= other.x <= self.x2
                and self.y1 <= other.y <= self.y2)

        return NotImplemented


# note: are size, point, and offset really different at all?  they're all just (x,y) vectors
