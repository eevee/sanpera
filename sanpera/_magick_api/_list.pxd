from sanpera._magick_api cimport _common, _image

cdef extern from "magick/list.h":
    void AppendImageToList(_image.Image**, _image.Image *)
    void DestroyImageList(_image.Image *)
    unsigned long GetImageListLength(_image.Image *)
    _image.Image* NewImageList()
    _image.Image* RemoveFirstImageFromList(_image.Image **)
