from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from sanpera._api import ffi, lib
from sanpera.exception import magick_try


class ImageFormat(object):
    def __init__(self, can_read, can_write, supports_frames, name,
            description):

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


def _get_formats():
    formats = dict()

    num_formats = ffi.new("size_t *")

    # Snag the list of known supported image formats
    with magick_try() as exc:
        magick_infos = ffi.gc(
            lib.GetMagickInfoList("*", num_formats, exc.ptr),
            lib.RelinquishMagickMemory)

    for i in range(num_formats[0]):
        name = ffi.string(magick_infos[i].name).decode('ascii')
        formats[name] = ImageFormat(
            name=name,
            description=ffi.string(magick_infos[i].description).decode('ascii'),
            can_read=magick_infos[i].decoder != ffi.NULL,
            can_write=magick_infos[i].encoder != ffi.NULL,
            supports_frames=magick_infos[i].adjoin != 0,
        )


    return formats


# TODO should the keys here be case-insensitive as in imagemagick, or can users
# suck it?
image_formats = _get_formats()
