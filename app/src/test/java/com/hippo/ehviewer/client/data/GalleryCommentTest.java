package com.hippo.ehviewer.client.data;

import android.os.Parcel;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class GalleryCommentTest {

  private static GalleryComment createSampleComment() {
    GalleryComment c = new GalleryComment();
    c.id = 12345L;
    c.score = 10;
    c.editable = true;
    c.voteUpAble = true;
    c.voteUpEd = false;
    c.voteDownAble = true;
    c.voteDownEd = true;
    c.voteState = "vote-state";
    c.time = 1609459200000L;
    c.user = "testuser";
    c.comment = "<p>Sample comment</p>";
    c.lastEdited = 1609545600000L;
    return c;
  }

  @Test
  public void galleryComment_parcelRoundTrip_preservesAllFields() {
    GalleryComment src = createSampleComment();

    Parcel parcel = Parcel.obtain();
    src.writeToParcel(parcel, 0);
    parcel.setDataPosition(0);

    GalleryComment dst = GalleryComment.CREATOR.createFromParcel(parcel);
    parcel.recycle();

    assertEquals(src.id, dst.id);
    assertEquals(src.score, dst.score);
    assertEquals(src.editable, dst.editable);
    assertEquals(src.voteUpAble, dst.voteUpAble);
    assertEquals(src.voteUpEd, dst.voteUpEd);
    assertEquals(src.voteDownAble, dst.voteDownAble);
    assertEquals(src.voteDownEd, dst.voteDownEd);
    assertEquals(src.voteState, dst.voteState);
    assertEquals(src.time, dst.time);
    assertEquals(src.user, dst.user);
    assertEquals(src.comment, dst.comment);
    assertEquals(src.lastEdited, dst.lastEdited);
  }

  @Test
  public void galleryComment_describeContents_returnsZero() {
    GalleryComment c = new GalleryComment();
    assertEquals(0, c.describeContents());
  }

  @Test
  public void galleryCommentList_parcelRoundTrip_preservesCommentsAndHasMore() {
    GalleryComment c1 = createSampleComment();
    c1.id = 1L;
    c1.user = "user1";
    GalleryComment c2 = new GalleryComment();
    c2.id = 2L;
    c2.user = "user2";
    c2.comment = "second";
    GalleryComment[] comments = new GalleryComment[]{c1, c2};
    GalleryCommentList src = new GalleryCommentList(comments, true);

    Parcel parcel = Parcel.obtain();
    src.writeToParcel(parcel, 0);
    parcel.setDataPosition(0);

    GalleryCommentList dst = GalleryCommentList.CREATOR.createFromParcel(parcel);
    parcel.recycle();

    assertNotNull(dst.comments);
    assertEquals(2, dst.comments.length);
    assertEquals(1L, dst.comments[0].id);
    assertEquals("user1", dst.comments[0].user);
    assertEquals(2L, dst.comments[1].id);
    assertEquals("user2", dst.comments[1].user);
    assertEquals("second", dst.comments[1].comment);
    assertEquals(true, dst.hasMore);
  }

  @Test
  public void galleryCommentList_parcelRoundTrip_emptyCommentsAndNoMore() {
    GalleryCommentList src = new GalleryCommentList(new GalleryComment[0], false);

    Parcel parcel = Parcel.obtain();
    src.writeToParcel(parcel, 0);
    parcel.setDataPosition(0);

    GalleryCommentList dst = GalleryCommentList.CREATOR.createFromParcel(parcel);
    parcel.recycle();

    assertNotNull(dst.comments);
    assertEquals(0, dst.comments.length);
    assertEquals(false, dst.hasMore);
  }

  @Test
  public void galleryCommentList_describeContents_returnsZero() {
    GalleryCommentList list = new GalleryCommentList(new GalleryComment[0], false);
    assertEquals(0, list.describeContents());
  }

  @Test
  public void galleryCommentList_creatorNewArray_returnsCorrectSize() {
    GalleryCommentList[] arr = GalleryCommentList.CREATOR.newArray(3);
    assertNotNull(arr);
    assertEquals(3, arr.length);
  }
}
