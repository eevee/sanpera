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

// constitute.h
Image *ReadImage(const ImageInfo *, ExceptionInfo *);

// exception.h
ExceptionInfo *AcquireExceptionInfo(void);
ExceptionInfo *DestroyExceptionInfo(ExceptionInfo *);



// =============================================================================
// core types
// -----------------------------------------------------------------------------
// magick-type.h

// actually macros, but cffi figures it out
static const int MAGICKCORE_QUANTUM_DEPTH;
static float const QuantumRange;
static char *const QuantumFormat;

typedef ... MagickRealType;

typedef enum {
    MagickFalse = 0,
    MagickTrue = 1
} MagickBooleanType;

// TODO mooore
//
// TODO forward decls actually go here


// =============================================================================
// the important stuff
// -----------------------------------------------------------------------------
// image.h

// TODO some defines for opacity up here

typedef enum {
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

    size_t columns;
    size_t rows;

    RectangleInfo page;

    char magick[];
    char filename[];
    ...;
};

struct _ImageInfo {

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
void InsertImageInList(Image **,Image *);
Image *NewImageList();
void PrependImageToList(Image **,Image *);
Image *RemoveImageFromList(Image **);
Image *RemoveLastImageFromList(Image **);
Image *RemoveFirstImageFromList(Image **);
void ReplaceImageInList(Image **,Image *);
void ReplaceImageInListReturnLast(Image **, Image *);
void ReverseImageList(Image **);
Image *SpliceImageIntoList(Image **, const size_t, const Image *);
Image *SplitImageList(Image *);
void SyncImageList(Image *);
Image *SyncNextImageInList(const Image *);


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
