from sanpera._magick_api cimport _common, _exception
from sanpera._magick_api._colorspace cimport ColorspaceType
from sanpera._magick_api._common cimport MagickBooleanType
from sanpera._magick_api._exception cimport ExceptionInfo
from sanpera._magick_api._image cimport ChannelType, Image, Quantum
from sanpera._magick_api._pixel cimport MagickPixelPacket, PixelPacket

cdef extern from "magick/paint.h":
    Image* OilPaintImage(Image*, double, ExceptionInfo*)

    #MagickBooleanType FloodfillPaintImage(Image*, ChannelType, DrawInfo*, MagickPixelPacket*, ssize_t, ssize_t, MagickBooleanType)
    MagickBooleanType GradientImage(Image*, GradientType, SpreadMethod, PixelPacket*, PixelPacket*)
    MagickBooleanType OpaquePaintImage(Image*, MagickPixelPacket*, MagickPixelPacket*, MagickBooleanType)
    MagickBooleanType OpaquePaintImageChannel(Image*, ChannelType, MagickPixelPacket*, MagickPixelPacket*, MagickBooleanType)
    MagickBooleanType TransparentPaintImage(Image*, MagickPixelPacket*, Quantum, MagickBooleanType)
    MagickBooleanType TransparentPaintImageChroma(Image*, MagickPixelPacket*, MagickPixelPacket*, Quantum, MagickBooleanType)
