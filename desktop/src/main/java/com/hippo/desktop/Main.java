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
import java.io.File;
import java.util.List;
import com.hippo.desktop.AppException;

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

            // Recent files manager
            RecentFilesManager recentFiles = new RecentFilesManager(Main.class);

            JPanel bottomBar = new JPanel(new FlowLayout(FlowLayout.LEFT));
            JButton prev = new JButton("Prev");
            JButton next = new JButton("Next");
            JButton zoomIn = new JButton("Zoom In");
            JButton zoomOut = new JButton("Zoom Out");
            JButton fitWindow = new JButton("Fit Window");
            JButton actualSize = new JButton("Actual Size");
            JLabel status = new JLabel("No book opened");
            bottomBar.add(prev);
            bottomBar.add(next);
            bottomBar.add(new javax.swing.JSeparator(javax.swing.SwingConstants.VERTICAL));
            bottomBar.add(zoomIn);
            bottomBar.add(zoomOut);
            bottomBar.add(fitWindow);
            bottomBar.add(actualSize);
            bottomBar.add(new javax.swing.JSeparator(javax.swing.SwingConstants.VERTICAL));
            bottomBar.add(status);
            frame.add(bottomBar, BorderLayout.SOUTH);

            JMenuBar menuBar = new JMenuBar();
            JMenu fileMenu = new JMenu("File");
            fileMenu.setMnemonic(KeyEvent.VK_F);
            
            JMenuItem openDirItem = new JMenuItem("Open Folder...");
            openDirItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_O, java.awt.event.InputEvent.CTRL_DOWN_MASK));
            
            JMenuItem openZipItem = new JMenuItem("Open Zip...");
            openZipItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_O, java.awt.event.InputEvent.CTRL_DOWN_MASK | java.awt.event.InputEvent.SHIFT_DOWN_MASK));
            
            JMenu recentMenu = new JMenu("Recent Files");
            recentMenu.setMnemonic(KeyEvent.VK_R);
            recentMenu.setEnabled(false);
            
            fileMenu.add(openDirItem);
            fileMenu.add(openZipItem);
            fileMenu.addSeparator();
            fileMenu.add(recentMenu);
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
                } catch (AppException ex) {
                    JOptionPane.showMessageDialog(frame, ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                } catch (Exception e) {
                    JOptionPane.showMessageDialog(frame, "Failed to load image: " + e.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                }
            };

            // Helper to refresh recent menu
            final Runnable[] refreshRecentMenu = new Runnable[1];
            refreshRecentMenu[0] = () -> {
                recentMenu.removeAll();
                List<String> recents = recentFiles.get();
                if (recents.isEmpty()) {
                    recentMenu.setEnabled(false);
                    return;
                }
                recentMenu.setEnabled(true);
                for (String path : recents) {
                    JMenuItem item = new JMenuItem(path);
                    item.addActionListener(ev -> {
                        File target = new File(path);
                        if (!target.exists()) {
                            JOptionPane.showMessageDialog(frame, "File not found: " + path, "Error", JOptionPane.ERROR_MESSAGE);
                            recentFiles.clear();
                            refreshRecentMenu[0].run();
                            return;
                        }
                        try {
                            if (target.isDirectory()) {
                                controller.openDirectory(target);
                            } else {
                                controller.openZip(target);
                            }
                            recentFiles.add(path);
                            refreshRecentMenu[0].run();
                            refresh.run();
                        } catch (AppException ex) {
                            JOptionPane.showMessageDialog(frame, ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                        } catch (Exception ex) {
                            JOptionPane.showMessageDialog(frame, "Failed to open: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                        }
                    });
                    recentMenu.add(item);
                }
                recentMenu.addSeparator();
                JMenuItem clearItem = new JMenuItem("Clear List");
                clearItem.addActionListener(ev -> {
                    recentFiles.clear();
                    refreshRecentMenu[0].run();
                });
                recentMenu.add(clearItem);
            };
            refreshRecentMenu[0].run();

            prev.addActionListener(e -> { if (controller.previous()) refresh.run(); });
            next.addActionListener(e -> { if (controller.next()) refresh.run(); });
            zoomIn.addActionListener(e -> imagePanel.zoomIn());
            zoomOut.addActionListener(e -> imagePanel.zoomOut());
            fitWindow.addActionListener(e -> imagePanel.fitToWindow());
            actualSize.addActionListener(e -> imagePanel.resetZoom());
            
            // Add keyboard shortcuts
            imagePanel.getInputMap(javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_LEFT, 0), "previous");
            imagePanel.getInputMap(javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_RIGHT, 0), "next");
            imagePanel.getInputMap(javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_SPACE, 0), "next");
            imagePanel.getInputMap(javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_PAGE_UP, 0), "previous");
            imagePanel.getInputMap(javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_PAGE_DOWN, 0), "next");
            imagePanel.getInputMap(javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_PLUS, java.awt.event.InputEvent.CTRL_DOWN_MASK), "zoomIn");
            imagePanel.getInputMap(javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_EQUALS, java.awt.event.InputEvent.CTRL_DOWN_MASK), "zoomIn");
            imagePanel.getInputMap(javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_MINUS, java.awt.event.InputEvent.CTRL_DOWN_MASK), "zoomOut");
            imagePanel.getInputMap(javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_0, java.awt.event.InputEvent.CTRL_DOWN_MASK), "fitWindow");
            imagePanel.getInputMap(javax.swing.JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke(KeyEvent.VK_1, java.awt.event.InputEvent.CTRL_DOWN_MASK), "actualSize");
            
            imagePanel.getActionMap().put("previous", new javax.swing.AbstractAction() {
                @Override
                public void actionPerformed(java.awt.event.ActionEvent e) {
                    if (controller.previous()) refresh.run();
                }
            });
            
            imagePanel.getActionMap().put("next", new javax.swing.AbstractAction() {
                @Override
                public void actionPerformed(java.awt.event.ActionEvent e) {
                    if (controller.next()) refresh.run();
                }
            });
            
            imagePanel.getActionMap().put("zoomIn", new javax.swing.AbstractAction() {
                @Override
                public void actionPerformed(java.awt.event.ActionEvent e) {
                    imagePanel.zoomIn();
                }
            });
            
            imagePanel.getActionMap().put("zoomOut", new javax.swing.AbstractAction() {
                @Override
                public void actionPerformed(java.awt.event.ActionEvent e) {
                    imagePanel.zoomOut();
                }
            });
            
            imagePanel.getActionMap().put("fitWindow", new javax.swing.AbstractAction() {
                @Override
                public void actionPerformed(java.awt.event.ActionEvent e) {
                    imagePanel.fitToWindow();
                }
            });
            
            imagePanel.getActionMap().put("actualSize", new javax.swing.AbstractAction() {
                @Override
                public void actionPerformed(java.awt.event.ActionEvent e) {
                    imagePanel.resetZoom();
                }
            });

            openDirItem.addActionListener(e -> {
                JFileChooser chooser = new JFileChooser();
                chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
                if (chooser.showOpenDialog(frame) == JFileChooser.APPROVE_OPTION) {
                    File dir = chooser.getSelectedFile();
                    try {
                        controller.openDirectory(dir);
                        recentFiles.add(dir.getAbsolutePath());
                        refreshRecentMenu[0].run();
                        refresh.run();
                    } catch (AppException ex) {
                        JOptionPane.showMessageDialog(frame, ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                    } catch (Exception ex) {
                        JOptionPane.showMessageDialog(frame, "Failed to open: " + ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
                    }
                }
            });

            openZipItem.addActionListener(e -> {
                JFileChooser chooser = new JFileChooser();
                chooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
                chooser.setFileFilter(new FileNameExtensionFilter("Archives", "zip", "cbz", "cbr"));
                if (chooser.showOpenDialog(frame) == JFileChooser.APPROVE_OPTION) {
                    File file = chooser.getSelectedFile();
                    try {
                        controller.openZip(file);
                        recentFiles.add(file.getAbsolutePath());
                        refreshRecentMenu[0].run();
                        refresh.run();
                    } catch (AppException ex) {
                        JOptionPane.showMessageDialog(frame, ex.getMessage(), "Error", JOptionPane.ERROR_MESSAGE);
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

