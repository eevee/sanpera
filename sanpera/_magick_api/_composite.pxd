from sanpera._magick_api cimport _common, _image

cdef extern from "magick/composite.h":
    _common.MagickBooleanType TextureImage(_image.Image*, _image.Image*)
