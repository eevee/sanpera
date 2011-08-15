from libc cimport string
cimport cpython.string
from graphick._magick_api cimport _constitute, _error, _image, _list, _magick, _resize

import sys

cdef extern from "Python.h":
    char* Py_GetProgramFullPath()

cpdef int gm_demo_program():
    cdef _error.ExceptionInfo exception

    cdef _image.Image *img
    cdef _image.Image *images
    cdef _image.Image *resize_image
    cdef _image.Image *thumbnails

    cdef _image.ImageInfo *image_info

    # Initialize the image info structure and read the _list of files
    # provided by the user as a image sequence

    _magick.InitializeMagick(Py_GetProgramFullPath())

    _error.GetExceptionInfo(&exception)
    image_info = _image.CloneImageInfo(<_image.ImageInfo*>NULL)
    images = _list.NewImageList()

    cdef char* filename
    for py_filename in sys.argv[1:-1]:
        string.strcpy(image_info.filename, <char*>py_filename)
        print("Reading %s ..." % image_info.filename)
        img = _constitute.ReadImage(image_info, &exception)
        print(" %lu frames" % _list.GetImageListLength(img))
        #if exception.severity != UndefinedException:
        _error.CatchException(&exception)
        if img is not NULL:
            _list.AppendImageToList(&images, img)

    if not images:
        raise IOError("Failed to read any images!")

    # Create a thumbnail image sequence
    thumbnails = _list.NewImageList()
    while True:
        img = _list.RemoveFirstImageFromList(&images)
        if img is NULL:
            break

        resize_image = _resize.ResizeImage(img, 106, 80, _image.LanczosFilter, 1.0, &exception)
        _image.DestroyImage(img)
        # if (resize_image == (Image *) NULL)
        #  {
        #    CatchException(&exception)
        #    continue
        #  }
        _list.AppendImageToList(&thumbnails, resize_image)

    # Write the thumbnail image sequence to file
    if thumbnails:
        string.strcpy(thumbnails.filename, <char*> sys.argv[-1])
        print("Writing %s ... %lu frames" % (thumbnails.filename,
             _list.GetImageListLength(thumbnails)))
        _constitute.WriteImage(image_info, thumbnails)
        # XXX image's exception  D:

    # Release resources
    _list.DestroyImageList(thumbnails)
    _image.DestroyImageInfo(image_info)
    _error.DestroyExceptionInfo(&exception)
    _magick.DestroyMagick()

    return 0
