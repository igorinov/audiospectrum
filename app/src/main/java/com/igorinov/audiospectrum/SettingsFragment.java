package com.igorinov.audiospectrum;

import android.app.Dialog;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.util.SparseArray;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.TextView;

import java.util.List;
import java.util.Locale;

import androidx.fragment.app.Fragment;

import static android.view.View.NO_ID;

/**
* Created by igorinov on 8/15/15.
*/
public class SettingsFragment extends Fragment
{
    static public String PREF_TEST_MODE = "test_mode";
    static public String PREF_FILE_NAME = "filename";
    static public String PREF_WINDOW_TYPE = "window_type";
    static public String PREF_WINDOW_SIZE = "window_size";
    static public String PREF_HOP_SIZE = "hop_size";
    static public String PREF_RECORD_TIME = "record_time";
    static public String PREF_SAMPLE_RATE = "sample_rate";
    static public String PREF_KEEP_SCREEN = "keep_screen";
    static public String PREF_COLOR_MAP = "color_map";

    SharedPreferences pref = null;
    SharedPreferences.Editor editor = null;
    SparseArray<View> labelMap = new SparseArray<View>();

    // Map labels of child Views

    int mapLabels(View layout) {
        ViewGroup group;
        View view;
        int c = 0;
        int n, i;

        if (!(layout instanceof ViewGroup))
            return 0;

        group = (ViewGroup) layout;

        n = group.getChildCount();
        for (i = 0; i < n; i += 1) {
            view = group.getChildAt(i);
            if (view == null)
                continue;

            if (view instanceof ViewGroup) {
                c += mapLabels(view);
            }

            int id = view.getLabelFor();
            if (id != NO_ID) {
                labelMap.put(id, view);
                c += 1;
            }
        }

        return c;
    }

    public class IntNumberDialog extends Dialog {
        Context myContext = null;
        EditText editNumber = null;
        TextView target = null;
        Button buttonSet = null;
        String key = null;
        String format = "%d";
        int number = 0;

        public IntNumberDialog(Context context) {
            super(context);
            myContext = context;
        }

        public IntNumberDialog(Context context, int theme) {
            super(context, theme);
            myContext = context;
        }

        public IntNumberDialog(Context context, boolean cancelable,
                               OnCancelListener cancelListener) {
            super(context, cancelable, cancelListener);
            myContext = context;
        }

        public void setKey(String s) {
            key = s;
        }

        public void setTarget(TextView textView) {
            target = textView;

            int id = target.getId();
            if (id != NO_ID) {
                View label = labelMap.get(id);
                if (label instanceof TextView) {
                    textView = (TextView) label;
                    String title = textView.getText().toString();
                    setTitle(title);
                }
            }

            if (target != null) {
                try {
                    number = Integer.parseInt(target.getText().toString(), 10);
                } catch (NumberFormatException e) {
                    // ?
                }
                try {
                    float a = Float.parseFloat(target.getText().toString());
                    number = Math.round(a);
                } catch (NumberFormatException e) {
                    // ?
                }
            }
        }

        public void setNumber(int x) {
            number = x;
            if (editNumber != null) {
                editNumber.setText(Integer.toString(x));
            }
        }

        private class ButtonSetListener implements View.OnClickListener {

            @Override
            public void onClick(View v) {
                updateSetting();
            }
        }

        public void updateSetting() {
            boolean valid = false;

            try {
                number = Integer.parseInt(editNumber.getText().toString(), 10);
                valid = true;
            } catch (NumberFormatException e) {
                // ?
            }

            if (!valid) {
                float a;
                try {
                    a = Float.parseFloat(editNumber.getText().toString());
                    number = Math.round(a);
                    valid = true;
                } catch (NumberFormatException e) {
                    //
                }
            }

            if (target != null) {
                target.setText(Integer.toString(number));
            }
            if (key != null) {
                SharedPreferences.Editor editor = pref.edit();
                editor.putInt(key, number);
                editor.commit();
            }
            dismiss();
        }

        @Override
        public void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            setContentView(R.layout.preference_number);
            editNumber = (EditText) findViewById(R.id.number);
            if (editNumber != null) {
                // specify the locale to make sure decimal point is not replaced by comma
                editNumber.setText(String.format(Locale.US, format, number));
                editNumber.setSelectAllOnFocus(true);
            }
            buttonSet = (Button) findViewById(R.id.set);
            if (buttonSet != null) {
                buttonSet.setOnClickListener(new ButtonSetListener());
            }
            setCancelable(true);
        }
    }

    public class FloatNumberDialog extends Dialog {
        Context myContext = null;
        EditText editNumber = null;
        TextView target = null;
        Button buttonSet = null;
        String key = null;
        String format = "%f";
        float number = 0;

        public FloatNumberDialog(Context context) {
            super(context);
            myContext = context;
        }

        public FloatNumberDialog(Context context, int theme) {
            super(context, theme);
            myContext = context;
        }

        public FloatNumberDialog(Context context, boolean cancelable,
                                 OnCancelListener cancelListener) {
            super(context, cancelable, cancelListener);
            myContext = context;
        }

        public void setKey(String s) {
            key = s;
        }

        public void setTarget(TextView textView) {
            target = textView;

            int id = target.getId();
            if (id != NO_ID) {
                View label = labelMap.get(id);
                if (label instanceof TextView) {
                    textView = (TextView) label;
                    String title = textView.getText().toString();
                    setTitle(title);
                }
            }

            if (target != null) {
                number = Float.parseFloat(target.getText().toString());
            }
        }

        public void setNumber(float x) {
            number = x;
            if (editNumber != null) {
                editNumber.setText(Float.toString(x));
            }
        }

        private class ButtonSetListener implements View.OnClickListener {

            @Override
            public void onClick(View v) {
                updateSetting();
            }
        }

        public void updateSetting() {
            try {
                number = Float.parseFloat(editNumber.getText().toString());
            } catch (NumberFormatException e) {
                // ?
            }

            if (target != null) {
                target.setText(Float.toString(number));
            }
            if (key != null) {
                SharedPreferences.Editor editor = pref.edit();
                editor.putFloat(key, number);
                editor.commit();
            }
            dismiss();
        }

        @Override
        public void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            setContentView(R.layout.preference_number);
            editNumber = (EditText) findViewById(R.id.number);
            if (editNumber != null) {
                // specify the locale to make sure decimal point is not replaced by comma
                editNumber.setText(String.format(Locale.US, format, number));
                editNumber.setSelectAllOnFocus(true);
            }
            buttonSet = (Button) findViewById(R.id.set);
            if (buttonSet != null) {
                buttonSet.setOnClickListener(new ButtonSetListener());
            }
            setCancelable(true);
        }
    }

    public class TextEditDialog extends Dialog {
        Context myContext = null;
        EditText editText = null;
        TextView target = null;
        Button buttonSet = null;
        String key = null;
        String text;

        public TextEditDialog(Context context) {
            super(context);
            myContext = context;
        }

        public TextEditDialog(Context context, int theme) {
            super(context, theme);
            myContext = context;
        }

        public TextEditDialog(Context context, boolean cancelable,
                              OnCancelListener cancelListener) {
            super(context, cancelable, cancelListener);
            myContext = context;
        }

        public void setKey(String s) {
            key = s;
        }

        public void setTarget(TextView textView) {
            target = textView;

            int id = target.getId();
            if (id != NO_ID) {
                View label = labelMap.get(id);
                if (label instanceof TextView) {
                    textView = (TextView) label;
                    String title = textView.getText().toString();
                    setTitle(title);
                }
            }

            if (target != null) {
                text = target.getText().toString();
            }
        }

        public void setString(String value) {
            text = value;
            if (editText != null) {
                editText.setText(value);
            }
        }

        private class ButtonSetListener implements View.OnClickListener {

            @Override
            public void onClick(View v) {
                updateSetting();
            }
        }

        public void updateSetting() {
            text = editText.getText().toString();

            if (target != null) {
                target.setText(text);
            }
            if (key != null) {
                SharedPreferences.Editor editor = pref.edit();
                editor.putString(key, text);
                editor.commit();
            }
            dismiss();
        }

        @Override
        public void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            setContentView(R.layout.preference_number);
            editText = (EditText) findViewById(R.id.number);
            if (editText != null) {
                // specify the locale to make sure decimal point is not replaced by comma
                editText.setText(text);
                editText.setSelectAllOnFocus(true);
            }
            buttonSet = (Button) findViewById(R.id.set);
            if (buttonSet != null) {
                buttonSet.setOnClickListener(new ButtonSetListener());
            }
            setCancelable(true);
        }
    }

    public void saveSpinner(int spinner_id, String key)
    {
        View view = getView();
        Spinner spinner = (Spinner) view.findViewById(spinner_id);

        if (spinner == null)
            return;

        int value = spinner.getSelectedItemPosition();
        editor.putInt(key, value);
    }

    public void saveCheckBox(int checkbox_id, String key) {
        View view = getView();
        CheckBox checkbox = (CheckBox) view.findViewById(checkbox_id);

        if (checkbox == null)
            return;

        boolean value = checkbox.isChecked();
        editor.putBoolean(key, value);
    }

    public boolean saveEditInt(int edittext_id, String key) {
        View view = getView();
        TextView edittext = (TextView) view.findViewById(edittext_id);

        if (edittext == null)
            return false;

        try {
            int value = Integer.parseInt(edittext.getText().toString());
            editor.putInt(key, value);
        } catch(NumberFormatException e) {
            edittext.requestFocus();
            return false;
        }

        return true;
    }

    public boolean saveEditFloat(int edittext_id, String key) {
        View view = getView();
        EditText edittext = (EditText) view.findViewById(edittext_id);

        if (edittext == null)
            return false;

        try {
            float value = Float.parseFloat(edittext.getText().toString());
            editor.putFloat(key, value);
        } catch(NumberFormatException e) {
            edittext.requestFocus();
            edittext.selectAll();
            return false;
        }

        return true;
    }

    class PrefCheckBoxListener implements CheckBox.OnCheckedChangeListener
    {
        String key;

        PrefCheckBoxListener(String keyName) {
            key = keyName;
        }

        @Override
        public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
            editor = pref.edit();
            editor.putBoolean(key, isChecked);
            editor.commit();
        }
    }

    class PrefSelectedListener implements Spinner.OnItemSelectedListener {
        String key;

        PrefSelectedListener(String keyName) {
            key = keyName;
        }

        @Override
        public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
            editor = pref.edit();
            editor.putString(key, parent.getItemAtPosition(position).toString());
            editor.commit();
        }

        @Override
        public void onNothingSelected(AdapterView<?> parent) {

        }
    }

    private class IntNumberClickListener implements TextView.OnClickListener {
        String key = null;

        public IntNumberClickListener(String s) {
            key = s;
        }

        @Override
        public void onClick(View v) {
            TextView textView = (TextView) v;
            int value = 0;

            if (textView != null) {
                try {
                    value = Integer.parseInt(textView.getText().toString(), 10);
                } catch (NumberFormatException e) {
                    value = 0;
                }
            }
            if (value > 65535)
                value = 65535;
            IntNumberDialog dialog = new IntNumberDialog(getActivity(), R.style.CustomDialog);
            dialog.setKey(key);
            dialog.setNumber(value);
            dialog.setTarget(textView);
            dialog.show();
        }
    }

    private class FloatNumberClickListener implements TextView.OnClickListener {
        String key = null;

        public FloatNumberClickListener(String s) {
            key = s;
        }

        @Override
        public void onClick(View v) {
            TextView textView = (TextView) v;
            float value = 0;

            if (textView != null) {
                try {
                    value = Float.parseFloat(textView.getText().toString());
                } catch (NumberFormatException e) {
                    value = 0;
                }
            }
            FloatNumberDialog dialog = new FloatNumberDialog(getActivity(), R.style.CustomDialog);
            dialog.setKey(key);
            dialog.setNumber(value);
            dialog.setTarget(textView);
            dialog.show();
        }
    }

    private class TextClickListener implements TextView.OnClickListener {
        String key = null;

        public TextClickListener(String s) {
            key = s;
        }

        @Override
        public void onClick(View v) {
            TextView textView = (TextView) v;
            String value = "";

            if (textView != null) {
                value = textView.getText().toString();
            }
            TextEditDialog dialog = new TextEditDialog(getActivity(), R.style.CustomDialog);
            dialog.setKey(key);
            dialog.setString(value);
            dialog.setTarget(textView);
            dialog.show();
        }
    }

    public void initSpinner(int spinner_id, int array_id, String key, String value)
    {
        View view = getView();
        Spinner spinner = (Spinner) view.findViewById(spinner_id);
        int position;

        if (spinner == null)
            return;

        try {
            value = pref.getString(key, value);
        } catch (ClassCastException e) {
            // ...
        }

        ArrayAdapter<CharSequence> typeAdapter =
                ArrayAdapter.createFromResource(getActivity(), array_id, R.layout.spinner);

        typeAdapter.setDropDownViewResource(R.layout.spinner_dropdown);
        spinner.setAdapter(typeAdapter);
        position = typeAdapter.getPosition(value);
        spinner.setSelection(position);
        spinner.setOnItemSelectedListener(new PrefSelectedListener(key));
    }

    public void initSpinner(int spinner_id, List<CharSequence> items, String key, String value)
    {
        View view = getView();
        Spinner spinner = view.findViewById(spinner_id);
        int position;

        if (spinner == null)
            return;

        try {
            value = pref.getString(key, value);
        } catch (ClassCastException e) {
            // ...
        }

        ArrayAdapter<CharSequence> typeAdapter =
                new ArrayAdapter<CharSequence>(getActivity(), R.layout.spinner, items);

        typeAdapter.setDropDownViewResource(R.layout.spinner_dropdown);
        spinner.setAdapter(typeAdapter);
        position = typeAdapter.getPosition(value);
        spinner.setSelection(position);
        spinner.setOnItemSelectedListener(new PrefSelectedListener(key));
    }

    public void initEditInt(int edit_text_id, String key, int value)
    {
        View view = getView();
        TextView textView = view.findViewById(edit_text_id);

        if (textView == null)
            return;

        try {
            value = pref.getInt(key, value);
        } catch (ClassCastException e) {
            // ...
        }

        textView.setText(Integer.toString(value));
        textView.setOnClickListener(new IntNumberClickListener(key));
    }

    public void initEditFloat(int edit_text_id, String key, float value)
    {
        View view = getView();
        TextView textView = (TextView) view.findViewById(edit_text_id);

        if (textView == null)
            return;

        try {
            value = pref.getFloat(key, value);
        } catch (ClassCastException e) {
            // ...
        }

        textView.setText(String.format(Locale.US, "%f", value));
        textView.setOnClickListener(new FloatNumberClickListener(key));
    }

    public void initEditText(int edit_text_id, int value_id, String key)
    {
        View view = getView();

        if (view == null)
            return;

        TextView textView = view.findViewById(edit_text_id);
        String value = getResources().getString(value_id);

        if (textView == null)
            return;

        textView.setText(value);
        textView.setOnClickListener(new TextClickListener(key));
    }

    public void initCheckBox(int edit_text_id, String key, boolean value)
    {
        View view = getView();
        CheckBox checkbox = view.findViewById(edit_text_id);

        if (checkbox == null)
            return;

        try {
            value = pref.getBoolean(key, value);
        } catch (ClassCastException e) {
            // ...
        }

        checkbox.setChecked(value);
        checkbox.setOnCheckedChangeListener(new PrefCheckBoxListener(key));
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState)
    {
        return inflater.inflate(R.layout.settings, container, false);
    }

    @Override
    public void onDestroyView() {
        labelMap.clear();
        super.onDestroyView();
    }

    @Override
    public void onViewCreated(View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        labelMap.clear();
        mapLabels(getView());

        pref = PreferenceManager.getDefaultSharedPreferences(getActivity().getApplicationContext());

        initCheckBox(R.id.test_mode, PREF_TEST_MODE, false);
        initEditText(R.id.filename, R.string.default_filename, PREF_FILE_NAME);
        initSpinner(R.id.window_type, R.array.window_types, PREF_WINDOW_TYPE, "hann");
        initEditInt(R.id.window_size, PREF_WINDOW_SIZE, 3997);
        initEditInt(R.id.hop_size, PREF_HOP_SIZE, 1024);
        initEditInt(R.id.record_time, PREF_RECORD_TIME, 1024);
        initSpinner(R.id.sample_rate, R.array.sample_rates, PREF_SAMPLE_RATE, "24000");
        initSpinner(R.id.color_map, R.array.color_maps, PREF_COLOR_MAP, "ocean");
        initCheckBox(R.id.keep_screen, PREF_KEEP_SCREEN, true);
    }
}
