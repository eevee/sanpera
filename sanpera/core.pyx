from sanpera._magick_api cimport _magick

cdef extern from "Python.h":
    char* Py_GetProgramFullPath()

_magick.InitializeMagick(Py_GetProgramFullPath())
