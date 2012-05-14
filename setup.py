import os.path
import shlex
import subprocess
import sys

from distutils.core import setup
from distutils.extension import Extension

# Find out where ImageMagick is and how it was built
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

# Add Cythonizing support for devs
cmdclass = {}
try:
    from Cython.Distutils import build_ext
except ImportError:
    pass
else:
    class build_cython(build_ext):
        def initialize_options(self):
            # Always build in-place, since this is dev-only anyway
            build_ext.initialize_options(self)
            self.inplace = True

        def build_extensions(self):
            # Rewrite .c back to .pyx
            for ext in self.extensions:
                for i, filename in enumerate(ext.sources):
                    base, extension = os.path.splitext(filename)
                    if extension == '.c':
                        ext.sources[i] = base + '.pyx'

            # Cythonize as normal
            return build_ext.build_extensions(self)

    cmdclass['build_cython'] = build_cython


def ext_module(module):
    return Extension(
        "sanpera.%s" % (module,),
        ["sanpera/%s.c" % (module,)],
        **extension_kwargs)

setup(
    name='sanpera',
    version='0.1.1',
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
    cmdclass=cmdclass,
    ext_modules=[
        ext_module('color'),
        ext_module('core'),
        ext_module('exception'),
        ext_module('format'),
        ext_module('geometry'),
        ext_module('image'),
    ],
)
