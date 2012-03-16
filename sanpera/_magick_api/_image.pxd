from sanpera._magick_api cimport _common, _exception
from sanpera._magick_api._colorspace cimport ColorspaceType
from sanpera._magick_api._common cimport MagickBooleanType, MagickPassFail
from sanpera._magick_api._exception cimport ExceptionInfo, ExceptionType
from sanpera._magick_api._pixel cimport MagickPixelPacket
from sanpera._magick_api._timer cimport TimerInfo

# XXX may need: forward, colorspace, error, timer

cdef extern from "magick/image.h":
    # TODO a bunch of #defines at the top, dealing with bit depth and
    # whatever

    ctypedef unsigned int Quantum
    int QuantumDepth

    ### Enums.  Lots...  of...  enums.
    ctypedef enum AlphaType:
        UnspecifiedAlpha
        AssociatedAlpha
        UnassociatedAlpha

    ctypedef enum ChannelType:
        # Note that this isn't the same order as the header file

        # RGB
        RedChannel
        GreenChannel
        BlueChannel

        # CMYK
        CyanChannel
        MagentaChannel
        YellowChannel
        BlackChannel

        OpacityChannel
        GrayChannel
        UndefinedChannel
        AllChannels

    ctypedef enum ClassType:
        # XXX what the hell is this
        UndefinedClass
        DirectClass
        PseudoClass

    ctypedef enum CompositeOperator:
        UndefinedCompositeOp
        OverCompositeOp
        InCompositeOp
        OutCompositeOp
        AtopCompositeOp
        XorCompositeOp
        PlusCompositeOp
        MinusCompositeOp
        AddCompositeOp
        SubtractCompositeOp
        DifferenceCompositeOp
        MultiplyCompositeOp
        BumpmapCompositeOp
        CopyCompositeOp
        CopyRedCompositeOp
        CopyGreenCompositeOp
        CopyBlueCompositeOp
        CopyOpacityCompositeOp
        ClearCompositeOp
        DissolveCompositeOp
        DisplaceCompositeOp
        ModulateCompositeOp
        ThresholdCompositeOp
        NoCompositeOp
        DarkenCompositeOp
        LightenCompositeOp
        HueCompositeOp
        SaturateCompositeOp
        ColorizeCompositeOp
        LuminizeCompositeOp
        #ScreenCompositeOp  # not yet implemented
        #OverlayCompositeOp  # not yet implemented
        CopyCyanCompositeOp
        CopyMagentaCompositeOp
        CopyYellowCompositeOp
        CopyBlackCompositeOp
        DivideCompositeOp

    ctypedef enum CompressionType:
        UndefinedCompression
        NoCompression
        BZipCompression
        FaxCompression
        Group4Compression
        JPEGCompression
        LosslessJPEGCompression
        LZWCompression
        RLECompression
        ZipCompression

    ctypedef enum DisposeType:
        UndefinedDispose
        NoneDispose
        BackgroundDispose
        PreviousDispose

    ctypedef enum EndianType:
        UndefinedEndian
        LSBEndian       # little endian
        MSBEndian       # big endian
        NativeEndian

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

    ctypedef enum GeometryFlags:
        NoValue
        XValue
        YValue
        WidthValue
        HeightValue
        AllValues
        XNegative
        YNegative
        PercentValue  # %
        AspectValue   # !
        LessValue     # <
        GreaterValue  # >
        AreaValue     # @
        MinimumValue  # ^

    ctypedef enum GravityType:
        ForgetGravity
        NorthWestGravity
        NorthGravity
        NorthEastGravity
        WestGravity
        CenterGravity
        EastGravity
        SouthWestGravity
        SouthGravity
        SouthEastGravity
        StaticGravity

    ctypedef enum ImageType:
        UndefinedType
        BilevelType
        GrayscaleType
        GrayscaleMatteType
        PaletteType
        PaletteMatteType
        TrueColorType
        TrueColorMatteType
        ColorSeparationType
        ColorSeparationMatteType
        OptimizeType

    ctypedef enum InterlaceType:
        UndefinedInterlace
        NoInterlace
        LineInterlace
        PlaneInterlace
        PartitionInterlace

    ctypedef enum MontageMode:
        UndefinedMode
        FrameMode
        UnframeMode
        ConcatenateMode

    ctypedef enum NoiseType:
        UniformNoise
        GaussianNoise
        MultiplicativeGaussianNoise
        ImpulseNoise
        LaplacianNoise
        PoissonNoise

    ctypedef enum OrientationType:
        # TIFF orientation
        UndefinedOrientation
        TopLeftOrientation
        TopRightOrientation
        BottomRightOrientation
        BottomLeftOrientation
        LeftTopOrientation
        RightTopOrientation
        RightBottomOrientation
        LeftBottomOrientation

    ctypedef enum PreviewType:
        UndefinedPreview
        RotatePreview
        ShearPreview
        RollPreview
        HuePreview
        SaturationPreview
        BrightnessPreview
        GammaPreview
        SpiffPreview
        DullPreview
        GrayscalePreview
        QuantizePreview
        DespecklePreview
        ReduceNoisePreview
        AddNoisePreview
        SharpenPreview
        BlurPreview
        ThresholdPreview
        EdgeDetectPreview
        SpreadPreview
        SolarizePreview
        ShadePreview
        RaisePreview
        SegmentPreview
        SwirlPreview
        ImplodePreview
        WavePreview
        OilPaintPreview
        CharcoalDrawingPreview
        JPEGPreview

    ctypedef enum RenderingIntent:
        UndefinedIntent
        SaturationIntent
        PerceptualIntent
        AbsoluteIntent
        RelativeIntent

    ctypedef enum ResolutionType:
        UndefinedResolution
        PixelsPerInchResolution
        PixelsPerCentimeterResolution

    ### Structs
    ctypedef struct AffineMatrix:
        double sx
        double rx
        double ry
        double sy
        double tx
        double ty

    ctypedef struct PrimaryInfo:
        double x
        double y
        double z

    ctypedef struct ChromaticityInfo:
        PrimaryInfo red_primary
        PrimaryInfo green_primary
        PrimaryInfo blue_primary
        PrimaryInfo white_point

    # XXX there are PixelPacket macros here, ifdef MAGICK_IMPLEMENTATION.  needed?

    ctypedef struct PixelPacket:
        Quantum red
        Quantum green
        Quantum blue
        Quantum opacity

    ctypedef struct DoublePixelPacket:
        double red
        double green
        double blue
        double opacity

    ctypedef struct ErrorInfo:
        # Statistical error.  Nothing to do with exceptions.
        double mean_error_per_pixel
        double normalized_mean_error
        double normalized_maximum_error

    ctypedef struct FrameInfo:
        unsigned long width
        unsigned long height
        long x
        long y
        long inner_bevel
        long outer_bevel

    ctypedef Quantum IndexPacket

    ctypedef struct LongPixelPacket:
        unsigned long red
        unsigned long green
        unsigned long blue
        unsigned long opacity

    ctypedef struct MontageInfo:
        char* geometry
        char* tile
        char* title
        char* frame
        char* texture
        char* font
        double pointsize
        unsigned long border_width
        unsigned int shadow
        PixelPacket fill
        PixelPacket stroke
        PixelPacket background_color
        PixelPacket border_color
        PixelPacket matte_color
        GravityType gravity
        char* filename  # XXX this is actually an array of [MaxTextExtent] -- this will be a problem in general i suspect

    ctypedef struct ProfileInfo:
        size_t length
        char* name
        unsigned char* info

    ctypedef struct RectangleInfo:
        unsigned long width
        unsigned long height
        long x
        long y

    ctypedef struct SegmentInfo:
        double x1
        double y1
        double x2
        double y2

    # XXX sorry for the interruption but: hey, look up how cython deals with (a) overflow and (b) string buffers with a max size

    ### The good part
    ctypedef struct Image:
        ClassType storage_class
        ColorspaceType colorspace
        CompressionType compression
        MagickBooleanType dither
        MagickBooleanType matte  # true iff image has an alpha channel
        unsigned long columns
        unsigned long rows
        unsigned int colors  # only matters for PseudoClass
        unsigned int depth
        PixelPacket* colormap
        PixelPacket background_color
        PixelPacket border_color
        PixelPacket matte_color
        double gamma
        ChromaticityInfo chromaticity
        OrientationType orientation
        RenderingIntent rendering_intent
        ResolutionType units
        # montage stuff
        char* montage
        char* directory
        # composite/crop stuff
        char* geometry

        long offset
        double x_resolution
        double y_resolution
        RectangleInfo page
        RectangleInfo tile_info
        double blur
        double fuzz
        FilterTypes filter
        InterlaceType interlace
        EndianType endian
        GravityType gravity
        CompositeOperator compose
        DisposeType dospose
        unsigned long scene
        unsigned long delay
        unsigned long iterations
        unsigned long total_colors
        long start_loop
        ErrorInfo error
        TimerInfo timer
        void* client_data  # XXX useful?

        # XXX these are arrays
        char* filename
        char* magick_filename  # original filename
        char* magick

        unsigned long magick_columns
        unsigned long magick_rows
        ExceptionInfo exception
        Image* previous
        Image* next

        # plus a lot of private stuff

    ctypedef struct FILE  # XXX need to do something about this

    ctypedef struct ImageInfo:
        CompressionType compression
        MagickBooleanType temporary
        MagickBooleanType adjoin
        MagickBooleanType antialias
        unsigned long subimage
        unsigned long subrange
        unsigned long depth
        char* size
        char* tile
        char* page
        InterlaceType interlace
        EndianType endian
        ResolutionType units
        unsigned long quality
        char* sampling_factor
        char* server_name  # used for X11
        char* font
        char* texture
        char* density
        double pointsize
        double fuzz
        PixelPacket pen
        PixelPacket background_color
        PixelPacket border_color
        PixelPacket matte_color
        MagickBooleanType dither
        MagickBooleanType monochrome
        MagickBooleanType progress
        ColorspaceType colorspace
        ImageType type
        long group  # used for X11
        unsigned int verbose
        char* view
        char* authenticate
        void* client_data
        FILE* file  # file pointer to read image from
        char *magick  # XXX ARRAY
        char *filename  # XXX ARRAY

        # plus a lot of private stuff

    ### Functions
    ImageInfo *CloneImageInfo(ImageInfo *)
    void DestroyImage(Image *)
    void DestroyImageInfo(ImageInfo *)

    ExceptionType CatchImageException(Image*)

    Image* AcquireImage(ImageInfo*)
    Image* AppendImages(Image*, unsigned int, ExceptionInfo*)
    Image* CloneImage(Image*, unsigned long, unsigned long, unsigned int, ExceptionInfo*)
    Image* GetImageClipMask(Image*, ExceptionInfo*)
    Image* NewMagickImage(ImageInfo*, size_t, size_t, MagickPixelPacket*)

    Image* ReferenceImage(Image*)

    ImageInfo* CloneImageInfo(ImageInfo*)

    char* AccessDefinition(ImageInfo* image_info, char* magick, char* key)

    int GetImageGeometry(Image*, char*, unsigned int, RectangleInfo*)

    MagickBooleanType ClipImage(Image*)
    MagickBooleanType ClipImagePath(Image*, char*, MagickBooleanType)
    MagickBooleanType GetImageAlphaChannel(Image*)
    MagickBooleanType IsTaintImage(Image*)
    MagickBooleanType IsMagickConflict(char*)
    MagickBooleanType IsHighDynamicRangeImage(Image*, ExceptionInfo*)
    MagickBooleanType IsImageObject(Image*)
    MagickBooleanType ListMagickInfo(FILE*, ExceptionInfo*)
    MagickBooleanType ModifyImage(Image**, ExceptionInfo*)
    MagickBooleanType ResetImagePage(Image*, char*)
    MagickBooleanType SeparateImageChannel(Image*, ChannelType)
    MagickBooleanType SetImageAlphaChannel(Image*, AlphaChannelType)
    MagickBooleanType SetImageBackgroundColor(Image*)
    MagickBooleanType SetImageClipMask(Image*, Image*)
    MagickBooleanType SetImageColor(Image*, MagickPixelPacket*)
    MagickBooleanType SetImageExtent(Image*, size_t, size_t)
    MagickBooleanType SetImageInfo(ImageInfo*, unsigned int, ExceptionInfo*)
    MagickBooleanType SetImageMask(Image*, Image*)
    MagickBooleanType SetImageOpacity(Image*, Quantum)
    MagickBooleanType SetImageChannels(Image*, size_t)
    MagickBooleanType SetImageStorageClass(Image*, ClassType)
    MagickBooleanType SetImageType(Image*, ImageType)
    MagickBooleanType StripImage(Image*)
    MagickBooleanType SyncImage(Image*)
    MagickBooleanType SyncImageSettings(ImageInfo*, Image*)
    MagickBooleanType SyncImagesSettings(ImageInfo*, Image*)

    void AllocateNextImage(ImageInfo*, Image*)
    void DestroyImage(Image*)
    void DestroyImageInfo(ImageInfo*)
    void GetImageException(Image*, ExceptionInfo*)
    void GetImageInfo(ImageInfo*)
