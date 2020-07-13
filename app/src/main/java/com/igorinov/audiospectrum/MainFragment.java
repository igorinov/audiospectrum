package com.igorinov.audiospectrum;

import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.os.Bundle;
import android.os.Environment;
import android.preference.PreferenceManager;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.Toast;
import android.widget.ToggleButton;

import com.igorinov.vispo.FourierTransform;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.PipedInputStream;
import java.util.concurrent.BrokenBarrierException;
import java.util.concurrent.CyclicBarrier;

import androidx.fragment.app.Fragment;

/**
 * Created by igorinov on 12/30/17.
 */

public class MainFragment extends Fragment {
    static final int REQUEST_CODE_SETTINGS = 1;
    SharedPreferences pref;
    SpectrumView viewSpectrum;
    ColorMapView viewMap;
    Button buttonZoomIn, buttonZoomOut;
    ToggleButton buttonRunStop;
    Button buttonSettings;
    AudioRecord record = null;
    File testFile = null;
    FileInputStream testStream;
    PipedInputStream pipeStreamIn;
    SoundReaderThread reader = null;
    ProcessingThread processor = null;
    boolean recording = false;
    CyclicBarrier cb0 = new CyclicBarrier(2);
    CyclicBarrier cb1 = new CyclicBarrier(2);
    FourierTransform.Single ft;
    Boolean testMode = false;
    String testFileName = "test.data";

    int[] colormap = new int[4096];
    int[] line;
    int[] pixelArray;

    byte[] testData;
    byte[] hopData;
    int hopOffset;
    int[] data;
    float[] wdata_s = null;
    double[] power;
    double[] w;
    double[] spec = null;
    float[] spec_s = null;
    int data_size = 4096;
    int time_size = 1024;
    int lineNumber = 0;
    int fft_size = 2048;
    int win_size = 3969;
    int hop_size = 256;
    int n_channels = 1;
    int bufferSize = 0;
    int offset = 0;
    int offset0 = 0;
    String windowName = "hann";
    String colorMapName = "ocean";
    int sample_rate = 24000;
    int zoom = 1;
    boolean viewReady = false;

    public class ProcessingThread extends Thread {
        @Override
        public void run() {
            double x, y;
            int i, j, k;

            while (recording) {
                try {
                    cb0.await();
                } catch (BrokenBarrierException e) {
                    break;
                } catch (InterruptedException e) {
                    break;
                }

                if (!recording)
                    break;

                j = offset - win_size;
                if (j < 0)
                    j += data_size;

                int win_center;
                if ((win_size & 1) == 0)
                    win_center = win_size / 2;
                else
                    win_center = (win_size - 1) / 2;

                if (wdata_s != null) {
                    k = 0;
                    for (i = fft_size - win_center; i < fft_size; i += 1) {
                        wdata_s[i] = (float) (data[j++] * w[k++]);
                        if (j >= data_size)
                            j -= data_size;
                    }
                    for (i = 0; i < win_size - win_center; i += 1) {
                        wdata_s[i] = (float) (data[j++] * w[k++]);
                        if (j >= data_size)
                            j -= data_size;
                    }

                    ft.fftReal(spec_s, wdata_s);

                    for (i = 0; i * 2 < fft_size; i += 1) {
                        x = spec_s[i * 2];
                        y = spec_s[i * 2 + 1];
                        power[i] = x * x + y * y;
                    }
                }

                int lx;
                int n = power.length;
                for (i = 0; i < n; i += 1) {
                    double a = power[i];
                    if (a < Math.scalb(1, -1000)) {
                        lx = 0;
                    } else {
                        a = Math.log(a) / (Math.log(2) * 2);
                        lx = (int) Math.round((a + 28) * 146.25);
                    }

                    if (lx < 0)
                        lx = 0;
                    if (lx > 4095)
                        lx = 4095;
                    pixelArray[(n - i - 1) * time_size + lineNumber] = colormap[lx];
                }

                if (viewReady && viewSpectrum != null)
                    viewSpectrum.addLine(lineNumber);

                lineNumber += 1;
                if (lineNumber >= time_size)
                    lineNumber -= time_size;
            }
        }
    }

    public class SoundReaderThread extends Thread {
        @Override
        public void run() {
            int off;
            int length;
            int n, i, k;
            int sample;

            android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_URGENT_AUDIO);

            while (recording) {
                n = hop_size * n_channels * 2;
                while (hopOffset < n) {
                    if (!recording)
                        break;

                    if (pipeStreamIn != null) {
                        try {
                            length = pipeStreamIn.read(hopData, hopOffset, n - hopOffset);
                            if (length <= 0) {
                                recording = false;
                                break;
                            }
                        } catch (IOException e) {
                            recording = false;
                            break;
                        }
                    } else {
                        length = record.read(hopData, hopOffset, n - hopOffset);
                    }
                    if (length < 0) {
                        break;
                    }
                    hopOffset += length;
                }

                off = offset;
                int j = 0;
                for (i = 0; i < hop_size; i += 1) {
                    sample = 0;
                    for (k = 0; k < n_channels; k += 1) {
                        sample += (short) (hopData[j++] & 0xff);
                        sample += ((short) hopData[j++]) << 8;
                    }
                    data[off++] = sample;
                    if (off >= data.length) {
                        off -= data.length;
                    }
                }
                offset = off;
                hopOffset = 0;

                if (!recording)
                    break;

                try {
                    cb0.await();
                } catch (BrokenBarrierException e) {
                    break;
                } catch (InterruptedException e) {
                    break;
                }
            }

        }
    }

    public boolean recordStart() {

        hop_size = pref.getInt(SettingsFragment.PREF_HOP_SIZE, hop_size);
        win_size = pref.getInt(SettingsFragment.PREF_WINDOW_SIZE, win_size);
        if (win_size > 65535)
            win_size = 65535;
        fft_size = 1;
        while (fft_size < win_size)
            fft_size <<= 1;

        data_size = fft_size * 2;
        data = new int[data_size];
        testData = new byte[data_size * 2];
        wdata_s = new float[fft_size];
        spec_s = new float[fft_size * 2];
        power = new double[fft_size / 2];
        w = new double[win_size];
        int i;
        double r_n = 1.0 / win_size;
        double scale = 2.0 / (win_size * Math.sqrt(fft_size) * 32768);
        double a0 = 1;
        double a1 = 0;
        double a2 = 0;
        double a3 = 0;

        try {
            testMode = pref.getBoolean(SettingsFragment.PREF_TEST_MODE, testMode);
        } catch (ClassCastException e) {
            testMode = false;
        }

        try {
            windowName = pref.getString(SettingsFragment.PREF_WINDOW_TYPE, windowName);
        } catch (ClassCastException e) {
        }

        try {
            colorMapName = pref.getString(SettingsFragment.PREF_COLOR_MAP, colorMapName);
            setColorMap(colorMapName);
        } catch (ClassCastException e) {
        }

        if (viewReady) {
            if (viewSpectrum != null)
                viewSpectrum.setColorMap(colormap);
            if (viewMap != null)
                viewMap.setColorMap(colormap);
        }

        try {
            time_size = pref.getInt(SettingsFragment.PREF_RECORD_TIME, time_size);
        } catch (ClassCastException e) {
        }

        try {
            String s = pref.getString(SettingsFragment.PREF_SAMPLE_RATE, null);
            if (s != null)
                sample_rate = Integer.parseInt(s);
        } catch (ClassCastException e) {
        }

        viewSpectrum.setPixelArray(null);
        viewSpectrum.setSampleRate(sample_rate, hop_size);
        viewSpectrum.setSize(fft_size / 2, time_size);
        lineNumber = 0;
        try {
            pixelArray = new int[time_size * fft_size / 2];
        } catch (OutOfMemoryError e) {
            Toast toast = Toast.makeText(getActivity(), "Out of memory", Toast.LENGTH_LONG);
            toast.show();
            return false;
        }
        viewSpectrum.setPixelArray(pixelArray);

        if (windowName.equals("nuttall")) {
            a0 = 0.355768;
            a1 = 0.487396;
            a2 = 0.144232;
            a3 = 0.012604;
        }

        if (windowName.equals("blackman-harris")) {
            a0 = 0.35875;
            a1 = 0.48829;
            a2 = 0.14128;
            a3 = 0.01168;
        }

        if (windowName.equals("hann")) {
            a0 = 0.5;
            a1 = 0.5;
            a2 = 0;
            a3 = 0;
        }

        for (i = 0; i < win_size; i += 1) {
            double c = (2 * Math.PI * i) * r_n;
            w[i] = a0 - a1 * Math.cos(c) + a2 * Math.cos(2 * c) - a3 * Math.cos(3 * c);
            w[i] *= scale;
        }

        ft = new FourierTransform.Single(fft_size, false);

        reader = new SoundReaderThread();
        processor = new ProcessingThread();
        int encoding = AudioFormat.ENCODING_PCM_16BIT;
        int channels = AudioFormat.CHANNEL_IN_MONO;
        testStream = null;

        if (testMode) {
            testFileName = pref.getString(SettingsFragment.PREF_FILE_NAME, testFileName);
            File sdCard = Environment.getExternalStorageDirectory();
            File dir = new File(sdCard.getAbsolutePath());
            testFile = new File(dir, testFileName);
            try {
                testStream = new FileInputStream(testFile);
            } catch (FileNotFoundException e) {
                testStream = null;
                return false;
            }
        } else {
            bufferSize = AudioRecord.getMinBufferSize(sample_rate, channels, encoding);
            record = new AudioRecord(MediaRecorder.AudioSource.MIC, sample_rate, channels, encoding, bufferSize * 4);
            if (record.getState() != AudioRecord.STATE_INITIALIZED)
                return false;
            record.startRecording();
        }

        hopData = new byte[hop_size * n_channels * 2];
        recording = true;
        processor.start();

        reader.start();

        if (buttonZoomIn != null)
            buttonZoomIn.setEnabled(zoom < 3);
        if (buttonZoomOut != null)
            buttonZoomOut.setEnabled(zoom > 1);
        getActivity().getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        return true;
    }

    public void recordStop() {

        recording = false;

        if (record != null) {
            record.stop();
        }

        cb0.reset();
        cb1.reset();

        if (reader != null) {
            try {
                reader.join();
                reader = null;
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        if (processor != null) {
            try {
                processor.join();
                processor = null;
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        testStream = null;

        if (record != null) {
            record.release();
            record = null;
        }

        offset = 0;
        offset0 = 0;
        viewSpectrum.addSeparator();

        spec = null;
        wdata_s = null;
        spec_s = null;

        getActivity().getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    public void setColorMap(String name) {
        float[] hsv = new float[3];
        double a;
        int c;
        int i;
        float h0, h1;
        float s0, s1;
        float v0, v1;

        if (name.equals("grayscale")) {
            for (i = 0; i < 4096; i += 1) {
                a = i / 4095.0;
                c = (int) Math.round(a * 255);
                colormap[i] = Color.rgb(c, c, c);
            }
        }

        if (name.equals("grayprint")) {
            for (i = 0; i < 4096; i += 1) {
                a = (4095 - i) / 4095.0;
                c = (int) Math.round(a * 255);
                colormap[i] = Color.rgb(c, c, c);
            }
        }

        if (name.equals("rainbow")) {
            h0 = 240;
            h1 = 0;
            s0 = 1;
            s1 = 1;
            v0 = 2.0f / 3;
            v1 = 1;

            for (i = 0; i < 4096; i += 1) {
                a = i / 4095.0;
                hsv[0] = (float) a * (h1 - h0) + h0;
                hsv[1] = (float) a * (s1 - s0) + s0;
                hsv[2] = (float) a * (v1 - v0) + v0;
                colormap[i] = Color.HSVToColor(hsv);
            }
        }

        if (name.equals("ocean")) {
            h0 = 240;
            h1 = 60;
            s0 = 2.0f / 3;
            s1 = 1.0f / 3;
            v0 = 1.0f / 3;
            v1 = 1.0f;

            for (i = 0; i < 4096; i += 1) {
                a = i / 4095.0;
                hsv[0] = (float) a * (h1 - h0) + h0;
                hsv[1] = (float) a * (s1 - s0) + s0;
                hsv[2] = (float) a * (v1 - v0) + v0;
                colormap[i] = Color.HSVToColor(hsv);
            }
        }

        if (name.equals("sunrise")) {
            h0 = 240;
            h1 = 60 + 360;
            s0 = 2.0f / 3;
            s1 = 2.0f / 3;
            v0 = 1.0f / 3;
            v1 = 1;

            for (i = 0; i < 4096; i += 1) {
                a = i / 4095.0;
                hsv[0] = (float) a * (h1 - h0) + h0;
                if (hsv[0] >= 360)
                    hsv[0] -= 360;
                hsv[1] = (float) a * (s1 - s0) + s0;
                hsv[2] = (float) a * (v1 - v0) + v0;
                colormap[i] = Color.HSVToColor(hsv);
            }
        }

        if (name.equals("inkjet")) {
            h0 = 60;
            h1 = 240;
            s0 = 0;
            s1 = 1;
            v0 = 1;
            v1 = 1.0f / 3;

            for (i = 0; i < 4096; i += 1) {
                a = i / 4095.0;
                hsv[0] = (float) a * (h1 - h0) + h0;
                hsv[1] = (float) a * (s1 - s0) + s0;
                hsv[2] = (float) a * (v1 - v0) + v0;
                colormap[i] = Color.HSVToColor(hsv);
            }
        }

        if (name.equals("incandescence")) {
            h0 = 0;
            h1 = 60;
            s0 = 1;
            s1 = 0.5f;
            v0 = 0.25f;
            v1 = 1;

            for (i = 0; i < 4096; i += 1) {
                a = i / 4095.0;
                hsv[0] = (float) a * (h1 - h0) + h0;
                hsv[1] = (float) a * (s1 - s0) + s0;
                hsv[2] = (float) a * (v1 - v0) + v0;
                colormap[i] = Color.HSVToColor(hsv);
            }
        }
    }

    public class ButtonZoomInListener implements View.OnClickListener {

        @Override
        public void onClick(View view) {
            if (zoom < 3) {
                zoom += 1;
//                viewSpectrum.setZoom(zoom);
            }
        }
    }

    public class ButtonZoomOutListener implements View.OnClickListener {

        @Override
        public void onClick(View view) {
            if (zoom > 3) {
                zoom -= 1;
//                viewSpectrum.setZoom(zoom);
            }
        }
    }

    public class ButtonRunStopListener implements CompoundButton.OnCheckedChangeListener {
        @Override
        public void onCheckedChanged(CompoundButton compoundButton, boolean b) {
            if (b && !recording) {
                recordStart();
                compoundButton.setChecked(recording);
            }

            if (!b && recording) {
                recordStop();
            }
        }
    }

    public class ButtonSettingsListener implements View.OnClickListener {

        @Override
        public void onClick(View view) {
            Intent intent = new Intent(getActivity(), SettingsActivity.class);
            startActivityForResult(intent, REQUEST_CODE_SETTINGS);
        }
    }

    public int setSize(int n, int nt) {
        data_size = n;
        time_size = nt;
        try {
            pixelArray = new int[n * nt];
        } catch (OutOfMemoryError e) {
            pixelArray = null;
            return 0;
        }
        line = new int[n];
        lineNumber = 0;

        return n * nt;
    }

    public static MainFragment newInstance(int index) {
        MainFragment f = new MainFragment();
        Bundle args = new Bundle();
        args.putInt("index", index);
        f.setArguments(args);

        return f;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setRetainInstance(true);

        pref = PreferenceManager.getDefaultSharedPreferences(getActivity().getApplicationContext());
        hop_size = pref.getInt(SettingsFragment.PREF_HOP_SIZE, hop_size);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_main, container, false);

        return view;
    }

    @Override
    public void onViewCreated(View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        viewReady = false;
        viewSpectrum = view.findViewById(R.id.spectrum);
        viewMap = view.findViewById(R.id.colormap);
        buttonRunStop = view.findViewById(R.id.run_stop);
        buttonSettings = view.findViewById(R.id.settings);

        viewSpectrum.setPixelArray(null);
        hop_size = pref.getInt(SettingsFragment.PREF_HOP_SIZE, hop_size);
        viewSpectrum.setSampleRate(sample_rate, hop_size);
        viewSpectrum.setSize(fft_size / 2, time_size);

        if (recording)
            getActivity().getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    @Override
    public void onActivityCreated(Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);

        pref = PreferenceManager.getDefaultSharedPreferences(getActivity().getApplicationContext());
        SharedPreferences.Editor edit = pref.edit();

        try {
            colorMapName = pref.getString(SettingsFragment.PREF_COLOR_MAP, colorMapName);
        } catch (ClassCastException e) {
            edit.putString(SettingsFragment.PREF_COLOR_MAP, colorMapName);
            edit.apply();
        }

        hop_size = pref.getInt(SettingsFragment.PREF_HOP_SIZE, hop_size);

        try {
            String s = pref.getString(SettingsFragment.PREF_SAMPLE_RATE, null);
            if (s != null)
                sample_rate = Integer.parseInt(s);
        } catch (ClassCastException e) {
        }

        setColorMap(colorMapName);

        viewSpectrum.setPixelArray(pixelArray);
        viewSpectrum.setColorMap(colormap);
        viewSpectrum.setSampleRate(sample_rate, hop_size);
        viewSpectrum.setSize(fft_size / 2, time_size);

        if (viewMap != null)
            viewMap.setColorMap(colormap);

        if (buttonZoomIn != null)
            buttonZoomIn.setOnClickListener(new ButtonZoomInListener());

        if (buttonZoomOut != null)
            buttonZoomOut.setOnClickListener(new ButtonZoomOutListener());

        if (buttonRunStop != null)
            buttonRunStop.setOnCheckedChangeListener(new ButtonRunStopListener());

        if (buttonRunStop != null) {
            buttonRunStop.setEnabled(true);
            buttonRunStop.setChecked(recording);
        }

        if (buttonSettings != null)
            buttonSettings.setOnClickListener(new ButtonSettingsListener());

        if (buttonSettings != null)
            buttonSettings.setOnClickListener(new ButtonSettingsListener());

        viewReady = true;
    }

    @Override
    public void onDetach() {
        viewReady = false;
        viewSpectrum = null;
        viewMap = null;
        buttonZoomIn = null;
        buttonZoomOut = null;
        buttonSettings = null;
        super.onDetach();
    }

    @Override
    public void onDestroyView() {
        viewReady = false;
        viewSpectrum = null;
        viewMap = null;
        buttonZoomIn = null;
        buttonZoomOut = null;
        buttonSettings = null;
        super.onDestroyView();
    }

    @Override
    public void onDestroy() {
        viewReady = false;
        viewSpectrum = null;
        super.onDestroy();
    }
}
