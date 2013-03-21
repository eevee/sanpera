from sanpera cimport c_api

cdef class ImageFrame:
    cdef c_api.Image* _frame

    cdef _set_frame(self, c_api.Image*)

cdef ImageFrame _ImageFrame_factory(c_api.Image*)

cdef class Image:
    cdef c_api.Image* _stack
    cdef list _frames

    cdef _post_init(self)
    cdef _setup_frames(self, c_api.Image* start=*)
    cdef _fix_page(self)
