from sanpera._magick_api cimport _common, _exception, _image

cdef extern from "magick/constitute.h":
    _image.Image *ReadImage(_image.ImageInfo*, _exception.ExceptionInfo*)
    unsigned int WriteImage(_image.ImageInfo*, _image.Image*)
    unsigned int WriteImages(_image.ImageInfo*, _image.Image*, char* filename, _exception.ExceptionInfo* exception)
