from sanpera._magick_api cimport _common, _exception, _image, _pixel

cdef extern from "magick/color.h":
    ctypedef enum ComplianceType:
        UndefinedCompliance
        NoCompliance
        SVGCompliance
        X11Compliance
        XPMCompliance
        AllCompliance

    _common.MagickBooleanType QueryMagickColor(char*, _pixel.MagickPixelPacket*, _exception.ExceptionInfo*)
