from sanpera._magick_api cimport _common, _exception, _image, _pixel
from sanpera._magick_api._common cimport MagickBooleanType

cdef extern from "magick/cache.h":
    #IndexPacket *GetVirtualIndexQueue(_image.Image*)

    _pixel.PixelPacket* GetVirtualPixels(_image.Image*, ssize_t, ssize_t, size_t, size_t, _exception.ExceptionInfo*)
    _pixel.PixelPacket* GetVirtualPixelQueue(_image.Image*)

    #void *AcquirePixelCachePixels(_image.Image*, MagickSizeType*, _exception.ExceptionInfo*)

    #IndexPacket* GetAuthenticIndexQueue(_image.Image*)

    MagickBooleanType CacheComponentGenesis()
    MagickBooleanType GetOneVirtualMagickPixel(_image.Image*, ssize_t, ssize_t, _pixel.MagickPixelPacket*, _exception.ExceptionInfo*)
    MagickBooleanType GetOneVirtualPixel(_image.Image*, ssize_t, ssize_t, _pixel.PixelPacket*, _exception.ExceptionInfo*)
    #MagickBooleanType GetOneVirtualMethodPixel(_image.Image*, VirtualPixelMethod, ssize_t, ssize_t, _pixel.PixelPacket*, _exception.ExceptionInfo*)
    MagickBooleanType GetOneAuthenticPixel(_image.Image*, ssize_t, ssize_t, _pixel.PixelPacket*, _exception.ExceptionInfo*)
    #MagickBooleanType PersistPixelCache(_image.Image*, char*, MagickBooleanType, MagickOffsetType*, _exception.ExceptionInfo*)
    MagickBooleanType SyncAuthenticPixels(_image.Image*, _exception.ExceptionInfo*)

    #MagickSizeType GetImageExtent(_image.Image*)

    _pixel.PixelPacket* GetAuthenticPixels(_image.Image*, ssize_t, ssize_t, size_t, size_t, _exception.ExceptionInfo*)
    _pixel.PixelPacket* GetAuthenticPixelQueue(_image.Image*)
    _pixel.PixelPacket* QueueAuthenticPixels(_image.Image*, ssize_t, ssize_t, size_t, size_t, _exception.ExceptionInfo*)

    #VirtualPixelMethod GetPixelCacheVirtualMethod(_image.Image*)
    #VirtualPixelMethod SetPixelCacheVirtualMethod(_image.Image*, VirtualPixelMethod)

    void CacheComponentTerminus()
    #void* GetPixelCachePixels(_image.Image*, MagickSizeType*, _exception.ExceptionInfo*)
