"""ImageMagick API bindings, for cffi."""

import atexit
import os.path
import shlex
import subprocess
from subprocess import CalledProcessError
import sys

import cffi


def check_output(*args, **kwargs):
    """Rough implementation of `subprocess.check_output`, which doesn't exist
    until 2.7.
    """
    proc = subprocess.Popen(stdout=subprocess.PIPE, *args, **kwargs)
    out, _err = proc.communicate()
    retcode = proc.poll()
    if retcode != 0:
        cmd = args[0]
        raise CalledProcessError(retcode, cmd)
    return out


def find_imagemagick_configuration():
    """Find out where ImageMagick is and how it was built.  Return a dict of
    distutils extension-building arguments.
    """

    # Easiest way: the user is telling us what to use.
    env_cflags = os.environ.get('SANPERA_IMAGEMAGICK_CFLAGS')
    env_ldflags = os.environ.get('SANPERA_IMAGEMAGICK_LDFLAGS')
    if env_cflags is not None or env_ldflags is not None:
        return dict(
            extra_compile_args=shlex.split(env_cflags or ''),
            extra_link_args=shlex.split(env_ldflags or ''),
        )

    # Easy way: pkg-config, part of freedesktop
    # Note that ImageMagick ships with its own similar program `Magick-config`,
    # but it's just a tiny wrapper around `pkg-config`, so why it even exists
    # is a bit of a mystery.
    try:
        compile_args = check_output(['pkg-config', 'ImageMagick', '--cflags']).decode('utf-8')
        link_args = check_output(['pkg-config', 'ImageMagick', '--libs']).decode('utf-8')
    except OSError:
        pass
    except CalledProcessError:
        # This means that pkg-config exists, but ImageMagick isn't registered
        # with it.  Odd, but not worth giving up yet.
        pass
    else:
        return dict(
            extra_compile_args=shlex.split(compile_args),
            extra_link_args=shlex.split(link_args),
        )

    # TODO this could use more fallback, but IM builds itself with different
    # names (as of some recent version, anyway) depending on quantum depth et
    # al.  the `wand` project just brute-force searches for the one it wants.
    # perhaps we could do something similar.  also, we only need the header
    # files for the build, so it would be nice to get away with only hunting
    # down the library for normal use.

    raise RuntimeError(
        "Can't find ImageMagick installation!\n"
        "If you're pretty sure you have it installed, please either install\n"
        "pkg-config or tell me how to find libraries on your platform."
    )


################################################################################
# FFI setup

ffi = cffi.FFI()

here = os.path.dirname(__file__)

# For the sake of sanity and syntax highlighting, the C-ish parts are in
# separate files with appropriate extensions.
with open(os.path.join(here, '_api.h')) as f_headers:
    ffi.cdef(f_headers.read())


extension_kwargs = {}
if os.environ.get('SANPERA_BUILD'):
    extension_kwargs = find_imagemagick_configuration()


with open(os.path.join(here, '_api.c')) as f_stub:
    lib = ffi.verify(
        f_stub.read(),
        ext_package='sanpera',
        modulename='_api_bridge',
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
