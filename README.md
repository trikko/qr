# QR Code for D

A QR Code generator library for D. It is self-contained and does not require any external dependencies.
You can use it to generate QR Codes and save them as PNG, SVG, SVGZ, PPM files (or print them as ASCII art).

Based on [Project Nayuki's code](https://github.com/nayuki/QR-Code-generator)
## Usage

Basic example:

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



## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.
