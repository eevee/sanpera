import sys

from sanpera.image import Image

def demo_program():
    filenames = sys.argv[1:]
    out_filename = filenames.pop()

    images = Image()
    for fn in filenames:
        print "Reading %s ..." % (fn,)
        #img = Image.from_filename(fn)
        #img = Image.from_buffer(open(fn).read())
        img = Image.read(open(fn))
        print " %lu frames" % (len(img),)
        images.extend(img)

    if not images:
        raise IOError("Failed to read any images!")

    # Create a thumbnail image sequence
    thumbnails = images.resize(106, 80)
    del img
    del images

    # Write the thumbnail image sequence to file
    if thumbnails:
        print "Writing %s ... %lu frames" % (out_filename,
             len(thumbnails))
        open(out_filename, 'w').write(thumbnails.to_buffer())
        #thumbnails.write_file(open(out_filename, 'w'))
        #thumbnails.write(out_filename)

if __name__ == '__main__':
    demo_program()


# XXX hey here's what to do next champ
# -  support /writing/
# -  support reading the builtin special images?
# -  support overriding the image type detection
# 2. fix yo hierarchy.  there's probably a pure-python Image, inherits from cython BaseImage with all the real stuff, which stores a list of RawFrames, and also there's a SingleImage somewhere i guess??
# 3. write some tests somehow
# 4. make resizing and cropping work about as well as they do in convert
# 5. implement pixel access
# 6. check out whether that foo.jpg[600x400] syntax is worth doing

# x. check for memory leaks, throw MemoryError when necessary, etc.
