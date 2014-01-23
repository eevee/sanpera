"""Classes that represent size, position, and other geometric properties of
images.
"""
from __future__ import division
from collections import namedtuple
import math

from sanpera._api import ffi, lib


def approx_equal(f1, f2, epsilon=1e-6):
    return abs(f1 - f2) < epsilon


class Vector(namedtuple('_Vector', ['x', 'y'])):
    """I'm a direction and magnitude in a two-dimensional plane, where the axes
    increase rightwards and down.  I can also represent a single point.
    """
    __slots__ = ()

    ### Attribute access

    @property
    def magnitude(self):
        return math.hypot(self.x, self.y)

    @property
    def direction(self):
        # Remember: the y-axis is flipped
        return math.atan2(- self.y, self.x)


    ### Construction

    @classmethod
    def coerce(cls, value):
        """Turn a value into a `Vector`.  Existing `Vector` objects are
        returned unchanged; tuples of `(x, y)` are fed to the constructor.
        """
        if isinstance(value, cls):
            return value

        return cls(*value)


    ### Special methods

    def __repr__(self):
        return "<{cls} x={x} y={y}>".format(
            cls=type(self).__name__,
            x=self.x,
            y=self.y)

    def __richcmp__(self, other, op):
        if not isinstance(self, Vector) or not isinstance(other, Vector):
            return NotImplemented


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

    def __nonzero__(self):
        """Every `Vector` is truthy, except the zero vector."""
        return self.x or self.y

    def __add__(self, other):
        cls = type(self)

        if isinstance(other, int):
            return cls(self.x + other, self.y + other)

        if isinstance(other, Vector):
            return cls(self.x + two.x, self.y + two.y)

        return NotImplemented

    def __radd__(self, other):
        return self.__add__(other)

    def __neg__(self):
        return type(self)(- self.x, - self.y)

    def __sub__(self, other):
        return self + -other

    def __rsub__(self, other):
        return -self + other

    def __mul__(self, other):
        cls = type(self)

        if isinstance(other, int):
            return cls(self.x * other, self.y * other)

        if isinstance(other, float):
            return cls(int(self.x * other + 0.5), int(self.y * other + 0.5))

        return NotImplemented


class Size(Vector):
    """I represent the dimensions of some rectangular area.  I'm like a
    `Vector`, but my `x` and `y` must be positive.

    `width`, `height`, and `diagonal` are provided as aliases for `Vector`
    properties.
    """
    __slots__ = ()

    @property
    def width(self):
        return self.x

    @property
    def height(self):
        return self.y

    @property
    def diagonal(self):
        return self.magnitude

    @property
    def area(self):
        return self.x * self.y


    ### Special methods

    def __repr__(self):
        return "<{cls} width={width} height={height}>".format(
            cls=self.__class__.__name__,
            width=self.x,
            height=self.y)

    def __nonzero__(self):
        """Sizes are falsey if _either_ dimension is zero."""
        return self.x and self.y

    def __neg__(self):
        return NotImplemented


    ### Helpful math

    def at(self, point):
        """Return a `Rectangle` of this size with its upper-right corner at the
        given point.
        """
        vec = Vector.coerce(point)
        return Rectangle(vec.x, vec.y, vec.x + self.x, vec.y + self.y)

    def fit_area(self, area, upscale=True, downscale=True):
        """Scale this Size proportionally to have approximately the given
        number of pixels (but no more).

        Exceptionally large images may not be able to fit in a given area; for
        example, a 1000x1 image can't be scaled to fit within 100 pixels.  In
        that case, this method raises a `ValueError`.

        Set `upscale` or `downscale` to `False` to prevent resizing in either
        direction.
        """
        # FYI: from between 6.7.3 and 6.7.6 until 6.8.6-5, ImageMagick rounded
        # the width and height when calculating the @ flag rather than
        # truncating them, which broke the promise that the new size is no
        # larger than the requested area.

        if area <= 0:
            raise ValueError("Area to fit must be positive")

        current_area = self.area

        if not upscale and current_area < area:
            return self

        if not downscale and current_area > area:
            return self

        cls = type(self)
        ratio = math.sqrt(area / current_area)

        approx_width = int(self.x * ratio)
        approx_height = int(self.y * ratio)

        # Find the combination of rounding the new width and height that gets
        # closest to the desired area.
        best_area = 0

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

    def fit_inside(self, other, upscale=True, downscale=True):
        """Scale this Size proportionally to fit within the given bounds.
        Useful for creating thumbnails.

        Set `upscale` or `downscale` to `False` to prevent resizing in either
        direction.
        """
        return self._fit(other, max, upscale, downscale)

    def fit_around(self, other, upscale=True, downscale=True):
        """Scale this Size proportionally to surround the given bounds.

        Set `upscale` or `downscale` to `False` to prevent resizing in either
        direction.
        """
        return self._fit(other, min, upscale, downscale)

    def _fit(self, other, minmax, upscale, downscale):
        """Implementation for `fit_inside` and `fit_around`."""

        coerced = type(self).coerce(other)

        if not upscale and (
                self.width < coerced.width and self.height < coerced.height):
            return self

        if not downscale and (
                self.width > coerced.width and self.height > coerced.height):
            return self

        width_ratio = self.width / coerced.width
        height_ratio = self.height / coerced.height
        if approx_equal(width_ratio, height_ratio):
            return coerced
        elif approx_equal(minmax(width_ratio, height_ratio), width_ratio):
            return self.__class__(coerced.width, int(self.height / width_ratio))
        else:
            return self.__class__(int(self.width / height_ratio), coerced.height)


class Rectangle(namedtuple('_Rectangle', ['x1', 'y1', 'x2', 'y2'])):
    """I represent a bounded rectangular area on a plane."""

    ### Attribute access

    @property
    def position(self):
        return Vector(self.x1, self.y1)

    @property
    def size(self):
        return Size(self.x2 - self.x1, self.y2 - self.y1)


    ### Construction

    # Have to use __new__ here since a `tuple` needs to know its size before
    # being created.  Not sure why __init__ works on py2, but it doesn't on 3
    def __new__(cls, x1, y1, x2, y2):
        """Create a rectangle using the coordinates of its sides."""
        # Fix up coordinate order if necessary
        if x1 > x2:
            x1, x2 = x2, x1
        if y1 > y2:
            y1, y2 = y2, y1

        return super(Rectangle, cls).__new__(cls, x1, y1, x2, y2)

    def at(self, point):
        return self.size.at(point)

    def intersection(self, other):
        """Return the rectangle for the overlapping areas between these two.
        """
        # Intersection is the right-most left edge, bottom-most top edge, etc.
        x1 = max(self.x1, other.x1)
        y1 = max(self.y1, other.y1)
        x2 = min(self.x2, other.x2)
        y2 = min(self.y2, other.y2)

        # Check for complete lack of overlap, indicated by swapped points, and
        # make the non-overlapping dimensions zero
        if x1 > x2:
            x1 = x2 = (x1 + x2) // 2
        if y1 > y2:
            y1 = y2 = (y1 + y2) // 2

        return Rectangle(x1, y1, x2, y2)


    ### Special methods

    def __iter__(self):
        raise NotImplementedError

    def __repr__(self):
        return "<{cls} topleft=({x1!r}, {y1!r}) bottomright=({x2!r}, {y2!r})".format(
            cls=self.__class__.__name__,
            x1=self.x1, y1=self.y1,
            x2=self.x2, y2=self.y2)

    def __bool__(self):
        return self.x1 != self.x2 and self.y1 != self.y2

    __nonzero__ = __bool__

    def __add__(self, other):
        cls = type(self)

        if isinstance(other, int):
            return cls(
                self.x1 + other, self.y1 + other,
                self.x2 + other, self.y2 + other)

        return NotImplemented

    def __contains__(self, other):
        if isinstance(other, Rectangle):
            return (
                self.x1 <= other.x1 and
                self.y1 <= other.y1 and
                self.x2 >= other.x2 and
                self.y2 >= other.y2
            )
        if isinstance(other, Vector):
            return (self.x1 <= other.x <= self.x2
                and self.y1 <= other.y <= self.y2)

        return NotImplemented


    ### Properties

    @property
    def left(self):
        return self.x1

    @property
    def right(self):
        return self.x2

    @property
    def top(self):
        return self.y1

    @property
    def bottom(self):
        return self.y2

    @property
    def width(self):
        return self.x2 - self.x1

    @property
    def height(self):
        return self.y2 - self.y1

    ### Conversion

    def to_rect_info(self):
        rectinfo = ffi.new("RectangleInfo *")
        rectinfo.x = self.left
        rectinfo.y = self.top
        rectinfo.width = self.width
        rectinfo.height = self.height
        return rectinfo


origin = Vector(0, 0)
empty = Size(0, 0)
