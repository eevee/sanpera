"""Provides a `Brush` class for drawing various primitives directly on a frame.
"""
from __future__ import division

from sanpera._api import ffi, lib

class Brush(object):
    """Wraps a `Frame` and draws directly onto it."""

    def __init__(self, frame):
        # TODO typecheck here, maybe?
        self.frame = frame

        self.draw_info = ffi.gc(
            lib.AcquireDrawInfo(),
            lib.DestroyDrawInfo)

    def gradient(self, from_color, to_color):
        gradient_info = self.draw_info.gradient

        gradient_info.type = lib.LinearGradient

        width = self.frame._frame.columns
        height = self.frame._frame.rows

        # Fit bounding box to the size of the image itself
        gradient_info.bounding_box.x = 0
        gradient_info.bounding_box.y = 0
        gradient_info.bounding_box.width = width
        gradient_info.bounding_box.height = height

        # Draw it vertically for now
        gradient_info.gradient_vector.x1 = 0.
        gradient_info.gradient_vector.y1 = 0.
        gradient_info.gradient_vector.x2 = 0.
        gradient_info.gradient_vector.y2 = height - 1.

        gradient_info.spread = lib.PadSpread

        gradient_info.center.x = width / 2
        gradient_info.center.y = height / 2

        gradient_info.radius = lib.sanpera_to_magick_real_type(max(width, height) / 2)

        # Construct some stops
        stops = ffi.new("StopInfo[]", 2)
        from_color._populate_magick_pixel(ffi.addressof(stops[0], "color"))
        stops[0].offset = lib.sanpera_to_magick_real_type(0.)
        to_color._populate_magick_pixel(ffi.addressof(stops[1], "color"))
        stops[1].offset = lib.sanpera_to_magick_real_type(1.)

        try:
            gradient_info.stops = stops
            gradient_info.number_stops = 2

            lib.DrawGradientImage(self.frame._frame, self.draw_info)
        finally:
            gradient_info.stops = ffi.NULL
            gradient_info.number_stops = 0
