// TODO comment out stuff that doesn't exist in older ImageMagick
// =============================================================================
// -----------------------------------------------------------------------------
// stdlib

FILE *fdopen(int fd, const char *mode);


// =============================================================================
// -----------------------------------------------------------------------------
// forward declarations

struct _Image;
typedef struct _Image Image;
struct _ImageInfo;
typedef struct _ImageInfo ImageInfo;
typedef ... CacheView;





typedef struct {
    size_t width;
    size_t height;
    ssize_t x;
    ssize_t y;
} RectangleInfo;

typedef enum {
    UndefinedException,
    ...
} ExceptionType;

typedef struct {
    ExceptionType severity;
    ...;
} ExceptionInfo;

// exception.h
ExceptionInfo *AcquireExceptionInfo(void);
ExceptionInfo *DestroyExceptionInfo(ExceptionInfo *);



// =============================================================================
// core types
// -----------------------------------------------------------------------------
// MagickCore.h

static const int MaxTextExtent;

// -----------------------------------------------------------------------------
// magick-type.h

// actually macros, but cffi figures it out
static const int MAGICKCORE_QUANTUM_DEPTH;
static float const QuantumRange;
static char *const QuantumFormat;

// XXX not right, not right at all
typedef float MagickRealType;


typedef enum {
    UndefinedChannel,
    RedChannel,
    GrayChannel,
    CyanChannel,
    GreenChannel,
    MagentaChannel,
    BlueChannel,
    YellowChannel,
    AlphaChannel,
    OpacityChannel,
    BlackChannel,
    IndexChannel,
    CompositeChannels,
    AllChannels,
    TrueAlphaChannel, /* extract actual alpha channel from opacity */
    RGBChannels,      /* set alpha from  grayscale mask in RGB */
    GrayChannels,
    SyncChannels,     /* channels should be modified equally */
    DefaultChannels,
    ...
} ChannelType;

typedef enum {
    UndefinedClass,
    DirectClass,
    PseudoClass
} ClassType;

typedef enum {
    MagickFalse = 0,
    MagickTrue = 1
} MagickBooleanType;

// TODO mooore
//
// TODO forward decls actually go here


// -----------------------------------------------------------------------------
// memory_.h

void RelinquishMagickMemory(void *);


// =============================================================================
// the important stuff
// -----------------------------------------------------------------------------
// image.h

// TODO some defines for opacity up here

typedef enum {
    UndefinedAlphaChannel,
    ActivateAlphaChannel,
    BackgroundAlphaChannel,
    CopyAlphaChannel,
    DeactivateAlphaChannel,
    ExtractAlphaChannel,
    OpaqueAlphaChannel,
    SetAlphaChannel,
    ShapeAlphaChannel,
    TransparentAlphaChannel,
    FlattenAlphaChannel,
    RemoveAlphaChannel,
    ...
} AlphaChannelType;

typedef enum {
    ...
} ImageType;

typedef enum {
    ...
} InterlaceType;

typedef enum {
    ...
} OrientationType;

typedef enum {
    ...
} ResolutionType;

typedef enum {
    ...
} PrimaryInfo;

typedef enum {
    ...
} SegmentInfo;

typedef enum {
    ...
} TransmitType;

typedef enum {
    ...
} ChromaticityInfo;


struct _Image {

    MagickBooleanType matte;

    size_t columns;
    size_t rows;
    size_t depth;
    size_t colors;

    RectangleInfo page;

    char magick[];
    char filename[];

    ExceptionInfo exception;

    ...;
};

struct _ImageInfo {

    MagickBooleanType adjoin;

    FILE *file;

    char magick[];
    char filename[];
    ...;
};


ImageInfo *AcquireImageInfo();
ImageInfo *CloneImageInfo(const ImageInfo *);
ImageInfo *DestroyImageInfo(ImageInfo *);
Image *ReferenceImage(Image *);
Image *DestroyImage(Image *);


// -----------------------------------------------------------------------------
// list.h
// (done)

void AppendImageToList(Image **, const Image *);
Image *CloneImageList(const Image *, ExceptionInfo *);
Image *CloneImages(const Image *, const char *, ExceptionInfo *);
void DeleteImageFromList(Image **);
void DeleteImages(Image **,const char *, ExceptionInfo *);
Image *DestroyImageList(Image *);
Image *DuplicateImages(Image *, const size_t, const char *, ExceptionInfo *);
Image *GetFirstImageInList(const Image *);
Image *GetImageFromList(const Image *, const ssize_t);
ssize_t GetImageIndexInList(const Image *);
size_t GetImageListLength(const Image *);
Image *GetLastImageInList(const Image *);
Image *GetNextImageInList(const Image *);
Image *GetPreviousImageInList(const Image *);
Image **ImageListToArray(const Image *, ExceptionInfo *);
void InsertImageInList(Image **, Image *);
Image *NewImageList();
void PrependImageToList(Image **, Image *);
Image *RemoveImageFromList(Image **);
Image *RemoveLastImageFromList(Image **);
Image *RemoveFirstImageFromList(Image **);
void ReplaceImageInList(Image **, Image *);
void ReplaceImageInListReturnLast(Image **, Image *);
void ReverseImageList(Image **);
Image *SpliceImageIntoList(Image **, const size_t, const Image *);
Image *SplitImageList(Image *);
void SyncImageList(Image *);
Image *SyncNextImageInList(const Image *);


// =============================================================================
// pixel access
// -----------------------------------------------------------------------------
// pixel.h
// (done)

typedef enum {
    UndefinedInterpolatePixel,
    AverageInterpolatePixel,           /* Average 4 nearest neighbours */
    BicubicInterpolatePixel,           /* Catmull-Rom interpolation */
    BilinearInterpolatePixel,          /* Triangular filter interpolation */
    FilterInterpolatePixel,            /* Use resize filter - (very slow) */
    IntegerInterpolatePixel,           /* Integer (floor) interpolation */
    MeshInterpolatePixel,              /* Triangular mesh interpolation */
    NearestNeighborInterpolatePixel,   /* Nearest neighbour only */
    SplineInterpolatePixel,            /* Cubic Spline (blurred) interpolation */
    Average9InterpolatePixel,          /* Average 9 nearest neighbours */
    Average16InterpolatePixel,         /* Average 16 nearest neighbours */
    BlendInterpolatePixel,             /* blend of nearest 1, 2 or 4 pixels */
    BackgroundInterpolatePixel,        /* just return background color */
    CatromInterpolatePixel,            /* Catmull-Rom interpolation */
    ...
} InterpolatePixelMethod;

typedef enum {
    PixelRed,
    PixelCyan,
    PixelGray,
    PixelY,
    PixelGreen,
    PixelMagenta,
    PixelCb,
    PixelBlue,
    PixelYellow,
    PixelCr,
    PixelAlpha,
    PixelBlack,
    PixelIndex,
    MaskPixelComponent,
    ...
} PixelComponent;

typedef enum {
    UndefinedPixelIntensityMethod,
    AveragePixelIntensityMethod,
    BrightnessPixelIntensityMethod,
    LightnessPixelIntensityMethod,
    Rec601LumaPixelIntensityMethod,
    Rec601LuminancePixelIntensityMethod,
    Rec709LumaPixelIntensityMethod,
    Rec709LuminancePixelIntensityMethod,
    RMSPixelIntensityMethod,
    MSPixelIntensityMethod,
    ...
} PixelIntensityMethod;

typedef struct {
    double red;
    double green;
    double blue;
    double opacity;
    double index;
} DoublePixelPacket;

typedef struct {
    unsigned int red;
    unsigned int green;
    unsigned int blue;
    unsigned int opacity;
    unsigned int index;
} LongPixelPacket;

typedef struct {
    //ClassType storage_class;
    //ColorspaceType colorspace;
    MagickBooleanType matte;
    double fuzz;
    size_t depth;

    MagickRealType red;
    MagickRealType green;
    MagickRealType blue;
    MagickRealType opacity;
    MagickRealType index;
    ...;
} MagickPixelPacket;

// XXX quantum isn't defined
//typedef Quantum IndexPacket;

typedef struct {
    /*
    Quantum red;
    Quantum green;
    Quantum blue;
    Quantum opacity;
    */
    ...;
} PixelPacket;

typedef struct {
    /*
    Quantum red;
    Quantum green;
    Quantum blue;
    Quantum opacity;
    Quantum index;
    */
    ...;
} QuantumPixelPacket;

MagickPixelPacket *CloneMagickPixelPacket(const MagickPixelPacket *);
MagickRealType DecodePixelGamma(const MagickRealType);
MagickRealType EncodePixelGamma(const MagickRealType);
//MagickBooleanType ExportImagePixels(const Image *, const ssize_t, const ssize_t, const size_t, const size_t, const char *, const StorageType, void *, ExceptionInfo *);
void GetMagickPixelPacket(const Image *, MagickPixelPacket *);
MagickRealType GetPixelIntensity(const Image *image, const PixelPacket *);
//MagickBooleanType ImportImagePixels(Image *, const ssize_t, const ssize_t, const size_t, const size_t, const char *, const StorageType, const void *);
MagickBooleanType InterpolateMagickPixelPacket(const Image *, const CacheView *, const InterpolatePixelMethod, const double, const double, MagickPixelPacket *, ExceptionInfo *);


// =============================================================================
// whole-image manipulation
// -----------------------------------------------------------------------------
// channel.h

Image *CombineImages(const Image *, const ChannelType, ExceptionInfo *);
//Image *SeparateImage(const Image *, const ChannelType, ExceptionInfo *);
//Image *SeparateImages(const Image *, const ChannelType, ExceptionInfo *);


MagickBooleanType GetImageAlphaChannel(const Image *);
//MagickBooleanType SeparateImageChannel(Image *, const ChannelType);
MagickBooleanType SetImageAlphaChannel(Image *, const AlphaChannelType);

// -----------------------------------------------------------------------------
// resample.h

typedef enum {
    UndefinedFilter,
    PointFilter,
    BoxFilter,
    TriangleFilter,
    HermiteFilter,
    HanningFilter,
    HammingFilter,
    BlackmanFilter,
    GaussianFilter,
    QuadraticFilter,
    CubicFilter,
    CatromFilter,
    MitchellFilter,
    JincFilter,
    SincFilter,
    SincFastFilter,
    KaiserFilter,
    WelshFilter,
    ParzenFilter,
    BohmanFilter,
    BartlettFilter,
    LagrangeFilter,
    LanczosFilter,
    LanczosSharpFilter,
    Lanczos2Filter,
    Lanczos2SharpFilter,
    RobidouxFilter,
    RobidouxSharpFilter,
    CosineFilter,
    SplineFilter,
    LanczosRadiusFilter,
    SentinelFilter,  /* a count of all the filters, not a real filter */
    ...
} FilterTypes;


// -----------------------------------------------------------------------------
// resize.h
// (done)

Image *AdaptiveResizeImage(const Image *, const size_t, const size_t, ExceptionInfo *);
//TODO Image *InterpolativeResizeImage(const Image *, const size_t, const size_t, const InterpolatePixelMethod, ExceptionInfo *);
Image *LiquidRescaleImage(const Image *, const size_t, const size_t, const double, const double, ExceptionInfo *);
Image *MagnifyImage(const Image *, ExceptionInfo *);
Image *MinifyImage(const Image *, ExceptionInfo *);
Image *ResampleImage(const Image *, const double, const double, const FilterTypes, const double, ExceptionInfo *);
Image *ResizeImage(const Image *, const size_t, const size_t, const FilterTypes, const double, ExceptionInfo *);
Image *SampleImage(const Image *, const size_t, const size_t, ExceptionInfo *);
Image *ScaleImage(const Image *, const size_t, const size_t, ExceptionInfo *);
Image *ThumbnailImage(const Image *, const size_t, const size_t, ExceptionInfo *);


// -----------------------------------------------------------------------------
// transform.h
// (done)

Image *AutoOrientImage(const Image *, const OrientationType, ExceptionInfo *);
Image *ChopImage(const Image *, const RectangleInfo *, ExceptionInfo *);
Image *ConsolidateCMYKImages(const Image *, ExceptionInfo *);
Image *CropImage(const Image *, const RectangleInfo *, ExceptionInfo *);
Image *CropImageToTiles(const Image *, const char *, ExceptionInfo *);
Image *ExcerptImage(const Image *, const RectangleInfo *, ExceptionInfo *);
Image *ExtentImage(const Image *, const RectangleInfo *, ExceptionInfo *);
Image *FlipImage(const Image *, ExceptionInfo *);
Image *FlopImage(const Image *, ExceptionInfo *);
Image *RollImage(const Image *, const ssize_t, const ssize_t, ExceptionInfo *);
Image *ShaveImage(const Image *, const RectangleInfo *, ExceptionInfo *);
Image *SpliceImage(const Image *, const RectangleInfo *, ExceptionInfo *);
MagickBooleanType TransformImage(Image **, const char *, const char *);
MagickBooleanType TransformImages(Image **, const char *, const char *);
Image *TransposeImage(const Image *, ExceptionInfo *);
Image *TransverseImage(const Image *, ExceptionInfo *);
Image *TrimImage(const Image *, ExceptionInfo *);


// =============================================================================
// i/o
// -----------------------------------------------------------------------------
// stream.h
// (done)

typedef size_t (*StreamHandler)(const Image *, const void *, const size_t);

Image *ReadStream(const ImageInfo *, StreamHandler, ExceptionInfo *);
MagickBooleanType WriteStream(const ImageInfo *, Image *, StreamHandler);


// -----------------------------------------------------------------------------
// blob.h
// (done)

static const int MagickMaxBufferExtent;

typedef enum {
    ReadMode,
    WriteMode,
    IOMode
} MapMode;

MagickBooleanType BlobToFile(char *, const void *, const size_t, ExceptionInfo *);
Image *BlobToImage(const ImageInfo *, const void *, const size_t, ExceptionInfo *);
void DestroyBlob(Image *);
void DuplicateBlob(Image *, const Image *);
unsigned char *FileToBlob(const char *, const size_t, size_t *, ExceptionInfo *);
MagickBooleanType FileToImage(Image *, const char *);
MagickBooleanType GetBlobError(const Image *);
FILE *GetBlobFileHandle(const Image *);
//MagickSizeType GetBlobSize(const Image *);
unsigned char *GetBlobStreamData(const Image *);
StreamHandler GetBlobStreamHandler(const Image *);
unsigned char *ImageToBlob(const ImageInfo *, Image *, size_t *, ExceptionInfo *);
MagickBooleanType ImageToFile(Image *, char *, ExceptionInfo *);
unsigned char *ImagesToBlob(const ImageInfo *, Image *, size_t *, ExceptionInfo *);
MagickBooleanType InjectImageBlob(const ImageInfo *, Image *, Image *, const char *, ExceptionInfo *);
MagickBooleanType IsBlobExempt(const Image *);
MagickBooleanType IsBlobSeekable(const Image *);
MagickBooleanType IsBlobTemporary(const Image *);
Image *PingBlob(const ImageInfo *, const void *, const size_t, ExceptionInfo *);
void SetBlobExempt(Image *, const MagickBooleanType);


// -----------------------------------------------------------------------------
// constitute.h

typedef enum {
    UndefinedPixel,
    CharPixel,
    DoublePixel,
    FloatPixel,
    IntegerPixel,
    LongPixel,
    QuantumPixel,
    ShortPixel
} StorageType;

MagickBooleanType ConstituteComponentGenesis();
void ConstituteComponentTerminus();
Image *ConstituteImage(const size_t, const size_t, const char *, const StorageType, const void *, ExceptionInfo *);
Image *PingImage(const ImageInfo *, ExceptionInfo *);
Image *PingImages(const ImageInfo *, ExceptionInfo *);
Image *ReadImage(const ImageInfo *, ExceptionInfo *);
Image *ReadImages(const ImageInfo *, ExceptionInfo *);
Image *ReadInlineImage(const ImageInfo *, const char *, ExceptionInfo *);
MagickBooleanType WriteImage(const ImageInfo *, Image *);
MagickBooleanType WriteImages(const ImageInfo *, Image *, const char *, ExceptionInfo *);
