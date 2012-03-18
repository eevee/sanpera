from sanpera._magick_api cimport _pixel

cdef class Color:
    cdef _pixel.MagickPixelPacket c_struct
