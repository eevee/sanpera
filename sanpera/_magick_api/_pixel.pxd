from sanpera._magick_api cimport _common

cdef extern from "magick/pixel.h":
    ctypedef struct MagickPixelPacket:
        pass
