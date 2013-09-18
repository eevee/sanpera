"""ImageMagick API bindings, for cffi."""

import atexit
import json
import os.path
import sys

import cffi


################################################################################
# FFI setup

ffi = cffi.FFI()

here = os.path.dirname(__file__)

# For the sake of sanity and syntax highlighting, the C-ish parts are in
# separate files with appropriate extensions.
with open(os.path.join(here, '_api.h')) as f_headers:
    ffi.cdef(f_headers.read())
with open(os.path.join(here, '_apiconfig.json')) as f_config:

    config = json.load(f_config)

if sys.version_info > (3,):
    extension_kwargs = config
else:
    extension_kwargs = {}
    for key, value in config.iteritems():
        extension_kwargs[key.encode()] = [v.encode() for v in value]

with open(os.path.join(here, '_api.c')) as f_stub:
    lib = ffi.verify(
        f_stub.read(),
        ext_package='sanpera',
        **extension_kwargs)

# ImageMagick initialization
lib.MagickCoreGenesis(sys.argv[0].encode('ascii'), lib.MagickFalse)

# Teardown
atexit.register(lib.MagickCoreTerminus)

# Disable the default warning/error behavior, which is to spew garbage to
# stderr (how considerate)
lib.SetWarningHandler(ffi.NULL)
lib.SetErrorHandler(ffi.NULL)
lib.SetFatalErrorHandler(ffi.NULL)
