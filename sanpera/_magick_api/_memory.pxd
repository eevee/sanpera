from sanpera._magick_api cimport _common

cdef extern from "magick/memory.h":
    ctypedef void* (*MagickMallocFunc)(size_t size)
    ctypedef void (*MagickFreeFunc)(void* ptr)
    ctypedef void* (*MagickReallocFunc)(void* ptr, size_t size)

    void MagickAllocFunctions(MagickFreeFunc free_func, MagickMallocFunc malloc_func, MagickReallocFunc realloc_func)
    void* MagickMalloc(size_t size)
    void* MagickMallocCleared(size_t size)
    void* MagickCloneMemory(void* destination, void* source, size_t size)
    void* MagickRealloc(void* memory, size_t size)
    void MagickFree(void* memory)
