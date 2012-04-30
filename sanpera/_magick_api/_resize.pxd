from sanpera._magick_api cimport _common, _exception, _image

cdef extern from "magick/resize.h":
    _image.Image* AdaptiveResizeImage(_image.Image*, size_t, size_t, _exception.ExceptionInfo*)
    _image.Image* LiquidRescaleImage(_image.Image*, size_t, size_t, double, double, _exception.ExceptionInfo*)
    _image.Image* MagnifyImage(_image.Image*, _exception.ExceptionInfo*)
    _image.Image* MinifyImage(_image.Image*, _exception.ExceptionInfo*)
    _image.Image* ResampleImage(_image.Image*, double, double, _image.FilterTypes, double, _exception.ExceptionInfo*)
    _image.Image* ResizeImage(_image.Image*, size_t, size_t, _image.FilterTypes, double, _exception.ExceptionInfo*)
    _image.Image* SampleImage(_image.Image*, size_t, size_t, _exception.ExceptionInfo*)
    _image.Image* ScaleImage(_image.Image*, size_t, size_t, _exception.ExceptionInfo*)
    _image.Image* ThumbnailImage(_image.Image*, size_t, size_t, _exception.ExceptionInfo*)
