from sanpera._magick_api cimport _common
from sanpera._wand_api cimport _common

cdef extern from "wand/pixel_wand.h":
    ctypedef struct PixelWand:
        # Opaque pointer
        pass
