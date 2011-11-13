"""Mandatory startup/shutdown for sanpera.

This module initializes the ImageMagick library.  This module gets imported
before anything else; user code should never have to worry about it.
"""
import atexit

from sanpera._magick_api cimport _common, _magick


### Setup

cdef extern from "Python.h":
    char* Py_GetProgramFullPath()

_magick.MagickCoreGenesis(Py_GetProgramFullPath(), _common.MagickFalse)


### Teardown

def _shutdown():
    _magick.MagickCoreTerminus()
atexit.register(_shutdown)
