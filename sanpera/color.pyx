"""Colors."""

from sanpera._magick_api cimport _color, _common, _pixel

from sanpera.exception cimport MagickException


# XXX: how does this interact with CMYK?  when does CMYK even exist?
cdef class Color:
    """Represents a color as RGBA."""

    # Declared in pxd
    #cdef _pixel.MagickPixelPacket c_struct

    def __init__(self):
        pass


    ### Constructors

    @classmethod
    def parse(type cls not None, bytes name not None):
        """Parse a color specification.

        Supports a whole buncha formats.
        """

        cdef Color self = cls()
        cdef MagickException exc = MagickException()
        cdef _common.MagickStatusType success

        success = _color.QueryMagickColor(name, &self.c_struct, exc.ptr)
        exc.check()
        if not success:
            raise ValueError("Can't find a color named {0!r}".format(name))

        return self

    @classmethod
    def coerce(type cls not None, value not None):
        if isinstance(value, cls):
            # Already an object; do nothing
            return value

        # Probably a name; parse it
        return cls.parse(value)
