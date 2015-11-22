import atexit
import sys

from ._api import lib, ffi

# ImageMagick initialization
lib.MagickCoreGenesis(sys.argv[0].encode('ascii'), lib.MagickFalse)

# Teardown
atexit.register(lib.MagickCoreTerminus)

# Disable the default warning/error behavior, which is to spew garbage to
# stderr (how considerate)
lib.SetWarningHandler(ffi.NULL)
lib.SetErrorHandler(ffi.NULL)
lib.SetFatalErrorHandler(ffi.NULL)
