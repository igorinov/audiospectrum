#include "vispo.h"

#ifndef ASSEMBLY_FFT

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

#ifndef ASSEMBLY_FFT_MULTICHANNEL

/*
 *  @l - signal length
 *  @m - number of signals
 *  @n - number of interleaved channels
 */

int fft_combine_multichannel_s(const complex_s *pt_s, complex_s *data, int l, int m, int n)
{
    complex_s s, a, b, t;
    complex_s *aa, *bb;
    int i, j, k;

    for (i = 0; i < m; i += 1) {
        aa = data;
        bb = data + l * n;
        for (j = 0; j < l; j += 1) {
            s = pt_s[j];
            for (k = 0; k < n; k += 1) {
                a = aa[k];
                b = bb[k];
                t.re = Re(b) * Re(s) - Im(b) * Im(s);
                t.im = Im(b) * Re(s) + Re(b) * Im(s);
                b.re = Re(a) - Re(t);
                b.im = Im(a) - Im(t);
                a.re += t.re;
                a.im += t.im;
                aa[k] = a;
                bb[k] = b;
            }
            aa += n;
            bb += n;
        }
        data += l * n * 2;
    }

    return i;
}

int fft_combine_multichannel_d(const complex_d *pt_s, complex_d *data, int l, int m, int n)
{
    complex_d s, a, b, t;
    complex_d *aa, *bb;
    int i, j, k;

    for (i = 0; i < m; i += 1) {
        aa = data;
        bb = data + l * n;
        for (j = 0; j < l; j += 1) {
            s = pt_s[j];
            for (k = 0; k < n; k += 1) {
                a = aa[k];
                b = bb[k];
                t.re = Re(b) * Re(s) - Im(b) * Im(s);
                t.im = Im(b) * Re(s) + Re(b) * Im(s);
                b.re = Re(a) - Re(t);
                b.im = Im(a) - Im(t);
                a.re += t.re;
                a.im += t.im;
                aa[k] = a;
                bb[k] = b;
            }
            aa += n;
            bb += n;
        }
        data += l * n * 2;
    }

    return i;
}

#endif  /* ASSEMBLY_FFT_MULTICHANNEL */

#ifndef VISPO_ASSEMBLY_FFT4

/*
 *  An efficient 4-point FFT implementation
 */

int fft4_fwd_s(complex_s *data, int m)
{
    complex_s a, b, c, d, t;
    int i;

    for (i = 0; i < m; i += 1) {
        a = data[0];
        b = data[1];
        c = data[2];
        d = data[3];

        t = b;
        b.re = a.re - t.re;
        b.im = a.im - t.im;
        a.re += t.re;
        a.im += t.im;
        t = d;
        d.re = c.re - t.re;
        d.im = c.im - t.im;
        c.re += t.re;
        c.im += t.im;

        t = c;
        c.re = a.re - t.re;
        c.im = a.im - t.im;
        a.re += t.re;
        a.im += t.im;
        t = d;
        d.re = b.re - t.im;
        d.im = b.im + t.re;
        b.re += t.im;
        b.im -= t.re;

        data[0] = a;
        data[1] = b;
        data[2] = c;
        data[3] = d;

        data += 4;
    }

    return m;
}

int fft4_inv_s(complex_s *data, int m)
{
    complex_s a, b, c, d, t;
    int i;

    for (i = 0; i < m; i += 1) {
        a = data[0];
        b = data[1];
        c = data[2];
        d = data[3];

        t = b;
        b.re = a.re - t.re;
        b.im = a.im - t.im;
        a.re += t.re;
        a.im += t.im;
        t = d;
        d.re = c.re - t.re;
        d.im = c.im - t.im;
        c.re += t.re;
        c.im += t.im;

        t = c;
        c.re = a.re - t.re;
        c.im = a.im - t.im;
        a.re += t.re;
        a.im += t.im;
        t = d;
        d.re = b.re + t.im;
        d.im = b.im - t.re;
        b.re -= t.im;
        b.im += t.re;

        data[0] = a;
        data[1] = b;
        data[2] = c;
        data[3] = d;

        data += 4;
    }

    return m;
}

int fft4_fwd_d(complex_d *data, int m)
{
    complex_d a, b, c, d, t;
    int i;

    for (i = 0; i < m; i += 1) {
        a = data[0];
        b = data[1];
        c = data[2];
        d = data[3];

        t = b;
        b.re = a.re - t.re;
        b.im = a.im - t.im;
        a.re += t.re;
        a.im += t.im;
        t = d;
        d.re = c.re - t.re;
        d.im = c.im - t.im;
        c.re += t.re;
        c.im += t.im;

        t = c;
        c.re = a.re - t.re;
        c.im = a.im - t.im;
        a.re += t.re;
        a.im += t.im;
        t = d;
        d.re = b.re - t.im;
        d.im = b.im + t.re;
        b.re += t.im;
        b.im -= t.re;

        data[0] = a;
        data[1] = b;
        data[2] = c;
        data[3] = d;

        data += 4;
    }

    return m;
}

int fft4_inv_d(complex_d *data, int m)
{
    complex_d a, b, c, d, t;
    int i;

    for (i = 0; i < m; i += 1) {
        a = data[0];
        b = data[1];
        c = data[2];
        d = data[3];

        t = b;
        b.re = a.re - t.re;
        b.im = a.im - t.im;
        a.re += t.re;
        a.im += t.im;
        t = d;
        d.re = c.re - t.re;
        d.im = c.im - t.im;
        c.re += t.re;
        c.im += t.im;

        t = c;
        c.re = a.re - t.re;
        c.im = a.im - t.im;
        a.re += t.re;
        a.im += t.im;
        t = d;
        d.re = b.re + t.im;
        d.im = b.im - t.re;
        b.re -= t.im;
        b.im += t.re;

        data[0] = a;
        data[1] = b;
        data[2] = c;
        data[3] = d;

        data += 4;
    }

    return m;
}

#endif  /* VISPO_ASSEMBLY_FFT4 */
