/*
 * Copyright 2019 Hippo Seven
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

package com.hippo.ehviewer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

import java.net.Proxy;
import java.net.URI;
import java.util.List;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class EhProxySelectorTest {

    @Before
    public void setUp() {
        Settings.initialize(RuntimeEnvironment.application);
    }

    @Test
    public void testDirectProxy() throws Exception {
        Settings.putProxyType(EhProxySelector.TYPE_DIRECT);
        EhProxySelector selector = new EhProxySelector();

        URI uri = new URI("http://example.com");
        List<Proxy> proxies = selector.select(uri);

        assertNotNull(proxies);
        assertEquals(1, proxies.size());
        assertEquals(Proxy.NO_PROXY, proxies.get(0));
    }

    @Test
    public void testSystemProxy() throws Exception {
        Settings.putProxyType(EhProxySelector.TYPE_SYSTEM);
        EhProxySelector selector = new EhProxySelector();

        URI uri = new URI("http://example.com");
        List<Proxy> proxies = selector.select(uri);

        assertNotNull(proxies);
        // System proxy returns whatever the default proxy selector returns
        assertEquals(1, proxies.size());
    }

    @Test
    public void testHttpProxyWithValidConfig() throws Exception {
        Settings.putProxyType(EhProxySelector.TYPE_HTTP);
        Settings.putProxyIp("127.0.0.1");
        Settings.putProxyPort(8080);
        EhProxySelector selector = new EhProxySelector();

        URI uri = new URI("http://example.com");
        List<Proxy> proxies = selector.select(uri);

        assertNotNull(proxies);
        assertEquals(1, proxies.size());
        assertEquals(Proxy.Type.HTTP, proxies.get(0).type());
    }

    @Test
    public void testSocksProxyWithValidConfig() throws Exception {
        Settings.putProxyType(EhProxySelector.TYPE_SOCKS);
        Settings.putProxyIp("127.0.0.1");
        Settings.putProxyPort(1080);
        EhProxySelector selector = new EhProxySelector();

        URI uri = new URI("http://example.com");
        List<Proxy> proxies = selector.select(uri);

        assertNotNull(proxies);
        assertEquals(1, proxies.size());
        assertEquals(Proxy.Type.SOCKS, proxies.get(0).type());
    }

    @Test
    public void testHttpProxyWithInvalidPort() throws Exception {
        Settings.putProxyType(EhProxySelector.TYPE_HTTP);
        Settings.putProxyIp("127.0.0.1");
        Settings.putProxyPort(-1);
        EhProxySelector selector = new EhProxySelector();

        URI uri = new URI("http://example.com");
        List<Proxy> proxies = selector.select(uri);

        assertNotNull(proxies);
        // Should fall back to system proxy since config is invalid
        assertEquals(1, proxies.size());
    }

    @Test
    public void testHttpProxyWithEmptyIp() throws Exception {
        Settings.putProxyType(EhProxySelector.TYPE_HTTP);
        Settings.putProxyIp("");
        Settings.putProxyPort(8080);
        EhProxySelector selector = new EhProxySelector();

        URI uri = new URI("http://example.com");
        List<Proxy> proxies = selector.select(uri);

        assertNotNull(proxies);
        // Should fall back since IP is empty
        assertEquals(1, proxies.size());
    }

    @Test
    public void testUpdateProxy() throws Exception {
        Settings.putProxyType(EhProxySelector.TYPE_DIRECT);
        EhProxySelector selector = new EhProxySelector();

        URI uri = new URI("http://example.com");
        List<Proxy> proxies = selector.select(uri);
        assertEquals(Proxy.NO_PROXY, proxies.get(0));

        // Update to HTTP proxy
        Settings.putProxyType(EhProxySelector.TYPE_HTTP);
        Settings.putProxyIp("127.0.0.1");
        Settings.putProxyPort(8080);
        selector.updateProxy();

        proxies = selector.select(uri);
        assertEquals(1, proxies.size());
        assertEquals(Proxy.Type.HTTP, proxies.get(0).type());
    }
}
