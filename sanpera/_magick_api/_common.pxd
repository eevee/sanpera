"""These files need to be loaded before anything else, or ImageMagick won't
work!  This is gleaned from magick/api.h and battle scars.

Note that he intended usage or ImageMgick seems to be to `#include
"magick/api.h"` and just get everything.  That's not very Pythony, though, and
even the documentation is split up by particular header file, so I and have
tried to preserve the header file arrangement in a less broken manner.
"""

cdef extern from "magick/magick-config.h":
    pass

cdef extern from "magick/magick-type.h":
    pass

cdef extern from "magick/MagickCore.h":
    ctypedef unsigned int MagickPassFail
    ctypedef enum MagickBooleanType:
        MagickFalse
        MagickTrue
