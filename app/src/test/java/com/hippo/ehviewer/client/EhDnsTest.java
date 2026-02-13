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

package com.hippo.ehviewer.client;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import com.hippo.ehviewer.Hosts;
import com.hippo.ehviewer.Settings;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.List;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class EhDnsTest {

  private Hosts hosts;

  @Before
  public void setUp() {
    Settings.initialize(RuntimeEnvironment.application);
    hosts = new Hosts(RuntimeEnvironment.application, "ehdns_test_hosts.db");
  }

  @Test(expected = UnknownHostException.class)
  public void testLookupNullHostnameThrows() throws UnknownHostException {
    EhDns dns = new EhDns(hosts);
    dns.lookup(null);
  }

  @Test
  public void testLookupUsesUserHosts() throws UnknownHostException {
    assertTrue(hosts.put("custom.example.com", "192.168.1.100"));
    EhDns dns = new EhDns(hosts);
    List<InetAddress> result = dns.lookup("custom.example.com");
    assertNotNull(result);
    assertEquals(1, result.size());
    assertEquals("custom.example.com/192.168.1.100", result.get(0).toString());
  }

  @Test
  public void testLookupUsesBuiltInHostsWhenEnabled() throws UnknownHostException {
    Settings.putBuiltInHosts(true);
    EhDns dns = new EhDns(hosts);
    List<InetAddress> result = dns.lookup("e-hentai.org");
    assertNotNull(result);
    assertEquals(1, result.size());
    assertEquals("e-hentai.org/104.20.26.25", result.get(0).toString());
  }

  @Test
  public void testLookupIgnoresBuiltInHostsWhenDisabled() throws UnknownHostException {
    Settings.putBuiltInHosts(false);
    EhDns dns = new EhDns(hosts);
    List<InetAddress> result = dns.lookup("e-hentai.org");
    assertNotNull(result);
    assertFalse(result.isEmpty());
    assertTrue(result.get(0).getHostAddress().length() > 0);
  }

  @Test
  public void testLookupUserHostsTakesPrecedenceOverBuiltIn() throws UnknownHostException {
    Settings.putBuiltInHosts(true);
    assertTrue(hosts.put("e-hentai.org", "127.0.0.1"));
    EhDns dns = new EhDns(hosts);
    List<InetAddress> result = dns.lookup("e-hentai.org");
    assertNotNull(result);
    assertEquals(1, result.size());
    assertEquals("e-hentai.org/127.0.0.1", result.get(0).toString());
  }

  @Test
  public void testLookupFallsBackToSystemForUnknownHost() throws UnknownHostException {
    Settings.putBuiltInHosts(false);
    EhDns dns = new EhDns(hosts);
    List<InetAddress> result = dns.lookup("localhost");
    assertNotNull(result);
    assertFalse(result.isEmpty());
  }
}
