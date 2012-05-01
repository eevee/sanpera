"""Deal with ImageMagick errors."""

from sanpera cimport c_api

class SanperaError(Exception):
    message = None

    def __init__(self):
        if self.message:
            super(SanperaError, self).__init__(self.message)

class MissingFormatError(SanperaError):
    message = "Refusing to guess image format; please provide one explicitly"

class EmptyImageError(SanperaError):
    message = "Can't write an image that has zero frames"


# Translations of ImageMagick errors
#class GenericMagickError(SanperaError): pass
class GenericMagickError(Exception): pass


cdef class MagickException:
    """Refcounty wrapper for an ImageMagick exception.  Create it and feed its
    `ptr` attribute to a C API call that wants an `ExceptionInfo` object,
    then call `check()`.  If there seems to be an exception set, it'll be
    translated into a Python exception.
    """

    # Defined in exception.pxd
    #cdef c_api.ExceptionInfo* ptr

    def __cinit__(self):
        self.ptr = c_api.AcquireExceptionInfo()

    def __dealloc__(self):
        c_api.DestroyExceptionInfo(self.ptr)

    def check(self):
        check_magick_exception(self.ptr)


cdef check_magick_exception(c_api.ExceptionInfo* exc):
    """If the given `ExceptionInfo` pointer contains an exception, convert it
    to a Python one and throw it.
    """
    if exc == NULL or exc.severity == c_api.UndefinedException:
        return

    # TODO have more exception classes

    # An exception's description tends to be blank; the actual message
    # is in `reason`
    cdef bytes message
    if exc.reason == NULL:
        message = b''
    else:
        message = exc.reason

    raise GenericMagickError(message + ' ' + str(<int>exc.severity))
    raise GenericMagickError(message)
