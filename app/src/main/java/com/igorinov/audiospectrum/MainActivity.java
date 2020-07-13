package com.igorinov.audiospectrum;

import android.Manifest;
import android.app.Dialog;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.widget.Button;
import android.widget.ToggleButton;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;

/**
 * Created by igorinov on 12/30/17.
 */

public class MainActivity extends AppCompatActivity {
    static final String TAG_SPECTRUM_FRAGMENT = "spectrum_fragment";
    static final int REQUEST_CODE_PREFERENCES = 1;
    MainFragment fragment = null;
    SharedPreferences pref;
    Button buttonRunStop;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        FragmentManager fm = getSupportFragmentManager();
        FragmentTransaction transaction;
        fragment = (MainFragment) fm.findFragmentByTag(TAG_SPECTRUM_FRAGMENT);
        if (fragment == null) {
            fragment = new MainFragment();
            transaction = fm.beginTransaction();
            transaction.add(fragment, TAG_SPECTRUM_FRAGMENT);
            transaction.commit();
        }
        transaction = fm.beginTransaction();
        transaction.replace(android.R.id.content, fragment);
        transaction.commit();

        pref = PreferenceManager.getDefaultSharedPreferences(this);

    }

    @Override
    protected void onPause() {
        super.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();

        buttonRunStop = (ToggleButton) fragment.buttonRunStop;
        int p;
        p = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO);
        if (p != PackageManager.PERMISSION_GRANTED) {
            if (buttonRunStop != null) {
                buttonRunStop.setEnabled(false);
            }
            ActivityCompat.requestPermissions(this,
                    new String[]{Manifest.permission.RECORD_AUDIO},
                    7);
        } else {
            if (buttonRunStop != null) {
                buttonRunStop.setEnabled(true);
            }
        }

        if (pref.getBoolean(SettingsFragment.PREF_TEST_MODE, false)) {
            p = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE);
            if (p != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this,
                        new String[]{Manifest.permission.READ_EXTERNAL_STORAGE},
                        8);
            }
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        switch (requestCode) {
            case 7:
                if (permissions[0].equals(Manifest.permission.RECORD_AUDIO)
                        && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    if (buttonRunStop != null) {
                        buttonRunStop.setEnabled(true);
                    }
                }
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.main, menu);
        return super.onCreateOptionsMenu(menu);
    }
    /*
     * Main menu
     */

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        Button b;
        // Handle item selection
        switch (item.getItemId()) {

            case R.id.settings:
                Intent intent = new Intent(this, SettingsActivity.class);
                startActivityForResult(intent, REQUEST_CODE_PREFERENCES);
                break;

            case R.id.about:
                Dialog aDialog = new Dialog(this, R.style.CustomDialog);
                aDialog.setContentView(R.layout.about);
                aDialog.setTitle(getString(R.string.app_name));
                aDialog.setCancelable(true);
                aDialog.show();
                break;

            default:
                return super.onOptionsItemSelected(item);
        }

        return true;
    }
}
