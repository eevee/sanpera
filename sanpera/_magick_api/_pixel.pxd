from sanpera._magick_api cimport _common
from sanpera._magick_api._common cimport MagickBooleanType

cdef extern from "magick/pixel.h":
    ctypedef struct MagickPixelPacket:
        #ClassType storage_class

        #ColorspaceType colorspace

        MagickBooleanType matte

        double fuzz

        size_t depth

        #MagickRealType red
        #MagickRealType green
        #MagickRealType blue
        #MagickRealType opacity
        #MagickRealType index

    ctypedef struct PixelPacket:
        pass
        #Quantum red
        #Quantum green
        #Quantum blue
        #Quantum opacity
