"""Deal with ImageMagick errors."""

from sanpera._magick_api cimport _exception

class SanperaError(Exception):
    message = None

    def __init__(self):
        if self.message:
            super(SanperaError, self).__init__(self.message)

class GenericMagickError(SanperaError): pass

class MissingFormatError(SanperaError):
    message = "Refusing to guess image format; please provide one explicitly"

class EmptyImageError(SanperaError):
    message = "Can't write an image that has zero frames"

cdef class ExceptionCatcher:
    """Context-manager object.  Create it and feed its `exception` attribute to
    a C API call that wants an `ExceptionInfo` object.  If there seems to be an
    exception set at the end of the `with` block, it will be translated into a
    Python exception.
    """

    # Defined in exception.pxd
    #cdef _exception.ExceptionInfo* exception

    def __cinit__(self):
        self.exception = _exception.AcquireExceptionInfo()

    def __dealloc__(self):
        _exception.DestroyExceptionInfo(self.exception)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        if self.exception.severity == _exception.UndefinedException:
            # Nothing happened.  Tell the context manager we didn't do anything
            return False

        # Uhoh.  Convert an exception.
        convert_magick_exception(self.exception)


cdef convert_magick_exception(_exception.ExceptionInfo* exc):
    if exc == NULL or exc.severity == _exception.UndefinedException:
        return

    # TODO have more exception classes

    # An exception's description tends to be blank; the actual message
    # is in `reason`
    cdef bytes message
    if exc.reason == NULL:
        message = b''
    else:
        message = exc.reason

    raise GenericMagickError(message)
