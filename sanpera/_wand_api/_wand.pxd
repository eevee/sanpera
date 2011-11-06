from sanpera._magick_api cimport _common

# TODO: finish this, because fuck core.
# TODO: the biggest problem here is dealing with lists, for example, the default example program of sticking together a bunch of read images and writing it out as a gif.  the old and new images all want to refer to the same frames.  what do i do about that?  the same approach i have now, and rewrite the magickwand when necessary?  for all i know that's what's breaking me now!

cdef extern from "wand/magick_wand.h":

    typedef struct _MagickWand
      MagickWand;

    char
      *MagickDescribeImage(MagickWand *),
      *MagickGetConfigureInfo(MagickWand *,char *),
      *MagickGetException(MagickWand *,ExceptionType *),
      *MagickGetFilename(MagickWand *),
      *MagickGetImageAttribute(MagickWand *, char *),
      *MagickGetImageFilename(MagickWand *),
      *MagickGetImageFormat(MagickWand *),
      *MagickGetImageSignature(MagickWand *),
      **MagickQueryFonts(char *,unsigned long *),
      **MagickQueryFormats(char *,unsigned long *);

    CompositeOperator
      MagickGetImageCompose(MagickWand *);

    ColorspaceType
      MagickGetImageColorspace(MagickWand *);

    CompressionType
      MagickGetImageCompression(MagickWand *);

    char
      *MagickGetCopyright(void),
      *MagickGetHomeURL(void),
      *MagickGetPackageName(void),
      *MagickGetQuantumDepth(unsigned long *),
      *MagickGetReleaseDate(void),
      *MagickGetVersion(unsigned long *);

    DisposeType
      MagickGetImageDispose(MagickWand *);

    double
      MagickGetImageGamma(MagickWand *),
      MagickGetImageFuzz(MagickWand *),
      *MagickGetSamplingFactors(MagickWand *,unsigned long *),
      *MagickQueryFontMetrics(MagickWand *,DrawingWand *,char *);

    ImageType
      MagickGetImageType(MagickWand *);

    InterlaceType
      MagickGetImageInterlaceScheme(MagickWand *);

    long
      MagickGetImageIndex(MagickWand *);

    MagickSizeType
      MagickGetImageSize(MagickWand *);

    MagickWand
      *CloneMagickWand(MagickWand *),
      *MagickAppendImages(MagickWand *,unsigned int),
      *MagickAverageImages(MagickWand *),
      *MagickCoalesceImages(MagickWand *),
      *MagickCompareImageChannels(MagickWand *,MagickWand *,ChannelType,
        MetricType,double *),
      *MagickCompareImages(MagickWand *,MagickWand *,MetricType,
        double *),
      *MagickDeconstructImages(MagickWand *),
      *MagickFlattenImages(MagickWand *),
      *MagickFxImage(MagickWand *,char *),
      *MagickFxImageChannel(MagickWand *,ChannelType,char *),
      *MagickGetImage(MagickWand *),
      *MagickMorphImages(MagickWand *,unsigned long),
      *MagickMosaicImages(MagickWand *),
      *MagickMontageImage(MagickWand *,DrawingWand *,char *,
        char *,MontageMode,char *),
      *MagickPreviewImages(MagickWand *wand,PreviewType),
      *MagickSteganoImage(MagickWand *,MagickWand *,long),
      *MagickStereoImage(MagickWand *,MagickWand *),
      *MagickTextureImage(MagickWand *,MagickWand *),
      *MagickTransformImage(MagickWand *,char *,char *),
      *NewMagickWand(void);

    PixelWand
      **MagickGetImageHistogram(MagickWand *,unsigned long *);

    RenderingIntent
      MagickGetImageRenderingIntent(MagickWand *);

    ResolutionType
      MagickGetImageUnits(MagickWand *);

    unsigned int
      DestroyMagickWand(MagickWand *),
      MagickAdaptiveThresholdImage(MagickWand *,unsigned long,
        unsigned long,long),
      MagickAddImage(MagickWand *,MagickWand *),
      MagickAddNoiseImage(MagickWand *,NoiseType),
      MagickAffineTransformImage(MagickWand *,DrawingWand *),
      MagickAnnotateImage(MagickWand *,DrawingWand *,double,
        double,double,char *),
      MagickAnimateImages(MagickWand *,char *),
      MagickBlackThresholdImage(MagickWand *,PixelWand *),
      MagickBlurImage(MagickWand *,double,double),
      MagickBorderImage(MagickWand *,PixelWand *,unsigned long,
        unsigned long),
      MagickCdlImage(MagickWand *wand,char *cdl),
      MagickCharcoalImage(MagickWand *,double,double),
      MagickChopImage(MagickWand *,unsigned long,unsigned long,
        long,long),
      MagickClipImage(MagickWand *),
      MagickClipPathImage(MagickWand *,char *,unsigned int),
      MagickColorFloodfillImage(MagickWand *,PixelWand *,double,
        PixelWand *,long,long),
      MagickColorizeImage(MagickWand *,PixelWand *,PixelWand *),
      MagickCommentImage(MagickWand *,char *),
      MagickCompositeImage(MagickWand *,MagickWand *,CompositeOperator,
        long,long),
      MagickContrastImage(MagickWand *,unsigned int),
      MagickConvolveImage(MagickWand *,unsigned long,double *),
      MagickCropImage(MagickWand *,unsigned long,unsigned long,
        long,long),
      MagickCycleColormapImage(MagickWand *,long),
      MagickDespeckleImage(MagickWand *),
      MagickDisplayImage(MagickWand *,char *),
      MagickDisplayImages(MagickWand *,char *),
      MagickDrawImage(MagickWand *,DrawingWand *),
      MagickEdgeImage(MagickWand *,double),
      MagickEmbossImage(MagickWand *,double,double),
      MagickEnhanceImage(MagickWand *),
      MagickEqualizeImage(MagickWand *),
      MagickFlipImage(MagickWand *),
      MagickFlopImage(MagickWand *),
      MagickFrameImage(MagickWand *,PixelWand *,unsigned long,
        unsigned long,long,long),
      MagickGammaImage(MagickWand *,double),
      MagickGammaImageChannel(MagickWand *,ChannelType,double),
      MagickGetImageBackgroundColor(MagickWand *,PixelWand *),
      MagickGetImageBluePrimary(MagickWand *,double *,double *),
      MagickGetImageBorderColor(MagickWand *,PixelWand *),
      MagickGetImageBoundingBox(MagickWand *wand,double fuzz,
        unsigned long *width,unsigned long *height,long *x, long *y),
      MagickGetImageChannelExtrema(MagickWand *,ChannelType,unsigned long *,
        unsigned long *),
      MagickGetImageChannelMean(MagickWand *,ChannelType,double *,double *),
      MagickGetImageColormapColor(MagickWand *,unsigned long,PixelWand *),
      MagickGetImageExtrema(MagickWand *,unsigned long *,unsigned long *),
      MagickGetImageGreenPrimary(MagickWand *,double *,double *),
      MagickGetImageMatteColor(MagickWand *,PixelWand *),
      MagickGetImagePixels(MagickWand *,long,long,unsigned long,
        unsigned long,char *,StorageType,unsigned char *),
      MagickGetImageRedPrimary(MagickWand *,double *,double *),
      MagickGetImageResolution(MagickWand *,double *,double *),
      MagickGetImageWhitePoint(MagickWand *,double *,double *),
      MagickGetSize(MagickWand *,unsigned long *,unsigned long *),
      MagickHaldClutImage(MagickWand *wand,MagickWand *clut_wand),
      MagickHasNextImage(MagickWand *),
      MagickHasPreviousImage(MagickWand *),
      MagickImplodeImage(MagickWand *,double),
      MagickLabelImage(MagickWand *,char *),
      MagickLevelImage(MagickWand *,double,double,double),
      MagickLevelImageChannel(MagickWand *,ChannelType,double,
        double,double),
      MagickMagnifyImage(MagickWand *),
      MagickMapImage(MagickWand *,MagickWand *,unsigned int),
      MagickMatteFloodfillImage(MagickWand *,Quantum,double,
        PixelWand *,long,long),
      MagickMedianFilterImage(MagickWand *,double),
      MagickMinifyImage(MagickWand *),
      MagickModulateImage(MagickWand *,double,double,double),
      MagickMotionBlurImage(MagickWand *,double,double,double),
      MagickNegateImage(MagickWand *,unsigned int),
      MagickNegateImageChannel(MagickWand *,ChannelType,unsigned int),
      MagickNextImage(MagickWand *),
      MagickNormalizeImage(MagickWand *),
      MagickOilPaintImage(MagickWand *,double),
      MagickOpaqueImage(MagickWand *,PixelWand *,PixelWand *,
        double),
      MagickPingImage(MagickWand *,char *),
      MagickPreviousImage(MagickWand *),
      MagickProfileImage(MagickWand *,char *,unsigned char *,
        unsigned long),
      MagickQuantizeImage(MagickWand *,unsigned long,ColorspaceType,
        unsigned long,unsigned int,unsigned int),
      MagickQuantizeImages(MagickWand *,unsigned long,ColorspaceType,
        unsigned long,unsigned int,unsigned int),
      MagickRadialBlurImage(MagickWand *,double),
      MagickRaiseImage(MagickWand *,unsigned long,unsigned long,
        long,long,unsigned int),
      MagickReadImage(MagickWand *,char *),
      MagickReadImageBlob(MagickWand *,unsigned char *,size_t length),
      MagickReadImageFile(MagickWand *,FILE *),
      MagickReduceNoiseImage(MagickWand *,double),
      MagickRelinquishMemory(void *),
      MagickRemoveImage(MagickWand *),
      MagickResampleImage(MagickWand *,double,double,FilterTypes,
        double),
      MagickResizeImage(MagickWand *,unsigned long,unsigned long,
        FilterTypes,double),
      MagickRollImage(MagickWand *,long,long),
      MagickRotateImage(MagickWand *,PixelWand *,double),
      MagickSampleImage(MagickWand *,unsigned long,unsigned long),
      MagickScaleImage(MagickWand *,unsigned long,unsigned long),
      MagickSeparateImageChannel(MagickWand *,ChannelType),
      MagickSetCompressionQuality(MagickWand *wand,unsigned long quality),
      MagickSetFilename(MagickWand *,char *),
      MagickSetImage(MagickWand *,MagickWand *),
      MagickSetImageAttribute(MagickWand *,char *, char *),
      MagickSetImageBackgroundColor(MagickWand *,PixelWand *),
      MagickSetImageBluePrimary(MagickWand *,double,double),
      MagickSetImageBorderColor(MagickWand *,PixelWand *),
      MagickSetImageChannelDepth(MagickWand *,ChannelType,
        unsigned long),
      MagickSetImageColormapColor(MagickWand *,unsigned long,
        PixelWand *),
      MagickSetImageCompose(MagickWand *,CompositeOperator),
      MagickSetImageCompression(MagickWand *,CompressionType),
      MagickSetImageDelay(MagickWand *,unsigned long),
      MagickSetImageDepth(MagickWand *,unsigned long),
      MagickSetImageDispose(MagickWand *,DisposeType),
      MagickSetImageColorspace(MagickWand *,ColorspaceType),
      MagickSetImageGreenPrimary(MagickWand *,double,double),
      MagickSetImageGamma(MagickWand *,double),
      MagickSetImageFilename(MagickWand *,char *),
      MagickSetImageFormat(MagickWand *wand,char *format),
      MagickSetImageFuzz(MagickWand *,double),
      MagickSetImageIndex(MagickWand *,long),
      MagickSetImageInterlaceScheme(MagickWand *,InterlaceType),
      MagickSetImageIterations(MagickWand *,unsigned long),
      MagickSetImageMatteColor(MagickWand *,PixelWand *),
      MagickSetImageOption(MagickWand *,char *,char *,char *),
      MagickSetImagePixels(MagickWand *,long,long,unsigned long,
        unsigned long,char *,StorageType,unsigned char *),
      MagickSetImageRedPrimary(MagickWand *,double,double),
      MagickSetImageRenderingIntent(MagickWand *,RenderingIntent),
      MagickSetImageResolution(MagickWand *,double,double),
      MagickSetImageScene(MagickWand *,unsigned long),
      MagickSetImageType(MagickWand *,ImageType),
      MagickSetImageUnits(MagickWand *,ResolutionType),
      MagickSetImageVirtualPixelMethod(MagickWand *,VirtualPixelMethod),
      MagickSetPassphrase(MagickWand *,char *),
      MagickSetImageProfile(MagickWand *,char *,unsigned char *,
        unsigned long),
      MagickSetResolution(MagickWand *wand,
        double x_resolution,double y_resolution),
      MagickSetResolutionUnits(MagickWand *wand,ResolutionType units),
      MagickSetResourceLimit(ResourceType type,unsigned long limit),
      MagickSetSamplingFactors(MagickWand *,unsigned long,double *),
      MagickSetSize(MagickWand *,unsigned long,unsigned long),
      MagickSetImageWhitePoint(MagickWand *,double,double),
      MagickSetInterlaceScheme(MagickWand *,InterlaceType),
      MagickSharpenImage(MagickWand *,double,double),
      MagickShaveImage(MagickWand *,unsigned long,unsigned long),
      MagickShearImage(MagickWand *,PixelWand *,double,double),
      MagickSolarizeImage(MagickWand *,double),
      MagickSpreadImage(MagickWand *,double),
      MagickStripImage(MagickWand *),
      MagickSwirlImage(MagickWand *,double),
      MagickTintImage(MagickWand *,PixelWand *,PixelWand *),
      MagickThresholdImage(MagickWand *,double),
      MagickThresholdImageChannel(MagickWand *,ChannelType,double),
      MagickTransparentImage(MagickWand *,PixelWand *,Quantum,
        double),
      MagickTrimImage(MagickWand *,double),
      MagickUnsharpMaskImage(MagickWand *,double,double,double,
        double),
      MagickWaveImage(MagickWand *,double,double),
      MagickWhiteThresholdImage(MagickWand *,PixelWand *),
      MagickWriteImage(MagickWand *,char *),
      MagickWriteImageFile(MagickWand *,FILE *),
      MagickWriteImages(MagickWand *,char *,unsigned int);

    unsigned long
      MagickGetImageColors(MagickWand *),
      MagickGetImageDelay(MagickWand *),
      MagickGetImageChannelDepth(MagickWand *,ChannelType),
      MagickGetImageDepth(MagickWand *),
      MagickGetImageHeight(MagickWand *),
      MagickGetImageIterations(MagickWand *),
      MagickGetImageScene(MagickWand *),
      MagickGetImageWidth(MagickWand *),
      MagickGetNumberImages(MagickWand *),
      MagickGetResourceLimit(ResourceType);

    VirtualPixelMethod
      MagickGetImageVirtualPixelMethod(MagickWand *);

    unsigned char
      *MagickGetImageProfile(MagickWand *,char *,unsigned long *),
      *MagickRemoveImageProfile(MagickWand *,char *,unsigned long *),
      *MagickWriteImageBlob(MagickWand *,size_t *);

    void
      MagickResetIterator(MagickWand *);
