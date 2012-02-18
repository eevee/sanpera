"""Deal with ImageMagick errors."""

from sanpera._magick_api cimport _exception

class GenericMagickException(Exception): pass

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
        # TODO have more exception classes

        # An exception's description tends to be blank; the actual message
        # is in `reason`
        cdef bytes message
        if self.exception.reason == NULL:
            message = b''
        else:
            message = self.exception.reason

        raise GenericMagickException(message)
