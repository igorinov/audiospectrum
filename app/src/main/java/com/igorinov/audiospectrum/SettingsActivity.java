package com.igorinov.audiospectrum;

import android.app.Activity;
import android.os.Bundle;

import androidx.fragment.app.FragmentActivity;

/**
 * Created by igorinov on 9/30/14.
 */
public class SettingsActivity extends FragmentActivity
{
    @Override
    protected void onCreate(final Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setResult(Activity.RESULT_OK);
        getSupportFragmentManager().beginTransaction().replace(android.R.id.content, new SettingsFragment()).commit();
    }

    @Override
    protected void onPause() {
        setResult(Activity.RESULT_OK);
        super.onPause();
    }

    @Override
    protected void onStop() {
        setResult(Activity.RESULT_OK);
        super.onStop();
    }
}
