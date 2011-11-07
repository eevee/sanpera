from sanpera._magick_api cimport _common

cdef extern from "magick/log.h":
    unsigned long SetLogEventMask(char*)
