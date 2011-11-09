from sanpera._magick_api cimport _common, _exception, _image

cdef extern from "magick/magick.h":
    ctypedef struct MagickInfo:
        char* name
        char* description
        char* note
        char* version
        char* module
        # TODO there are more, naturally

    char* GetImageMagick(unsigned char* magick, size_t length)
    MagickInfo** GetMagickInfoArray(_exception.ExceptionInfo* exception)

    void MagickCoreGenesis(char*, _common.MagickBooleanType)
    void MagickCoreTerminus()
