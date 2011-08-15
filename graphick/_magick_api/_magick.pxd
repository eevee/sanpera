from graphick._magick_api cimport _common, _error

cdef extern from "magick/magick.h":
    ctypedef struct MagickInfo:
        char* name
        char* description
        char* note
        char* version
        char* module
        # TODO there are more, naturally

    void DestroyMagick()
    char* GetImageMagick(unsigned char* magick, size_t length)
    MagickInfo** GetMagickInfoArray(_error.ExceptionInfo* exception)
    void InitializeMagick(char *path)
