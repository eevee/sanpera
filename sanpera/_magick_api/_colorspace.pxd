cdef extern from "magick/colorspace.h":
    ctypedef enum ColorspaceType:
        UndefinedColorspace
        RGBColorspace
        GRAYColorspace
        TransparentColorspace
        OHTAColorspace
        XYZColorspace
        YCCColorspace
        YIQColorspace
        YPbPrColorspace
        YUVColorspace
        CMYKColorspace
        sRGBColorspace
        HSLColorspace
        HWBColorspace
        LABColorspace
        CineonLogRGBColorspace
        Rec601LumaColorspace
        Rec601YCbCrColorspace
        Rec709LumaColorspace
        Rec709YCbCrColorspace
