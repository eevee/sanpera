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
    print ('WARNING: pkg-config not found; '
           'you will need to set CFLAGS and/or LDFLAGS')
    extension_kwargs = {}
else:
    compile_args, err = proc.communicate()
    proc = subprocess.Popen(['pkg-config', 'ImageMagick', '--libs'],
            stdout=subprocess.PIPE)
    link_args, err = proc.communicate()
    extension_kwargs = dict(
        extra_compile_args=shlex.split(compile_args),
        extra_link_args=shlex.split(link_args),
    )

def ext_module(module):
    return Extension(
        "sanpera.%s" % (module,),
        ["sanpera/%s.pyx" % (module,)],
        **extension_kwargs)

setup(
    name='sanpera',
    cmdclass={'build_ext': build_ext},
    ext_modules=[
        ext_module('core'),
        ext_module('exception'),
        ext_module('image'),
        ext_module('format'),
    ],
)
