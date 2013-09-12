#include <stdio.h>
#include <magick/MagickCore.h>

// -----------------------------------------------------------------------------
// Pixel channel handling

// Quantum varies in size depending on how ImageMagick was compiled, so it
// can't be exposed to cffi.  It's only used in a couple pixel structs, so
// those are left opaque and the below accessors convert to a double in [0.0,
// 1.0].
// This also insulates partially against the ABI changes in ImageMagick 7;
// directly twiddling parts of PixelPacket will no longer work, but these
// macros will
void sanpera_pixel_to_doubles(PixelPacket *pixel, double out[static 4]) {
    out[0] = (double)(GetPixelRed(pixel)) / QuantumRange;
    out[1] = (double)(GetPixelGreen(pixel)) / QuantumRange;
    out[2] = (double)(GetPixelBlue(pixel)) / QuantumRange;
    // Distinct from "opacity", which treats 0 as opaque
    out[3] = (double)(GetPixelAlpha(pixel)) / QuantumRange;
}

void sanpera_pixel_from_doubles(PixelPacket *pixel, double in[static 4]) {
    SetPixelRed(pixel, ClampToQuantum(in[0] * QuantumRange));
    SetPixelGreen(pixel, ClampToQuantum(in[1] * QuantumRange));
    SetPixelBlue(pixel, ClampToQuantum(in[2] * QuantumRange));
    // Distinct from "opacity", which treats 0 as opaque
    SetPixelAlpha(pixel, ClampToQuantum(in[3] * QuantumRange));
}
