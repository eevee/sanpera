from sanpera._magick_api cimport _common, _image

cdef extern from "magick/property.h":
    char* GetImageProperty(_image.Image*, char*)
    char* GetNextImageProperty(_image.Image*)
    void ResetImagePropertyIterator(_image.Image*)
