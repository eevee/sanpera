"""Utility classes to represent size, position, and other dimensional
properties of images.
"""
from __future__ import division

from collections import namedtuple

# TODO cdef class to speed up the math?
class Size(namedtuple('Size', ('width', 'height'))):
    """Width and height of a rectangle."""

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
    __slots__ = ()

    @classmethod
    def coerce(cls, value):
        if isinstance(value, cls):
            return value

        return cls(*value)



class Offset(Point):
    __slots__ = ()

    def __nonzero__(self):
        return self.x or self.y
