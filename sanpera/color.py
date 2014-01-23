"""Colors."""
import colorsys

from sanpera._api import ffi, lib
from sanpera.exception import magick_try
from sanpera.imagemagick import HAS_HDRI


# Scale between a fixed integral range and continuous 0-1:
#  0 ----- 1 ----- 2 ----- 3
# 0.0                     1.0

if HAS_HDRI:
    # Never clamp!
    def _clamp(ch):
        return ch
else:
    def _clamp(ch):
        if ch < 0:
            return 0.
        if ch > 1:
            return 1.
        return ch


# TODO: handle more colorspaces, and arbitrary extra channels.
class BaseColor(object):
    """Represents a color.

    Colors have some amount of color data (determined by the colorspace, but
    generally three channels' worth), an opacity, and an arbitrary number of
    other user-defined channels.  Channels' values are floats ranging from 0.0
    to 1.0.

    Particular colorspaces, and conversions between them, are implemented as
    subclasses of this class.

    All colors are immutable.  Convenience methods exist to make simple
    modifications, which will return a new color.
    """

    # TODO maybe i should just store the opacity like IM does, and only convert
    # when exposing to python  :|  and call it alpha.

    COLOR_WHEEL = [
        "red", "orange", "yellow", "chartreuse",
        "green", "seafoam", "cyan", "azure",
        "blue", "violet", "magenta", "rose",
    ]

    def __init__(self):
        raise TypeError("Can't instantiate BaseColor; use a subclass or other constructor")

    @property
    def description(self):
        """Return a human-friendly description of this color as a string."""
        hslself = self.hsl()

        # Do lightness first, because it can short-circuit for near-black
        # and near-white
        l = hslself.lightness
        if l <= 0:
            return "black"
        elif l < 0.025:
            return "blackish"
        elif l < 0.1:
            shade = "very dark"
        elif l < 0.2:
            shade = "kinda dark"
        elif l < 0.3:
            shade = "dark"
        elif l < 0.4:
            shade = ""
        elif l < 0.6:
            shade = "bright"
        elif l < 0.7:
            shade = "powder"
        elif l < 0.8:
            shade = "pastel"
        elif l < 0.9:
            shade = "light"
        elif l < 0.975:
            shade = "pale"
        elif l < 1:
            return "whitish"
        else:
            return "white"

        # Saturation, another potential short-circuit, and another
        # adjective to be stuck on a color name
        s = hslself.saturation
        if s < 0.015:
            if shade:
                return shade + " gray"
            else:
                return "gray"
        elif s < 0.05:
            sat = "grayish"
        elif s < 0.15:
            sat = "very dim"
        elif s < 0.25:
            sat = "dim"
        elif s < 0.4:
            sat = "dusty"
        elif s < 0.6:
            sat = ""
        elif s < 0.75:
            sat = "deep"
        elif s < 0.85:
            sat = "bold"
        elif s < 0.95:
            sat = "intense"
        else:
            sat = "pure"

        # Compute the hue description.  Find the name from the list of
        # colors above, treating each as the *middle* of a section, and
        # treat colors roughly halfway between X and Y as "X-Y"
        h = hslself.hue
        colors = len(self.COLOR_WHEEL)
        wheel_position = (h * colors + 0.5 / colors) % colors
        wheel_index = int(wheel_position)

        hue = self.COLOR_WHEEL[wheel_index]
        if wheel_position - wheel_index > 0.5:
            hue += "-" + self.COLOR_WHEEL[(wheel_index + 1) % colors]

        color = hue
        if sat:
            color = sat + " " + color
        if shade:
            color = shade + " " + color

        # TODO opacity description?
        return color

    # TODO call me alpha
    @property
    def opacity(self):
        return self._opacity

    # TODO does this work??
    @property
    def extra_channels(self):
        return self._extra_channels

    ### Conversions

    def rgb(self):
        raise NotImplementedError

    def hsl(self):
        raise NotImplementedError

    ### Constructors

    @classmethod
    def parse(cls, name):
        """Parse a color specification.

        Supports a whole buncha formats.
        """
        # TODO i don't like that this is tied to imagemagick's implementation.
        # would rather do most of the parsing myself, well-define what those
        # formats *are*, and use some other mechanism to expose the list of
        # builtin color names.  (maybe several lists, even.)
        # TODO also this always returns RGB anyway.

        pixel = ffi.new("PixelPacket *")

        with magick_try() as exc:
            success = lib.QueryColorDatabase(name.encode('ascii'), pixel, exc.ptr)
        if not success:
            raise ValueError("Can't find a color named {0!r}".format(name))

        return cls._from_pixel(pixel)

    @classmethod
    def coerce(cls, value):
        if isinstance(value, cls):
            # Already an object; do nothing
            return value

        # Probably a name; parse it
        return cls.parse(value)

    @classmethod
    def _from_pixel(cls, pixel):
        """Create a color from a PixelPacket."""
        array = ffi.new("double[]", 4)
        lib.sanpera_pixel_to_doubles(pixel, array)

        # Okay, yes, this isn't much of a classmethod.  TODO?
        return RGBColor._from_c_array(array)

    def _populate_pixel(self, pixel):
        """Copy values to a PixelPacket."""
        rgb = self.rgb()
        lib.sanpera_pixel_from_doubles(pixel, rgb._array)
        # TODO extra channels?

    def _populate_magick_pixel(self, pixel):
        """Copy values to a MagickPixelPacket."""
        rgb = self.rgb()
        lib.sanpera_magick_pixel_from_doubles(pixel, rgb._array)
        # TODO extra channels?
        # TODO imagemagick code uses:
        # SetMagickPixelPacket(image,start_color,(IndexPacket *) NULL, ptr)
        # ... why the IndexPacket?  should i be using that?


    ### Special methods

    def __eq__(self, other):
        if not isinstance(other, BaseColor):
            return NotImplemented

        left = self.rgb()
        right = other.rgb()

        # TODO should all alpha=0 colors be equal?
        return (
            left._red == right._red and
            left._green == right._green and
            left._blue == right._blue and
            left._opacity == right._opacity)

    def __ne__(self, other):
        return not self.__eq__(other)


class RGBColor(BaseColor):
    def __init__(self, red, green, blue, opacity=1.0, _array=None):
        self._red = red
        self._green = green
        self._blue = blue
        self._opacity = opacity
        self._extra_channels = ()

        if _array is None:
            self._array = ffi.new("double[]", [red, green, blue, opacity])
        else:
            self._array = _array

    @classmethod
    def _from_c_array(cls, array):
        return cls(*array, _array=array)

    def __repr__(self):
        return "<RGBColor {0:0.3f} red, {1:0.3f} green, {2:0.3f} blue ({3}) {4:0.1f}% opacity>".format(
            self._red, self._green, self._blue, self.description, self._opacity * 100)

    def __mul__(self, factor):
        # TODO does this semantic make sense?  it's just what IM's fx syntax
        # does
        # TODO this is only defined for RGB.  move it to base and just make it
        # convert to RGB, then back to the original class...?

        # TODO extra channels??
        return RGBColor(
            self._red * factor,
            self._green * factor,
            self._blue * factor,
            self._opacity)

    def __rmul__(self, factor):
        return self.__mul__(factor)

    def __add__(self, other):
        # TODO this is also what IM's fx syntax does; maybe a little less
        # sensible than multiplication even.
        # TODO type check
        # TODO extra channels
        return RGBColor(
            self._red + other,
            self._green + other,
            self._blue + other,
            self._opacity)

    def __sub__(self, other):
        return self + (-other)

    def clamped(self):
        return RGBColor(
            _clamp(self._red),
            _clamp(self._green),
            _clamp(self._blue),
            _clamp(self._opacity))
        # TODO every color type
        # TODO extra channels (clamp them??)

    # TODO are these even useful without cython?  they're just python doubles
    # now.  (nice to stay immutable, but other ways to do that)
    @property
    def red(self):
        return self._red

    @property
    def green(self):
        return self._green

    @property
    def blue(self):
        return self._blue

    @property
    def alpha(self):
        return self._opacity

    def rgb(self):
        return self

    def hsl(self):
        hue, light, sat = colorsys.rgb_to_hls(
            _clamp(self._red), _clamp(self._green), _clamp(self._blue))
        # TODO extra channels
        return HSLColor(hue, sat, light, self._opacity)


class CMYKColor(BaseColor):
    def __init__(self, cyan, magenta, yellow, black, alpha=1.0):
        self.cyan = cyan
        self.magenta = magenta
        self.yellow = yellow
        self.black = black
        self.alpha = alpha

    def rgb(self):
        return RGBColor(
            1 - self.cyan - self.black,
            1 - self.magenta - self.black,
            1 - self.yellow - self.black,
            self.alpha)


class HSLColor(BaseColor):
    def __init__(self, hue, saturation, lightness, opacity=1.0):
        if hue == 1.0:
            hue = 0.0

        self._hue = hue
        self._saturation = saturation
        self._lightness = lightness
        self._opacity = opacity
        self._extra_channels = ()

    def __repr__(self):
        return "<HSLColor {0:0.3f} hue, {1:0.3f} sat, {2:0.3f} light ({3}) {4:0.1f}% opacity>".format(
            self._hue, self._saturation, self._lightness, self.description, self._opacity * 100)

    @property
    def hue(self):
        return self._hue

    @property
    def saturation(self):
        return self._saturation

    @property
    def lightness(self):
        return self._lightness

    def rgb(self):
        r, g, b = colorsys.hls_to_rgb(self._hue, self._lightness, self._saturation)
        # TODO extra channels
        return RGBColor(r, g, b, self._opacity)

    def hsl(self):
        return self


class GrayColor(BaseColor):
    def __init__(self, value, alpha=1.0):
        self.value = value
        self.alpha = alpha

    def rgb(self):
        return RGBColor(self.value, self.value, self.value, self.alpha)

    def hsl(self):
        return HSLColor(0, 0, self.value, self.alpha)
