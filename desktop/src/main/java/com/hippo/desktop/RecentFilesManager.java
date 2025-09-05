package com.hippo.desktop;

import java.util.ArrayList;
import java.util.List;
import java.util.prefs.Preferences;

/**
 * Utility class that stores and retrieves recently opened files or directories
 * using {@link java.util.prefs.Preferences}. It keeps the order (most recent first)
 * and a maximum of {@value #MAX_RECENT} entries.
 */
public class RecentFilesManager {

    private static final String PREF_KEY = "recent_files";
    private static final String DELIMITER = "|"; // unlikely in file path
    private static final int MAX_RECENT = 10;

    private final Preferences prefs;

    public RecentFilesManager(Class<?> cls) {
        prefs = Preferences.userNodeForPackage(cls);
    }

    /**
     * Adds a path to recent list, moves it to top if already exists.
     */
    public void add(String path) {
        if (path == null || path.isEmpty()) return;
        List<String> list = get();
        list.remove(path);
        list.add(0, path);
        while (list.size() > MAX_RECENT) {
            list.remove(list.size() - 1);
        }
        save(list);
    }

    /**
     * Returns recent list (most recent first).
     */
    public List<String> get() {
        String raw = prefs.get(PREF_KEY, "");
        List<String> list = new ArrayList<>();
        if (!raw.isEmpty()) {
            for (String s : raw.split("\\Q" + DELIMITER + "\\E")) {
                if (!s.isEmpty()) list.add(s);
            }
        }
        return list;
    }

    /** Clears all stored entries */
    public void clear() {
        prefs.remove(PREF_KEY);
    }

    private void save(List<String> list) {
        StringBuilder sb = new StringBuilder();
        for (String s : list) {
            if (sb.length() > 0) sb.append(DELIMITER);
            sb.append(s);
        }
        prefs.put(PREF_KEY, sb.toString());
    }
}