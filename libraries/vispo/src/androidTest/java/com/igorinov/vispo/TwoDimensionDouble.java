package com.igorinov.vispo;

import org.junit.Test;

import static org.junit.Assert.*;

public class TwoDimensionDouble {
    static double delta = 1e-9f;

    static void TwoDimension(int width, int height) {
        double[] x, temp, test;
        int fx = 5;
        int fy = 7;
        x = new double[width * height * 2];
        temp = new double[width * height * 2];
        test = new double[width * height * 2];
        double dphx = 2 * Math.PI * fx / width;
        double dphy = 2 * Math.PI * fy / height;
        double scale = 1.0 / (width * height);
        FourierTransform.Double fftX = new FourierTransform.Double(width, false);
        FourierTransform.Double fftY = new FourierTransform.Double(height, false);
        int i, j, k;

        k = 0;
        for (i = 0; i < height; i += 1) {
            for (j = 0; j < width; j += 1) {
                x[k++] = scale * Math.cos(i * dphy + j * dphx);
                x[k++] = scale * Math.sin(i * dphy + j * dphx);
            }
        }
        fftX.fft(temp, x, height);
        fftY.fftMultichannel(x, temp, width);
        test[(fy * width + fx) * 2] = 1;
        assertArrayEquals(test, x, delta);

    }

    @Test
    public void TwoDimension8x8() {
        TwoDimension(8,8);
    }


    @Test
    public void TwoDimension32x32() {
        TwoDimension(32,32);
    }

    @Test
    public void TwoDimension256x256() {
        TwoDimension(64,64);
    }
}