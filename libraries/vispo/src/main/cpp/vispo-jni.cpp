//
// Java interface for VISPO
//

#include <jni.h>

#include "vispo.h"

#define CLASS_NAME FourierTransform
#define CAT_NAMES(a, b, c, d) a ## _ ## b ## _ ## c ## _ ## d
#define JAVA_NAME(p, c, n) CAT_NAMES(Java, p, c, n)
#define FN_NAME(method) JAVA_NAME(PACKAGE_NAME, CLASS_NAME, method)

extern "C" JNIEXPORT jint JNICALL FN_NAME(fftSetupS)(JNIEnv *env, jclass jc,
    jfloatArray jce, jint size, jboolean inverse)
{
    vispo_fft_s fft;
    float *ce  = env->GetFloatArrayElements(jce, 0);

    fft.tables = (complex_s *) ce;
    fft.n = size;
    vispo_fft_setup_s(&fft, inverse);

    env->ReleaseFloatArrayElements(jce, ce, 0);

    return 0;
}

extern "C" JNIEXPORT jint JNICALL FN_NAME(fftSetupD)(JNIEnv *env, jclass jc,
    jdoubleArray jce, jint size, jboolean inverse)
{
    vispo_fft_d fft;
    double *ce  = env->GetDoubleArrayElements(jce, 0);

    fft.tables = (complex_d *) ce;
    fft.n = size;
    vispo_fft_setup_d(&fft, inverse);

    env->ReleaseDoubleArrayElements(jce, ce, 0);

    return 0;
}

extern "C" JNIEXPORT jint JNICALL FN_NAME(fftS)(JNIEnv *env, jclass jc,
    jfloatArray jce, jfloatArray jout, jfloatArray jin, jint size)
{
    vispo_fft_s fft;
    float *ce  = env->GetFloatArrayElements(jce, 0);
    float *in  = env->GetFloatArrayElements(jin, 0);
    float *out  = env->GetFloatArrayElements(jout, 0);

    fft.tables = (complex_s *) ce;
    fft.n = size;
    vispo_fft_complex_s(&fft, (complex_s *) out, (complex_s *) in);

    env->ReleaseFloatArrayElements(jce, ce, JNI_ABORT);  /* read only; not copied back */
    env->ReleaseFloatArrayElements(jin, in, JNI_ABORT);  /* read only; not copied back */
    env->ReleaseFloatArrayElements(jout, out, 0);

    return 0;
}

extern "C" JNIEXPORT jint JNICALL FN_NAME(fftD)(JNIEnv *env, jclass jc,
    jdoubleArray jce, jdoubleArray jout, jdoubleArray jin, jint size)
{
    vispo_fft_d fft;
    double *ce  = env->GetDoubleArrayElements(jce, 0);
    double *in  = env->GetDoubleArrayElements(jin, 0);
    double *out  = env->GetDoubleArrayElements(jout, 0);

    fft.tables = (complex_d *) ce;
    fft.n = size;
    vispo_fft_complex_d(&fft, (complex_d *) out, (complex_d *) in);

    env->ReleaseDoubleArrayElements(jce, ce, JNI_ABORT);  /* read only; not copied back */
    env->ReleaseDoubleArrayElements(jin, in, JNI_ABORT);  /* read only; not copied back */
    env->ReleaseDoubleArrayElements(jout, out, 0);

    return 0;
}

extern "C" JNIEXPORT jint JNICALL FN_NAME(fftRealS)(JNIEnv *env, jclass jc,
    jfloatArray jce, jfloatArray jout, jfloatArray jin, jint size)
{
    vispo_fft_s fft;
    float *ce  = env->GetFloatArrayElements(jce, 0);
    float *in  = env->GetFloatArrayElements(jin, 0);
    float *out  = env->GetFloatArrayElements(jout, 0);

    fft.tables = (complex_s *) ce;
    fft.n = size;
    vispo_fft_real_s(&fft, (complex_s *) out, (const float *) in);

    env->ReleaseFloatArrayElements(jce, ce, JNI_ABORT);  /* read only; not copied back */
    env->ReleaseFloatArrayElements(jin, in, JNI_ABORT);  /* read only; not copied back */
    env->ReleaseFloatArrayElements(jout, out, 0);

    return 0;
}

extern "C" JNIEXPORT jint JNICALL FN_NAME(fftRealD)(JNIEnv *env, jclass jc,
    jdoubleArray jce, jdoubleArray jout, jdoubleArray jin, jint size)
{
    vispo_fft_d fft;
    double *ce  = env->GetDoubleArrayElements(jce, 0);
    double *in  = env->GetDoubleArrayElements(jin, 0);
    double *out  = env->GetDoubleArrayElements(jout, 0);

    fft.tables = (complex_d *) ce;
    fft.n = size;
    vispo_fft_real_d(&fft, (complex_d *) out, (const double *) in);

    env->ReleaseDoubleArrayElements(jce, ce, JNI_ABORT);  /* read only; not copied back */
    env->ReleaseDoubleArrayElements(jin, in, JNI_ABORT);  /* read only; not copied back */
    env->ReleaseDoubleArrayElements(jout, out, 0);

    return 0;
}
