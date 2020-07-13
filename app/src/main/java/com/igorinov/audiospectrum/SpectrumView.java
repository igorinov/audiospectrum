package com.igorinov.audiospectrum;

import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.graphics.Typeface;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowManager;

import java.util.Locale;

/**
 * Created by igorinov on 11/21/16.
 */
public class SpectrumView extends View {
    DisplayMetrics metrics;
    Paint paint;

    Rect src = new Rect();
    Rect dst = new Rect();
    Rect src1 = new Rect();
    Rect dst1 = new Rect();

    // Part of spectrum visible in the window
    Bitmap spectrum = null;

    // Time / Frequency scales
    Bitmap freqScale = null;
    Bitmap timeScale = null;
    Bitmap corner = null;

    int[] colormap;
    int[] cursor;

    // Pixel data for the whole spectrum.
    // Unlike android.graphics.Bitmap, it is not limited to 2048x2048
    int[] pixelArray;

    int lineNumber = 0;
    int freq_size = 0;
    int time_size = 0;
    int textSize = 16;

    // Touchdown point
    float touchDownX = Float.NaN;
    float touchDownY = Float.NaN;

    // Current bitmap position inside the whole spectrum image
    int viewPositionX = 0;
    int viewPositionY = 0;

    // Bitmap displacement during drag, rounded to integer
    int displacementX = 0;
    int displacementY = 0;

    int sample_rate = 0;
    float line_rate = 0;

    // Width of the frequency scale
    int scaleWidth = 128;
    // Height of the time scale
    int scaleHeight = 64;

    public SpectrumView(Context context) {
        this(context, null);
    }

    public SpectrumView(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public SpectrumView(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);

        int x, i;
        colormap = new int[4096];

        for (i = 0; i < 4096; i += 1) {
            x = i >> 4;
            colormap[i] = Color.argb(255, x, x, x);
        }

        if (!isInEditMode()) {
            WindowManager wm;
            metrics = new DisplayMetrics();
            wm = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
            wm.getDefaultDisplay().getMetrics(metrics);
        }

        TypedArray a = context.obtainStyledAttributes(attrs,
                R.styleable.SpectrumView);

        final int N = a.getIndexCount();
        for (i = 0; i < N; i++) {
            int attr = a.getIndex(i);
            switch (attr) {
                case R.styleable.SpectrumView_android_textSize:
                    textSize = a.getDimensionPixelSize(attr, -1);
                    break;

            }
        }
        a.recycle();

        paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    }

    public int[] getColormap() {
        return colormap;
    }

    public void setSampleRate(int rate, int hop_size) {
        sample_rate = rate;
        line_rate = rate / (float) hop_size;
        drawGrid();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        int width = getWidth();
        int height = getHeight();
        int y;

        if (spectrum == null)
            return;

        paint.setColor(Color.WHITE);

        if (displacementX > 0) {
            dst.left = scaleWidth + displacementX;
            dst.right = width;
            src.left = 0;
            src.right = width - dst.left;
        } else {
            src.left = -displacementX;
            src.right = width - scaleWidth;
            dst.left = scaleWidth;
            dst.right = width - src.left;
        }

        if (freq_size < height - scaleHeight) {
            y = (height - scaleHeight) - freq_size;
            src.top = 0;
            src.bottom = freq_size;
            dst.top = y;
            dst.bottom = dst.top + freq_size;
        } else {
            if (displacementY > 0) {
                dst.top = displacementY;
                dst.bottom = height - scaleHeight;
                src.top = 0;
                src.bottom = height - scaleHeight - dst.top;
            } else {
                src.top = -displacementY;
                src.bottom = height - scaleHeight;
                dst.top = 0;
                dst.bottom = height - scaleHeight - src.top;
            }
        }

        canvas.drawBitmap(spectrum, src, dst, paint);

        if (freqScale != null) {
            src1.set(src);
            dst1.set(dst);
            src1.left = 0;
            src1.right = scaleWidth;
            dst1.left = 0;
            dst1.right = scaleWidth;
            canvas.drawBitmap(freqScale, src1, dst1, paint);
        }

        if (timeScale != null) {
            src1.set(src);
            dst1.set(dst);
            src1.top = 0;
            src1.bottom = scaleHeight;
            dst1.top = height - scaleHeight;
            dst1.bottom = height;
            canvas.drawBitmap(timeScale, src1, dst1, paint);
        }

        if (corner != null) {
            src1.set(src);
            dst1.set(dst);
            src1.left = 0;
            src1.right = scaleWidth;
            src1.top = 0;
            src1.bottom = scaleHeight;
            dst1.left = 0;
            dst1.right = scaleWidth;
            dst1.top = height - scaleHeight;
            dst1.bottom = height;
            canvas.drawBitmap(corner, src1, dst1, paint);
        }
    }

    @Override
    protected void onSizeChanged(int width, int height, int w0, int h0) {
        int i;

        paint.setTextSize(textSize);
        paint.setTypeface(Typeface.MONOSPACE);
        Rect bounds = new Rect();
        paint.getTextBounds(" 000---", 0, 7, bounds);
        int x, y;

        scaleWidth = bounds.width();
        scaleHeight = bounds.height() * 3;

        if (spectrum != null) {
            spectrum.recycle();
            spectrum = null;
        }

        if (freqScale != null) {
            freqScale.recycle();
            freqScale = null;
        }

        if (timeScale != null) {
            timeScale.recycle();
            timeScale = null;
        }

        if (corner != null) {
            corner.recycle();
            corner = null;
        }

        if (width * height == 0)
            return;

        x = (width - scaleWidth);
        y = (height - scaleHeight);
        spectrum = Bitmap.createBitmap(x, y, Bitmap.Config.ARGB_8888);
        spectrum.eraseColor(Color.BLACK);

        freqScale = Bitmap.createBitmap(scaleWidth, height - scaleHeight, Bitmap.Config.ARGB_8888);
        timeScale = Bitmap.createBitmap(width - scaleWidth, scaleHeight, Bitmap.Config.ARGB_8888);
        corner = Bitmap.createBitmap(scaleWidth, scaleHeight, Bitmap.Config.ARGB_8888);

        cursor = new int[height];
        for (i = 0; i < height; i += 1) {
            cursor[i] = Color.WHITE;
        }

        viewPositionX = 0;

        if (freq_size > spectrum.getHeight()) {
            viewPositionY = freq_size - spectrum.getHeight();
        } else {
            viewPositionY = 0;
        }

        redrawSpectrum();
        drawGrid();
    }

    protected void drawGrid() {
        if (freqScale == null)
            return;
        int width = freqScale.getWidth();
        int height = freqScale.getHeight();
        Path path;

        corner.eraseColor(Color.TRANSPARENT);
        freqScale.eraseColor(Color.DKGRAY);
        timeScale.eraseColor(Color.DKGRAY);
        Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        int f, f_max;
        int t, t_max;
        float r_f_max;
        float x, y;

        if (width * height == 0)
            return;

        if (sample_rate == 0)
            return;

        f_max = sample_rate / 2;
        r_f_max = 1f / f_max;

        t_max = Math.round(time_size / line_rate);

        Canvas canvas = new Canvas(freqScale);
        String str;
        paint.setTextSize(textSize);
        paint.setTypeface(Typeface.MONOSPACE);
        paint.setTextAlign(Paint.Align.RIGHT);
        paint.setColor(Color.BLACK);

        int df = 100;
        if (freq_size <= 1024)
            df = 200;
        if (freq_size <= 512)
            df = 500;
        if (freq_size <= 256)
            df = 2000;

        paint.setColor(Color.WHITE);
        y = freq_size - viewPositionY;
        if (y + 16 >= 0) {
            path = new Path();

            path.moveTo(scaleWidth, y);
            path.lineTo(scaleWidth - 16, y - 16);
            path.lineTo(scaleWidth - 16, y);
            path.lineTo(scaleWidth, y);
            canvas.drawPath(path, paint);
        }
        for (f = 0; f < f_max; f += df) {
            y = (1f - f * r_f_max) * freq_size - viewPositionY;
            if ((f % 1000) == 0) {
                str = String.format(Locale.US, "%5d", f / 1000);
                if (f != 0) {
                    canvas.drawText(str, scaleWidth - 24, y + textSize / 3f, paint);
                    paint.setStrokeWidth(height / 512f);
                }
                canvas.drawLine(width * (7f / 8f), y, width, y, paint);
            } else {
                paint.setStrokeWidth(height / 1024f);
                canvas.drawLine(width * (15f / 16f), y, width, y, paint);
            }
        }

        canvas = new Canvas(timeScale);
        paint.setTextSize(textSize);
        paint.setTypeface(Typeface.MONOSPACE);
        paint.setTextAlign(Paint.Align.CENTER);
        Rect bounds = new Rect();
        paint.getTextBounds("000", 0, 3, bounds);

        int n = 1;
        int dt = 1;
        if (n * line_rate < bounds.width())
            n = 5;
        if (n * line_rate < bounds.width()) {
            n = 10;
            dt = 5;
        }
        if (n * line_rate < bounds.width())
            n = 20;

        paint.setColor(Color.WHITE);
        path = new Path();
        x = -viewPositionX;
        path.moveTo(x, 0);
        path.lineTo(x + 16, 16);
        path.lineTo(x, 16);
        path.lineTo(x, 0);
        canvas.drawPath(path, paint);
        for (t = dt; t <= t_max; t += dt) {
            x = t * line_rate - viewPositionX;
            if ((t % n) == 0) {
                str = String.format(Locale.US, "%02d", t);
                canvas.drawText(str, x, scaleHeight - textSize / 2f, paint);
                paint.setStrokeWidth(height / 512f);
                canvas.drawLine(x, 0, x, 16, paint);
            } else {
                paint.setStrokeWidth(height / 1024f);
                canvas.drawLine(x, 0, x, 12, paint);
            }
        }

        canvas = new Canvas(corner);
        paint.setTextSize(textSize);
        paint.setTypeface(Typeface.MONOSPACE);
        paint.setColor(Color.WHITE);
        paint.getTextBounds("000", 0, 3, bounds);
        paint.setTextAlign(Paint.Align.LEFT);
        canvas.drawText("KHz", 0, textSize, paint);
        paint.setTextAlign(Paint.Align.RIGHT);
        canvas.drawText("s ", scaleWidth, scaleHeight - textSize / 4f, paint);
    }

    public int setSize(int n, int nt) {
        freq_size = n;
        time_size = nt;
        drawGrid();
        lineNumber = 0;
        if (spectrum != null) {
            if (spectrum.getHeight() < freq_size)
                viewPositionY = freq_size - spectrum.getHeight();
            else
                viewPositionY = 0;
        }

        return n * nt;
    }

    public void setColorMap(int[] data) {
        System.arraycopy(data, 0, colormap, 0, 4096);
    }

    public int addSeparator() {
        int i, j;

        if (pixelArray == null)
            return -1;

        j = lineNumber;
        for (i = 0; i < freq_size; i += 1) {
            pixelArray[j] = Color.GRAY;
            j += time_size;
        }
        lineNumber += 1;
        if (lineNumber >= time_size)
            lineNumber = time_size;

        return i;
    }

    public int setPixelArray(int[] array) {
        pixelArray = array;
        if (spectrum != null) {
            spectrum.eraseColor(Color.BLACK);
            redrawSpectrum();
            drawGrid();
            postInvalidate();
        }

        return 0;
    }

    public int addLine(int number) {
        int n = freq_size;

        if (spectrum == null)
            return -1;

        lineNumber = number;

        if (n > spectrum.getHeight())
            n = spectrum.getHeight();

        int src_x, src_y, dst_x, dst_y;

        src_x = lineNumber;
        dst_x = lineNumber - viewPositionX;

        if (viewPositionY > 0) {
            src_y = viewPositionY;
            dst_y = 0;
        } else {
            src_y = 0;
            dst_y = -viewPositionY;
        }

        if (dst_x >= 0 && dst_x < spectrum.getWidth()) {
            try {
                spectrum.setPixels(pixelArray, src_y * time_size + src_x, time_size, dst_x, dst_y, 1, n);
            } catch (ArrayIndexOutOfBoundsException e) {
                Log.getStackTraceString(e);
            }
        }

        lineNumber += 1;
        if (lineNumber >= time_size)
            lineNumber = 0;

        dst_x = lineNumber - viewPositionX;
        if (dst_x >= 0 && dst_x < spectrum.getWidth()) {
            try {
                spectrum.setPixels(cursor, 0, 1, dst_x, 0, 1, spectrum.getHeight());
            } catch (NullPointerException e) {
                Log.getStackTraceString(e);
            }
        }

        postInvalidate();

        return n;
    }

    public void redrawSpectrum() {
        if (pixelArray == null)
            return;

        if (spectrum != null) {
            int src_x, src_y, dst_x, dst_y;
            int nx, ny;

            if (viewPositionY >= 0) {
                src_y = viewPositionY;
                dst_y = 0;
                ny = spectrum.getHeight();
                if (ny > freq_size)
                    ny = freq_size;
            } else {
                if (spectrum.getHeight() > freq_size) {
                    viewPositionY = freq_size - spectrum.getHeight();
                    ny = freq_size;
                } else {
                    ny = spectrum.getHeight() + viewPositionY;
                }
                src_y = 0;
                dst_y = -viewPositionY;
            }

            if (spectrum.getWidth() < time_size) {
                nx = spectrum.getWidth();
            } else {
                nx = time_size;
            }

            if (viewPositionX >= 0) {
                src_x = viewPositionX;
                dst_x = 0;
            } else {
                nx = time_size;
                if (spectrum.getWidth() > time_size) {
                    viewPositionX = (time_size - spectrum.getWidth()) / 2;
                }
                src_x = 0;
                dst_x = -viewPositionX;
            }

            try {
                spectrum.setPixels(pixelArray, src_y * time_size + src_x, time_size, dst_x, dst_y, nx, ny);
            } catch(ArrayIndexOutOfBoundsException e) {
                Log.getStackTraceString(e);
            }
        }
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        final int w = spectrum.getWidth();
        final int h = spectrum.getHeight();
        final int action = event.getAction();
        final float y = event.getY();
        final float x = event.getX();

        if (spectrum == null)
            return true;

        if (spectrum.getWidth() < time_size) {
            displacementX = Math.round(x - touchDownX);

            // Image dragged all the way left
            if (displacementX > viewPositionX)
                displacementX = viewPositionX;

            // Image dragged all the way right
            if (time_size - viewPositionX + displacementX < w)
                displacementX = w - (time_size - viewPositionX);
        }

        if (spectrum.getHeight() < freq_size) {
            displacementY = Math.round(y - touchDownY);

            // Image dragged all the way down
            if (displacementY > viewPositionY)
                displacementY = viewPositionY;

            // Image dragged all the way up
            if (freq_size - viewPositionY + displacementY < h)
                displacementY = h - (freq_size - viewPositionY);
        }

        switch (action & MotionEvent.ACTION_MASK) {
            case MotionEvent.ACTION_DOWN:
                touchDownX = x;
                touchDownY = y;
                break;

            case MotionEvent.ACTION_MOVE:
                if (Float.isNaN(x))
                    break;

                if (Float.isNaN(y))
                    break;

                postInvalidate();

                break;

            case MotionEvent.ACTION_UP:
                viewPositionX -= displacementX;
                viewPositionY -= displacementY;
                displacementX = 0;
                displacementY = 0;
                touchDownX = Float.NaN;
                touchDownY = Float.NaN;
                if (spectrum != null) {
                    int src_x, src_y, dst_x, dst_y;
                    int nx, ny;

                    if (viewPositionY >= 0) {
                        src_y = viewPositionY;
                        dst_y = 0;
                        ny = spectrum.getHeight();
                        if (ny > freq_size)
                            ny = freq_size;
                    } else {
                        if (spectrum.getHeight() > freq_size)
                            viewPositionY = (freq_size - spectrum.getHeight()) / 2;
                        src_y = 0;
                        dst_y = -viewPositionY;
                        ny = freq_size;
                    }

                    if (spectrum.getWidth() < time_size) {
                        nx = spectrum.getWidth();
                    } else {
                        nx = time_size;
                    }

                    if (viewPositionX >= 0) {
                        src_x = viewPositionX;
                        dst_x = 0;
                    } else {
                        nx = time_size;
                        if (spectrum.getWidth() > time_size) {
                            viewPositionX = (time_size - spectrum.getWidth()) / 2;
                        }
                        src_x = 0;
                        dst_x = -viewPositionX;
                    }
                    if (pixelArray != null) {
                        int offset = src_y * time_size + src_x;
                        try {
                            spectrum.setPixels(pixelArray, offset, time_size, dst_x, dst_y, nx, ny);
                        } catch (ArrayIndexOutOfBoundsException e) {
                            Log.getStackTraceString(e);
                        }
                    }
                }
                drawGrid();
                postInvalidate();
        }
        return true;
    }
}
