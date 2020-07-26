package com.igorinov.vispo;

import org.junit.Test;

import java.util.Random;

import static org.junit.Assert.*;

public class MultiChannelDouble {
    static double delta = 1e-6;

    private void MultiChannelTest(int l, int channels) {
        Random random = new Random();
        FourierTransform.Double forward = new FourierTransform.Double(l, false);

        double[] input = new double[l * channels * 2];
        double[] output = new double[l * channels * 2];
        double[] test = new double[l * channels * 2];
        double[] channelInput = new double[l * 2];
        double[] channelOutput = new double[l * 2];
        int i, j, k;

        for (k = 0; k < channels; k += 1) {
            j = k;
            for (i = 0; i < l; i += 1) {
                double re, im;
                re = (random.nextInt(65535) - 32767) / 32768f;
                im = (random.nextInt(65535) - 32767) / 32768f;

                // Copy the sample to the single channel buffer
                channelInput[i * 2] = re;
                channelInput[i * 2 + 1] = im;

                // Copy the sample to channel K in the multichannel buffer
                input[j * 2] = re;
                input[j * 2 + 1] = im;
                j += channels;
            }

            // Compute single channel K spectrum
            forward.fft(channelOutput, channelInput);

            // Copy channel K spectrum to the control buffer
            j = k;
            for (i = 0; i < l; i += 1) {
                double re, im;
                re = channelOutput[i * 2];
                im = channelOutput[i * 2 + 1];
                test[j * 2] = re;
                test[j * 2 + 1] = im;
                j += channels;
            }
        }
        forward.fftMultichannel(output, input, channels);
        assertArrayEquals(test, output, delta);
    }

    @Test
    public void fftMultichannel1() {
        MultiChannelTest(65536, 1);
    }

    @Test
    public void fftMultichannel2() {
        MultiChannelTest(32768, 2);
    }

    @Test
    public void fftMultichannel3x3() {
        MultiChannelTest(3, 3);
    }

    @Test
    public void fftMultichannel4() {
        MultiChannelTest(16384, 4);
    }

    @Test
    public void fftMultichannel8() {
        MultiChannelTest(8192, 8);
    }

    @Test
    public void fftMultichannel16() {
        MultiChannelTest(4096, 16);
    }

    @Test
    public void fftMultichannel64() {
        MultiChannelTest(1024, 64);
    }

    @Test
    public void fftMultichannel256() {
        MultiChannelTest(256, 256);
    }

    @Test
    public void fftMultichannel1K() {
        MultiChannelTest(1024, 1024);
    }

    @Test
    public void fftMultichannel1K3() {
        MultiChannelTest(1024, 3);
    }

    @Test
    public void fftMultichannel6x6() {
        MultiChannelTest(6, 6);
    }

    @Test
    public void fftMultichannel720() {
        MultiChannelTest(720, 720);
    }
}