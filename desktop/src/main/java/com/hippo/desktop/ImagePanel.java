package com.hippo.desktop;

import javax.swing.ImageIcon;
import javax.swing.JLabel;
import javax.swing.JScrollPane;
import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;

public class ImagePanel extends JScrollPane {

    private final JLabel imageLabel;
    private BufferedImage originalImage;
    private double scaleFactor = 1.0;

    public ImagePanel() {
        super();
        this.imageLabel = new JLabel();
        setViewportView(imageLabel);
        setLayout(new BorderLayout());
        imageLabel.setHorizontalAlignment(JLabel.CENTER);
        imageLabel.setVerticalAlignment(JLabel.CENTER);
    }

    public void showImage(BufferedImage image) {
        this.originalImage = image;
        if (image == null) {
            imageLabel.setIcon(null);
            imageLabel.setText("No image");
            return;
        }
        imageLabel.setText(null);
        updateDisplayedImage();
    }

    public void setScaleFactor(double scaleFactor) {
        this.scaleFactor = Math.max(0.1, Math.min(5.0, scaleFactor));
        if (originalImage != null) {
            updateDisplayedImage();
        }
    }

    public double getScaleFactor() {
        return scaleFactor;
    }

    public void zoomIn() {
        setScaleFactor(scaleFactor * 1.2);
    }

    public void zoomOut() {
        setScaleFactor(scaleFactor / 1.2);
    }

    public void fitToWindow() {
        if (originalImage == null) return;
        
        Dimension viewportSize = getViewport().getSize();
        if (viewportSize.width <= 0 || viewportSize.height <= 0) return;
        
        double scaleX = (double) viewportSize.width / originalImage.getWidth();
        double scaleY = (double) viewportSize.height / originalImage.getHeight();
        setScaleFactor(Math.min(scaleX, scaleY) * 0.95); // 95% to leave some margin
    }

    public void actualSize() {
        setScaleFactor(1.0);
    }

    private void updateDisplayedImage() {
        if (originalImage == null) return;
        
        int newWidth = (int) (originalImage.getWidth() * scaleFactor);
        int newHeight = (int) (originalImage.getHeight() * scaleFactor);
        
        BufferedImage scaledImage = new BufferedImage(newWidth, newHeight, BufferedImage.TYPE_INT_RGB);
        Graphics2D g2d = scaledImage.createGraphics();
        g2d.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
        g2d.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        
        g2d.drawImage(originalImage, 0, 0, newWidth, newHeight, null);
        g2d.dispose();
        
        imageLabel.setIcon(new ImageIcon(scaledImage));
        imageLabel.revalidate();
        imageLabel.repaint();
    }
}

