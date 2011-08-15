from graphick._magick_api cimport _common

cdef extern from "magick/error.h":
    ctypedef struct ExceptionInfo:
        # XXX severity
        char* reason
        char* description
        int error_number
        char* module
        char* function
        unsigned long line
        # nb: this appears to be struct junk, ignore
        #unsigned long signature

    void CatchException(ExceptionInfo*)
    void DestroyExceptionInfo(ExceptionInfo *)
    void GetExceptionInfo(ExceptionInfo *)
