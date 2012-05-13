Overview
========

Warning
-------

ImageMagick is a complicated library with poor documentation and too many
warts.  Additionally, the author's C is a bit rusty.  sanpera is thus
completely unreliable and may destroy your images, eat all your memory, and/or
burn your house down.

Patches and expertise are, of course, entirely welcome.


Compatibility
-------------

sanpera is known to work with Python 2.7.  It *probably* works with earlier
versions of Python 2, and *possibly* works with Python 3.


Installation
------------

sanpera requires Cython.

You will also need ImageMagick and its headers installed if you plan to get
very far.

Minimum versions are unclear; thusfar sanpera has only been built and used with
the latest versions of everything.


Regarding ImageMagick
---------------------

There are several Python libraries, in varying states of completion and decay,
that wrap ImageMagick.

sanpera is explicitly *not* such a library.  ImageMagick is considered an
implementation detail, and its design influences sanpera's as little as
possible.  sanpera actually goes to considerable lengths to subvert ImageMagick
features in many cases, where such features are awkward in Python, obscure and
surprising, inappropriate for a general-use library, or otherwise deemed
undesireable.

ImageMagick was chosen for its ubiquity, fairly broad feature set, and
familiarity.  GraphicsMagick was briefly evaluated, and even powered the
initial prototype, but it has languished considerably since it was forked from
ImageMagick.  Other candidates for an underlying library were either too
cumbersome, too underpowered, or tragically unknown to the author at the time.


Name
----

As it's a library and not a program, the name "sanpera" is written in
lowercase.

"Sanpera" is the Hindi term for a snake charmer—i.e., one who might manipulate
Python with magick.


Links
-----

* `Project homepage <http://eevee.github.com/sanpera/>`_
* `GitHub repository <https://github.com/eevee/sanpera>`_
* `ImageMagick <http://www.imagemagick.org/>`_
