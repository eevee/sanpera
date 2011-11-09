from sanpera._magick_api cimport _common, _exception, _image

cdef extern from "magick/blob.h":
    _image.Image* BlobToImage(_image.ImageInfo* image_info, void* blob, size_t length, _exception.ExceptionInfo *exception)
    void* ImageToBlob(_image.ImageInfo* image_info, _image.Image* image, size_t* length, _exception.ExceptionInfo *exception)
