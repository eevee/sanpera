from enum import EnumMeta, IntEnum

from sanpera._api import ffi


class CEnumMeta(EnumMeta):
    def __new__(meta, name, bases, attrs):
        cls = super(CEnumMeta, meta).__new__(meta, name, bases, attrs)
        if '__ctype__' in attrs:
            cls.c = IntEnum(cls.__ctype__.cname, cls.__ctype__.relements)
        return cls


class _CEnum(IntEnum):
    def __new__(cls, cname):
        value = cls.__ctype__.relements[cname]
        obj = int.__new__(cls, value)
        obj._value_ = value
        return obj


# Apply metaclass; syntax differs between 2 and 3.
CEnum = CEnumMeta('CEnum', (_CEnum,), {})


# ------------------------------------------------------------------------------
# Actual enum definitions from here

class Channel(CEnum):
    __ctype__ = ffi.typeof('ChannelType')
    red = 'RedChannel'
    blue = 'BlueChannel'
    green = 'GreenChannel'
