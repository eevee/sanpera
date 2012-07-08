"""Deal with ImageMagick errors."""

import warnings

from cpython cimport bool

from sanpera cimport c_api


class SanperaError(Exception):
    message = None

    def __init__(self, message=None):
        if message is None:
            message = self.message

        if message:
            super(SanperaError, self).__init__(message)

class SanperaWarning(SanperaError, UserWarning): pass


class MissingFormatError(SanperaError):
    message = "Refusing to guess image format; please provide one explicitly"

class EmptyImageError(SanperaError):
    message = "Can't write an image that has zero frames"


### Translations of ImageMagick errors
class GenericMagickWarning(SanperaWarning): pass
class GenericMagickError(SanperaError): pass

class MysteryError(SanperaError):
    message = "ImageMagick reported an error but didn't say what it was!"


class OptionWarning(SanperaWarning): pass

# TODO: i can't actually check for this particular warning.
class MissedCropWarning(OptionWarning):
    message = "Trying to crop outside the bounds of an image"




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

    def check(self, bool force not None = False):
        check_magick_exception(self.ptr, force)


magick_exception_map = {
    c_api.OptionWarning: OptionWarning
}

cdef check_magick_exception(c_api.ExceptionInfo* exc, int force = 0):
    """If the given `ExceptionInfo` pointer contains an exception, convert it
    to a Python one and throw it.

    Set `force` to True to throw a generic error even if the pointer doesn't
    seem to indicate an exception.  This is useful in cases where a function
    uses both exceptions and `NULL` returns, which are sadly all too common in
    ImageMagick.
    """
    if exc == NULL or exc.severity == c_api.UndefinedException:
        if force:
            raise MysteryError
        return

    # TODO have more exception classes

    # An exception's description tends to be blank; the actual message
    # is in `reason`
    cdef bytes message
    if exc.reason == NULL:
        message = b''
    else:
        message = exc.reason

    message = message + '   ' + str(<int>exc.severity) + '   ' + str(<int>exc.error_number)

    if exc.severity < c_api.ErrorException:
        # This is a warning, so do a warning
        cls = magick_exception_map.get(exc.severity, GenericMagickWarning)
        warnings.warn(cls(message))
    else:
        # ERROR ERROR
        cls = magick_exception_map.get(exc.severity, GenericMagickError)
        raise cls(message)
