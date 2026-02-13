package com.hippo.ehviewer.client.data;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import com.hippo.ehviewer.Settings;
import com.hippo.ehviewer.client.EhConfig;
import com.hippo.ehviewer.client.EhUrl;
import com.hippo.ehviewer.client.EhUtils;
import com.hippo.ehviewer.dao.QuickSearch;
import com.hippo.ehviewer.widget.AdvanceSearchTable;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class ListUrlBuilderTest {

    private static final String HOST_E = EhUrl.HOST_E;

    @Before
    public void setUp() {
        Settings.initialize(RuntimeEnvironment.application);
        Settings.putGallerySite(EhUrl.SITE_E);
    }

    @Test
    public void build_normal_homepage() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setMode(ListUrlBuilder.MODE_NORMAL);
        assertEquals(HOST_E, b.build());
    }

    @Test
    public void build_normal_withCategory() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setMode(ListUrlBuilder.MODE_NORMAL);
        b.setCategory(EhConfig.DOUJINSHI | EhConfig.MANGA);
        String url = b.build();
        assertTrue(url.startsWith(HOST_E));
        assertTrue(url.contains("f_cats="));
    }

    @Test
    public void build_normal_withKeyword() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setMode(ListUrlBuilder.MODE_NORMAL);
        b.setKeyword("test tag");
        String url = b.build();
        assertTrue(url.startsWith(HOST_E));
        assertTrue(url.contains("f_search="));
    }

    @Test
    public void build_normal_withPage() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setMode(ListUrlBuilder.MODE_NORMAL);
        b.setPageIndex(2);
        String url = b.build();
        assertTrue(url.contains("page=2"));
    }

    @Test
    public void build_normal_withAdvanceSearch() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setMode(ListUrlBuilder.MODE_NORMAL);
        b.setAdvanceSearch(AdvanceSearchTable.SNAME | AdvanceSearchTable.STAGS);
        b.setMinRating(3);
        String url = b.build();
        assertTrue(url.contains("advsearch=1"));
        assertTrue(url.contains("f_sname=on"));
        assertTrue(url.contains("f_stags=on"));
        assertTrue(url.contains("f_sr=on"));
        assertTrue(url.contains("f_srdd=3"));
    }

    @Test
    public void build_uploader() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setMode(ListUrlBuilder.MODE_UPLOADER);
        b.setKeyword("user1");
        assertEquals(HOST_E + "uploader/user1", b.build());
    }

    @Test
    public void build_uploader_withPage() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setMode(ListUrlBuilder.MODE_UPLOADER);
        b.setKeyword("user1");
        b.setPageIndex(1);
        assertEquals(HOST_E + "uploader/user1/1", b.build());
    }

    @Test
    public void build_tag() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setMode(ListUrlBuilder.MODE_TAG);
        b.setKeyword("artist:name");
        assertEquals(HOST_E + "tag/artist%3Aname", b.build());
    }

    @Test
    public void build_tag_withPage() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setMode(ListUrlBuilder.MODE_TAG);
        b.setKeyword("female:glasses");
        b.setPageIndex(2);
        assertTrue(b.build().startsWith(HOST_E + "tag/"));
        assertTrue(b.build().endsWith("/2"));
    }

    @Test
    public void build_whatsHot() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setMode(ListUrlBuilder.MODE_WHATS_HOT);
        assertEquals(EhUrl.URL_POPULAR_E, b.build());
    }

    @Test
    public void build_imageSearch() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setMode(ListUrlBuilder.MODE_IMAGE_SEARCH);
        assertNotNull(b.build());
        assertTrue(b.build().contains("image"));
    }

    @Test
    public void setQuery_empty_resetsToHomepage() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setKeyword("foo");
        b.setCategory(EhConfig.DOUJINSHI);
        b.setQuery("");
        assertEquals(EhUtils.NONE, b.getCategory());
        assertEquals(null, b.getKeyword());
    }

    @Test
    public void setQuery_fSearch_setsKeyword() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setQuery("f_search=hello+world");
        assertEquals("hello world", b.getKeyword());
    }

    @Test
    public void setQuery_fCats_setsCategory() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setQuery("f_cats=0"); // 0 means all categories selected -> category becomes ALL_CATEGORY
        assertEquals(EhConfig.ALL_CATEGORY, b.getCategory());
    }

    @Test
    public void setQuery_advanceSearch_setsFlags() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setQuery("advsearch=1&f_sname=on&f_stags=on&f_sr=on&f_srdd=2");
        assertTrue(b.getAdvanceSearch() != -1);
        assertEquals(AdvanceSearchTable.SNAME | AdvanceSearchTable.STAGS, b.getAdvanceSearch());
        assertEquals(2, b.getMinRating());
    }

    @Test
    public void setQuery_thenBuild_roundTrip() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setMode(ListUrlBuilder.MODE_NORMAL);
        b.setQuery("f_search=tag&f_cats=1023&page=1");
        String url = b.build();
        assertTrue(url.contains("f_search="));
        assertTrue(url.contains("f_cats="));
        assertTrue(url.contains("page=1"));
    }

    @Test
    public void reset_clearsAll() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setMode(ListUrlBuilder.MODE_TAG);
        b.setKeyword("x");
        b.setPageIndex(5);
        b.setAdvanceSearch(AdvanceSearchTable.SNAME);
        b.reset();
        assertEquals(ListUrlBuilder.MODE_NORMAL, b.getMode());
        assertEquals(0, b.getPageIndex());
        assertEquals(EhUtils.NONE, b.getCategory());
        assertEquals(null, b.getKeyword());
        assertEquals(-1, b.getAdvanceSearch());
    }

    @Test
    public void clone_copiesFields() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setMode(ListUrlBuilder.MODE_TAG);
        b.setKeyword("clone");
        b.setPageIndex(3);
        ListUrlBuilder c = b.clone();
        assertEquals(b.getMode(), c.getMode());
        assertEquals(b.getKeyword(), c.getKeyword());
        assertEquals(b.getPageIndex(), c.getPageIndex());
    }

    @Test
    public void set_fromListUrlBuilder() {
        ListUrlBuilder src = new ListUrlBuilder();
        src.setMode(ListUrlBuilder.MODE_UPLOADER);
        src.setKeyword("src");
        ListUrlBuilder dst = new ListUrlBuilder();
        dst.set(src);
        assertEquals(ListUrlBuilder.MODE_UPLOADER, dst.getMode());
        assertEquals("src", dst.getKeyword());
    }

    @Test
    public void set_fromQuickSearch() {
        QuickSearch q = new QuickSearch();
        q.mode = ListUrlBuilder.MODE_TAG;
        q.keyword = "qs";
        q.advanceSearch = AdvanceSearchTable.STAGS;
        ListUrlBuilder b = new ListUrlBuilder();
        b.set(q);
        assertEquals(ListUrlBuilder.MODE_TAG, b.getMode());
        assertEquals("qs", b.getKeyword());
        assertEquals(AdvanceSearchTable.STAGS, b.getAdvanceSearch());
    }

    @Test
    public void toQuickSearch_andEqualsQuickSearch() {
        ListUrlBuilder b = new ListUrlBuilder();
        b.setMode(ListUrlBuilder.MODE_NORMAL);
        b.setKeyword("k");
        b.setCategory(EhConfig.MANGA);
        QuickSearch q = b.toQuickSearch();
        assertTrue(b.equalsQuickSearch(q));
        q.keyword = "other";
        assertFalse(b.equalsQuickSearch(q));
    }

    @Test
    public void parcelRoundTrip_preservesFields() {
        ListUrlBuilder src = new ListUrlBuilder();
        src.setMode(ListUrlBuilder.MODE_TAG);
        src.setPageIndex(2);
        src.setKeyword("parcel");
        src.setCategory(EhConfig.DOUJINSHI);
        src.setAdvanceSearch(AdvanceSearchTable.SDESC);
        src.setMinRating(4);
        src.setPageFrom(1);
        src.setPageTo(10);

        android.os.Parcel parcel = android.os.Parcel.obtain();
        src.writeToParcel(parcel, 0);
        parcel.setDataPosition(0);

        ListUrlBuilder dst = ListUrlBuilder.CREATOR.createFromParcel(parcel);
        parcel.recycle();

        assertEquals(src.getMode(), dst.getMode());
        assertEquals(src.getPageIndex(), dst.getPageIndex());
        assertEquals(src.getKeyword(), dst.getKeyword());
        assertEquals(src.getCategory(), dst.getCategory());
        assertEquals(src.getAdvanceSearch(), dst.getAdvanceSearch());
        assertEquals(src.getMinRating(), dst.getMinRating());
        assertEquals(src.getPageFrom(), dst.getPageFrom());
        assertEquals(src.getPageTo(), dst.getPageTo());
    }
}
