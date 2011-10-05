cimport libc.string
from sanpera._magick_api cimport _constitute, _error, _image, _list, _magick, _resize
import atexit


# Setup and shutdown
cdef extern from "Python.h":
    char* Py_GetProgramFullPath()

_magick.InitializeMagick(Py_GetProgramFullPath())

def _shutdown():
    _magick.DestroyMagick()
atexit.register(_shutdown)



# TODO better exception handling /by far/; less ugly and more enforced
# TODO read docs carefully for when exception might be populated
# TODO these module names are unwieldy, and too much stuff called Image
# TODO no way to inspect an image or image-info
# TODO i am probably leaking like a sieve here
# TODO docstrings
# TODO expose more properties and whatever to python-land

class MagickException(Exception): pass

cdef class Frame:
    """Represents a single static frame."""

    cdef _image.Image* _img

    def __cinit__(self):
        self._img = NULL

    def __dealloc__(self):
        _image.DestroyImage(self._img)


    def resize(self, int columns, int rows):
        # XXX size ought to be a tuple
        # TODO percents
        # TODO < > ^ ! ...
        # XXX should size be a geometry object or summat
        # TODO allow picking a filter
        # TODO allow messing with blur?

        # TODO better way to check for exceptions
        # TODO do i need to destroy this?
        cdef _error.ExceptionInfo exception
        _error.GetExceptionInfo(&exception)

        cdef _image.Image* new_image = _resize.ResizeImage(
            self._img, columns, rows,
            _image.LanczosFilter, 1.0, &exception)
        if exception.severity != _error.UndefinedException:
            raise MagickException(<bytes>exception.reason + <bytes>exception.description)

        cdef Frame ret = Frame()
        ret._img = new_image
        return ret

cdef Frame _frame_from_c(_image.Image* other):
    # Avoid the constructor
    # XXX make sure this is ok when you write the actual constructor
    cdef Frame self = Frame.__new__(Frame)
    self._img = other
    return self


cdef class Image:
    """Represents a stack of zero or more frames."""

    cdef list _frames

    def __cinit__(self):
        self._frames = []

    def __dealloc__(self):
        pass

    def __len__(self):
        return len(self._frames)

    def __nonzero__(self):
        return bool(self._frames)

    @classmethod
    def from_filename(type cls, bytes filename):
        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(<_image.ImageInfo*>NULL)
        cdef _error.ExceptionInfo exception
        _error.GetExceptionInfo(&exception)
        # XXX OH NO THIS IS AWFUL
        # TODO ReadImages?
        libc.string.strcpy(image_info.filename, <char*>filename)

        cdef _image.Image* image = _constitute.ReadImage(image_info, &exception)
        if exception.severity != _error.UndefinedException:
            raise MagickException(<bytes>exception.reason + <bytes>exception.description)

        cdef Image self = cls()
        while image != NULL:
            self._raw_append(image)
            _list.RemoveFirstImageFromList(&image)
        return self


    cdef void _raw_append(self, _image.Image* other):
        cdef Frame frame = _frame_from_c(other)
        self._frames.append(frame)

    def extend(self, Image other):
        self._frames.extend(other._frames)


    def resize(self, *a, **kw):
        cdef Image ret = Image()
        ret._frames = [frame.resize(*a, **kw) for frame in self._frames]
        return ret


    def write(self, bytes filename):
        # XXX what if there are no images

        # First fix up the image links
        # TODO split me out
        cdef _image.Image* prev_image = NULL
        cdef Frame frame
        for frame in self._frames:
            frame._img.previous = prev_image
            if prev_image:
                prev_image.next = frame._img
            prev_image = frame._img
        prev_image.next = NULL

        # Gimme a blank image_info
        cdef _image.ImageInfo* image_info = _image.CloneImageInfo(NULL)
        # XXX OH NO THIS IS AWFUL
        # XXX this relies on GraphicsMagick's filename parsing.  eh.
        cdef _image.Image* head_image = (<Frame>self._frames[0])._img
        cdef _error.ExceptionInfo exception
        _error.GetExceptionInfo(&exception)
        _constitute.WriteImages(image_info, head_image, filename, &exception)
        if exception.severity != _error.UndefinedException:
            raise MagickException(<bytes>exception.reason + <bytes>exception.description)

        _image.DestroyImageInfo(image_info)
