package com.igorinov.vispo;

import org.junit.Test;

import static org.junit.Assert.*;

public class TwoDimensionSingle {
    static float delta = 1e-6f;

    static void TwoDimension(int width, int height) {
        float[] x, temp, test;
        int fx = 3;
        int fy = 5;
        x = new float[width * height * 2];
        temp = new float[width * height * 2];
        test = new float[width * height * 2];
        double dphx = 2 * Math.PI * fx / width;
        double dphy = 2 * Math.PI * fy / height;
        float scale = 1.0f / (width * height);
        FourierTransform.Single fftX = new FourierTransform.Single(width, false);
        FourierTransform.Single fftY = new FourierTransform.Single(height, false);
        int i, j, k;

        k = 0;
        for (i = 0; i < height; i += 1) {
            for (j = 0; j < width; j += 1) {
                x[k++] = scale * (float) Math.cos(i * dphy + j * dphx);
                x[k++] = scale * (float) Math.sin(i * dphy + j * dphx);
            }
        }

        // Transform the rows
        fftX.fft(temp, x, height);

        // Transform the columns
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
    public void TwoDimension64x64() {
        TwoDimension(64,64);
    }

    @Test
    public void TwoDimension256x256() {
        TwoDimension(256,256);
    }

    @Test
    public void TwoDimension1024x768() {
        TwoDimension(1024,768);
    }
}
