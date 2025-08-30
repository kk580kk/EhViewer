package com.hippo.desktop;

import javax.swing.JButton;
import javax.swing.JFileChooser;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JMenu;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.SwingUtilities;
import javax.swing.WindowConstants;
import javax.swing.filechooser.FileNameExtensionFilter;
import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.io.File;

public class Main {
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            JFrame frame = new JFrame("EhViewer Desktop (Minimal)");
            frame.setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);
            frame.setLayout(new BorderLayout());
            frame.setPreferredSize(new Dimension(960, 640));

            ReaderController controller = new ReaderController();
            ImagePanel imagePanel = new ImagePanel();
            frame.add(imagePanel, BorderLayout.CENTER);

            JPanel bottomBar = new JPanel(new FlowLayout(FlowLayout.LEFT));
            JButton prev = new JButton("Prev");
            JButton next = new JButton("Next");
            JLabel status = new JLabel("No book opened");
            bottomBar.add(prev);
            bottomBar.add(next);
            bottomBar.add(status);
            frame.add(bottomBar, BorderLayout.SOUTH);

            JMenuBar menuBar = new JMenuBar();
            JMenu fileMenu = new JMenu("File");
            JMenuItem openDirItem = new JMenuItem("Open Folder...");
            JMenuItem openZipItem = new JMenuItem("Open Zip...");
            fileMenu.add(openDirItem);
            fileMenu.add(openZipItem);
            menuBar.add(fileMenu);
            frame.setJMenuBar(menuBar);

            Runnable refresh = () -> {
                try {
                    if (controller.hasImages()) {
                        imagePanel.showImage(controller.loadCurrentImage());
                        status.setText((controller.getCurrentIndex() + 1) + "/" + controller.getTotalCount() + " - " + controller.getCurrentName());
                    } else {
                        imagePanel.showImage(null);
                        status.setText("No images");
                    }
                } catch (Exception e) {
                    JOptionPane.showMessageDialog(frame, "Failed to load image: " + e.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                }
            };

            prev.addActionListener(e -> { if (controller.previous()) refresh.run(); });
            next.addActionListener(e -> { if (controller.next()) refresh.run(); });

            openDirItem.addActionListener(e -> {
                JFileChooser chooser = new JFileChooser();
                chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
                if (chooser.showOpenDialog(frame) == JFileChooser.APPROVE_OPTION) {
                    File dir = chooser.getSelectedFile();
                    try {
                        controller.openDirectory(dir);
                        refresh.run();
                    } catch (Exception ex) {
                        JOptionPane.showMessageDialog(frame, "Failed to open: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                    }
                }
            });

            openZipItem.addActionListener(e -> {
                JFileChooser chooser = new JFileChooser();
                chooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
                chooser.setFileFilter(new FileNameExtensionFilter("Archives", "zip", "cbz"));
                if (chooser.showOpenDialog(frame) == JFileChooser.APPROVE_OPTION) {
                    File file = chooser.getSelectedFile();
                    try {
                        controller.openZip(file);
                        refresh.run();
                    } catch (Exception ex) {
                        JOptionPane.showMessageDialog(frame, "Failed to open: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                    }
                }
            });

            frame.pack();
            frame.setLocationRelativeTo(null);
            frame.setVisible(true);
        });
    }
}

