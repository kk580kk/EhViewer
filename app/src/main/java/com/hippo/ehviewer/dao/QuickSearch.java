package com.hippo.ehviewer.dao;

public class QuickSearch {

    public Long id;
    public String name;
    public int mode;
    public int category;
    public String keyword;
    public int advanceSearch;
    public int minRating;
    public int pageFrom;
    public int pageTo;
    public long time;

    public QuickSearch() {
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public int getMode() { return mode; }
    public void setMode(int mode) { this.mode = mode; }
    public int getCategory() { return category; }
    public void setCategory(int category) { this.category = category; }
    public String getKeyword() { return keyword; }
    public void setKeyword(String keyword) { this.keyword = keyword; }
    public int getAdvanceSearch() { return advanceSearch; }
    public void setAdvanceSearch(int advanceSearch) { this.advanceSearch = advanceSearch; }
    public int getMinRating() { return minRating; }
    public void setMinRating(int minRating) { this.minRating = minRating; }
    public int getPageFrom() { return pageFrom; }
    public void setPageFrom(int pageFrom) { this.pageFrom = pageFrom; }
    public int getPageTo() { return pageTo; }
    public void setPageTo(int pageTo) { this.pageTo = pageTo; }
    public long getTime() { return time; }
    public void setTime(long time) { this.time = time; }

    @Override
    public String toString() {
        return name;
    }
}
