from cpython cimport bool

from sanpera cimport c_api
import sanpera.core
from sanpera.exception cimport MagickException

class ImageFormat:

    def __init__(self, bool can_read not None, bool can_write not None, bool supports_frames not None,
        str name not None, str description not None):

        self.can_read = can_read
        self.can_write = can_write
        self.supports_frames = supports_frames
        self.name = name
        self.description = description
        # TODO: indicate blob support?  how does that matter to consumer?

    def __repr__(self):
        return "<{cls} {name}>".format(
            cls=type(self).__name__,
            name=self.name)


cdef _get_formats():
    cdef dict formats = dict()

    cdef c_api.MagickInfo** magick_infos
    cdef size_t num_formats
    cdef MagickException exc = MagickException()

    # Snag the list of known supported image formats
    # nb: the cast is just to drop the 'const' on the return value type
    magick_infos = <c_api.MagickInfo**> c_api.GetMagickInfoList(
        "*", &num_formats, exc.ptr)
    exc.check()

    cdef int i
    cdef str name
    try:
        for i in range(num_formats):
            name = magick_infos[i].name
            formats[name] = ImageFormat(
                name=name,
                description=magick_infos[i].description,
                can_read=magick_infos[i].decoder != NULL,
                can_write=magick_infos[i].encoder != NULL,
                supports_frames=magick_infos[i].adjoin != 0,
            )


        return formats

    finally:
        c_api.RelinquishMagickMemory(<void*> magick_infos)

# TODO should the keys here be case-insensitive as in imagemagick, or can users
# suck it?
image_formats = _get_formats()
