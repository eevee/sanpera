from cpython cimport bool

from sanpera._magick_api cimport _image

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

    cdef _image.RectangleInfo to_rect_info(self)
