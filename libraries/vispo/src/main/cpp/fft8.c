#ifndef VISPO_ASSEMBLY_FFT8

#include "vispo.h"

/*
 *  An efficient 8-point FFT implementation
 */

int fft8_fwd_s(const complex_s *s, complex_s *data, int m)
{
    complex_s a, b, c, d, e, f, g, h;
    complex_s t;
    int i;

    for (i = 0; i < m; i += 1) {
        a = data[0];
        b = data[1];
        c = data[2];
        d = data[3];
        e = data[4];
        f = data[5];
        g = data[6];
        h = data[7];

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
        t = f;
        f.re = e.re - t.re;
        f.im = e.im - t.im;
        e.re += t.re;
        e.im += t.im;
        t = h;
        h.re = g.re - t.re;
        h.im = g.im - t.im;
        g.re += t.re;
        g.im += t.im;

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
        t = g;
        g.re = e.re - t.re;
        g.im = e.im - t.im;
        e.re += t.re;
        e.im += t.im;
        t = h;
        h.re = f.re - t.im;
        h.im = f.im + t.re;
        f.re += t.im;
        f.im -= t.re;

        t.re = e.re * s[0].re - e.im * s[0].im;
        t.im = e.re * s[0].im + e.im * s[0].re;
        e.re = a.re - t.re;
        e.im = a.im - t.im;
        a.re += t.re;
        a.im += t.im;
        t.re = f.re * s[1].re - f.im * s[1].im;
        t.im = f.re * s[1].im + f.im * s[1].re;
        f.re = b.re - t.re;
        f.im = b.im - t.im;
        b.re += t.re;
        b.im += t.im;
        t.re = g.re * s[2].re - g.im * s[2].im;
        t.im = g.re * s[2].im + g.im * s[2].re;
        g.re = c.re - t.re;
        g.im = c.im - t.im;
        c.re += t.re;
        c.im += t.im;
        t.re = h.re * s[3].re - h.im * s[3].im;
        t.im = h.re * s[3].im + h.im * s[3].re;
        h.re = d.re - t.re;
        h.im = d.im - t.im;
        d.re += t.re;
        d.im += t.im;

        data[0] = a;
        data[1] = b;
        data[2] = c;
        data[3] = d;
        data[4] = e;
        data[5] = f;
        data[6] = g;
        data[7] = h;

        data += 8;
    }

    return m;
}

int fft8_inv_s(const complex_s *s, complex_s *data, int m)
{
    complex_s a, b, c, d, e, f, g, h;
    complex_s t;
    int i;

    for (i = 0; i < m; i += 1) {
        a = data[0];
        b = data[1];
        c = data[2];
        d = data[3];
        e = data[4];
        f = data[5];
        g = data[6];
        h = data[7];

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
        t = f;
        f.re = e.re - t.re;
        f.im = e.im - t.im;
        e.re += t.re;
        e.im += t.im;
        t = h;
        h.re = g.re - t.re;
        h.im = g.im - t.im;
        g.re += t.re;
        g.im += t.im;

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
        t = g;
        g.re = e.re - t.re;
        g.im = e.im - t.im;
        e.re += t.re;
        e.im += t.im;
        t = h;
        h.re = f.re + t.im;
        h.im = f.im - t.re;
        f.re -= t.im;
        f.im += t.re;

        t.re = e.re * s[0].re - e.im * s[0].im;
        t.im = e.re * s[0].im + e.im * s[0].re;
        e.re = a.re - t.re;
        e.im = a.im - t.im;
        a.re += t.re;
        a.im += t.im;
        t.re = f.re * s[1].re - f.im * s[1].im;
        t.im = f.re * s[1].im + f.im * s[1].re;
        f.re = b.re - t.re;
        f.im = b.im - t.im;
        b.re += t.re;
        b.im += t.im;
        t.re = g.re * s[2].re - g.im * s[2].im;
        t.im = g.re * s[2].im + g.im * s[2].re;
        g.re = c.re - t.re;
        g.im = c.im - t.im;
        c.re += t.re;
        c.im += t.im;
        t.re = h.re * s[3].re - h.im * s[3].im;
        t.im = h.re * s[3].im + h.im * s[3].re;
        h.re = d.re - t.re;
        h.im = d.im - t.im;
        d.re += t.re;
        d.im += t.im;

        data[0] = a;
        data[1] = b;
        data[2] = c;
        data[3] = d;
        data[4] = e;
        data[5] = f;
        data[6] = g;
        data[7] = h;

        data += 8;
    }

    return m;
}

int fft8_fwd_d(const complex_d *s, complex_d *data, int m)
{
    complex_d a, b, c, d, e, f, g, h;
    complex_d t;
    int i;

    for (i = 0; i < m; i += 1) {
        a = data[0];
        b = data[1];
        c = data[2];
        d = data[3];
        e = data[4];
        f = data[5];
        g = data[6];
        h = data[7];

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
        t = f;
        f.re = e.re - t.re;
        f.im = e.im - t.im;
        e.re += t.re;
        e.im += t.im;
        t = h;
        h.re = g.re - t.re;
        h.im = g.im - t.im;
        g.re += t.re;
        g.im += t.im;

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
        t = g;
        g.re = e.re - t.re;
        g.im = e.im - t.im;
        e.re += t.re;
        e.im += t.im;
        t = h;
        h.re = f.re - t.im;
        h.im = f.im + t.re;
        f.re += t.im;
        f.im -= t.re;

        t.re = e.re * s[0].re - e.im * s[0].im;
        t.im = e.re * s[0].im + e.im * s[0].re;
        e.re = a.re - t.re;
        e.im = a.im - t.im;
        a.re += t.re;
        a.im += t.im;
        t.re = f.re * s[1].re - f.im * s[1].im;
        t.im = f.re * s[1].im + f.im * s[1].re;
        f.re = b.re - t.re;
        f.im = b.im - t.im;
        b.re += t.re;
        b.im += t.im;
        t.re = g.re * s[2].re - g.im * s[2].im;
        t.im = g.re * s[2].im + g.im * s[2].re;
        g.re = c.re - t.re;
        g.im = c.im - t.im;
        c.re += t.re;
        c.im += t.im;
        t.re = h.re * s[3].re - h.im * s[3].im;
        t.im = h.re * s[3].im + h.im * s[3].re;
        h.re = d.re - t.re;
        h.im = d.im - t.im;
        d.re += t.re;
        d.im += t.im;

        data[0] = a;
        data[1] = b;
        data[2] = c;
        data[3] = d;
        data[4] = e;
        data[5] = f;
        data[6] = g;
        data[7] = h;

        data += 8;
    }

    return m;
}

int fft8_inv_d(const complex_d *s, complex_d *data, int m)
{
    complex_d a, b, c, d, e, f, g, h;
    complex_d t;
    int i;

    for (i = 0; i < m; i += 1) {
        a = data[0];
        b = data[1];
        c = data[2];
        d = data[3];
        e = data[4];
        f = data[5];
        g = data[6];
        h = data[7];

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
        t = f;
        f.re = e.re - t.re;
        f.im = e.im - t.im;
        e.re += t.re;
        e.im += t.im;
        t = h;
        h.re = g.re - t.re;
        h.im = g.im - t.im;
        g.re += t.re;
        g.im += t.im;

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
        t = g;
        g.re = e.re - t.re;
        g.im = e.im - t.im;
        e.re += t.re;
        e.im += t.im;
        t = h;
        h.re = f.re + t.im;
        h.im = f.im - t.re;
        f.re -= t.im;
        f.im += t.re;

        t.re = e.re * s[0].re - e.im * s[0].im;
        t.im = e.re * s[0].im + e.im * s[0].re;
        e.re = a.re - t.re;
        e.im = a.im - t.im;
        a.re += t.re;
        a.im += t.im;
        t.re = f.re * s[1].re - f.im * s[1].im;
        t.im = f.re * s[1].im + f.im * s[1].re;
        f.re = b.re - t.re;
        f.im = b.im - t.im;
        b.re += t.re;
        b.im += t.im;
        t.re = g.re * s[2].re - g.im * s[2].im;
        t.im = g.re * s[2].im + g.im * s[2].re;
        g.re = c.re - t.re;
        g.im = c.im - t.im;
        c.re += t.re;
        c.im += t.im;
        t.re = h.re * s[3].re - h.im * s[3].im;
        t.im = h.re * s[3].im + h.im * s[3].re;
        h.re = d.re - t.re;
        h.im = d.im - t.im;
        d.re += t.re;
        d.im += t.im;

        data[0] = a;
        data[1] = b;
        data[2] = c;
        data[3] = d;
        data[4] = e;
        data[5] = f;
        data[6] = g;
        data[7] = h;

        data += 8;
    }

    return m;
}

#endif  /* VISPO_ASSEMBLY_FFT8 */
