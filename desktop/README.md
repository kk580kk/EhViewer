# EhViewer Desktop

A minimal desktop image viewer application for viewing manga/comic archives and image folders.

## Features

- Open image folders recursively
- Open ZIP/CBZ archive files
- Navigate images with Previous/Next buttons
- Natural order sorting for numbered files
- Supports common image formats: JPG, JPEG, PNG, GIF

## Building

From the project root directory:

```bash
./gradlew desktop:build
```

## Running

### Option 1: Using Gradle
```bash
./gradlew desktop:run
```

### Option 2: Using Distribution
```bash
# Create distribution
./gradlew desktop:distZip

# Extract and run
unzip desktop/build/distributions/desktop.zip
./desktop/bin/desktop
```

## Usage

1. Launch the application
2. Use File menu to:
   - **Open Folder** (Ctrl+O): Browse and select a folder containing images
   - **Open Zip** (Ctrl+Shift+O): Browse and select a ZIP/CBZ archive file
3. Navigate through images using:
   - Previous/Next buttons
   - **Navigation shortcuts**:
     - Left Arrow / Page Up: Previous image
     - Right Arrow / Page Down / Space: Next image
4. Control image display:
   - Zoom In/Out buttons
   - Fit Window / Actual Size buttons
   - **Zoom shortcuts**:
     - Ctrl + Plus/Equals: Zoom in
     - Ctrl + Minus: Zoom out
     - Ctrl + 0: Fit to window
     - Ctrl + 1: Actual size (100%)
5. Status bar shows current image position and filename

## Supported Formats

- Images: JPG, JPEG, PNG, GIF, BMP, WebP
- Archives: ZIP, CBZ

## Requirements

- Java 8 or higher
- Display environment (not suitable for headless servers)

## Architecture

The application consists of:
- `Main.java`: Swing UI and application entry point
- `ReaderController.java`: Image navigation logic
- `ImagePanel.java`: Image display component
- `ImageSource.java`: Interface for image providers
- `DirectoryImageSource.java`: Reads images from directories
- `ZipImageSource.java`: Reads images from ZIP archives
- `NaturalOrderComparator.java`: Sorts filenames naturally (e.g., "page2" before "page10")