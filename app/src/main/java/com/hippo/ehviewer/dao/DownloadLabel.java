package com.hippo.ehviewer.dao;

public class DownloadLabel {

    private Long id;
    private String label;
    private long time;

    public DownloadLabel() {
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getLabel() { return label; }
    public void setLabel(String label) { this.label = label; }
    public long getTime() { return time; }
    public void setTime(long time) { this.time = time; }
}
