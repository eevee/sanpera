from sanpera cimport c_api

cdef class MagickException:
    cdef c_api.ExceptionInfo* ptr

cdef check_magick_exception(c_api.ExceptionInfo*, int force=*)
