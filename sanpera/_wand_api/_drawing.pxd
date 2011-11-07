from sanpera._magick_api cimport _common
from sanpera._wand_api cimport _common

cdef extern from "wand/drawing_wand.h":
    ctypedef struct DrawingWand:
        # Opaque pointer
        pass
