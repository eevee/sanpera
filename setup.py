import os
import sys

from setuptools import setup
from setuptools.dist import Distribution


# Depend on backported libraries only if they don't already exist in the stdlib
BACKPORTS = []
if sys.version_info < (3, 4):
    BACKPORTS.append('enum34')

setup(
    name='sanpera',
    version='0.2rc0',
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
    install_requires=BACKPORTS + [
        'cffi>=1.0.0',
    ],

    setup_requires=['cffi>=1.0.0'],
    cffi_modules=['sanpera/_api_build.py:ffi'],
)
