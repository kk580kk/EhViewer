# EhViewer Desktop

A minimal desktop image viewer application based on EhViewer, built with Java Swing.

## Features

- **Image Viewing**: Support for common image formats (JPG, PNG, GIF, BMP, WebP, TIFF)
- **Archive Support**: Open ZIP and CBZ archives containing images
- **Smart Scaling**: Automatic fit-to-window with high-quality image scaling
- **Keyboard Navigation**: Full keyboard support for efficient browsing
- **Simple UI**: Clean, minimal interface focused on image viewing

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `←` / `A` | Previous image |
| `→` / `D` / `Space` | Next image |
| `Home` | Go to first image |
| `End` | Go to last image |
| `Page Up` | Previous image |
| `Page Down` | Next image |
| `Ctrl+O` | Open folder |
| `Ctrl+Shift+O` | Open archive |
| `Ctrl+F` | Toggle fit to window |
| `F11` | Toggle fullscreen |

## Building and Running

```bash
# Build the application
./gradlew desktop:build

# Run the application
./gradlew desktop:run
```

## Supported Formats

### Images
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- BMP (.bmp)
- WebP (.webp)
- TIFF (.tiff, .tif)

### Archives
- ZIP (.zip)
- Comic Book ZIP (.cbz)
- RAR (.rar) - *Planned support*
- Comic Book RAR (.cbr) - *Planned support*

## Usage

1. Launch the application
2. Use `File > Open Folder` to browse images in a directory
3. Use `File > Open Zip` to browse images in an archive
4. Navigate using keyboard shortcuts or the buttons
5. Toggle between fit-to-window and original size with `Ctrl+F`
6. Use `F11` for fullscreen viewing

## Status Information

The status bar shows:
- Current image position (e.g., "3/15")
- Current filename
- Image dimensions
- Current view mode ([Fit] or [Original])