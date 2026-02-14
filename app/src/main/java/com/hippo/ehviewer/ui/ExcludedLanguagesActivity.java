/*
 * Copyright 2016 Hippo Seven
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.hippo.ehviewer.ui;

import android.os.Bundle;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.hippo.android.resource.AttrResources;
import com.hippo.easyrecyclerview.EasyRecyclerView;
import com.hippo.ehviewer.R;
import com.hippo.ehviewer.Settings;
import com.hippo.ehviewer.client.ExcludedLanguagesHelper;
import com.hippo.ripple.Ripple;
import com.hippo.widget.SensitiveCheckBox;
import com.hippo.yorozuya.ViewUtils;

public class ExcludedLanguagesActivity extends ToolbarActivity
        implements View.OnClickListener {

    private static final String KEY_SELECTIONS = "selections";

    private static final int ROW_COUNT = ExcludedLanguagesHelper.ROW_COUNT;
    private static final int[] LANGUAGE_STR_IDS = {
            R.string.language_japanese,
            R.string.language_english,
            R.string.language_chinese,
            R.string.language_dutch,
            R.string.language_french,
            R.string.language_german,
            R.string.language_hungarian,
            R.string.language_italian,
            R.string.language_korean,
            R.string.language_polish,
            R.string.language_portuguese,
            R.string.language_russian,
            R.string.language_spanish,
            R.string.language_thai,
            R.string.language_vietnamese,
            R.string.language_na,
            R.string.language_other
    };

    private final boolean[][] mSelections = new boolean[ROW_COUNT][3];

    /*---------------
     Whole life cycle
     ---------------*/
    @Nullable
    private View mCancel;
    @Nullable
    private View mOk;
    @Nullable
    private View mSelectAll;
    @Nullable
    private View mDeselectAll;
    @Nullable
    private View mInvertSelection;
    @Nullable
    private EasyRecyclerView mRecyclerView;
    @Nullable
    private LanguageAdapter mAdapter;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.scene_excluded_languages);
        setNavigationIcon(R.drawable.v_arrow_left_dark_x24);

        if (null == savedInstanceState) {
            onInit();
        } else {
            onRestore(savedInstanceState);
        }

        mCancel = ViewUtils.$$(this, R.id.cancel);
        mOk = ViewUtils.$$(this, R.id.ok);
        mSelectAll = ViewUtils.$$(this, R.id.select_all);
        mDeselectAll = ViewUtils.$$(this, R.id.deselect_all);
        mInvertSelection = ViewUtils.$$(this, R.id.invert_selection);
        mRecyclerView = (EasyRecyclerView) ViewUtils.$$(this, R.id.recycler_view);

        mRecyclerView.setHasFixedSize(true);
        mRecyclerView.setClipToPadding(false);
        mAdapter = new LanguageAdapter();
        mRecyclerView.setAdapter(mAdapter);
        mRecyclerView.setLayoutManager(new LinearLayoutManager(this));

        mCancel.setOnClickListener(this);
        mOk.setOnClickListener(this);
        mSelectAll.setOnClickListener(this);
        mDeselectAll.setOnClickListener(this);
        mInvertSelection.setOnClickListener(this);

        boolean isDarkTheme = !AttrResources.getAttrBoolean(this, R.attr.isLightTheme);
        Ripple.addRipple(mCancel, isDarkTheme);
        Ripple.addRipple(mOk, isDarkTheme);
        Ripple.addRipple(mSelectAll, isDarkTheme);
        Ripple.addRipple(mDeselectAll, isDarkTheme);
        Ripple.addRipple(mInvertSelection, isDarkTheme);
    }

    private void onInit() {
        String excludedLanguages = Settings.getExcludedLanguages();
        boolean[][] parsed = ExcludedLanguagesHelper.parseExcludedLanguages(excludedLanguages);
        for (int i = 0; i < ROW_COUNT; i++) {
            System.arraycopy(parsed[i], 0, mSelections[i], 0, 3);
        }
    }

    private long saveSelectionsToLong() {
        boolean[][] selections = mSelections;
        long value = 0;
        for (int i = 0; i < ROW_COUNT; i++) {
            for (int j = 0; j < 3; j++) {
                if (selections[i][j]) {
                    value |= 1 << (i * 3 + j);
                }
            }
        }
        return value;
    }

    private void restoreSelectionsFromLong(long value) {
        boolean[][] selections = mSelections;
        for (int i = 0; i < ROW_COUNT; i++) {
            for (int j = 0; j < 3; j++) {
                selections[i][j] = 0 != ((value >>> (i * 3 + j)) & 1);
            }
        }
    }

    private void onRestore(@NonNull Bundle savedInstanceState) {
        restoreSelectionsFromLong(savedInstanceState.getLong(KEY_SELECTIONS));
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putLong(KEY_SELECTIONS, saveSelectionsToLong());
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        mCancel = null;
        mOk = null;
        mSelectAll = null;
        mDeselectAll = null;
        mInvertSelection = null;
        mRecyclerView = null;
        mAdapter = null;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case android.R.id.home:
                finish();
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }

    @Override
    public void onClick(View v) {
        if (null == mAdapter) {
            return;
        }

        if (v == mCancel) {
            finish();
        } else if (v == mOk) {
            String excludedLanguages = ExcludedLanguagesHelper.buildExcludedLanguages(mSelections);
            Settings.putExcludedLanguages(excludedLanguages);
            finish();
        } else if (v == mSelectAll) {
            for (boolean[] selections : mSelections) {
                int length = selections.length;
                for (int i = 0; i < length; i++) {
                    selections[i] = true;
                }
            }
            mAdapter.notifyDataSetChanged();
        } else if (v == mDeselectAll) {
            for (boolean[] selections : mSelections) {
                int length = selections.length;
                for (int i = 0; i < length; i++) {
                    selections[i] = false;
                }
            }
            mAdapter.notifyDataSetChanged();
        } else if (v == mInvertSelection) {
            for (boolean[] selections : mSelections) {
                int length = selections.length;
                for (int i = 0; i < length; i++) {
                    selections[i] = !selections[i];
                }
            }
            mAdapter.notifyDataSetChanged();
        }
    }

    private class LanguageHolder extends RecyclerView.ViewHolder
            implements SensitiveCheckBox.OnCheckedChangeListener {

        public TextView language;
        public SensitiveCheckBox original;
        public SensitiveCheckBox translated;
        public SensitiveCheckBox rewrite;

        public LanguageHolder(View itemView) {
            super(itemView);

            ViewGroup viewGroup = (ViewGroup) itemView;
            language = (TextView) viewGroup.getChildAt(0);
            original = (SensitiveCheckBox) viewGroup.getChildAt(1);
            translated = (SensitiveCheckBox) viewGroup.getChildAt(2);
            rewrite = (SensitiveCheckBox) viewGroup.getChildAt(3);

            original.setOnCheckedChangeListener(this);
            translated.setOnCheckedChangeListener(this);
            rewrite.setOnCheckedChangeListener(this);
        }

        @Override
        public void onCheckedChanged(SensitiveCheckBox view, boolean isChecked, boolean fromUser) {
            if (fromUser) {
                int row = getAdapterPosition();
                if (row < 0) {
                    return;
                }
                int column;
                if (view == original) {
                    column = 0;
                } else if (view == translated) {
                    column = 1;
                } else {
                    column = 2;
                }
                mSelections[row][column] = !mSelections[row][column];
            }
        }
    }

    private class LanguageAdapter extends RecyclerView.Adapter<LanguageHolder> {

        @Override
        public LanguageHolder onCreateViewHolder(ViewGroup parent, int viewType) {
            return new LanguageHolder(getLayoutInflater().inflate(R.layout.item_excluded_languages, parent, false));
        }

        @Override
        public void onBindViewHolder(LanguageHolder holder, int position) {
            holder.language.setText(LANGUAGE_STR_IDS[position]);
            boolean[] selections = mSelections[position];
            holder.original.setChecked(selections[0]);
            holder.translated.setChecked(selections[1]);
            holder.rewrite.setChecked(selections[2]);
        }

        @Override
        public int getItemCount() {
            return ROW_COUNT;
        }
    }
}
