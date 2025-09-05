package com.hippo.desktop;

import javax.swing.ImageIcon;
import javax.swing.JLabel;
import javax.swing.JScrollPane;
import javax.swing.SwingConstants;
import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.Image;
import java.awt.image.BufferedImage;

public class ImagePanel extends JScrollPane {

    private final JLabel imageLabel;
    private BufferedImage originalImage;
    private double zoomLevel = 1.0;
    private boolean fitToWindow = true;

    public ImagePanel() {
        super();
        this.imageLabel = new JLabel();
        this.imageLabel.setHorizontalAlignment(SwingConstants.CENTER);
        this.imageLabel.setVerticalAlignment(SwingConstants.CENTER);
        setViewportView(imageLabel);
        setLayout(new BorderLayout());
    }

    public void showImage(BufferedImage image) {
        this.originalImage = image;
        updateDisplay();
    }
    
    public void setZoomLevel(double zoom) {
        this.zoomLevel = Math.max(0.1, Math.min(5.0, zoom));
        this.fitToWindow = false;
        updateDisplay();
    }
    
    public void zoomIn() {
        setZoomLevel(zoomLevel * 1.2);
    }
    
    public void zoomOut() {
        setZoomLevel(zoomLevel / 1.2);
    }
    
    public void fitToWindow() {
        this.fitToWindow = true;
        updateDisplay();
    }
    
    public void resetZoom() {
        this.zoomLevel = 1.0;
        this.fitToWindow = false;
        updateDisplay();
    }
    
    private void updateDisplay() {
        if (originalImage == null) {
            imageLabel.setIcon(null);
            imageLabel.setText("No image");
            return;
        }
        
        imageLabel.setText(null);
        
        int displayWidth, displayHeight;
        
        if (fitToWindow) {
            Dimension viewportSize = getViewport().getSize();
            if (viewportSize.width == 0 || viewportSize.height == 0) {
                viewportSize = getSize();
            }
            
            double widthRatio = (double) viewportSize.width / originalImage.getWidth();
            double heightRatio = (double) viewportSize.height / originalImage.getHeight();
            double ratio = Math.min(widthRatio, heightRatio);
            
            displayWidth = (int) (originalImage.getWidth() * ratio);
            displayHeight = (int) (originalImage.getHeight() * ratio);
        } else {
            displayWidth = (int) (originalImage.getWidth() * zoomLevel);
            displayHeight = (int) (originalImage.getHeight() * zoomLevel);
        }
        
        if (displayWidth != originalImage.getWidth() || displayHeight != originalImage.getHeight()) {
            Image scaledImage = originalImage.getScaledInstance(displayWidth, displayHeight, Image.SCALE_SMOOTH);
            imageLabel.setIcon(new ImageIcon(scaledImage));
        } else {
            imageLabel.setIcon(new ImageIcon(originalImage));
        }
        
        imageLabel.revalidate();
        imageLabel.repaint();
    }
    
    @Override
    public void doLayout() {
        super.doLayout();
        if (fitToWindow && originalImage != null) {
            updateDisplay();
        }
    }
}

