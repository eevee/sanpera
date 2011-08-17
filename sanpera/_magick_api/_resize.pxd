from sanpera._magick_api cimport _common, _error, _image

cdef extern from "magick/resize.h":
    _image.Image *ResizeImage(_image.Image *, unsigned long, unsigned long, _image.FilterTypes, double, _error.ExceptionInfo *)
