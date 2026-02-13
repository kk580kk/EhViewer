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

package com.hippo.ehviewer.client;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import android.content.Context;
import java.util.List;
import okhttp3.Cookie;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class EhCookieStoreTest {

    private EhCookieStore store;

    @Before
    public void setUp() {
        Context app = RuntimeEnvironment.application;
        store = new EhCookieStore(app);
    }

    @After
    public void tearDown() {
        if (store != null) {
            store.close();
        }
    }

    @Test
    public void getCookiesForDomain_emptyOrNull_returnsEmpty() {
        assertTrue(store.getCookiesForDomain(null).isEmpty());
        assertTrue(store.getCookiesForDomain("").isEmpty());
    }

    @Test
    public void getCookiesForDomain_afterAddCookie_returnsCookiesForThatDomain() {
        Cookie c1 = new Cookie.Builder()
                .name("a")
                .value("1")
                .domain(EhUrl.DOMAIN_E)
                .path("/")
                .expiresAt(System.currentTimeMillis() + 3600_000)
                .build();
        Cookie c2 = new Cookie.Builder()
                .name("b")
                .value("2")
                .domain(EhUrl.DOMAIN_E)
                .path("/")
                .expiresAt(System.currentTimeMillis() + 3600_000)
                .build();
        Cookie other = new Cookie.Builder()
                .name("x")
                .value("y")
                .domain(EhUrl.DOMAIN_EX)
                .path("/")
                .expiresAt(System.currentTimeMillis() + 3600_000)
                .build();

        store.addCookie(c1);
        store.addCookie(c2);
        store.addCookie(other);

        List<Cookie> forE = store.getCookiesForDomain(EhUrl.DOMAIN_E);
        List<Cookie> forEx = store.getCookiesForDomain(EhUrl.DOMAIN_EX);

        assertEquals(2, forE.size());
        assertTrue(forE.stream().anyMatch(c -> "a".equals(c.name()) && "1".equals(c.value())));
        assertTrue(forE.stream().anyMatch(c -> "b".equals(c.name()) && "2".equals(c.value())));
        assertEquals(1, forEx.size());
        assertEquals("x", forEx.get(0).name());
        assertEquals("y", forEx.get(0).value());
    }

    @Test
    public void getCookiesForDomain_subdomainMatch() {
        Cookie c = new Cookie.Builder()
                .name("sid")
                .value("abc")
                .domain(EhUrl.DOMAIN_E)
                .path("/")
                .expiresAt(System.currentTimeMillis() + 3600_000)
                .build();
        store.addCookie(c);

        List<Cookie> forRoot = store.getCookiesForDomain(EhUrl.DOMAIN_E);
        List<Cookie> forSub = store.getCookiesForDomain("forums." + EhUrl.DOMAIN_E);

        assertEquals(1, forRoot.size());
        assertEquals(1, forSub.size());
        assertEquals("sid", forSub.get(0).name());
    }

    @Test
    public void writeByDomain_addCookieThenReadByDomain() {
        store.addCookie(new Cookie.Builder()
                .name(EhCookieStore.KEY_IPD_MEMBER_ID)
                .value("123")
                .domain(EhUrl.DOMAIN_E)
                .path("/")
                .expiresAt(Long.MAX_VALUE)
                .build());
        store.addCookie(new Cookie.Builder()
                .name(EhCookieStore.KEY_IPD_PASS_HASH)
                .value("hash")
                .domain(EhUrl.DOMAIN_E)
                .path("/")
                .expiresAt(Long.MAX_VALUE)
                .build());

        List<Cookie> cookies = store.getCookiesForDomain(EhUrl.DOMAIN_E);
        assertEquals(2, cookies.size());
        assertTrue(store.hasSignedIn());
    }

    @Test
    public void signOut_clearsAllDomains() {
        store.addCookie(new Cookie.Builder()
                .name("k")
                .value("v")
                .domain(EhUrl.DOMAIN_E)
                .path("/")
                .expiresAt(Long.MAX_VALUE)
                .build());
        store.addCookie(new Cookie.Builder()
                .name("k2")
                .value("v2")
                .domain(EhUrl.DOMAIN_EX)
                .path("/")
                .expiresAt(Long.MAX_VALUE)
                .build());

        store.signOut();

        assertTrue(store.getCookiesForDomain(EhUrl.DOMAIN_E).isEmpty());
        assertTrue(store.getCookiesForDomain(EhUrl.DOMAIN_EX).isEmpty());
        assertFalse(store.hasSignedIn());
    }
}
