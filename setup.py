import io
import json
import os
import shlex
import subprocess
from subprocess import CalledProcessError
import sys

from setuptools import setup
from setuptools.dist import Distribution

# Do this first, so setuptools installs cffi immediately before trying to do
# the below import
Distribution(dict(setup_requires='cffi'))


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
            extra_compile_args=env_cflags or '',
            extra_link_args=env_ldflags or '',
        )

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


config = find_imagemagick_configuration()
with open('sanpera/_apiconfig.json', 'w') as f_config:
    json.dump(config, f_config)


from sanpera._api import ffi

# Depend on backported libraries only if they don't already exist in the stdlib
BACKPORTS = []
if sys.version_info < (3, 4):
    BACKPORTS.append('enum34')

setup(
    name='sanpera',
    version='0.2pre',
    description='Image manipulation library, powered by ImageMagick',
    author='Eevee',
    author_email='eevee.sanpera@veekun.com',
    url='http://eevee.github.com/sanpera/',
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: ISC License (ISCL)',
        'Programming Language :: Python',
        'Topic :: Multimedia :: Graphics',
        'Topic :: Multimedia :: Graphics :: Graphics Conversion',
        'Topic :: Software Development :: Libraries',
    ],

    packages=['sanpera'],
    package_data={
        'sanpera': ['_api.c', '_api.h', '_apiconfig.json'],
    },
    install_requires=BACKPORTS + [
        'cffi',
    ],

    ext_modules=[ffi.verifier.get_extension()],
    ext_package='sanpera',
)
