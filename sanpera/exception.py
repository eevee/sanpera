"""Translate ImageMagick exceptions into Python exceptions."""
from contextlib import contextmanager
import warnings

from sanpera._api import ffi, lib


@contextmanager
def magick_try():
    """Returns an object whose `ptr` is an ImageMagick exception object, which
    you can pass to C calls.  At the end of the block, if the pointer contains
    exception information, a corresponding Python exception will be raised.

    You can also call the `check` method on the returned object to manually
    check a return value and raise an exception if it's truthy.
    """
    ctx = MagickExceptionContext()
    yield ctx
    ctx.check_self()


class MagickExceptionContext(object):
    """Wrapper for an ImageMagick exception.  Should generally be used with
    `magick_try`.
    """
    def __init__(self):
        self.ptr = ffi.gc(
            lib.AcquireExceptionInfo(),
            lib.DestroyExceptionInfo)

    def check(self, condition):
        magick_raise(self.ptr, force=condition)

    def check_self(self):
        magick_raise(self.ptr)


def magick_raise(exc, force=False):
    """If the given `ExceptionInfo` pointer contains an exception, convert it
    to a Python one and throw it.

    Set `force` to True to throw a generic error even if the pointer doesn't
    seem to indicate an exception.  This is useful in cases where a function
    uses both exceptions and `NULL` returns, which are sadly all too common in
    ImageMagick.
    """
    if exc == ffi.NULL or exc.severity == lib.UndefinedException:
        if force:
            raise MysteryError
        return

    # TODO have more exception classes

    # An exception's description tends to be blank; the actual message
    # is in `reason`
    if exc.reason == ffi.NULL:
        message = b''
    else:
        message = ffi.string(exc.reason)

    severity_name = ffi.string(ffi.cast("ExceptionType", exc.severity))
    # severity_name is an enum name and thus a string, not bytes
    message = message + b'   ' + severity_name.encode('ascii')

    if exc.severity < lib.ErrorException:
        # This is a warning, so do a warning
        cls = magick_exception_map.get(exc.severity, GenericMagickWarning)
        warnings.warn(cls(message))
    else:
        # ERROR ERROR
        cls = magick_exception_map.get(exc.severity, GenericMagickError)
        raise cls(message)


# ------------------------------------------------------------------------------
# Rest of the module is just specific error classes

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




magick_exception_map = {
    lib.OptionWarning: OptionWarning
}
