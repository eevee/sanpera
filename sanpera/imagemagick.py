# encoding: utf8
"""Various information about the underlying ImageMagick library and the
features it supports.

Deliberately not named ``features`` to emphasize that everything herein is
highly specific to ImageMagick and completely out of the library's hands.
"""
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from collections import namedtuple

from sanpera._api import ffi, lib
from sanpera.exception import magick_try

FEATURES = frozenset(ffi.string(lib.GetMagickFeatures()).decode('ascii').split(' '))
HAS_OPENMP = 'OpenMP' in FEATURES
HAS_OPENCL = 'OpenCL' in FEATURES
HAS_HDRI = 'HDRI' in FEATURES


ImageFormat = namedtuple(
    'ImageFormat',
    ['name', 'description', 'can_read', 'can_write', 'supports_frames'])

def _get_formats():
    formats = dict()

    num_formats = ffi.new("size_t *")

    # Snag the list of known supported image formats
    with magick_try() as exc:
        magick_infos = ffi.gc(
            lib.GetMagickInfoList(b"*", num_formats, exc.ptr),
            lib.RelinquishMagickMemory)

    for i in range(num_formats[0]):
        name = ffi.string(magick_infos[i].name).decode('ascii')
        formats[name.lower()] = ImageFormat(
            name=name,
            description=ffi.string(magick_infos[i].description).decode('ascii'),
            can_read=magick_infos[i].decoder != ffi.NULL,
            can_write=magick_infos[i].encoder != ffi.NULL,
            supports_frames=magick_infos[i].adjoin != 0,
        )

    return formats

IMAGE_FORMATS = _get_formats()
