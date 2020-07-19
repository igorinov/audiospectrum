#ifndef ASSEMBLY_FFT

#include "vispo.h"

/**
 *  fft_combine() - combine M spectrum pairs, L points each
 *  into M spectra, N * 2 points each
 *
 *  @cs - complex sinusoid table for this round
 */

int fft_combine_d(const complex_d *pt_s, complex_d *data, int l, int m)
{
    complex_d s, a, b, t;
    int i, j;

    for (i = 0; i < m; i += 1) {
        /* pt_s = cs + n * 2; */
        for (j = 0; j < l; j += 1) {
            s = pt_s[j];
            a = data[j];
            b = data[l + j];
            t.re = Re(b) * Re(s) - Im(b) * Im(s);
            t.im = Im(b) * Re(s) + Re(b) * Im(s);
            b.re = Re(a) - Re(t);
            b.im = Im(a) - Im(t);
            a.re += t.re;
            a.im += t.im;
            data[j] = a;
            data[l + j] = b;
        }
        data += l * 2;
    }

    return i;
}

int fft_combine_s(const complex_s *pt_s, complex_s *data, int l, int m)
{
    complex_s s, a, b, t;
    int i, j;

    for (i = 0; i < m; i += 1) {
        /* pt_s = cs + n * 2; */
        for (j = 0; j < l; j += 1) {
            s = pt_s[j];
            a = data[j];
            b = data[l + j];
            t.re = Re(b) * Re(s) - Im(b) * Im(s);
            t.im = Im(b) * Re(s) + Re(b) * Im(s);
            b.re = Re(a) - Re(t);
            b.im = Im(a) - Im(t);
            a.re += t.re;
            a.im += t.im;
            data[j] = a;
            data[l + j] = b;
        }
        data += l * 2;
    }

    return i;
}

#endif  /* ASSEMBLY_FFT */
