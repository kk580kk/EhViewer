package com.hippo.server.service;

import okhttp3.Cookie;
import okhttp3.CookieJar;
import okhttp3.HttpUrl;
import okhttp3.OkHttpClient;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class SessionService implements CookieJar {
    private final Map<String, List<Cookie>> hostCookies = new ConcurrentHashMap<>();
    private final OkHttpClient httpClient;

    public SessionService() {
        this.httpClient = new OkHttpClient.Builder()
                .cookieJar(this)
                .build();
    }

    public OkHttpClient getHttpClient() {
        return httpClient;
    }

    @Override
    public void saveFromResponse(HttpUrl url, List<Cookie> cookies) {
        hostCookies.put(url.host(), new ArrayList<>(cookies));
    }

    @Override
    public List<Cookie> loadForRequest(HttpUrl url) {
        return hostCookies.getOrDefault(url.host(), Collections.emptyList());
    }
}

