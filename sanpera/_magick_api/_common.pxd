"""These files need to be loaded before anything else, or GraphicsMagick won't
work!  This is gleaned from magick/api.h and battle scars.

Note that he intended usage or GraphicsMgick seems to be to `#include
"magick/api.h"` and just get everything.  That's not very Pythony, though, and
even the documentation is split up by particular header file, so I and have
tried to preserve the header file arrangement in a less broken manner.
"""

cdef extern from "magick/magick_config.h":
    pass

cdef extern from "magick/common.h":
    ctypedef unsigned int MagickPassFail
    ctypedef unsigned int MagickBool

cdef extern from "magick/forward.h":
    pass
