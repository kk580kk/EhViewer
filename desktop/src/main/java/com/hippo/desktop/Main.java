package com.hippo.desktop;

import javax.swing.AbstractAction;
import javax.swing.JButton;
import javax.swing.JFileChooser;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JMenu;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.KeyStroke;
import javax.swing.SwingUtilities;
import javax.swing.WindowConstants;
import javax.swing.filechooser.FileNameExtensionFilter;
import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.KeyEvent;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
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
            JButton zoomIn = new JButton("Zoom In");
            JButton zoomOut = new JButton("Zoom Out");
            JButton fitToWindow = new JButton("Fit to Window");
            JButton actualSize = new JButton("Actual Size");
            JLabel status = new JLabel("No book opened");
            bottomBar.add(prev);
            bottomBar.add(next);
            bottomBar.add(zoomIn);
            bottomBar.add(zoomOut);
            bottomBar.add(fitToWindow);
            bottomBar.add(actualSize);
            bottomBar.add(status);
            frame.add(bottomBar, BorderLayout.SOUTH);

            JMenuBar menuBar = new JMenuBar();
            JMenu fileMenu = new JMenu("File");
            JMenuItem openDirItem = new JMenuItem("Open Folder...");
            JMenuItem openZipItem = new JMenuItem("Open Zip...");
            fileMenu.add(openDirItem);
            fileMenu.add(openZipItem);
            menuBar.add(fileMenu);
            
            JMenu viewMenu = new JMenu("View");
            JMenuItem zoomInItem = new JMenuItem("Zoom In");
            JMenuItem zoomOutItem = new JMenuItem("Zoom Out");
            JMenuItem fitToWindowItem = new JMenuItem("Fit to Window");
            JMenuItem actualSizeItem = new JMenuItem("Actual Size");
            viewMenu.add(zoomInItem);
            viewMenu.add(zoomOutItem);
            viewMenu.addSeparator();
            viewMenu.add(fitToWindowItem);
            viewMenu.add(actualSizeItem);
            menuBar.add(viewMenu);
            
            frame.setJMenuBar(menuBar);

            Runnable refresh = () -> {
                try {
                    if (controller.hasImages()) {
                        imagePanel.showImage(controller.loadCurrentImage());
                        String scaleText = String.format("%.0f%%", imagePanel.getScaleFactor() * 100);
                        status.setText((controller.getCurrentIndex() + 1) + "/" + controller.getTotalCount() + " - " + controller.getCurrentName() + " (" + scaleText + ")");
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
            zoomIn.addActionListener(e -> { imagePanel.zoomIn(); refresh.run(); });
            zoomOut.addActionListener(e -> { imagePanel.zoomOut(); refresh.run(); });
            fitToWindow.addActionListener(e -> { imagePanel.fitToWindow(); refresh.run(); });
            actualSize.addActionListener(e -> { imagePanel.actualSize(); refresh.run(); });
            
            // Menu item listeners
            zoomInItem.addActionListener(e -> { imagePanel.zoomIn(); refresh.run(); });
            zoomOutItem.addActionListener(e -> { imagePanel.zoomOut(); refresh.run(); });
            fitToWindowItem.addActionListener(e -> { imagePanel.fitToWindow(); refresh.run(); });
            actualSizeItem.addActionListener(e -> { imagePanel.actualSize(); refresh.run(); });

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

            // Add keyboard shortcuts
            frame.getRootPane().getInputMap().put(KeyStroke.getKeyStroke(KeyEvent.VK_LEFT, 0), "prev");
            frame.getRootPane().getInputMap().put(KeyStroke.getKeyStroke(KeyEvent.VK_RIGHT, 0), "next");
            frame.getRootPane().getInputMap().put(KeyStroke.getKeyStroke(KeyEvent.VK_PLUS, 0), "zoomIn");
            frame.getRootPane().getInputMap().put(KeyStroke.getKeyStroke(KeyEvent.VK_EQUALS, 0), "zoomIn");
            frame.getRootPane().getInputMap().put(KeyStroke.getKeyStroke(KeyEvent.VK_MINUS, 0), "zoomOut");
            frame.getRootPane().getInputMap().put(KeyStroke.getKeyStroke(KeyEvent.VK_F, 0), "fitToWindow");
            frame.getRootPane().getInputMap().put(KeyStroke.getKeyStroke(KeyEvent.VK_1, 0), "actualSize");
            frame.getRootPane().getInputMap().put(KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0), "exit");
            
            frame.getRootPane().getActionMap().put("prev", new AbstractAction() {
                @Override
                public void actionPerformed(ActionEvent e) {
                    if (controller.previous()) refresh.run();
                }
            });
            frame.getRootPane().getActionMap().put("next", new AbstractAction() {
                @Override
                public void actionPerformed(ActionEvent e) {
                    if (controller.next()) refresh.run();
                }
            });
            frame.getRootPane().getActionMap().put("zoomIn", new AbstractAction() {
                @Override
                public void actionPerformed(ActionEvent e) {
                    imagePanel.zoomIn();
                    refresh.run();
                }
            });
            frame.getRootPane().getActionMap().put("zoomOut", new AbstractAction() {
                @Override
                public void actionPerformed(ActionEvent e) {
                    imagePanel.zoomOut();
                    refresh.run();
                }
            });
            frame.getRootPane().getActionMap().put("fitToWindow", new AbstractAction() {
                @Override
                public void actionPerformed(ActionEvent e) {
                    imagePanel.fitToWindow();
                    refresh.run();
                }
            });
            frame.getRootPane().getActionMap().put("actualSize", new AbstractAction() {
                @Override
                public void actionPerformed(ActionEvent e) {
                    imagePanel.actualSize();
                    refresh.run();
                }
            });
            frame.getRootPane().getActionMap().put("exit", new AbstractAction() {
                @Override
                public void actionPerformed(ActionEvent e) {
                    frame.dispose();
                }
            });

            // Handle window closing
            frame.addWindowListener(new WindowAdapter() {
                @Override
                public void windowClosing(WindowEvent e) {
                    controller.close();
                    System.exit(0);
                }
            });

            frame.pack();
            frame.setLocationRelativeTo(null);
            frame.setVisible(true);
        });
    }
}

