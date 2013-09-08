"""ImageMagick API bindings, for cffi."""

import shlex
import subprocess
from subprocess import CalledProcessError

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
    # Easy way: pkg-config, part of freedesktop
    # Note that ImageMagick ships with its own similar program `Magick-config`,
    # but it's just a tiny wrapper around `pkg-config`, so why it even exists
    # is a bit of a mystery.
    try:
        compile_args = check_output(['pkg-config', 'ImageMagick', '--cflags'])
        link_args = check_output(['pkg-config', 'ImageMagick', '--libs'])
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

# XXX the constants below only work if pkg-config worked
ffi.cdef("""
    const int MAGICKCORE_QUANTUM_DEPTH;
    //const int MAGICKCORE_HDRI_SUPPORT;

    const char *GetMagickCopyright(void);
""")


extension_kwargs = find_imagemagick_configuration()
lib = ffi.verify("""
    #include <magick/MagickCore.h>
""", **extension_kwargs)


# ------------------------------------------------------------------------------
# Actual API


# XXX actually i'm testing it lol
print ffi.string(lib.GetMagickCopyright())
print lib.MAGICKCORE_QUANTUM_DEPTH
