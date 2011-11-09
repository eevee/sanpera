from sanpera._magick_api cimport _common

cdef extern from "magick/memory_.h":
    ctypedef void* (*AcquireMemoryHandler)(size_t)
    ctypedef void (*DestroyMemoryHandler)(void*)
    ctypedef void* (*ResizeMemoryHandler)(void*, size_t)

    void* AcquireAlignedMemory(size_t, size_t)
    void* AcquireMagickMemory(size_t)
    void* AcquireQuantumMemory(size_t, size_t)
    void* CopyMagickMemory(void*, void*, size_t)
    void DestroyMagickMemory()
    void GetMagickMemoryMethods(AcquireMemoryHandler*, ResizeMemoryHandler*, DestroyMemoryHandler*)
    void* RelinquishAlignedMemory(void*)
    void* RelinquishMagickMemory(void*)
    void* ResetMagickMemory(void*, int, size_t)
    void* ResizeMagickMemory(void*, size_t)
    void* ResizeQuantumMemory(void*, size_t, size_t)
    void SetMagickMemoryMethods(AcquireMemoryHandler,ResizeMemoryHandler, DestroyMemoryHandler)
