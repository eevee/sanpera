from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

setup(
    cmdclass={'build_ext': build_ext},
    ext_modules=[
        # XXX this takes a lot of external effort to work.  how to fix durr ??
        Extension('graphick.demo_program', ['graphick/demo_program.pyx'],
            libraries=['GraphicsMagick'])
    ],
)
