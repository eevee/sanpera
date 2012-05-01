from cpython cimport bool

from sanpera cimport c_api

cdef class Vector:
    cdef int _x
    cdef int _y

cdef class Size(Vector):
    cdef _fit(self, other, minmax, bool upscale, bool downscale)

cdef class Rectangle:
    cdef int _x1
    cdef int _x2
    cdef int _y1
    cdef int _y2

    cdef c_api.RectangleInfo to_rect_info(self)
