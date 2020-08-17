package com.igorinov.vispo;

/**
 * Created by igorinov on 11/22/16.
 */
public class FourierTransform {

    public static native int fftSetupS(float[] ce, int size, boolean inverse);
    public static native int fftS(float[] ce, float[] out, float[] signal, int size, int signals);
    public static native int fftRealS(float[] ce, float[] out, float[] signal, int size);
    public static native int fftMultichannelS(float[] ce, float[] out, float[] signal, int size, int channels);

    public static native int fftSetupD(double[] ce, int size, boolean inverse);
    public static native int fftD(double[] ce, double[] out, double[] signal, int size, int signals);
    public static native int fftRealD(double[] ce, double[] out, double[] signal, int size);
    public static native int fftMultichannelD(double[] ce, double[] out, double[] signal, int size, int channels);

    public static class Single {
        float[] ce;
        int size;

        public Single(int n, boolean inverse) {
            size = n;
            ce = new float[size * 4];
            fftSetupS(ce, size, inverse);
        }

        public int fft(float[] out, float[] in, int signals) {
            return fftS(ce, out, in, size, signals);
        }

        public int fft(float[] out, float[] in) {
            return fftS(ce, out, in, size, 1);
        }

        public int fftReal(float[] out, float[] in) {
            return fftRealS(ce, out, in, size);
        }

        public int fftMultichannel(float[] out, float[] in, int channels) {
            return fftMultichannelS(ce, out, in, size, channels);
        }
    }

    public static class Double {
        double[] ce;
        int size;

        public Double(int n, boolean inverse) {
            size = n;
            ce = new double[size * 4];
            fftSetupD(ce, size, inverse);
        }

        public int fft(double[] out, double[] in, int signals) {
            return fftD(ce, out, in, size, signals);
        }

        public int fft(double[] out, double[] in) {
            return fftD(ce, out, in, size, 1);
        }

        public int fftReal(double[] out, double[] in) {
            return fftRealD(ce, out, in, size);
        }

        public int fftMultichannel(double[] out, double[] in, int channels) {
            return fftMultichannelD(ce, out, in, size, channels);
        }
    }

    static {
        try {
            System.loadLibrary("vispo");
        } catch (UnsatisfiedLinkError e) {
            e.printStackTrace();
        }
    }
}
