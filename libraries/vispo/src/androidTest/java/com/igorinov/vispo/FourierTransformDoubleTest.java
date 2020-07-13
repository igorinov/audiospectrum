package com.igorinov.vispo;

import org.junit.Test;

import java.util.Random;

import static org.junit.Assert.*;

public class FourierTransformDoubleTest {
    static double delta = 1e-6;

    /**
     * Compute sum of squared array elements using compensated summation
     * @param data Input array
     * @return Sum of squared array elements
     */
    private double powersum(double[] data) {
        int length = data.length;
        int i;
        double sum = 0;
        double comp = 0;
        double next;
        double x;

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
        FourierTransform.Double ft = new FourierTransform.Double(6, false);
        double[] a = new double[12];
        double[] b = new double[12];
        double[] b_exp = new double[12];
        double hsqrt3 = Math.sqrt(3) / 2f;
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

    private void ForwardInverse(int n) {
        Random random = new Random();
        double[] data0 = new double[n * 2];
        double[] data1 = new double[n * 2];
        double[] data2 = new double[n * 2];
        double power0, power1;
        FourierTransform.Double forward = new FourierTransform.Double(n, false);
        FourierTransform.Double inverse = new FourierTransform.Double(n, true);
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
        double powerRatio = power1 / power0;
        assertEquals(powerRatio / n, 1, delta);

        inverse.fft(data2, data1);

        // Scale back the output of reverse transform
        double rn = 1f / n;
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