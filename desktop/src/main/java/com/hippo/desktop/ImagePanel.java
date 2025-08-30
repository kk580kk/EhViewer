package com.hippo.desktop;

import javax.swing.ImageIcon;
import javax.swing.JLabel;
import javax.swing.JScrollPane;
import java.awt.BorderLayout;
import java.awt.image.BufferedImage;

public class ImagePanel extends JScrollPane {

    private final JLabel imageLabel;

    public ImagePanel() {
        super();
        this.imageLabel = new JLabel();
        setViewportView(imageLabel);
        setLayout(new BorderLayout());
    }

    public void showImage(BufferedImage image) {
        if (image == null) {
            imageLabel.setIcon(null);
            imageLabel.setText("No image");
            return;
        }
        imageLabel.setText(null);
        imageLabel.setIcon(new ImageIcon(image));
        imageLabel.revalidate();
        imageLabel.repaint();
    }
}

