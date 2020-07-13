package com.igorinov.vispo;

import org.junit.Test;

import java.util.Random;

import static org.junit.Assert.*;

/**
 * Cross-check between single and double precision transform implementations
 */

public class FourierTransformCrossCheck {

    static float delta = 1e-6f;

    private void CrossCheck(int n) {
        Random random = new Random();
        float[] inS = new float[n * 2];
        float[] outS = new float[n * 2];
        double[] inD = new double[n * 2];
        double[] outD = new double[n * 2];
        FourierTransform.Single ftS = new FourierTransform.Single(n, false);
        FourierTransform.Double ftD = new FourierTransform.Double(n, false);
        int i;

        for (i = 0; i < n * 2; i += 1) {
            float x = (random.nextInt(65535) - 32767) / 32768f;
            inS[i] = x;
            inD[i] = x;
            outS[i] = Float.NaN;
            outD[i] = Double.NaN;
        }

        ftS.fft(outS, inS);
        ftD.fft(outD, inD);

        for (i = 0; i < n * 2; i += 1) {
            assertEquals(outS[i], (float) outD[i], delta * Math.sqrt(n));
        }
    }

    @Test
    public void CrossCheck() {
        CrossCheck(1);
    }

    @Test
    public void CrossCheck2() {
        CrossCheck(2);
    }

    @Test
    public void CrossCheck720() {
        CrossCheck(720);
    }

    @Test
    public void CrossCheck1080() {
        CrossCheck(1080);
    }

    @Test
    public void CrossCheck2160() {
        CrossCheck(2160);
    }

    @Test
    public void CrossCheck4K() {
        CrossCheck(4096);
    }

    @Test
    public void CrossCheck64K() {
        CrossCheck(65536);
    }

    @Test
    public void CrossCheck1M() {
        CrossCheck(1048576);
    }
}