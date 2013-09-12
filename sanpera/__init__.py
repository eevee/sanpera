# Force loading the cffi API, since it also does the IM lib initialization.
# Only for compat with Cython parts.
import sanpera._api
