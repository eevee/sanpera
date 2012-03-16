from sanpera._magick_api cimport _exception

cdef class MagickException:
    cdef _exception.ExceptionInfo* ptr

cdef check_magick_exception(_exception.ExceptionInfo*)
