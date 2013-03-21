from sanpera cimport c_api

cdef double _quantum_to_double(c_api.Quantum value)
cdef c_api.Quantum _double_to_quantum(double value)
cdef double _real_quantum_to_double(c_api.MagickRealType value)
cdef c_api.MagickRealType _double_to_real_quantum(double value)

cdef class BaseColor:
    cdef double _opacity
    cdef tuple _extra_channels

    cpdef RGBColor rgb(self)
    cpdef HSLColor hsl(self)
    cdef _populate_pixel(self, c_api.PixelPacket* magick)
    cdef _populate_magick_pixel(self, c_api.MagickPixelPacket* magick)

cdef BaseColor _color_from_magick_pixel(c_api.MagickPixelPacket* pixel)
cdef BaseColor _color_from_pixel(c_api.PixelPacket* pixel)

cdef class RGBColor(BaseColor):
    cdef double _red
    cdef double _green
    cdef double _blue

cdef class HSLColor(BaseColor):
    cdef double _hue
    cdef double _saturation
    cdef double _lightness
