from sanpera cimport c_api

cdef class Color:
    cdef c_api.MagickPixelPacket c_struct
