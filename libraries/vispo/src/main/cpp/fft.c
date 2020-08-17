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

#ifdef VISPO_ALLOC

int vispo_fft_alloc_d(struct vispo_fft_d *fft, int n)
{
    fft->tables = (complex_d *) vispo_alloc_pages(n * 2 * sizeof(complex_d));
    if (!fft->tables)
        return -1;

    fft->size = n;

    return 0;
}

int vispo_fft_alloc_s(struct vispo_fft_s *fft, int n)
{
    fft->tables = (complex_s *) vispo_alloc_pages(n * 2 * sizeof(complex_s));
    if (!fft->tables)
        return -1;

    fft->size = n;

    return 0;
}

int vispo_fft_free_d(struct vispo_fft_d *fft)
{
    vispo_free_pages((void *) fft->tables, fft->size * 2 * sizeof(complex_d));

    return 0;
}

int vispo_fft_free_s(struct vispo_fft_s *fft)
{
    vispo_free_pages((void *) fft->tables, fft->size * 2 * sizeof(complex_s));

    return 0;
}

#endif

/**
 *  factorize() - find odd prime factors of N
 *  Example: n = 45, factors = { 3, 3, 5 }
 *  @factors - array of integers, at least VISP_MAX_FACTORS long
 *  @n - number to factorize
 *  Returns: number of factors found
 */

static int factorize(int *factors, int max, int n)
{
    int d = 3;
    int i;

    for (i = 0; i < max; i += 1)
        factors[i] = 0;

    i = 0;
    while (d * d <= n) {
        while (n % d == 0) {
            factors[i++] = d;
            n /= d;
        }
        d += 2;
    }

    if (n > 1)
        factors[i++] = n;

    return i;
}

/**
 *  fft_setup() - prepare complex sinusoid tables for fft_... functions
 *  for dft... functions, table (cs + n) can be used
 *  @fft - initialized vispo_fft structure, @fft.tables at least @n * 2 elements of complex type
 *  @n - size of the transform
 *  @inverse - direction: 0 - forward, 1 - inverse
 */

int vispo_fft_setup_d(struct vispo_fft_d *fft, int inverse)
{
    complex_d *cs = fft->tables;
    int n = fft->size;
	int i, j;

	if (n == 0)
		return 0;

	vispo_dft_setup_d(cs + n, n, inverse);

	while (!(n & 1)) {
		n >>= 1;
		j = n * 2;
		for (i = 0; i < n; i += 1) {
			cs[n + i] = cs[j];
			j += 2;
		}
	}

	for (i = 0; i < n; i += 1) {
		cs[i].re = 0;
		cs[i].im = 0;
	}

	cs[0].im = inverse ? 1 : -1;

	return n;
}

int vispo_fft_setup_s(struct vispo_fft_s *fft, int inverse)
{
    complex_s *cs = fft->tables;
    int n = fft->size;
	int i, j;

	if (n == 0)
		return 0;

	vispo_dft_setup_s(cs + n, n, inverse);

	while (!(n & 1)) {
		n >>= 1;
		j = n * 2;
		for (i = 0; i < n; i += 1) {
			cs[n + i] = cs[j];
			j += 2;
		}
	}

	for (i = 0; i < n; i += 1) {
		cs[i].re = 0;
		cs[i].im = 0;
	}

	cs[0].im = inverse ? 1 : -1;

	return n;
}

#ifndef ASSEMBLY_BITREV

int bit_reverse(int i, int bits)
{
	unsigned int x = i;

	x = ((x & 0xffff0000) >> 16) | ((x & 0x0000ffff) << 16);
	x = ((x & 0xff00ff00) >>  8) | ((x & 0x00ff00ff) <<  8);
	x = ((x & 0xf0f0f0f0) >>  4) | ((x & 0x0f0f0f0f) <<  4);
	x = ((x & 0xcccccccc) >>  2) | ((x & 0x33333333) <<  2);
	x = ((x & 0xaaaaaaaa) >>  1) | ((x & 0x55555555) <<  1);

	return x >> (32 - bits);
}

#endif

/**
 *  fft_combine_loop() - combine M * N spectrum pairs, L points each
 *  into N spectra, L * M * 2 points each
 *
 *  @cs - complex sinusoid tables, prepared by fft_setup()
 */

static int fft_combine_loop_s(const complex_s *ww, complex_s *data, int l, int m, int n)
{
	if (l == 1 && (m & 7) == 0) {
		if (ww[5].im < 0) {
            m >>= 3;
			fft8_fwd_s(ww + 8, data, m * n);
			l <<= 3;
		} else {
			m >>= 3;
			fft8_inv_s(ww + 8, data, m * n);
			l <<= 3;
		}
	}

    if (l == 1 && (m & 3) == 0) {
		if (ww[5].im < 0) {
			m >>= 2;
			fft4_fwd_s(data, m * n);
			l <<= 2;
		} else {
			m >>= 2;
			fft4_inv_s(data, m * n);
			l <<= 2;
		}
    }

	while (!(m & 1)) {
		m >>= 1;
		fft_combine_s(ww + l * 2, data, l, m * n);
		l <<= 1;
	}

	return m;
}

static int fft_combine_loop_d(const complex_d *ww, complex_d *data, int l, int m, int n)
{
	if (l == 1 && (m & 7) == 0) {
		if (ww[5].im < 0) {
			m >>= 3;
			fft8_fwd_d(ww + 8, data, m * n);
			l <<= 3;
		} else {
			m >>= 3;
			fft8_inv_d(ww + 8, data, m * n);
			l <<= 3;
		}
	}

	if (l == 1 && (m & 3) == 0) {
		if (ww[0].im < 0) {
			m >>= 2;
			fft4_fwd_d(data, m * n);
			l <<= 2;
		} else {
			m >>= 2;
			fft4_inv_d(data, m * n);
			l <<= 2;
		}
	}

	while (!(m & 1)) {
		m >>= 1;
		fft_combine_d(ww + l * 2, data, l, m * n);
		l <<= 1;
	}

	return m;
}

/**
 *  fft_combine_loop_multichannel() - combine M spectrum pairs, L points each
 *  into one spectrum (L * M * 2 points) for N interleaved channels
 *
 *  @cs - complex sinusoid tables, prepared by fft_setup()
 */

static int fft_combine_loop_multichannel_s(const complex_s *ww, complex_s *data, int l, int m, int n)
{
    while (!(m & 1)) {
        m >>= 1;
        fft_combine_multichannel_s(ww + l * 2, data, l, m, n);
        l <<= 1;
    }

    return m;
}

static int fft_combine_loop_multichannel_d(const complex_d *ww, complex_d *data, int l, int m, int n)
{
    while (!(m & 1)) {
        m >>= 1;
        fft_combine_multichannel_d(ww + l * 2, data, l, m, n);
        l <<= 1;
    }

    return m;
}

/**
 *  fft_complex() - compute FFT from complex data
 */

static int __fft_complex_d(const complex_d *ww,
    complex_d *out, const complex_d *in, int size, int signals)
{
    complex_d *data = out;
	int i, j, k;
	int bits = 0;
	int l = size;
	int m = 1;
	int n = signals;

	/* length = l * m,  m = 2 ^ bits */

	while (l > 1) {
		if (l & 1)
			break;
		l >>= 1;
		m <<= 1;
		bits += 1;
	}

	for (j = 0; j < n; j += 1) {
		for (i = 0; i < m; i += 1) {
			k = bit_reverse(i, bits);

			if (l > 1) {
				vispo_dft_complex_step_d(ww + l, out + k * l, in + i, l, 1, m);
			} else {
				out[k] = in[i];
			}
		}
		in += size;
		out += size;
	}

	return fft_combine_loop_d(ww, data, l, m, n);
}

static int __fft_complex_multichannel_d(struct vispo_fft_d *fft,
        complex_d *out, const complex_d *in, int size, int channels)
{
    int i, j, k;
    int bits = 0;
    int l = size;
    int m = 1;
    int n = channels;
    complex_d *ww = fft->tables;

    /* length = l * m,  m = 2 ^ bits */

    while (l > 1) {
        if (l & 1)
            break;
        l >>= 1;
        m <<= 1;
        bits += 1;
    }

    for (i = 0; i < m; i += 1) {
        j = bit_reverse(i, bits);

        if (l > 1) {
            for(k = 0; k < n; k += 1)
                vispo_dft_complex_step_d(ww + l, out + j * l * n + k, in + i * n + k, l, n, m * n);
        } else {
            for(k = 0; k < n; k += 1)
                out[j * n + k] = in[i * n + k];
        }
    }

    return fft_combine_loop_multichannel_d(ww, out, l, m, n);
}

int vispo_fft_complex_d(struct vispo_fft_d *fft,
    complex_d *out, const complex_d *in, int signals)
{
    return __fft_complex_d(fft->tables, out, in, fft->size, signals);
}

int vispo_fft_complex_multichannel_d(struct vispo_fft_d *fft,
                        complex_d *out, const complex_d *in, int channels)
{
    return __fft_complex_multichannel_d(fft, out, in, fft->size, channels);
}

static int __fft_complex_s(struct vispo_fft_s *fft,
    complex_s *out, const complex_s *in, int size, int signals)
{
    complex_s *data = out;
	int i, j, k;
	int bits = 0;
	int m = 1;
	int l = size;
	int n = signals;
    complex_s *ww = fft->tables;

	/* length = l * m,  m = 2 ^ bits */

	while (l > 1) {
		if (l & 1)
			break;
		l >>= 1;
		m <<= 1;
		bits += 1;
	}

	for (j = 0; j < n; j += 1) {
		for (i = 0; i < m; i += 1) {
			k = bit_reverse(i, bits);

			if (l > 1) {
				vispo_dft_complex_step_s(ww + l, out + k * l, in + i, l, 1, m);
			} else {
				out[k] = in[i];
			}
		}
		in += size;
		out += size;
	}

	return fft_combine_loop_s(ww, data, l, m, n);
}

static int __fft_complex_multichannel_s(struct vispo_fft_s *fft,
                           complex_s *out, const complex_s *in, int size, int channels)
{
    int i, j, k;
    int bits = 0;
    int l = size;
    int m = 1;
    int n = channels;
    complex_s *ww = fft->tables;

    /* length = l * m,  m = 2 ^ bits */

    while (l > 1) {
        if (l & 1)
            break;
        l >>= 1;
        m <<= 1;
        bits += 1;
    }

    for (i = 0; i < m; i += 1) {
        j = bit_reverse(i, bits);

        if (l > 1) {
            for(k = 0; k < n; k += 1)
                vispo_dft_complex_step_s(ww + l, out + j * l * n + k, in + i * n + k, l, n, m * n);
        } else {
            for(k = 0; k < n; k += 1)
                out[j * n + k] = in[i * n + k];
        }
    }

    return fft_combine_loop_multichannel_s(ww, out, l, m, n);
}

int vispo_fft_complex_s(struct vispo_fft_s *fft,
   complex_s *out, const complex_s *in, int signals)
{
    return __fft_complex_s(fft, out, in, fft->size, signals);
}

int vispo_fft_complex_multichannel_s(struct vispo_fft_s *fft,
						complex_s *out, const complex_s *in, int n)
{
	return __fft_complex_multichannel_s(fft, out, in, fft->size, n);
}

/**
 *  fft_real_odd() - compute FFT from real data, odd size
 */

int fft_real_odd_d(const complex_d *cs, complex_d *out, const double *in, int size)
{
	int i, j;
	int bits = 0;
	int m = 1;
	int n = size;

	/* length = m * n,  m = 2 ^ bits */

	while (n > 1) {
		if (n & 1)
			break;
		n >>= 1;
		m <<= 1;
		bits += 1;
	}

	for (i = 0; i < m; i += 1) {
		j = bit_reverse(i, bits);

		if (n > 1) {
			vispo_dft_real_step_d(cs + n, out + j * n, in + i, n, 1, m);
		} else {
			out[j].re = in[i];
			out[j].im = 0;
		}
	}

	return fft_combine_loop_d(cs, out, n, m, 1);
}


int fft_real_odd_s(const complex_s *cs, complex_s *out, const float *in, int size)
{
	int i, j, k;
	int bits = 0;
	int m = 1;
	int n = size;

	/* length = m * n,  m = 2 ^ bits */

	while (n > 1) {
		if (n & 1)
			break;
		n >>= 1;
		m <<= 1;
		bits += 1;
	}

	for (i = 0; i < m; i += 1) {
		j = bit_reverse(i, bits);

		if (n > 1) {
			vispo_dft_real_step_s(cs + n, out + j * n, in + i, n, 1, m);
		} else {
			out[j].re = in[i];
			out[j].im = 0;
		}
	}

	if (m == 1)
		return 1;

	return fft_combine_loop_s(cs, out, n, m, 1);
}

/**
 *  fft_real() - compute FFT from real data
 *  @sig - real input signal
 *  @n - FFT size
 */

int vispo_fft_real_d(struct vispo_fft_d *fft,
    complex_d *out, const double *input)
{
    const complex_d *cs = fft->tables;
    int n = fft->size;
	complex_d a, b;
	int c, quarter;
	int i, j;

	if (n & 3)
		return fft_real_odd_d(cs, out, input, n);

	c = n / 2;
	quarter = n / 4;

	/*
	 *  casting the pointer makes the real signal
	 *  seen as complex signal with size N/2
	 *  sig'[i].re = sig[i * 2]
	 *  sig'[i].im = sig[i * 2 + 1]
	 */

	__fft_complex_d(cs, out, (const complex_d *) input, c, 1);

	/* odd-even decomposition */

	i = 0;

	out[c + i].re = out[i].im;
	out[c + i].im = 0;
	out[i].im = 0;

	for (i = 1; i < quarter; i += 1) {
		j = c - i;
		a.re = out[i].re / 2;
		a.im = out[i].im / 2;
		b.re = out[j].re / 2;
		b.im = out[j].im / 2;
		out[c + i].re = b.im + a.im;
		out[c + i].im = b.re - a.re;
		out[c + j].re = a.im + b.im;
		out[c + j].im = a.re - b.re;
		out[j].re = b.re + a.re;
		out[j].im = b.im - a.im;
		out[i].re = a.re + b.re;
		out[i].im = a.im - b.im;
	}

	out[c + i].re = out[i].im;
	out[c + i].im = 0;
	out[i].im = 0;

	return fft_combine_loop_d(cs, out, c, 2, 1);
}

int vispo_fft_real_s(struct vispo_fft_s *fft,
    complex_s *out, const float *input)
{
    const complex_s *cs = fft->tables;
    int n = fft->size;
	complex_s a, b;
	int c, quarter;
	int i, j;

	if (n & 3)
		return fft_real_odd_s(cs, out, input, n);

	c = n / 2;
	quarter = n / 4;

	/*
	 *  casting the pointer makes the real signal
	 *  seen as complex signal with size N/2
	 *  sig'[i].re = sig[i * 2]
	 *  sig'[i].im = sig[i * 2 + 1]
	 */

	__fft_complex_s(fft, out, (const complex_s *) input, c, 1);

	/* odd-even decomposition */

	i = 0;

	out[c + i].re = out[i].im;
	out[c + i].im = 0;
	out[i].im = 0;

	for (i = 1; i < quarter; i += 1) {
		j = c - i;
		a.re = out[i].re / 2;
		a.im = out[i].im / 2;
		b.re = out[j].re / 2;
		b.im = out[j].im / 2;
		out[c + i].re = b.im + a.im;
		out[c + i].im = b.re - a.re;
		out[c + j].re = a.im + b.im;
		out[c + j].im = a.re - b.re;
		out[j].re = b.re + a.re;
		out[j].im = b.im - a.im;
		out[i].re = a.re + b.re;
		out[i].im = a.im - b.im;
	}

	out[c + i].re = out[i].im;
	out[c + i].im = 0;
	out[i].im = 0;

	return fft_combine_loop_s(cs, out, c, 2, 1);
}
