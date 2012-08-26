"""API bindings for ImageMagick.

These are an incomplete work in progress, based on ImageMagick 6.7.6.

Header files are defined in a roughly intuitive order, from low-level to high.
"""

### COMMON
# These files need to be loaded before anything else, or ImageMagick won't
# work!  This is gleaned from magick/api.h and battle scars.

# Note that he intended usage or ImageMgick seems to be to `#include
# "magick/api.h"` and just get everything.  That's not very Pythony, though,
# and even the documentation is split up by particular header file, so I've
# tried to preserve the header file arrangement in a less broken manner.

cdef extern from "magick/magick-config.h":
    pass

cdef extern from "magick/magick-type.h":
    int MAGICKCORE_QUANTUM_DEPTH
    float MagickEpsilon
    float MagickHuge
    unsigned long MaxColormapSize
    unsigned long MaxMap

    # NOTE: Quantum can actually be either a float or int, depending on how
    # ImageMagick was built.  C's weak typing to the rescue: we'll just always
    # assume it's a float.  Er, double.
    ctypedef double Quantum
    double QuantumRange

    # Same story here; may be a long double
    ctypedef double MagickRealType

    ctypedef long MagickOffsetType
    ctypedef unsigned long MagickSizeType

    ctypedef unsigned int MagickStatusType

cdef extern from "magick/MagickCore.h":
    ctypedef unsigned int MagickPassFail
    ctypedef enum MagickBooleanType:
        MagickFalse
        MagickTrue

    cdef unsigned int MaxTextExtent


### LOGGING

cdef extern from "magick/log.h":
    unsigned long SetLogEventMask(char*)


### TIMER

cdef extern from "magick/timer.h":
    ctypedef enum TimerState:
        UndefinedTimerState
        StoppedTimerState
        RunningTimerState

    ctypedef struct Timer:
        double start
        double stop
        double total

    ctypedef struct TimerInfo:
        Timer user
        Timer elapsed

        TimerState state

    double GetElapsedTime(TimerInfo*)
    double GetUserTime(TimerInfo*)
    double GetTimerResolution()

    unsigned int ContinueTimer(TimerInfo*)

    void GetTimerInfo(TimerInfo*)
    void ResetTimer(TimerInfo*)


### MEMORY

cdef extern from "magick/memory_.h":
    ctypedef void* (*AcquireMemoryHandler)(size_t)
    ctypedef void (*DestroyMemoryHandler)(void*)
    ctypedef void* (*ResizeMemoryHandler)(void*, size_t)

    void* AcquireAlignedMemory(size_t, size_t)
    void* AcquireMagickMemory(size_t)
    void* AcquireQuantumMemory(size_t, size_t)
    void* CopyMagickMemory(void*, void*, size_t)
    void DestroyMagickMemory()
    void GetMagickMemoryMethods(AcquireMemoryHandler*, ResizeMemoryHandler*, DestroyMemoryHandler*)
    void* RelinquishAlignedMemory(void*)
    void* RelinquishMagickMemory(void*)
    void* ResetMagickMemory(void*, int, size_t)
    void* ResizeMagickMemory(void*, size_t)
    void* ResizeQuantumMemory(void*, size_t, size_t)
    void SetMagickMemoryMethods(AcquireMemoryHandler,ResizeMemoryHandler, DestroyMemoryHandler)


### EXCEPTIONS

cdef extern from "magick/exception.h":
    # XXX this clobbers a couple python builtin names; doubt that matters though
    ctypedef enum ExceptionType:
        UndefinedException

        WarningException
        ResourceLimitWarning
        TypeWarning
        OptionWarning
        DelegateWarning
        MissingDelegateWarning
        CorruptImageWarning
        FileOpenWarning
        BlobWarning
        StreamWarning
        CacheWarning
        CoderWarning
        FilterWarning
        ModuleWarning
        DrawWarning
        ImageWarning
        WandWarning
        RandomWarning
        XServerWarning
        MonitorWarning
        RegistryWarning
        ConfigureWarning
        PolicyWarning

        ErrorException
        ResourceLimitError
        TypeError
        OptionError
        DelegateError
        MissingDelegateError
        CorruptImageError
        FileOpenError
        BlobError
        StreamError
        CacheError
        CoderError
        FilterError
        ModuleError
        DrawError
        ImageError
        WandError
        RandomError
        XServerError
        MonitorError
        RegistryError
        ConfigureError
        PolicyError

        FatalErrorException
        ResourceLimitFatalError
        TypeFatalError
        OptionFatalError
        DelegateFatalError
        MissingDelegateFatalError
        CorruptImageFatalError
        FileOpenFatalError
        BlobFatalError
        StreamFatalError
        CacheFatalError
        CoderFatalError
        FilterFatalError
        ModuleFatalError
        DrawFatalError
        ImageFatalError
        WandFatalError
        RandomFatalError
        XServerFatalError
        MonitorFatalError
        RegistryFatalError
        ConfigureFatalError
        PolicyFatalError


    # Main exception type
    ctypedef struct ExceptionInfo:
        # Description of the exception
        ExceptionType severity
        char* reason
        char* description

        # Value of errno when the exception was thrown
        int error_number


    # Exception handler function reference types
    ctypedef void (*ErrorHandler)(ExceptionType, char*, char*)
    ctypedef void (*FatalErrorHandler)(ExceptionType, char*, char*)
    ctypedef void (*WarningHandler)(ExceptionType, char*, char*)

    ErrorHandler SetErrorHandler(ErrorHandler)
    FatalErrorHandler SetFatalErrorHandler(FatalErrorHandler)
    WarningHandler SetWarningHandler(WarningHandler)


    ExceptionInfo* AcquireExceptionInfo()
    ExceptionInfo* DestroyExceptionInfo(ExceptionInfo*)

    char* GetExceptionMessage(int)
    char* GetLocaleExceptionMessage(ExceptionType, char*)

    void CatchException(ExceptionInfo*)
    void ClearMagickException(ExceptionInfo*)
    void GetExceptionInfo(ExceptionInfo*)
    void InheritException(ExceptionInfo*, ExceptionInfo*)
    void MagickError(ExceptionType, char*, char*)
    void MagickFatalError(ExceptionType, char*, char*)
    void MagickWarning(ExceptionType, char*, char*)


### COLORSPACE

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


### PIXEL

cdef extern from "magick/quantum.h":
    ctypedef enum EndianType:
        UndefinedEndian
        LSBEndian
        MSBEndian

    ctypedef enum QuantumAlphaType:
        UndefinedQuantumAlpha
        AssociatedQuantumAlpha
        DisassociatedQuantumAlpha

    ctypedef enum QuantumFormatType:
        UndefinedQuantumFormat
        FloatingPointQuantumFormat
        SignedQuantumFormat
        UnsignedQuantumFormat

    ctypedef enum QuantumType:
        UndefinedQuantum
        AlphaQuantum
        BlackQuantum
        BlueQuantum
        CMYKAQuantum
        CMYKQuantum
        CyanQuantum
        GrayAlphaQuantum
        GrayQuantum
        GreenQuantum
        IndexAlphaQuantum
        IndexQuantum
        MagentaQuantum
        OpacityQuantum
        RedQuantum
        RGBAQuantum
        BGRAQuantum
        RGBOQuantum
        RGBQuantum
        YellowQuantum
        RGBPadQuantum
        CbYCrYQuantum
        CbYCrQuantum
        CbYCrAQuantum
        CMYKOQuantum
        BGRQuantum
        BGROQuantum

    ctypedef struct QuantumInfo:
        pass

    Quantum ClampToQuantum(MagickRealType)
    unsigned char ScaleQuantumToChar(Quantum)

    # NOTE: there's more, but unclear if any is useful

cdef extern from "magick/pixel.h":
    ctypedef struct MagickPixelPacket:
        #ClassType storage_class

        #ColorspaceType colorspace

        MagickBooleanType matte

        double fuzz

        size_t depth

        MagickRealType red
        MagickRealType green
        MagickRealType blue
        MagickRealType opacity
        MagickRealType index

    ctypedef struct PixelPacket:
        Quantum red
        Quantum green
        Quantum blue
        Quantum opacity

    double GetPixelRed(PixelPacket*)
    double SetPixelRed(PixelPacket*, double)


### COLOR

cdef extern from "magick/color.h":
    ctypedef enum ComplianceType:
        UndefinedCompliance
        NoCompliance
        SVGCompliance
        X11Compliance
        XPMCompliance
        AllCompliance

    MagickBooleanType QueryColorDatabase(char*, PixelPacket*, ExceptionInfo*)
    MagickBooleanType QueryMagickColor(char*, MagickPixelPacket*, ExceptionInfo*)


### IMAGE

cdef extern from "magick/image.h":
    # TODO a bunch of #defines at the top, dealing with bit depth and
    # whatever
    # TODO this was originally created for graphicsmagick and doesn't quite
    # match imagemagick

    ctypedef unsigned int Quantum
    int QuantumDepth

    ### Enums.  Lots...  of...  enums.
    ctypedef enum AlphaChannelType:
        UndefinedAlphaChannel
        ActivateAlphaChannel
        BackgroundAlphaChannel
        CopyAlphaChannel
        DeactivateAlphaChannel
        ExtractAlphaChannel
        OpaqueAlphaChannel
        SetAlphaChannel
        ShapeAlphaChannel
        TransparentAlphaChannel

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
        UndefinedClass
        DirectClass  # i.e., full color
        PseudoClass  # i.e., indexed

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


### LIST

cdef extern from "magick/list.h":
    Image* CloneImageList(Image*, ExceptionInfo*)
    Image* GetFirstImageInList(Image*)
    Image* GetImageFromList(Image*, long)
    Image* GetLastImageInList(Image*)
    Image* GetNextImageInList(Image*)
    Image* GetPreviousImageInList(Image*)
    Image** ImageListToArray(Image*, ExceptionInfo*)
    Image* NewImageList()
    Image* RemoveLastImageFromList(Image**)
    Image* RemoveFirstImageFromList(Image**)
    Image* SplitImageList(Image*)
    Image* SyncNextImageInList(Image*)

    long GetImageIndexInList(Image*)

    unsigned long GetImageListLength(Image*)

    void AppendImageToList(Image**, Image*)
    void DeleteImageFromList(Image**)
    void DestroyImageList(Image*)
    void InsertImageInList(Image**, Image*)
    void PrependImageToList(Image**, Image*)
    void ReplaceImageInList(Image**, Image*)
    void ReverseImageList(Image**)
    void SpliceImageIntoList(Image**, unsigned long, Image*)


### MAGICK (filetypes)

cdef extern from "magick/magick.h":
    ctypedef enum MagickFormatType:
        UndefinedFormatType
        ImplicitFormatType
        ExplicitFormatType

    # nb: These are actually function pointers, but we only care whether
    # they're NULL or not (indicating read/write support), so the actual type
    # doesn't matter
    ctypedef struct DecodeImageHandler:
        pass
    ctypedef struct EncodeImageHandler:
        pass

    ctypedef struct MagickInfo:
        char* name
        char* description
        char* version
        char* note
        char* module
        ImageInfo* image_info
        DecodeImageHandler* decoder
        EncodeImageHandler* encoder
        #IsImageFormatHandler* magick
        void* client_data
        MagickBooleanType adjoin
        MagickBooleanType raw
        MagickBooleanType endian_support
        MagickBooleanType blob_support
        MagickBooleanType seekable_stream
        MagickFormatType format_type
        MagickStatusType thread_support
        MagickBooleanType stealth
        #size_t signature

    MagickInfo* GetMagickInfo(char*, ExceptionInfo*)
    MagickInfo** GetMagickInfoList(char*, size_t*, ExceptionInfo*)

    void MagickCoreGenesis(char*, MagickBooleanType)
    void MagickCoreTerminus()


### BLOB

cdef extern from "magick/blob.h":
    Image* BlobToImage(ImageInfo* image_info, void* blob, size_t length, ExceptionInfo *exception)
    void* ImageToBlob(ImageInfo* image_info, Image* image, size_t* length, ExceptionInfo *exception)


### CONSTITUTE

cdef extern from "magick/constitute.h":
    Image *ReadImage(ImageInfo*, ExceptionInfo*)
    MagickBooleanType WriteImage(ImageInfo*, Image*)
    MagickBooleanType WriteImages(ImageInfo*, Image*, char* filename, ExceptionInfo* exception)


### PROPERTY

cdef extern from "magick/property.h":
    char* GetImageProperty(Image*, char*)
    char* GetNextImageProperty(Image*)
    void ResetImagePropertyIterator(Image*)


### COMPOSITE

cdef extern from "magick/composite.h":
    MagickBooleanType TextureImage(Image*, Image*)


### RESIZE

cdef extern from "magick/resize.h":
    Image* AdaptiveResizeImage(Image*, size_t, size_t, ExceptionInfo*)
    Image* LiquidRescaleImage(Image*, size_t, size_t, double, double, ExceptionInfo*)
    Image* MagnifyImage(Image*, ExceptionInfo*)
    Image* MinifyImage(Image*, ExceptionInfo*)
    Image* ResampleImage(Image*, double, double, FilterTypes, double, ExceptionInfo*)
    Image* ResizeImage(Image*, size_t, size_t, FilterTypes, double, ExceptionInfo*)
    Image* SampleImage(Image*, size_t, size_t, ExceptionInfo*)
    Image* ScaleImage(Image*, size_t, size_t, ExceptionInfo*)
    Image* ThumbnailImage(Image*, size_t, size_t, ExceptionInfo*)


### TRANSFORM

cdef extern from "magick/transform.h":
    Image* ChopImage(Image*, RectangleInfo*, ExceptionInfo*)
    Image* ConsolidateCMYKImages(Image*, ExceptionInfo*)
    Image* CropImage(Image*, RectangleInfo*, ExceptionInfo*)
    Image* CropImageToTiles(Image*, char*, ExceptionInfo*)
    Image* ExcerptImage(Image*, RectangleInfo*, ExceptionInfo*)
    Image* ExtentImage(Image*, RectangleInfo*, ExceptionInfo*)
    Image* FlipImage(Image*, ExceptionInfo*)
    Image* FlopImage(Image*, ExceptionInfo*)
    Image* RollImage(Image*, ssize_t, ssize_t, ExceptionInfo*)
    Image* ShaveImage(Image*, RectangleInfo*, ExceptionInfo*)
    Image* SpliceImage(Image*, RectangleInfo*, ExceptionInfo*)
    Image* TransposeImage(Image*, ExceptionInfo*)
    Image* TransverseImage(Image*, ExceptionInfo*)
    Image* TrimImage(Image*, ExceptionInfo*)

    MagickBooleanType TransformImage(Image**, char*, char*)
    MagickBooleanType TransformImages(Image**, char*, char*)


### PAINT

cdef extern from "magick/paint.h":
    Image* OilPaintImage(Image*, double, ExceptionInfo*)

    #MagickBooleanType FloodfillPaintImage(Image*, ChannelType, DrawInfo*, MagickPixelPacket*, ssize_t, ssize_t, MagickBooleanType)
    MagickBooleanType GradientImage(Image*, GradientType, SpreadMethod, PixelPacket*, PixelPacket*)
    MagickBooleanType OpaquePaintImage(Image*, MagickPixelPacket*, MagickPixelPacket*, MagickBooleanType)
    MagickBooleanType OpaquePaintImageChannel(Image*, ChannelType, MagickPixelPacket*, MagickPixelPacket*, MagickBooleanType)
    MagickBooleanType TransparentPaintImage(Image*, MagickPixelPacket*, Quantum, MagickBooleanType)
    MagickBooleanType TransparentPaintImageChroma(Image*, MagickPixelPacket*, MagickPixelPacket*, Quantum, MagickBooleanType)


### CACHE (pixel cache)

cdef extern from "magick/cache.h":
    #IndexPacket *GetVirtualIndexQueue(Image*)

    PixelPacket* GetVirtualPixels(Image*, ssize_t, ssize_t, size_t, size_t, ExceptionInfo*)
    PixelPacket* GetVirtualPixelQueue(Image*)

    #void *AcquirePixelCachePixels(Image*, MagickSizeType*, ExceptionInfo*)

    #IndexPacket* GetAuthenticIndexQueue(Image*)

    MagickBooleanType CacheComponentGenesis()
    MagickBooleanType GetOneVirtualMagickPixel(Image*, ssize_t, ssize_t, MagickPixelPacket*, ExceptionInfo*)
    MagickBooleanType GetOneVirtualPixel(Image*, ssize_t, ssize_t, PixelPacket*, ExceptionInfo*)
    #MagickBooleanType GetOneVirtualMethodPixel(Image*, VirtualPixelMethod, ssize_t, ssize_t, PixelPacket*, ExceptionInfo*)
    MagickBooleanType GetOneAuthenticPixel(Image*, ssize_t, ssize_t, PixelPacket*, ExceptionInfo*)
    #MagickBooleanType PersistPixelCache(Image*, char*, MagickBooleanType, MagickOffsetType*, ExceptionInfo*)
    MagickBooleanType SyncAuthenticPixels(Image*, ExceptionInfo*)

    #MagickSizeType GetImageExtent(Image*)

    PixelPacket* GetAuthenticPixels(Image*, ssize_t, ssize_t, size_t, size_t, ExceptionInfo*)
    PixelPacket* GetAuthenticPixelQueue(Image*)
    PixelPacket* QueueAuthenticPixels(Image*, ssize_t, ssize_t, size_t, size_t, ExceptionInfo*)

    #VirtualPixelMethod GetPixelCacheVirtualMethod(Image*)
    #VirtualPixelMethod SetPixelCacheVirtualMethod(Image*, VirtualPixelMethod)

    void CacheComponentTerminus()
    #void* GetPixelCachePixels(Image*, MagickSizeType*, ExceptionInfo*)

cdef extern from "magick/cache-view.h":
    ctypedef enum VirtualPixelMethod:
        UndefinedVirtualPixelMethod
        BackgroundVirtualPixelMethod
        ConstantVirtualPixelMethod
        DitherVirtualPixelMethod
        EdgeVirtualPixelMethod
        MirrorVirtualPixelMethod
        RandomVirtualPixelMethod
        TileVirtualPixelMethod
        TransparentVirtualPixelMethod
        MaskVirtualPixelMethod
        BlackVirtualPixelMethod
        GrayVirtualPixelMethod
        WhiteVirtualPixelMethod
        HorizontalTileVirtualPixelMethod
        VerticalTileVirtualPixelMethod
        HorizontalTileEdgeVirtualPixelMethod
        VerticalTileEdgeVirtualPixelMethod
        CheckerTileVirtualPixelMethod

    ctypedef struct CacheView:
        pass

    CacheView* AcquireCacheView(Image*)
    CacheView* CloneCacheView(CacheView*)
    CacheView* DestroyCacheView(CacheView*)

    ClassType GetCacheViewStorageClass(CacheView*)

    ColorspaceType GetCacheViewColorspace(CacheView*)

    IndexPacket* GetCacheViewVirtualIndexQueue(CacheView*)

    PixelPacket* GetCacheViewVirtualPixels(CacheView*, ssize_t, ssize_t, size_t, size_t,ExceptionInfo*)
    PixelPacket* GetCacheViewVirtualPixelQueue(CacheView*)

    ExceptionInfo* GetCacheViewException(CacheView*)

    IndexPacket* GetCacheViewAuthenticIndexQueue(CacheView*)

    MagickBooleanType GetOneCacheViewVirtualPixel(CacheView*, ssize_t, ssize_t, PixelPacket*,ExceptionInfo*)
    MagickBooleanType GetOneCacheViewVirtualMethodPixel(CacheView*, VirtualPixelMethod, ssize_t, ssize_t, PixelPacket*, ExceptionInfo*)
    MagickBooleanType GetOneCacheViewAuthenticPixel(CacheView*, ssize_t, ssize_t, PixelPacket*, ExceptionInfo*)
    MagickBooleanType SetCacheViewStorageClass(CacheView*, ClassType)
    MagickBooleanType SetCacheViewVirtualPixelMethod(CacheView*, VirtualPixelMethod)
    MagickBooleanType SyncCacheViewAuthenticPixels(CacheView*, ExceptionInfo*)

    MagickSizeType GetCacheViewExtent(CacheView*)

    size_t GetCacheViewChannels(CacheView*)

    PixelPacket* GetCacheViewAuthenticPixelQueue(CacheView*)
    PixelPacket* GetCacheViewAuthenticPixels(CacheView*, ssize_t, ssize_t, size_t, size_t,ExceptionInfo*)
    PixelPacket* QueueCacheViewAuthenticPixels(CacheView*, ssize_t, ssize_t, size_t, size_t, ExceptionInfo*)
