from sanpera._magick_api cimport _common, _exception, _image

cdef extern from "magick/magick.h":
    ctypedef enum MagickFormatType:
        UndefinedFormatType
        ImplicitFormatType
        ExplicitFormatType

    # nb: These are actually function pointers, but we only care whether
    # they're NULL or not (indicating read/write support), so the actual type
    # doesn't matter
    ctypedef struct DecodeImageHandler:
        pass
    ctypedef struct EncodeImageHandler:
        pass

    ctypedef struct MagickInfo:
        char* name
        char* description
        char* version
        char* note
        char* module
        _image.ImageInfo* image_info
        DecodeImageHandler* decoder
        EncodeImageHandler* encoder
        #IsImageFormatHandler* magick
        void* client_data
        _common.MagickBooleanType adjoin
        _common.MagickBooleanType raw
        _common.MagickBooleanType endian_support
        _common.MagickBooleanType blob_support
        _common.MagickBooleanType seekable_stream
        MagickFormatType format_type
        _common.MagickStatusType thread_support
        _common.MagickBooleanType stealth
        #size_t signature

    MagickInfo* GetMagickInfo(char*, _exception.ExceptionInfo*)
    MagickInfo** GetMagickInfoList(char*, size_t*, _exception.ExceptionInfo*)

    void MagickCoreGenesis(char*, _common.MagickBooleanType)
    void MagickCoreTerminus()
