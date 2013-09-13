from distutils.core import setup

from sanpera._api import ffi

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
    requires=[
        'cffi',
    ],

    ext_modules=[ffi.verifier.get_extension()],
)
