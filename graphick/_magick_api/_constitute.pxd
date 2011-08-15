from graphick._magick_api cimport _common, _error, _image

cdef extern from "magick/constitute.h":
    _image.Image *ReadImage(_image.ImageInfo*, _error.ExceptionInfo*)
    unsigned int WriteImage(_image.ImageInfo*, _image.Image*)
