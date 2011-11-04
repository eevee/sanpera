from sanpera._magick_api cimport _common, _error, _image

cdef extern from "magick/blob.h":
    _image.Image* BlobToImage(_image.ImageInfo* image_info, void* blob, size_t length, _error.ExceptionInfo *exception)
