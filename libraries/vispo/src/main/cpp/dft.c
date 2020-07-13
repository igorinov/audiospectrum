/**
 *  Copyright (C) 2016 Ivan Gorinov
 *
 *  SPDX-License-Identifier: BSD-2-Clause
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

#include "vispo.h"

/**
 *  dft_setup() - prepare complex sinusoid table to use with dft_... functions
 *  for fft_... functions, use fft_setup()
 *  @s - buffer for sinusoid table, @n elements of complex type
 *  @n - size of the transform
 *  @inverse - direction: 0 - forward, 1 - inverse
 */

int vispo_dft_setup_d(complex_d *s, int n, int inverse)
{
    double da;
    double t;
    int sign = inverse ? 1 : -1;
    int c, q, i;

    if (n == 0)
        return 0;

    da = 2 * M_PI / n;

    s[0].re = 1;
    s[0].im = 0;

    if ((n & 1) == 0) {
        c = n / 2;
        if ((c & 1) == 0) {
            q = c / 2;
            for (i = 1; i < q; i += 1) {
                t = i * da;
                s[i].re = cos(t);
                s[q - i].im = s[i].re * sign;
            }
            s[q].re = 0;
            s[q].im = sign;
            for (i = 1; i < q; i += 1) {
                s[q + i].re = - s[q - i].re;
                s[q + i].im = s[q - i].im;
            }
        } else {
            for (i = 1; i < c; i += 1) {
                t = i * da;
                s[i].re = cos(t);
                s[i].im = sin(t) * sign;
            }
        }
        for (i = 0; i < c; i += 1) {
            s[c + i].re = - s[i].re;
            s[c + i].im = - s[i].im;
        }
    } else {
        /* n is odd */
        c = (n - 1) / 2;
        for (i = 1; i <= c; i += 1) {
            t = i * da;
            s[i].re = cos(t);
            s[i].im = sin(t) * sign;
        }
        for (i = c + 1; i < n; i += 1) {
            s[i].re = s[n - i].re;
            s[i].im = - s[n - i].im;
        }
    }

    return n;
}

int vispo_dft_setup_s(complex_s *s, int n, int inverse)
{
    double da;
    double t;
    int sign = inverse ? 1 : -1;
    int c, q, i;

    if (n == 0)
        return 0;

    da = 2 * M_PI / n;

    s[0].re = 1;
    s[0].im = 0;

    if ((n & 1) == 0) {
        c = n / 2;
        if ((c & 1) == 0) {
            q = c / 2;
            for (i = 1; i < q; i += 1) {
                t = i * da;
                s[i].re = cos(t);
                s[q - i].im = s[i].re * sign;
            }
            s[q].re = 0;
            s[q].im = sign;
            for (i = 1; i < q; i += 1) {
                s[q + i].re = - s[q - i].re;
                s[q + i].im = s[q - i].im;
            }
        } else {
            for (i = 1; i < c; i += 1) {
                t = i * da;
                s[i].re = cos(t);
                s[i].im = sin(t) * sign;
            }
        }
        for (i = 0; i < c; i += 1) {
            s[c + i].re = - s[i].re;
            s[c + i].im = - s[i].im;
        }
    } else {
        /* n is odd */
        c = (n - 1) / 2;
        for (i = 1; i <= c; i += 1) {
            t = i * da;
            s[i].re = cos(t);
            s[i].im = sin(t) * sign;
        }
        for (i = c + 1; i < n; i += 1) {
            s[i].re = s[n - i].re;
            s[i].im = - s[n - i].im;
        }
    }

    return n;
}

/**
 *  dft_complex() - simple DFT, any size
 *  @s - sinusoid table prepared by dft_setup()
 *  @data - input data
 *  @out - output buffer
 *  @n - number of points in @data and @out
 */

int vispo_dft_complex_d(const complex_d *cs,
    complex_d *output, const complex_d *input, int n)
{
    return vispo_dft_complex_step_d(cs, output, input, n, 1, 1);
}

int vispo_dft_complex_s(const complex_s *cs,
                        complex_s *output, const complex_s *input, int n)
{
    return vispo_dft_complex_step_s(cs, output, input, n, 1, 1);
}

/**
 *  dft_complex_step() - compute DFT of complex signal
 *  using compensated summation (Kahan's algorithm) to
 *  reduce numerical error
 *  @s - complex sinusoid table prepared by dft_setup()
 *  @input - input data
 *  @output - output buffer
 *  @n - number of rows
 *  @in_step - input data interleaving step
 */

int vispo_dft_complex_step_d(const complex_d *s,
    complex_d *output, const complex_d *input, int n, int in_step, int s_step)
{
    const complex_d *px, *ps;
    double acc[4];
    double inc[4];
    double sum[4];
    complex_d x;
    int i, j, k, si;
    int s_end = n * s_step;

    /* DC component */

    px = input;
    acc[0] = 0;
    acc[1] = 0;
    inc[0] = Re(*px);
    inc[1] = Im(*px);
    for (i = 1; i < n; i += 1) {
        px += in_step;
        inc[0] += Re(*px);
        inc[1] += Im(*px);
        for (j = 0; j < 2; j += 1) {
            sum[j] = acc[j] + inc[j];
            inc[j] -= (sum[j] - acc[j]);
            acc[j] = sum[j];
        }
    }
    output[0].re = acc[0];
    output[0].im = acc[1];

    for (k = 1; k < n; k += 1) {
        px = input;

        acc[0] = 0;
        acc[1] = 0;
        acc[2] = 0;
        acc[3] = 0;

        inc[0] = Re(*px);
        inc[1] = Im(*px);
        inc[2] = 0;
        inc[3] = 0;

        si = k * s_step;
        for (i = 1; i < n; i += 1) {
            px += in_step;
            ps = s + si;
            x = *px;

            inc[0] += Re(*ps) * Re(x);
            inc[1] += Re(*ps) * Im(x);
            inc[2] += Im(*ps) * Re(x);
            inc[3] += Im(*ps) * Im(x);

            for (j = 0; j < 4; j += 1)
                sum[j] = acc[j] + inc[j];

            for (j = 0; j < 4; j += 1)
                inc[j] -= (sum[j] - acc[j]);

            for (j = 0; j < 4; j += 1)
                acc[j] = sum[j];

            /*
             * si = (i * k) % n
             */
            si += k * s_step;
            if (si >= s_end)
                si -= s_end;
        }
        output[k].re = (acc[0] - acc[3]) + (inc[0] - inc[3]);
        output[k].im = (acc[1] + acc[2]) + (inc[1] + inc[2]);
    }

    return k;
}

int vispo_dft_complex_step_s(const complex_s *s,
    complex_s *output, const complex_s *input, int n, int in_step, int s_step)
{
    const complex_s *px, *ps;
    float acc[4];
    float inc[4];
    float sum[4];
    complex_s x;
    int i, j, k, si;
    int s_end = n * s_step;

    /* DC component */

    px = input;
    acc[0] = 0;
    acc[1] = 0;
    inc[0] = Re(*px);
    inc[1] = Im(*px);
    for (i = 1; i < n; i += 1) {
        px += in_step;
        inc[0] += Re(*px);
        inc[1] += Im(*px);
        for (j = 0; j < 2; j += 1) {
            sum[j] = acc[j] + inc[j];
            inc[j] -= (sum[j] - acc[j]);
            acc[j] = sum[j];
        }
    }
    output[0].re = acc[0];
    output[0].im = acc[1];

    for (k = 1; k < n; k += 1) {
        px = input;

        acc[0] = 0;
        acc[1] = 0;
        acc[2] = 0;
        acc[3] = 0;

        inc[0] = Re(*px);
        inc[1] = Im(*px);
        inc[2] = 0;
        inc[3] = 0;

        si = k * s_step;
        for (i = 1; i < n; i += 1) {
            px += in_step;
            ps = s + si;
            x = *px;

            inc[0] += Re(*ps) * Re(x);
            inc[1] += Re(*ps) * Im(x);
            inc[2] += Im(*ps) * Re(x);
            inc[3] += Im(*ps) * Im(x);

            for (j = 0; j < 4; j += 1)
                sum[j] = acc[j] + inc[j];

            for (j = 0; j < 4; j += 1)
                inc[j] -= (sum[j] - acc[j]);

            for (j = 0; j < 4; j += 1)
                acc[j] = sum[j];

            /*
             * si = (i * k) % n
             */
            si += k * s_step;
            if (si >= s_end)
                si -= s_end;
        }
        output[k].re = (acc[0] - acc[3]) + (inc[0] - inc[3]);
        output[k].im = (acc[1] + acc[2]) + (inc[1] + inc[2]);
    }

    return k;
}

/**
 *  dft_real_step() - compute DFT of real signal
 *  using Kahan's algorithm to reduce numerical error
 *  @s - complex sinusoid table prepared by dft_setup()
 *  @input - input data
 *  @output - output buffer
 *  @n - number of rows
 *  @in_step - interleaving step
 */

int vispo_dft_real_step_d(const complex_d *s,
    complex_d *output, const double *input, int n, int in_step, int f_step)
{
    const complex_d *ps;
    const double *pt;
    double acc[2];
    double inc[2];
    double sum[2];
    double x;
    int i, j, k, si, ss;
    int s_end = n * f_step;

    /* DC component */

    pt = input;
    acc[0] = *pt;
    inc[0] = 0;
    for (i = 1; i < n; i += 1) {
        pt += in_step;
        inc[0] += *pt;
        sum[0] = acc[0] + inc[0];
        inc[0] -= (sum[0] - acc[0]);
        acc[0] = sum[0];
    }
    output[0].re = acc[0];
    output[0].im = 0;

    ss = 0;
    for (k = 1; k < n; k += 1) {
        ss += f_step;
        pt = input;
        acc[0] = *pt;
        acc[1] = 0;
        inc[0] = 0;
        inc[1] = 0;

        for (j = 0; j < 2; j += 1)
            inc[j] = 0;

        si = ss;
        for (i = 1; i < n; i += 1) {
            pt += in_step;
            ps = s + si;
            x = *pt;

            inc[0] += x * Re(*ps);
            inc[1] += x * Im(*ps);

            /* this should be vectorized by SIMD-enabled compiler */

            for (j = 0; j < 2; j += 1)
                sum[j] = acc[j] + inc[j];

            for (j = 0; j < 2; j += 1)
                inc[j] -= (sum[j] - acc[j]);

            for (j = 0; j < 2; j += 1)
                acc[j] = sum[j];

            /*
             * si = (i * k) % n
             */
            si += ss;
            if (si >= s_end)
                si -= s_end;
        }
        output[k].re = acc[0];
        output[k].im = acc[1];
    }

    return k;
}

int vispo_dft_real_step_s(const complex_s *s,
    complex_s *output, const float *input, int n, int in_step, int f_step)
{
    const complex_s *ps;
    const float *pt;
    float acc[2];
    float inc[2];
    float sum[2];
    float x;
    int i, j, k, si, ss;
    int s_end = n * f_step;

    /* DC component */

    pt = input;
    acc[0] = *pt;
    inc[0] = 0;
    for (i = 1; i < n; i += 1) {
        pt += in_step;
        inc[0] += *pt;
        sum[0] = acc[0] + inc[0];
        inc[0] -= (sum[0] - acc[0]);
        acc[0] = sum[0];
    }
    output[0].re = acc[0];
    output[0].im = 0;

    ss = 0;
    for (k = 1; k < n; k += 1) {
        ss += f_step;
        pt = input;
        acc[0] = *pt;
        acc[1] = 0;
        inc[0] = 0;
        inc[1] = 0;

        for (j = 0; j < 2; j += 1)
            inc[j] = 0;

            si = ss;
        for (i = 1; i < n; i += 1) {
            pt += in_step;
            ps = s + si;
            x = *pt;

            inc[0] += x * ps->re;
            inc[1] += x * ps->im;

            #pragma clang loop vectorize_width(2) interleave_count(1)
            for (j = 0; j < 2; j += 1)
                sum[j] = acc[j] + inc[j];

            #pragma clang loop vectorize_width(2) interleave_count(1)
            for (j = 0; j < 2; j += 1)
                inc[j] -= (sum[j] - acc[j]);

            #pragma clang loop vectorize_width(2) interleave_count(1)
            for (j = 0; j < 2; j += 1)
                acc[j] = sum[j];

            /*
             * si = (i * k) % n
             */
            si += ss;
            if (si >= s_end)
                si -= s_end;
        }
        output[k].re = acc[0];
        output[k].im = acc[1];
    }

    return k;
}
