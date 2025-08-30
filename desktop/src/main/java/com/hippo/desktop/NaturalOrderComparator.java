package com.hippo.desktop;

import java.util.Comparator;

public class NaturalOrderComparator implements Comparator<String> {

    @Override
    public int compare(String a, String b) {
        int ia = 0, ib = 0;
        int nza, nzb;
        char ca, cb;
        int result;
        while (true) {
            nza = nzb = 0;
            ca = charAt(a, ia);
            cb = charAt(b, ib);

            while (Character.isSpaceChar(ca) || ca == '0') {
                if (ca == '0') nza++;
                else nza = 0;
                ca = charAt(a, ++ia);
            }
            while (Character.isSpaceChar(cb) || cb == '0') {
                if (cb == '0') nzb++;
                else nzb = 0;
                cb = charAt(b, ++ib);
            }

            if (Character.isDigit(ca) && Character.isDigit(cb)) {
                result = compareRight(a.substring(ia), b.substring(ib));
                if (result != 0) return result;
            }

            if (ca == 0 && cb == 0) {
                return nza - nzb;
            }
            if (ca < cb) return -1;
            if (ca > cb) return +1;
            ++ia; ++ib;
        }
    }

    private static int compareRight(String a, String b) {
        int ia = 0, ib = 0;
        int bias = 0;
        for (;; ia++, ib++) {
            char ca = charAt(a, ia);
            char cb = charAt(b, ib);
            if (!Character.isDigit(ca) && !Character.isDigit(cb)) return bias;
            if (!Character.isDigit(ca)) return -1;
            if (!Character.isDigit(cb)) return +1;
            if (ca < cb) { if (bias == 0) bias = -1; }
            else if (ca > cb) { if (bias == 0) bias = +1; }
            else if (ca == 0 && cb == 0) return bias;
        }
    }

    private static char charAt(String s, int i) {
        if (i >= s.length()) return 0;
        return s.charAt(i);
    }
}

