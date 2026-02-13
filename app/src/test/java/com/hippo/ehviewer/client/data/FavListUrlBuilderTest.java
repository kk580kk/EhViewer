package com.hippo.ehviewer.client.data;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import com.hippo.ehviewer.Settings;
import com.hippo.ehviewer.client.EhUrl;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FavListUrlBuilderTest {

    private static final String URL_FAVORITES_E = EhUrl.URL_FAVORITES_E;

    @Before
    public void setUp() {
        Settings.initialize(RuntimeEnvironment.application);
        Settings.putGallerySite(EhUrl.SITE_E);
    }

    @Test
    public void build_default_isBaseFavoritesUrl() {
        FavListUrlBuilder b = new FavListUrlBuilder();
        assertTrue(b.build().startsWith(URL_FAVORITES_E));
        assertTrue(b.build().contains("favcat=all"));
    }

    @Test
    public void build_favCatAll_hasFavcatAll() {
        FavListUrlBuilder b = new FavListUrlBuilder();
        b.setFavCat(FavListUrlBuilder.FAV_CAT_ALL);
        assertTrue(b.build().contains("favcat=all"));
    }

    @Test
    public void build_favCatValid_addsFavcatNumber() {
        FavListUrlBuilder b = new FavListUrlBuilder();
        b.setFavCat(3);
        String url = b.build();
        assertTrue(url.contains("favcat=3"));
    }

    @Test
    public void build_favCatLocal_noFavcatParam() {
        FavListUrlBuilder b = new FavListUrlBuilder();
        b.setFavCat(FavListUrlBuilder.FAV_CAT_LOCAL);
        String url = b.build();
        assertFalse(url.contains("favcat="));
    }

    @Test
    public void build_withKeyword_addsSearchParams() {
        FavListUrlBuilder b = new FavListUrlBuilder();
        b.setKeyword("test");
        String url = b.build();
        assertTrue(url.contains("f_search="));
        assertTrue(url.contains("sn=on"));
        assertTrue(url.contains("st=on"));
        assertTrue(url.contains("sf=on"));
    }

    @Test
    public void build_withIndex_addsPageParam() {
        FavListUrlBuilder b = new FavListUrlBuilder();
        b.setIndex(2);
        assertTrue(b.build().contains("page=2"));
    }

    @Test
    public void build_indexZero_noPageParam() {
        FavListUrlBuilder b = new FavListUrlBuilder();
        b.setIndex(0);
        assertFalse(b.build().contains("page="));
    }

    @Test
    public void isValidFavCat_validRange() {
        assertTrue(FavListUrlBuilder.isValidFavCat(0));
        assertTrue(FavListUrlBuilder.isValidFavCat(9));
        assertFalse(FavListUrlBuilder.isValidFavCat(-1));
        assertFalse(FavListUrlBuilder.isValidFavCat(10));
    }

    @Test
    public void isLocalFavCat() {
        FavListUrlBuilder b = new FavListUrlBuilder();
        assertFalse(b.isLocalFavCat());
        b.setFavCat(FavListUrlBuilder.FAV_CAT_LOCAL);
        assertTrue(b.isLocalFavCat());
    }

    @Test
    public void getters_returnSetValues() {
        FavListUrlBuilder b = new FavListUrlBuilder();
        b.setKeyword("kw");
        b.setFavCat(5);
        assertEquals("kw", b.getKeyword());
        assertEquals(5, b.getFavCat());
    }

    @Test
    public void parcelRoundTrip_preservesBuildResult() {
        FavListUrlBuilder src = new FavListUrlBuilder();
        src.setIndex(3);
        src.setKeyword("parcel");
        src.setFavCat(2);
        String expectedUrl = src.build();

        android.os.Parcel parcel = android.os.Parcel.obtain();
        src.writeToParcel(parcel, 0);
        parcel.setDataPosition(0);

        FavListUrlBuilder dst = FavListUrlBuilder.CREATOR.createFromParcel(parcel);
        parcel.recycle();

        assertEquals(expectedUrl, dst.build());
        assertEquals("parcel", dst.getKeyword());
        assertEquals(2, dst.getFavCat());
    }
}
