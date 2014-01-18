import os
import sys

from setuptools import setup
from setuptools.dist import Distribution


# Do this first, so setuptools installs cffi immediately before trying to do
# the below import
Distribution(dict(setup_requires='cffi'))

# Set this so the imagemagick flags will get sniffed out.
os.environ['SANPERA_BUILD'] = 'yes'

from sanpera._api import ffi

# Depend on backported libraries only if they don't already exist in the stdlib
BACKPORTS = []
if sys.version_info < (3, 4):
    BACKPORTS.append('enum34')

setup(
    name='sanpera',
    version='0.2.dev1',
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
        'sanpera': ['_api.c', '_api.h'],
    },
    install_requires=BACKPORTS + [
        'cffi',
    ],

    ext_modules=[ffi.verifier.get_extension()],
    ext_package='sanpera',
)
