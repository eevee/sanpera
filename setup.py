import sys
import subprocess
import shlex

from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

try:
    proc = subprocess.Popen(['pkg-config', 'ImageMagick', '--cflags'],
            stdout=subprocess.PIPE)
except OSError:
    print 'WARNING: pkg-config not found; you may need to edit setup.py'
    extension_kwargs = dict(
        # Uncomment the following lines and put in your paths:
        #include_dirs=['/usr/include'],
        #library_dirs=['/usr/lib'],
        libraries=['ImageMagick'],
    )
else:
    compile_args, err = proc.communicate()
    proc = subprocess.Popen(['pkg-config', 'ImageMagick', '--libs'],
            stdout=subprocess.PIPE)
    link_args, err = proc.communicate()
    extension_kwargs = dict(
        extra_compile_args=shlex.split(compile_args),
        extra_link_args=shlex.split(link_args),
    )

setup(
    name='sanpera',
    cmdclass={'build_ext': build_ext},
    ext_modules=[
        Extension('sanpera.core', ['sanpera/core.pyx'],
            **extension_kwargs),
    ],
)
