"""Mandatory startup/shutdown for sanpera.

This module initializes the ImageMagick library.  This module gets imported
before anything else; user code should never have to worry about it.
"""
import atexit

from sanpera cimport c_api


### Setup

cdef extern from "Python.h":
    char* Py_GetProgramFullPath()

# Let ImageMagick do its setup stuff
c_api.MagickCoreGenesis(Py_GetProgramFullPath(), c_api.MagickFalse)


### Teardown

def _shutdown():
    c_api.MagickCoreTerminus()
atexit.register(_shutdown)
