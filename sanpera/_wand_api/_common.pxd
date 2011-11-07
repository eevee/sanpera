# Similar to _magick_api, some include files quietly need including before
# others, and they appear here.

cdef extern from "wand/magick_wand.h":
    # Contains WandExport
    pass
