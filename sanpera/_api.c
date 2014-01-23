#include <stdio.h>
#include <magick/MagickCore.h>

// -----------------------------------------------------------------------------
// Conversion to ImageMagick's opaque types

MagickRealType sanpera_to_magick_real_type(long double value) {
    return (MagickRealType)value;
}

Quantum sanpera_to_quantum(long double value) {
    return (Quantum)value;
}


// -----------------------------------------------------------------------------
// Pixel channel handling

// Quantum varies in size depending on how ImageMagick was compiled, so it
// can't be exposed to cffi.  It's only used in a couple pixel structs, so
// those are left opaque and the below accessors convert to a double in [0.0,
// 1.0].
// This also insulates partially against the ABI changes in ImageMagick 7;
// directly twiddling parts of PixelPacket will no longer work, but these
// macros will.  TODO, obviously, handling arbitrary channels needs doing here.
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

// This populates only the specified channels of a particular (existing) pixel,
// which is similarly awkward to do from Python-land.  There's no equivalent
// for returning only some channels because that doesn't make a lot of sense.
void sanpera_pixel_from_doubles_channel(
        PixelPacket *pixel, double in[static 4], ChannelType channels)
{
    if (channels & RedChannel)
        SetPixelRed(pixel, ClampToQuantum(in[0] * QuantumRange));
    if (channels & GreenChannel)
        SetPixelGreen(pixel, ClampToQuantum(in[1] * QuantumRange));
    if (channels & BlueChannel)
        SetPixelBlue(pixel, ClampToQuantum(in[2] * QuantumRange));
    // Distinct from "opacity", which treats 0 as opaque
    if (channels & AlphaChannel)
        SetPixelAlpha(pixel, ClampToQuantum(in[3] * QuantumRange));
}


// Same story for MagickPixelPacket, which is different in ways beyond my
// understanding
void sanpera_magick_pixel_to_doubles(MagickPixelPacket *pixel, double out[static 4]) {
    out[0] = (double)(GetPixelRed(pixel)) / QuantumRange;
    out[1] = (double)(GetPixelGreen(pixel)) / QuantumRange;
    out[2] = (double)(GetPixelBlue(pixel)) / QuantumRange;
    // Distinct from "opacity", which treats 0 as opaque
    out[3] = (double)(GetPixelAlpha(pixel)) / QuantumRange;
}

void sanpera_magick_pixel_from_doubles(MagickPixelPacket *pixel, double in[static 4]) {
    SetPixelRed(pixel, ClampToQuantum(in[0] * QuantumRange));
    SetPixelGreen(pixel, ClampToQuantum(in[1] * QuantumRange));
    SetPixelBlue(pixel, ClampToQuantum(in[2] * QuantumRange));
    // Distinct from "opacity", which treats 0 as opaque
    SetPixelAlpha(pixel, ClampToQuantum(in[3] * QuantumRange));
}

void sanpera_magick_pixel_from_doubles_channel(
        MagickPixelPacket *pixel, double in[static 4], ChannelType channels)
{
    if (channels & RedChannel)
        SetPixelRed(pixel, ClampToQuantum(in[0] * QuantumRange));
    if (channels & GreenChannel)
        SetPixelGreen(pixel, ClampToQuantum(in[1] * QuantumRange));
    if (channels & BlueChannel)
        SetPixelBlue(pixel, ClampToQuantum(in[2] * QuantumRange));
    // Distinct from "opacity", which treats 0 as opaque
    if (channels & AlphaChannel)
        SetPixelAlpha(pixel, ClampToQuantum(in[3] * QuantumRange));
}



typedef enum {
    SANPERA_OP_LOAD_SOURCE_COLOR,
    SANPERA_OP_LOAD_COLOR,
    SANPERA_OP_LOAD_NUMBER,
    SANPERA_OP_ADD,
    SANPERA_OP_MULTIPLY,
    SANPERA_OP_CLAMP,
    SANPERA_OP_DONE
} sanpera_evaluate_op;

typedef struct {
    sanpera_evaluate_op op;
    PixelPacket *color;
    double number;
} sanpera_evaluate_step;

Quantum sanpera_evaluate_filter_once(sanpera_evaluate_step steps[], Quantum value, ChannelType channel);

// TODO this should use a cache view i guess
Image *sanpera_evaluate_filter(
        Image **frames, sanpera_evaluate_step steps[], ChannelType channels, ExceptionInfo *exception)
{
    const PixelPacket *p;
    PixelPacket *q;
    ssize_t x, y;
    Image *source = frames[0];
    Image *destination = CloneImage(source,source->columns,source->rows,MagickTrue, exception);

    if (destination == (Image *) NULL) { return NULL; }
    for (y=0; y < (ssize_t) source->rows; y++) {
        p = GetVirtualPixels(source,0,y,source->columns,1,exception);
        q = GetAuthenticPixels(destination,0,y,destination->columns,1,exception);

        if ((p == (const PixelPacket *) NULL) || (q == (PixelPacket *) NULL))
            break;

        for (x=0; x < (ssize_t) source->columns; x++) {
            // TODO would be lovely if this ran once per /pixel/ then extracted
            // the resulting channels
            if (channels & RedChannel) {
                SetPixelRed(q, sanpera_evaluate_filter_once(steps, p->red, RedChannel));
            }
            else {
                SetPixelRed(q, p->red);
            }

            if (channels & GreenChannel) {
                SetPixelGreen(q, sanpera_evaluate_filter_once(steps, p->green, GreenChannel));
            }
            else {
                SetPixelGreen(q, p->green);
            }

            if (channels & BlueChannel) {
                SetPixelBlue(q, sanpera_evaluate_filter_once(steps, p->blue, BlueChannel));
            }
            else {
                SetPixelBlue(q, p->blue);
            }

            if (channels & AlphaChannel) {
                SetPixelOpacity(q,90*p->opacity/100);
            }
            else {
                SetPixelOpacity(q, p->opacity);
            }

            p++;
            q++;
        }
        if (SyncAuthenticPixels(destination,exception) == MagickFalse)
            break;
    }
    if (y < (ssize_t) source->rows) {
        DestroyImage(destination);
        return NULL;
    }

    return destination;
}

#define SANPERA_STACK_SIZE 256
static double stack[SANPERA_STACK_SIZE];

Quantum sanpera_evaluate_filter_once(sanpera_evaluate_step steps[], Quantum value, ChannelType channel) {
    int i;
    sanpera_evaluate_op op;
    Quantum pixel_channel;
    int stack_pos = -1;
    for (i = 0;; i++) {
        op = steps[i].op;
        switch (op) {
            case SANPERA_OP_LOAD_SOURCE_COLOR:
                stack_pos++;
                stack[stack_pos] = (double)(value) / QuantumRange;
                break;

            case SANPERA_OP_LOAD_COLOR:
                // TODO...?
                // TODO how does this interact with quantum anyway
                stack_pos++;
                if (channel == RedChannel) {
                    pixel_channel = GetPixelRed(steps[i].color);
                }
                else if (channel == GreenChannel) {
                    pixel_channel = GetPixelGreen(steps[i].color);
                }
                else if (channel == BlueChannel) {
                    pixel_channel = GetPixelBlue(steps[i].color);
                }
                else {
                    // XXX not sure how to handle errors really
                    pixel_channel = 0.0;
                }
                stack[stack_pos] = (double)(pixel_channel) / QuantumRange;
                break;

            case SANPERA_OP_LOAD_NUMBER:
                stack_pos++;
                stack[stack_pos] = steps[i].number;
                break;

            case SANPERA_OP_ADD:
                stack_pos--;
                stack[stack_pos] = stack[stack_pos] + stack[stack_pos + 1];
                break;

            case SANPERA_OP_MULTIPLY:
                stack_pos--;
                stack[stack_pos] = stack[stack_pos] * stack[stack_pos + 1];
                break;

            case SANPERA_OP_CLAMP:
                if (stack[stack_pos] < 0.) {
                    stack[stack_pos] = 0.;
                }
                else if (stack[stack_pos] > 1.) {
                    stack[stack_pos] = 1.;
                }
                break;

            case SANPERA_OP_DONE:
                return ClampToQuantum(stack[stack_pos] * QuantumRange);
        }
    }
}
