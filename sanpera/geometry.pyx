"""Classes that represent size, position, and other geometric properties of
images.
"""
from __future__ import division

from cpython cimport bool

from sanpera cimport c_api

import math

cdef class Vector:
    """I'm a direction and magnitude in a two-dimensional plane, where the axes
    increase rightwards and down.  I can also represent a single point.
    """
    #cdef int _x
    #cdef int _y

    ### Attribute access

    property x:
        def __get__(self):
            return self._x

    property y:
        def __get__(self):
            return self._y

    property magnitude:
        def __get__(self):
            return math.hypot(self._x, self._y)

    property direction:
        def __get__(self):
            # Remember: the y-axis is flipped
            return math.atan2(- self._y, self._x)


    ### Construction

    def __cinit__(self):
        self._x = 0
        self._y = 0

    def __init__(self, int x, int y):
        self._x = x
        self._y = y

    @classmethod
    def coerce(type cls, value):
        """Turn a value into a `Vector`.  Existing `Vector` objects are
        returned unchanged; tuples of `(x, y)` are fed to the constructor.
        """
        if isinstance(value, cls):
            return value

        return cls(*value)


    ### Special methods

    def __repr__(self):
        return "<{cls} x={x} y={y}>".format(
            cls=self.__class__.__name__,
            x=self._x,
            y=self._y)

    def __richcmp__(self, other, int op):
        if not isinstance(self, Vector) or not isinstance(other, Vector):
            return NotImplemented

        cdef Vector one = self
        cdef Vector two = other

        lt = one._x < two._x and one._y < two._y
        eq = one._x == two._x and one._y == two._y
        gt = one._x > two._x and one._y > two._y

        if op == 0:
            return lt
        elif op == 1:
            return lt or eq
        elif op == 2:
            return eq
        elif op == 3:
            return not eq
        elif op == 4:
            return gt
        elif op == 5:
            return gt or eq

        return NotImplemented

    def __iter__(self):
        """Unpacks into `(x, y)`."""
        return iter((self._x, self._y))

    def __nonzero__(self):
        """Every `Vector` is truthy, except the zero vector."""
        return self._x or self._y

    def __add__(self, other):
        cdef Vector one
        cdef Vector two
        cdef type cls

        if isinstance(self, Vector):
            one = self
            pytwo = other
        else:
            one = other
            pytwo = self
        cls = one.__class__

        if isinstance(pytwo, int):
            return cls(one._x + pytwo, one._y + pytwo)
        if isinstance(pytwo, Vector):
            two = pytwo
            return cls(one._x + two._x, one._y + two._y)

        return NotImplemented

    def __neg__(self):
        return self.__class__(- self._x, - self._y)

    def __sub__(self, other):
        if isinstance(self, Vector):
            return self + -other
        else:
            return -self + other

    def __mul__(self, other):
        cdef Vector one
        cdef Vector two
        cdef type cls

        if isinstance(self, Vector):
            one = self
            pytwo = other
        else:
            one = other
            pytwo = self
        cls = one.__class__

        if isinstance(pytwo, int):
            return cls(one._x * pytwo, one._y * pytwo)
        if isinstance(pytwo, float):
            return cls(int(one._x * pytwo + 0.5), int(one._y * pytwo + 0.5))
        if isinstance(pytwo, Vector):
            two = pytwo
            return cls(one._x * two._x, one._y * two._y)

        return NotImplemented

    ### Helpful math


cdef class Size(Vector):
    """I represent the dimensions of some rectangular area.  I'm like a
    `Vector`, but my `x` and `y` must be positive.

    `width`, `height`, and `diagonal` are provided as aliases for `Vector`
    properties.
    """

    property width:
        def __get__(self):
            return self._x

    property height:
        def __get__(self):
            return self._y

    property diagonal:
        def __get__(self):
            return self.magnitude

    property area:
        def __get__(self):
            return self._x * self._y


    def __init__(self, unsigned int width, unsigned int height):
        Vector.__init__(self, width, height)


    ### Special methods

    def __repr__(self):
        return "<{cls} width={width} height={height}>".format(
            cls=self.__class__.__name__,
            width=self._x,
            height=self._y)

    def __nonzero__(self):
        """Sizes are falsey if _either_ dimension is zero."""
        return self._x and self._y

    def __neg__(self):
        return NotImplemented


    ### Helpful math

    def at(self, point):
        """Return a `Rectangle` of this size with its upper-right corner at the
        given point.
        """
        cdef Vector vec = Vector.coerce(point)
        return Rectangle(vec._x, vec._y, vec._x + self._x, vec._y + self._y)

    def fit_area(self, int area, bool upscale not None=True, bool downscale not None=True,
            bool emulate not None=False):
        """Scale this Size proportionally to have approximately the given
        number of pixels (but no more).

        Exceptionally large images may not be able to fit in a given area; for
        example, a 1000x1 image can't be scaled to fit within 100 pixels.  In
        that case, this method raises a `ValueError`.

        Set `upscale` or `downscale` to `False` to prevent resizing in either
        direction.
        """
        # A note on ImageMagick's actual behavior:
        # In 6.7.3, the width and height are merely truncated.
        # In 6.7.6, the width and height are rounded.
        # The "emulate" flag emulates the latter behavior, which violates the
        # guarantee that the new size is no larger than the requested area.

        if area <= 0:
            raise ValueError("Area to fit must be positive")

        cdef int current_area = self._x * self._y

        if not upscale and current_area < area:
            return self

        if not downscale and current_area > area:
            return self

        cls = self.__class__
        cdef float ratio = math.sqrt(area / current_area)

        if emulate:
            return cls(int(self._x * ratio + 0.5), int(self._y * ratio + 0.5))

        cdef int approx_width = int(self._x * ratio)
        cdef int approx_height = int(self._y * ratio)

        # Find the combination of rounding the new width and height that gets
        # closest to the desired area.
        cdef int best_width
        cdef int best_height
        cdef int best_area = 0

        cdef int temp_width
        cdef int temp_height
        cdef int temp_area

        cdef int dw
        cdef int dh

        for dw, dh in ((0, 0), (0, 1), (1, 0)):
            temp_width = approx_width + dw
            temp_height = approx_height + dh
            temp_area = temp_width * temp_height
            if best_area < temp_area <= area:
                best_width = temp_width
                best_height = temp_height
                best_area = temp_area

        if best_area == 0:
            raise ValueError("Couldn't fit image to desired area")

        return cls(best_width, best_height)

    def fit_inside(self, other, bool upscale not None=True, bool downscale not None=True):
        """Scale this Size proportionally to fit within the given bounds.
        Useful for creating thumbnails.

        Set `upscale` or `downscale` to `False` to prevent resizing in either
        direction.
        """
        return self._fit(other, max, upscale, downscale)

    def fit_around(self, other, bool upscale not None=True, bool downscale not None=True):
        """Scale this Size proportionally to surround the given bounds.

        Set `upscale` or `downscale` to `False` to prevent resizing in either
        direction.
        """
        return self._fit(other, min, upscale, downscale)

    cdef _fit(self, other, minmax, bool upscale, bool downscale):
        """Implementation for `fit_inside` and `fit_around`."""

        cdef Size coerced = self.__class__.coerce(other)

        if not upscale and (
                self.width < coerced.width and self.height < coerced.height):
            return self

        if not downscale and (
                self.width > coerced.width and self.height > coerced.height):
            return self

        ratio = minmax((
            self.width / coerced.width,
            self.height / coerced.height))

        return self.__class__(
            int(self.width / ratio),
            int(self.height / ratio),
        )



    ### Utilities


cdef class Rectangle:
    """I represent a bounded rectangular area on a plane."""
    #cdef int _x1
    #cdef int _x2
    #cdef int _y1
    #cdef int _y2

    ### Attribute access

    property position:
        def __get__(self):
            return Vector(self._x1, self._y1)

    property size:
        def __get__(self):
            return Size(self._x2 - self._x1, self._y2 - self._y1)


    ### Construction

    def __cinit__(self):
        self._x1 = 0
        self._y1 = 0
        self._x2 = 0
        self._y2 = 0

    def __init__(self, int x1, int y1, int x2, int y2):
        """Create a rectangle using the coordinates of its sides."""
        # Fix up coordinate order if necessary
        if x1 > x2:
            x1, x2 = x2, x1
        if y1 > y2:
            y1, y2 = y2, y1

        self._x1 = x1
        self._y1 = y1
        self._x2 = x2
        self._y2 = y2


    ### Special methods

    def __repr__(self):
        return "<{cls} topleft=({x1!r}, {y1!r}) bottomright=({x2!r}, {y2!r})".format(
            cls=self.__class__.__name__,
            x1=self._x1, y1=self._y1,
            x2=self._x2, y2=self._y2)

    def __nonzero__(self):
        return self._x1 != self._x2 and self._y1 != self._y2

    def __add__(self, other):
        cls = self.__class__

        if isinstance(other, int):
            return cls(
                self._x1 + other, self._y1 + other,
                self._x2 + other, self._y2 + other)

        return NotImplemented

    def __contains__(self, other):
        if isinstance(other, Rectangle):
            return (
                self._x1 <= other._x1 and
                self._y1 <= other._y1 and
                self._x2 >= other._x2 and
                self._y2 >= other._y2
            )
        if isinstance(other, Vector):
            return (self._x1 <= other._x <= self._x2
                and self._y1 <= other._y <= self._y2)

        return NotImplemented


    ### Conversion

    cdef c_api.RectangleInfo to_rect_info(self):
        cdef c_api.RectangleInfo rectinfo

        rectinfo.x = self._x1
        rectinfo.y = self._y1
        rectinfo.width = self._x2 - self._x1
        rectinfo.height = self._y2 - self._y1

        return rectinfo




origin = Vector(0, 0)
empty = Size(0, 0)
