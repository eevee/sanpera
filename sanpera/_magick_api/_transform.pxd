from sanpera._magick_api cimport _common
from sanpera._magick_api._common cimport MagickBooleanType
from sanpera._magick_api._exception cimport ExceptionInfo
from sanpera._magick_api._image cimport Image, RectangleInfo

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
