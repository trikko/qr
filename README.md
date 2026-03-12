# QR Code for D

A self-contained QR Code generator library and CLI tool for the D programming language. No external dependencies required.

Generate QR Codes and save them as **PNG**, **SVG**, **SVGZ**, or **PPM** files, or display them directly in your terminal as **ASCII art**.

Based on [Project Nayuki's implementation](https://github.com/nayuki/QR-Code-generator).

## Library Usage

Add this library to your project using:
```dub add qr```

### Basic Example


```d
import qr;
QrCode("Hello, world!").saveAs("test.png");

/* same as above
QrCode qrcode = "Hello, world!";
qrcode.saveAs("test.png");
*/
```

You can set extra options for generator:

- `ecl`: Error Correction Level.
- `mask`: Mask pattern.
- `boostEcl`: Boost the error correction level (without increasing the size of the QR Code).

For example:

```d
import qr;
QrCode("Hello, world!", ecl: ErrorCorrectionLevel.HIGH).writeln; // Print QR Code to stdout
```

You can save the QR Code to a file (PNG, SVG, PPM) with some options:

 - `moduleSize`: Size of each module (pixel)
 - `padding`: Padding around the QR Code (in modules)
 - `foreground`: Foreground color (default: `#000000`)
 - `background`: Background color (default: `#FFFFFF`)

```d
import qr;
QrCode("Hello, world!").saveAs("test.png", moduleSize: 10, foreground: "#ff0000"); // Save a red QR Code as PNG
```

You can also access the raw QR Code data:

```d
import qr;
QrCode qrcode = "Hello, world!";
qrcode.size.writeln; // Print the size (number of modules per side) of the QR Code
qrcode[0,0].writeln; // Print the module at position (0, 0) (true = black, false = white)
```

You can print QR Code as ASCII art:

```d
import qr;
QrCode("Hello, world!").writeln; // Print QR Code as ASCII art
QrCode("Hello, world!").toString(dense: true).writeln; // Print QR Code as ASCII art, dense!
```
![immagine](https://github.com/user-attachments/assets/8eaff80d-f8eb-4751-9fdc-e22c87a5b0de)

## CLI Tool (qrc)

The project includes a versatile CLI tool called `qrc`.

### Help Message

```text
qrc v0.1.1 - Your versatile QR Code generator
Usage: qrc [options] "data"

Examples:
  qrc "hello world"                # Print QR code to terminal
  qrc "hello world" -o qr.png      # Save as PNG image
  qrc "data" -f dense              # Use compact terminal representation
  qrc "secret" -f svg              # Print QR code as SVG

Options:
-o  --output Output file (if omitted, results are printed to stdout)
-f  --format Output format: png, svg, svgz, ppm, ascii, dense
-m    --mask Mask pattern (0-7, or -1 for auto)
-e     --ecl Error correction level: low, medium_low, medium_high, high
     --boost Boost error correction level (default: true). Use --boost=false to disable.
-p --padding Quiet zone size in modules (default: 2)
-s    --size Module size in pixels for images (default: 10)
        --fg Foreground color hex (e.g. #000000) (default: #000000)
        --bg Background color hex (e.g. #FFFFFF) (default: #FFFFFF)
-h    --help This help information.
```

### Usage Examples

#### Terminal Output (ASCII)

Generate a standard ASCII QR code:
```bash
qrc "https://github.com/trikko/qr"
```

#### Compact Terminal Output (Dense)

Use the `dense` format for a more compact representation (uses Unicode half-block characters):
```bash
qrc "https://github.com/trikko/qr" -f dense
```

#### Save as Image

Save as a PNG with custom colors:
```bash
qrc "https://github.com/trikko/qr" -o logo.png --size 20 --fg "#1a2b3c" --bg "#f0f0f0"
```

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
