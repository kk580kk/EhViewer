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
import javax.swing.KeyStroke;
import javax.swing.SwingUtilities;
import javax.swing.WindowConstants;
import javax.swing.filechooser.FileNameExtensionFilter;
import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.event.KeyEvent;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.ComponentAdapter;
import java.awt.event.ComponentEvent;
import java.awt.image.BufferedImage;
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
            openDirItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_O, KeyEvent.CTRL_DOWN_MASK));
            JMenuItem openZipItem = new JMenuItem("Open Zip...");
            openZipItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_O, KeyEvent.CTRL_DOWN_MASK | KeyEvent.SHIFT_DOWN_MASK));
            fileMenu.add(openDirItem);
            fileMenu.add(openZipItem);
            
            JMenu viewMenu = new JMenu("View");
            JMenuItem fitToWindowItem = new JMenuItem("Toggle Fit to Window");
            fitToWindowItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_F, KeyEvent.CTRL_DOWN_MASK));
            JMenuItem fullscreenItem = new JMenuItem("Toggle Fullscreen");
            fullscreenItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_F11, 0));
            viewMenu.add(fitToWindowItem);
            viewMenu.add(fullscreenItem);
            
            menuBar.add(fileMenu);
            menuBar.add(viewMenu);
            frame.setJMenuBar(menuBar);

            Runnable refresh = () -> {
                try {
                    if (controller.hasImages()) {
                        BufferedImage image = controller.loadCurrentImage();
                        imagePanel.showImage(image);
                        String statusText = String.format("%d/%d - %s", 
                            controller.getCurrentIndex() + 1, 
                            controller.getTotalCount(), 
                            controller.getCurrentName());
                        if (image != null) {
                            statusText += String.format(" (%dx%d)", image.getWidth(), image.getHeight());
                        }
                        if (imagePanel.isFitToWindow()) {
                            statusText += " [Fit]";
                        } else {
                            statusText += " [Original]";
                        }
                        status.setText(statusText);
                    } else {
                        imagePanel.showImage(null);
                        status.setText("No images found");
                    }
                } catch (Exception e) {
                    JOptionPane.showMessageDialog(frame, "Failed to load image: " + e.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                }
            };

            ActionListener prevAction = e -> { if (controller.previous()) refresh.run(); };
            ActionListener nextAction = e -> { if (controller.next()) refresh.run(); };
            
            prev.addActionListener(prevAction);
            next.addActionListener(nextAction);
            
            // Add keyboard shortcuts
            frame.getRootPane().registerKeyboardAction(prevAction,
                KeyStroke.getKeyStroke(KeyEvent.VK_LEFT, 0), 
                javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW);
            frame.getRootPane().registerKeyboardAction(prevAction,
                KeyStroke.getKeyStroke(KeyEvent.VK_A, 0), 
                javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW);
            frame.getRootPane().registerKeyboardAction(nextAction,
                KeyStroke.getKeyStroke(KeyEvent.VK_RIGHT, 0), 
                javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW);
            frame.getRootPane().registerKeyboardAction(nextAction,
                KeyStroke.getKeyStroke(KeyEvent.VK_D, 0), 
                javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW);
            frame.getRootPane().registerKeyboardAction(nextAction,
                KeyStroke.getKeyStroke(KeyEvent.VK_SPACE, 0), 
                javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW);
            
            // Add F11 for fullscreen
            ActionListener fullscreenAction = e -> {
                if (frame.getExtendedState() == JFrame.MAXIMIZED_BOTH) {
                    frame.setExtendedState(JFrame.NORMAL);
                } else {
                    frame.setExtendedState(JFrame.MAXIMIZED_BOTH);
                }
            };
            frame.getRootPane().registerKeyboardAction(fullscreenAction,
                KeyStroke.getKeyStroke(KeyEvent.VK_F11, 0), 
                javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW);
            
            // Add Home/End navigation
            ActionListener firstAction = e -> { if (controller.goToFirst()) refresh.run(); };
            ActionListener lastAction = e -> { if (controller.goToLast()) refresh.run(); };
            
            frame.getRootPane().registerKeyboardAction(firstAction,
                KeyStroke.getKeyStroke(KeyEvent.VK_HOME, 0), 
                javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW);
            frame.getRootPane().registerKeyboardAction(lastAction,
                KeyStroke.getKeyStroke(KeyEvent.VK_END, 0), 
                javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW);
            
            // Add Page Up/Down for navigation
            frame.getRootPane().registerKeyboardAction(prevAction,
                KeyStroke.getKeyStroke(KeyEvent.VK_PAGE_UP, 0), 
                javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW);
            frame.getRootPane().registerKeyboardAction(nextAction,
                KeyStroke.getKeyStroke(KeyEvent.VK_PAGE_DOWN, 0), 
                javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW);

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
                chooser.setFileFilter(new FileNameExtensionFilter("Archives", "zip", "cbz", "rar", "cbr", "7z"));
                if (chooser.showOpenDialog(frame) == JFileChooser.APPROVE_OPTION) {
                    File file = chooser.getSelectedFile();
                    try {
                        controller.openArchive(file);
                        refresh.run();
                    } catch (Exception ex) {
                        JOptionPane.showMessageDialog(frame, "Failed to open: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                    }
                }
            });

            fitToWindowItem.addActionListener(e -> {
                imagePanel.toggleFitToWindow();
                refresh.run();
            });

            fullscreenItem.addActionListener(e -> {
                if (frame.getExtendedState() == JFrame.MAXIMIZED_BOTH) {
                    frame.setExtendedState(JFrame.NORMAL);
                } else {
                    frame.setExtendedState(JFrame.MAXIMIZED_BOTH);
                }
            });

            // Add component listener to handle window resizing
            imagePanel.addComponentListener(new ComponentAdapter() {
                @Override
                public void componentResized(ComponentEvent e) {
                    if (imagePanel.isFitToWindow() && controller.hasImages()) {
                        SwingUtilities.invokeLater(refresh);
                    }
                }
            });

            frame.pack();
            frame.setLocationRelativeTo(null);
            frame.setVisible(true);
        });
    }
}

