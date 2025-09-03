package com.hippo.desktop;

import javax.swing.ImageIcon;
import javax.swing.JLabel;
import javax.swing.JScrollPane;
import javax.swing.SwingConstants;
import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;

public class ImagePanel extends JScrollPane {

    private final JLabel imageLabel;
    private BufferedImage originalImage;
    private boolean fitToWindow = true;

    public ImagePanel() {
        super();
        this.imageLabel = new JLabel();
        imageLabel.setHorizontalAlignment(SwingConstants.CENTER);
        imageLabel.setVerticalAlignment(SwingConstants.CENTER);
        setViewportView(imageLabel);
        setLayout(new BorderLayout());
    }

    public void showImage(BufferedImage image) {
        this.originalImage = image;
        updateDisplay();
    }

    private void updateDisplay() {
        if (originalImage == null) {
            imageLabel.setIcon(null);
            imageLabel.setText("No image");
            return;
        }
        
        imageLabel.setText(null);
        BufferedImage displayImage = originalImage;
        
        if (fitToWindow) {
            Dimension viewportSize = getViewport().getSize();
            if (viewportSize.width > 0 && viewportSize.height > 0) {
                displayImage = scaleImage(originalImage, viewportSize);
            }
        }
        
        imageLabel.setIcon(new ImageIcon(displayImage));
        imageLabel.revalidate();
        imageLabel.repaint();
    }

    private BufferedImage scaleImage(BufferedImage original, Dimension targetSize) {
        int originalWidth = original.getWidth();
        int originalHeight = original.getHeight();
        
        double scaleX = (double) targetSize.width / originalWidth;
        double scaleY = (double) targetSize.height / originalHeight;
        double scale = Math.min(scaleX, scaleY);
        
        // Don't upscale images
        if (scale > 1.0) scale = 1.0;
        
        int scaledWidth = (int) (originalWidth * scale);
        int scaledHeight = (int) (originalHeight * scale);
        
        BufferedImage scaled = new BufferedImage(scaledWidth, scaledHeight, BufferedImage.TYPE_INT_RGB);
        Graphics2D g2d = scaled.createGraphics();
        g2d.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
        g2d.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g2d.drawImage(original, 0, 0, scaledWidth, scaledHeight, null);
        g2d.dispose();
        
        return scaled;
    }

    public void toggleFitToWindow() {
        fitToWindow = !fitToWindow;
        updateDisplay();
    }

    public boolean isFitToWindow() {
        return fitToWindow;
    }
}

