from sanpera._magick_api cimport _common, _error, _image

cdef extern from "magick/list.h":
    _image.Image* CloneImageList(_image.Image*, _error.ExceptionInfo*)
    _image.Image* GetFirstImageInList(_image.Image*)
    _image.Image* GetImageFromList(_image.Image*, long)
    _image.Image* GetLastImageInList(_image.Image*)
    _image.Image* GetNextImageInList(_image.Image*)
    _image.Image* GetPreviousImageInList(_image.Image*)
    _image.Image** ImageListToArray(_image.Image*, _error.ExceptionInfo*)
    _image.Image* NewImageList()
    _image.Image* RemoveLastImageFromList(_image.Image**)
    _image.Image* RemoveFirstImageFromList(_image.Image**)
    _image.Image* SplitImageList(_image.Image*)
    _image.Image* SyncNextImageInList(_image.Image*)

    long GetImageIndexInList(_image.Image*)

    unsigned long GetImageListLength(_image.Image*)

    void AppendImageToList(_image.Image**, _image.Image*)
    void DeleteImageFromList(_image.Image**)
    void DestroyImageList(_image.Image*)
    void InsertImageInList(_image.Image**, _image.Image*)
    void PrependImageToList(_image.Image**, _image.Image*)
    void ReplaceImageInList(_image.Image**, _image.Image*)
    void ReverseImageList(_image.Image**)
    void SpliceImageIntoList(_image.Image**, unsigned long, _image.Image*)
