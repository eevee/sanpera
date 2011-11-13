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
    #cdef _exception.ExceptionInfo exception

    def __cinit__(self):
        _exception.GetExceptionInfo(&self.exception)

    def __dealloc__(self):
        _exception.DestroyExceptionInfo(&self.exception)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        # TODO have more exceptions
        if self.exception.severity != _exception.UndefinedException:
            raise GenericMagickException(<bytes>self.exception.reason + <bytes>self.exception.description)

        return False
