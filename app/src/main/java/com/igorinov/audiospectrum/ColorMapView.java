package com.igorinov.audiospectrum;

import android.content.Context;
import android.content.res.TypedArray;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.Typeface;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.view.View;
import android.widget.LinearLayout;

/**
 * Created by igorinov on 11/21/16.
 */
public class ColorMapView extends View {
    DisplayMetrics metrics;
    Bitmap spectrum = null;
    Bitmap grid = null;
    int[] colormap;
    int[] line;
    int lineNumber = 0;
    float scale = 0.5f;
    int data_size = 0;
    int orientation = LinearLayout.HORIZONTAL;
    int textSize = 16;

    public ColorMapView(Context context) {
        this(context, null);
    }

    public ColorMapView(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public ColorMapView(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
        int i;

        colormap = new int[4096];
        orientation = attrs.getAttributeIntValue("http://schemas.android.com/apk/res/android", "orientation", orientation);

        TypedArray a = context.obtainStyledAttributes(attrs,
                R.styleable.ColorMapView);

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
    }

    @Override
    protected void onDraw(Canvas canvas) {
        Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);

        if (grid != null) {
            canvas.drawBitmap(grid, 0, 0, paint);
        }
    }

    @Override
    protected void onSizeChanged(int width, int height, int w0, int h0) {
        if (grid != null) {
            grid.recycle();
        }
        grid = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        lineNumber = 0;
        drawMap();
    }

    public void setSize(int n) {
        data_size = n;
        spectrum = Bitmap.createBitmap(512, n, Bitmap.Config.ARGB_8888);
        line = new int[n];
    }

    public void drawMap() {
        Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        Canvas canvas;
        int width, height;
        float x, y;
        int i;
        int db, db_min = -160;
        int bits_min = -28;
        float bits;
        float r_db_min = 1f / db_min;
        float r_bits_min = 1f / bits_min;
        String str;
        Rect bounds = new Rect();
        float k = 0.875f;
        float x0, y0;

        if (grid == null)
            return;

        width = grid.getWidth();
        height = grid.getHeight();

        canvas = new Canvas(grid);

        if (height == 0) {
            return;
        }
        float r_width = 1 / (width * k);
        float r_height = 1 / (height * k);

        x0 = (float) width * 0.0625f;
        y0 = (float) height * 0.0625f;

        paint.setStyle(Paint.Style.FILL);
        paint.setTypeface(Typeface.MONOSPACE);

        if (orientation == LinearLayout.HORIZONTAL) {
            paint.setTextSize(textSize);
            paint.setTextAlign(Paint.Align.CENTER);
            paint.setColor(Color.WHITE);
            str = "dB  ";
            paint.getTextBounds(str, 0, str.length(), bounds);
            canvas.drawText(str, x0, height * 7 / 8f, paint);

            for (db = 0; db >= db_min; db -= 10) {
                double b = (double) db * Math.log(10) / Math.log(2) * 0.05;
                x = (1 - (float) b * r_bits_min) * width * k;
                str = String.format("%4d ", db);
                paint.getTextBounds(str, 0, str.length(), bounds);
                paint.setStrokeWidth(1);
                if ((db % 20) == 0) {
                    paint.setColor(Color.LTGRAY);
                    canvas.drawText(str, x + x0, height * 5 / 16f, paint);
                    paint.setColor(Color.WHITE);
                    paint.setStrokeWidth(width / 256f);
                    canvas.drawLine(x + x0, height * 3 / 8f, x + x0, height * 4 / 8, paint);
                } else {
                    paint.setColor(Color.LTGRAY);
                    canvas.drawText(str, x + x0, height * 15 / 16f, paint);
                    paint.setColor(Color.WHITE);
                    paint.setStrokeWidth(width / 256f);
                    canvas.drawLine(x + x0, height * 6 / 8f, x + x0, height * 5 / 8, paint);
                }
            }
        }

        if (orientation == LinearLayout.VERTICAL) {
            paint.setTextSize(textSize);
            paint.setTextAlign(Paint.Align.RIGHT);
            paint.setColor(Color.WHITE);
            str = "dB  ";
            paint.getTextBounds(str, 0, str.length(), bounds);
            canvas.drawText(str, width * 4 / 8f, y0 - bounds.height(), paint);

            for (db = 0; db >= db_min; db -= 10) {
                double b = (double) db * Math.log(10) / Math.log(2) * 0.05;
                y = ((float) b * r_bits_min) * height * k;
                if ((db % 10) == 0) {
                    str = String.format("%4d ", db);
                    paint.setColor(Color.LTGRAY);
                    paint.getTextBounds(str, 0, str.length(), bounds);
                    canvas.drawText(str, width * 9 / 16f, y + y0 + bounds.height() * 0.5f, paint);
                    paint.setColor(Color.WHITE);
                } else {
                }
                paint.setStrokeWidth(height / 256f);
                canvas.drawLine(width * 9 / 16, y + y0, width * 5 / 8f, y + y0, paint);
            }
        }

        if (orientation == LinearLayout.HORIZONTAL) {
            for (x = 0; x <= width * k; x += 1) {
                bits = 28 + bits_min * (1f - x * r_width);
                i = Math.round(bits * 140.25f);
                paint.setColor(colormap[i]);
                canvas.drawLine(x + x0, height * 4 / 8f, x + x0, height * 5 / 8f, paint);
            }
            paint.setColor(Color.WHITE);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            canvas.drawRect(x0, height * 4 / 8f, x0 + width * k, height * 5 / 8f, paint);
        }

        if (orientation == LinearLayout.VERTICAL) {
            for (y = 0; y <= height * k; y += 1) {
                bits = 28 + bits_min * y * r_height;
                i = Math.round(bits * 140.25f);
                paint.setColor(colormap[i]);
                canvas.drawLine(width * 5 / 8f, y + y0, width * 6 / 8f, y + y0, paint);
            }
            paint.setColor(Color.WHITE);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(2);
            canvas.drawRect(width * 5 / 8f, y0, width * 6 / 8f, y0 + height * k, paint);
        }

        invalidate();
    }

    public void setColorMap(int[] data) {
        int i;

        for (i = 0; i < 4096; i += 1) {
            colormap[i] = data[i];
        }
        drawMap();
    }
}
