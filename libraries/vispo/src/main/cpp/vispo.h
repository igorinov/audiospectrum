/**
 *  Copyright (C) 2016 Ivan Gorinov
 *  License: BSD
 */

#ifndef __vispo_h
#define __vispo_h

#define Re(a) (a).re
#define Im(a) (a).im

typedef struct {
    double re;
    double im;
} complex_d;

typedef struct {
    float re;
    float im;
} complex_s;


#ifdef __cplusplus
extern "C" {
#endif

struct vispo_fft_s {
    complex_s *tables;
    complex_s *tmpbuf;
    int n;
};

struct vispo_fft_d {
    complex_d *tables;
    complex_d *tmpbuf;
    int n;
};

void vispo_init(void);

#ifdef VISPO_ALLOC

void *vispo_alloc_pages(int length);
int vispo_free_pages(void *address, int length);

int vispo_fft_alloc_s(struct vispo_fft_s *fft, int n);
int vispo_fft_alloc_d(struct vispo_fft_d *fft, int n);

int vispo_fft_free_s(struct vispo_fft_s *fft);
int vispo_fft_free_d(struct vispo_fft_d *fft);

#endif

int vispo_dft_setup_s(complex_s *w, int n, int inverse);
int vispo_dft_setup_d(complex_d *w, int n, int inverse);

int vispo_fft_setup_s(struct vispo_fft_s *fft, int inverse);
int vispo_fft_setup_d(struct vispo_fft_d *fft, int inverse);

int vispo_fft_complex_s(struct vispo_fft_s *fft, complex_s *out, const complex_s *in);
int vispo_fft_complex_d(struct vispo_fft_d *fft, complex_d *out, const complex_d *in);

int vispo_fft_real_s(struct vispo_fft_s *fft, complex_s *out, const float *in);
int vispo_fft_real_d(struct vispo_fft_d *fft, complex_d *out, const double *in);

int vispo_dft_complex_step_s(const complex_s *w, complex_s *output, const complex_s *input, int n, int in_step, int s_step);
int vispo_dft_complex_step_d(const complex_d *w, complex_d *output, const complex_d *input, int n, int in_step, int s_step);

int vispo_dft_real_step_s(const complex_s *w, complex_s *output, const float *input, int n, int in_step, int f_step);
int vispo_dft_real_step_d(const complex_d *w, complex_d *output, const double *input, int n, int in_step, int f_step);

int vispo_dft_complex_s(const complex_s *w, complex_s *output, const complex_s *input, int n);
int vispo_dft_complex_d(const complex_d *w, complex_d *output, const complex_d *input, int n);

int bit_reverse(int i, int bits);
int fft_combine_s(const complex_s *s, complex_s *data, int m, int n);
int fft_combine_d(const complex_d *s, complex_d *data, int m, int n);

#ifdef __cplusplus
}
#endif

#endif  /* __vispo_h */

