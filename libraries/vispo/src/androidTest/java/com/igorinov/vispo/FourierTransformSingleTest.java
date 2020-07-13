package com.igorinov.vispo;

import org.junit.Test;

import java.util.Random;

import static org.junit.Assert.*;

public class FourierTransformSingleTest {
    static float delta = 1e-6f;

    /**
     * Compute sum of squared array elements using compensated summation
     * @param data Input array
     * @return Sum of squared array elements
     */
    private float powersum(float[] data) {
        int length = data.length;
        int i;
        float sum = 0;
        float comp = 0;
        float next;
        float x;

        for (i = 0; i < length; i += 1) {
            x = data[i];
            comp += x * x;
            next = sum + comp;
            comp -= (next - sum);
            sum = next;
        }

        return sum;
    }

    @Test
    public void fftComplex6() {
        FourierTransform.Single ft = new FourierTransform.Single(6, false);
        float[] a = new float[12];
        float[] b = new float[12];
        float[] b_exp = new float[12];
        float hsqrt3 = (float) Math.sqrt(3) / 2f;
        int i;

        for (i = 0; i < 12; i += 1)
            b_exp[i] = 0;

        b_exp[2] = 6;

        a[0] = +1;
        a[1] = 0;

        a[2] = +0.5f;
        a[3] = +hsqrt3;

        a[4] = -0.5f;
        a[5] = +hsqrt3;

        a[6] = -1;
        a[7] = 0;

        a[8] = -0.5f;
        a[9] = -hsqrt3;

        a[10] = +0.5f;
        a[11] = -hsqrt3;

        ft.fft(b, a);
        assertArrayEquals(b_exp, b, delta);
    }

    @Test
    public void fftReal4() {
        FourierTransform.Single ft = new FourierTransform.Single(4, false);
        float[] a = new float[4];
        float[] b = new float[8];
        float[] b_exp = new float[8];
        int i;

        for (i = 0; i < 8; i += 1)
            b_exp[i] = 0;
        b_exp[4] = 4;

        a[0] = 1;
        a[1] = -1;
        a[2] = 1;
        a[3] = -1;

        ft.fftReal(b, a);
        assertArrayEquals(b_exp, b, delta);

        for (i = 0; i < 8; i += 1)
            b_exp[i] = 0;
        b_exp[2] = 2;
        b_exp[6] = 2;

        a[0] = 1;
        a[1] = 0;
        a[2] = -1;
        a[3] = 0;
        ft.fftReal(b, a);
        assertArrayEquals(b_exp, b, delta);
    }

    @Test
    public void fftReal8() {
        int n = 8;
        FourierTransform.Single ft = new FourierTransform.Single(n, false);
        float[] a = new float[n];
        float[] b = new float[n * 2];
        float[] b_exp = new float[n * 2];
        int i;

        for (i = 0; i < n * 2; i += 1)
            b_exp[i] = 0;

        b_exp[8] = 8;

        a[0] = +1;
        a[1] = -1;
        a[2] = +1;
        a[3] = -1;
        a[4] = +1;
        a[5] = -1;
        a[6] = +1;
        a[7] = -1;

        ft.fftReal(b, a);
        assertArrayEquals(b_exp, b, delta);

        for (i = 0; i < n * 2; i += 1)
            b_exp[i] = 0;

        b_exp[4] = 4;
        b_exp[12] = 4;

        a[0] = +1;
        a[1] = 0;
        a[2] = -1;
        a[3] = 0;
        a[4] = +1;
        a[5] = 0;
        a[6] = -1;
        a[7] = 0;
        ft.fftReal(b, a);
        assertArrayEquals(b_exp, b, delta);

        for (i = 0; i < n * 2; i += 1)
            b_exp[i] = 0;

        b_exp[2] = 4;
        b_exp[14] = 4;

        float hsqrt2 = (float) Math.sqrt(2) / 2;

        a[0] = +1;
        a[1] = +hsqrt2;
        a[2] = 0;
        a[3] = -hsqrt2;
        a[4] = -1;
        a[5] = -hsqrt2;
        a[6] = 0;
        a[7] = +hsqrt2;
        ft.fftReal(b, a);
        assertArrayEquals(b_exp, b, delta);
    }

    private void ForwardInverse(int n) {
        Random random = new Random();
        float[] data0 = new float[n * 2];
        float[] data1 = new float[n * 2];
        float[] data2 = new float[n * 2];
        float power0, power1;
        FourierTransform.Single forward = new FourierTransform.Single(n, false);
        FourierTransform.Single inverse = new FourierTransform.Single(n, true);
        int i;

        for (i = 0; i < n * 2; i += 1) {
            data0[i] = (random.nextInt(65535) - 32767) / 32768f;
            data1[i] = Float.NaN;
            data2[i] = Float.NaN;
        }

        power0 = powersum(data0);

        forward.fft(data1, data0);

        power1 = powersum(data1);

        // Parseval's equation check
        float powerRatio = power1 / power0;
        assertEquals(powerRatio / n, 1, delta);

        inverse.fft(data2, data1);

        // Scale back the output of reverse transform
        float rn = 1f / n;
        for (i = 0; i < n * 2; i += 1) {
            data2[i] *= rn;
        }

        // Should match the input of forward transform
        assertArrayEquals(data2, data0, delta);
    }

    @Test
    public void ForwardInverse1() {
        ForwardInverse(1);
    }

    @Test
    public void ForwardInverse2() {
        ForwardInverse(2);
    }

    @Test
    public void ForwardInverse6() {
        ForwardInverse(6);
    }

    @Test
    public void ForwardInverse720() {
        ForwardInverse(720);
    }

    @Test
    public void ForwardInverse1080() {
        ForwardInverse(1080);
    }

    @Test
    public void ForwardInverse2160() {
        ForwardInverse(2160);
    }

    @Test
    public void ForwardInverse4K() {
        ForwardInverse(4096);
    }

    @Test
    public void ForwardInverse64K() {
        ForwardInverse(65536);
    }

    @Test
    public void ForwardInverse1M() {
        ForwardInverse(1048576);
    }
}