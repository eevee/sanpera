// stdlib
FILE *fdopen(int fd, const char *mode);

const int MAGICKCORE_QUANTUM_DEPTH;
//const int MAGICKCORE_HDRI_SUPPORT;

const char *GetMagickCopyright();


typedef struct {
    size_t width;
    size_t height;
    ssize_t x;
    ssize_t y;
} RectangleInfo;

typedef struct {
    FILE *file;
    char magick[];
    char filename[];
    ...;
} ImageInfo;

typedef struct {
    RectangleInfo page;


    char magick[];
    char filename[];
    ...;
} Image;

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

// image.h
ImageInfo *AcquireImageInfo();
ImageInfo *CloneImageInfo(const ImageInfo *);
ImageInfo *DestroyImageInfo(ImageInfo *);
Image *ReferenceImage(Image *);
Image *DestroyImage(Image *);

// list.h
Image *DestroyImageList(Image *);
Image *GetNextImageInList(const Image *);
size_t GetImageListLength(const Image *);

// exception.h
ExceptionInfo *AcquireExceptionInfo(void);
ExceptionInfo *DestroyExceptionInfo(ExceptionInfo *);
