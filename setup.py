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
    version='0.1.0',
    description='Image manipulation library, powered by ImageMagick',
    author='Eevee',
    author_email='eevee.sanpera@veekun.com',
    url='http://eevee.github.com/sanpera/',
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: ISC License (ISCL)',
        'Programming Language :: Cython',
        'Programming Language :: Python',
        'Topic :: Multimedia :: Graphics',
        'Topic :: Multimedia :: Graphics :: Graphics Conversion',
        'Topic :: Software Development :: Libraries',
    ],

    packages=['sanpera'],
    cmdclass={'build_ext': build_ext},
    ext_modules=[
        ext_module('color'),
        ext_module('core'),
        ext_module('exception'),
        ext_module('format'),
        ext_module('geometry'),
        ext_module('image'),
    ],
)
