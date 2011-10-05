import sys

from sanpera.core import Image

def demo_program():
    filenames = sys.argv[1:]
    out_filename = filenames.pop()

    images = Image()
    for fn in filenames:
        print "Reading %s ..." % (fn,)
        img = Image.from_filename(fn)
        print " %lu frames" % (len(img),)
        images.extend(img)

    if not images:
        raise IOError("Failed to read any images!")

    # Create a thumbnail image sequence
    thumbnails = images.resize(106, 80)

    # Write the thumbnail image sequence to file
    if thumbnails:
        print "Writing %s ... %lu frames" % (out_filename,
             len(thumbnails))
        thumbnails.write(out_filename)

if __name__ == '__main__':
    demo_program()
