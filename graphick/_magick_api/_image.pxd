from graphick._magick_api cimport _common, _error

cdef extern from "magick/image.h":
    ctypedef struct Image:
        # TODO fill these all in
        char* filename
        pass
    ctypedef struct ImageInfo:
        # TODO fill these all in
        char* filename
        char* magick
        pass

    ctypedef enum FilterTypes:
        UndefinedFilter
        PointFilter
        BoxFilter
        TriangleFilter
        HermiteFilter
        HanningFilter
        HammingFilter
        BlackmanFilter
        GaussianFilter
        QuadraticFilter
        CubicFilter
        CatromFilter
        MitchellFilter
        LanczosFilter
        BesselFilter
        SincFilter


    ImageInfo *CloneImageInfo(ImageInfo *)
    void DestroyImage(Image *)
    void DestroyImageInfo(ImageInfo *)

    # XXX this is wrong and also internal
    void SetImageInfo(ImageInfo* image_info, unsigned int flags, _error.ExceptionInfo* exception)
