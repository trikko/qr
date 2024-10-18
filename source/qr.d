/*
 * QR library
 *
 * Copyright (c) Andrea Fontana. (MIT License)
 * https://github.com/trikko/qr
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * - The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * - The Software is provided "as is", without warranty of any kind, express or
 *   implied, including but not limited to the warranties of merchantability,
 *   fitness for a particular purpose and noninfringement. In no event shall the
 *   authors or copyright holders be liable for any claim, damages or other
 *   liability, whether in an action of contract, tort or otherwise, arising from,
 *   out of or in connection with the Software or the use or other dealings in the
 *   Software.
 */

module qr;
import backend;


/++ The error correction level determines how many errors the QR Code can withstand.
++/
enum ErrorCorrectionLevel {
   LOW,         // The QR Code can tolerate about  7% erroneous codewords
   MEDIUM_LOW,  // The QR Code can tolerate about 15% erroneous codewords
   MEDIUM_HIGH, // The QR Code can tolerate about 25% erroneous codewords
   HIGH         // The QR Code can tolerate about 30% erroneous codewords
}

/++ The mask determines how the QR Code is masked.
++/
enum Mask {
   AUTO = -1,  /// The QR Code encoder will automatically select an appropriate mask pattern
   ZERO = 0,   /// Mask pattern 0
   ONE = 1,    /// Mask pattern 1
   TWO = 2,    /// Mask pattern 2
   THREE = 3,  /// Mask pattern 3
   FOUR = 4,   /// Mask pattern 4
   FIVE = 5,   /// Mask pattern 5
   SIX = 6,    /// Mask pattern 6
   SEVEN = 7   /// Mask pattern 7
}

/++ The OutputFormat enum determines the output format of the QR Code.
++/
enum OutputFormat {
   AUTO, /// The QR Code encoder will automatically select an appropriate output format
   PPM,  /// The QR Code will be output in PPM format
   SVG,  /// The QR Code will be output in SVG format
   PNG  /// The QR Code will be output in PNG format
}


alias QrCode = QRCode;

/++ The QR Code struct contains the QR Code data and provides methods to manipulate and display it.
++/
struct QRCode
{
   private ubyte[qrcodegen_BUFFER_LEN_MAX()] qr0;

   /++ Create a new QR Code.
     Params:
      data = The data to encode in the QR Code.
      ecl = The error correction level.
      mask = The mask to use.
      boostEcl = Whether to boost the error correction level (without increasing the size of the QR Code).
      ---
      QrCode("hello world!", ecl: ErrorCorrectionLevel.HIGH).writeln; // Print the QR Code to the console
      ---
   +/
   this(string data, ErrorCorrectionLevel ecl = ErrorCorrectionLevel.LOW, Mask mask = Mask.AUTO, bool boostEcl = true)
   {
      import std.string : toStringz;

      ubyte[qrcodegen_BUFFER_LEN_MAX] tempBuffer;

      qrcodegen_Ecc _ecl = qrcodegen_Ecc_LOW;

      final switch (ecl) {
         case ErrorCorrectionLevel.LOW:         _ecl = qrcodegen_Ecc_LOW;        break;
         case ErrorCorrectionLevel.MEDIUM_LOW:  _ecl = qrcodegen_Ecc_MEDIUM;     break;
         case ErrorCorrectionLevel.MEDIUM_HIGH: _ecl = qrcodegen_Ecc_QUARTILE;   break;
         case ErrorCorrectionLevel.HIGH:        _ecl = qrcodegen_Ecc_HIGH;       break;
      }

      bool ok = qrcodegen_encodeText(data.toStringz,
         tempBuffer.ptr, qr0.ptr, _ecl,
         qrcodegen_VERSION_MIN, qrcodegen_VERSION_MAX,
         cast(qrcodegen_Mask)mask, boostEcl
      );

      if (!ok) throw new Exception("Failed to generate QR Code");
   }

   /// Returns the size of the QR Code (side length in modules).
   size_t size() const { return qrcodegen_getSize(qr0.ptr); }

   /// Returns true if the module at the specified coordinates is set (black).
   bool getModule(size_t x, size_t y) const {

      if (x > int.max || y > int.max)
         throw new Exception("Coordinates out of range");

      return qrcodegen_getModule(qr0.ptr, cast(int)x, cast(int)y);
   }

   /// Returns true if the module at the specified coordinates is set (black).
   bool opIndex(size_t x, size_t y) const { return getModule(x, y); }


   /++ Returns a string representation of the QR Code
      Params:
         padding = The number of modules between the QR Code and the border of the output.
         dense = Whether to use a denser font for the output. (probably it won't render correctly on Windows)
   ++/
   string toString(size_t padding = 2, bool dense = false) const {

      import std.range : repeat, join;

      auto qrSize = size();
      auto totalSize = qrSize + 2 * padding;
      string result = "";

      if (dense) {
         immutable sotto = "\342\226\204";
         immutable sopra = "\342\226\200";
         immutable pieno = "\342\226\210";
         immutable vuoto = " ";

         // Top padding
         result ~= (vuoto.repeat(totalSize).join ~ "\n").repeat(padding).join();

         // QR code with side padding
         for (int y = 0; y < qrSize; y += 2) {
            // Left padding
            result ~= vuoto.repeat(padding).join;

            // QR code row
            for (int x = 0; x < qrSize; x++) {
                  bool top = getModule(x, y);
                  bool bottom = (y + 1 < qrSize) && getModule(x, y + 1);

                  if (top && bottom) result ~= pieno;
                  else if (top) result ~= sopra;
                  else if (bottom) result ~= sotto;
                  else result ~= vuoto;
            }

            // Right padding
            result ~= vuoto.repeat(padding).join ~ "\n";
         }

         // Bottom padding
         result ~= (vuoto.repeat(totalSize).join ~ "\n").repeat(padding).join();
      }
      else {
         // Top padding
         for (int i = 0; i < padding; i++) result ~= "  ".repeat(totalSize).join ~ "\n";

         // QR code with side padding
         for (int y = 0; y < qrSize; y++) {
            // Left padding
            result ~= "  ".repeat(padding).join;

            // QR code row
            for (int x = 0; x < qrSize; x++) result ~= getModule(x, y) ? "██" : "  ";

            // Right padding
            result ~= "  ".repeat(padding).join ~ "\n";
         }

         // Bottom padding
         for (int i = 0; i < padding; i++) result ~= "  ".repeat(totalSize).join ~ "\n";
      }

      return result;
   }

   deprecated("Use saveAs instead")
   alias save = saveAs;

   /++ Saves the QR Code to a file. Supports SVG, PPM, PNG formats.
   ++/
   void saveAs(string filename, size_t moduleSize = 10, size_t padding = 2, string foreground = "#000000", string background = "#FFFFFF", OutputFormat format = OutputFormat.AUTO ) const {

      void parseColor(string color, ref int r, ref int g, ref int b) {
         import std.conv : parse;

         if (color.length != 7 || color[0] != '#') throw new Exception("Invalid color format");

         auto sr = color[1..3];
         auto sg = color[3..5];
         auto sb = color[5..7];

         r = parse!int(sr, 16);
         g = parse!int(sg, 16);
         b = parse!int(sb, 16);
      }

      if (format == OutputFormat.AUTO) {
         import std.string : toLower;
         import std.algorithm : endsWith;

         if (filename.toLower.endsWith(".svg"))         format = OutputFormat.SVG;
         else if (filename.toLower.endsWith(".ppm"))    format = OutputFormat.PPM;
         else if (filename.toLower.endsWith(".png"))    format = OutputFormat.PNG;
         else throw new Exception("Unsupported file extension");
      }

      int fr, fg, fb;
      int br, bg, bb;

      parseColor(foreground, fr, fg, fb);
      parseColor(background, br, bg, bb);

      size_t qrSize = size();

      // SVG
      if (format == OutputFormat.SVG) {
         import std.format : format;

         auto totalSize = (qrSize + 2 * padding) * moduleSize;

         string svg = format(`<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 %d %d" stroke="none"><rect width="100%%" height="100%%" fill="#%02X%02X%02X"/><path d="`, totalSize, totalSize, br, bg, bb);

         foreach (y; 0 .. qrSize)
            foreach (x; 0 .. qrSize) {
                  if (getModule(x, y)) {
                     auto rx = (x + padding) * moduleSize;
                     auto ry = (y + padding) * moduleSize;
                     svg ~= format("M%d,%dh%dv%dh-%dz ", rx, ry, moduleSize, moduleSize, moduleSize);
                  }
            }

         svg ~= format(`" fill="#%02X%02X%02X"/></svg>`, fr, fg, fb);

         import std.file : write;
         write(filename, svg);
      }

      // PPM
      else if (format == OutputFormat.PPM)
      {
         import std.format : format;
         import std.array : appender;
         import std.bitmanip : append;
         import std.string : representation;
         auto imgSize = (qrSize + 2 * padding) * moduleSize;

         ubyte[] ppm;

         // PPM header
         ppm ~= format("P6\n%d %d\n255\n", imgSize, imgSize).representation;

         // Pixel data
         foreach (y; 0 .. imgSize) {
            foreach (x; 0 .. imgSize) {
                  // Calculate the corresponding module in the QR code
                  auto qrX = (x / moduleSize) - padding;
                  auto qrY = (y / moduleSize) - padding;

                  if (qrX >= 0 && qrX < qrSize && qrY >= 0 && qrY < qrSize && getModule(qrX, qrY))
                     ppm ~= [cast(ubyte)fr, cast(ubyte)fg, cast(ubyte)fb];  // Foreground color
                  else
                     ppm ~= [cast(ubyte)br, cast(ubyte)bg, cast(ubyte)bb];  // Background color
            }
         }

         import std.file : write;
         write(filename, ppm);
      }

      // Indexed PNG
      else if (format == OutputFormat.PNG)
      {
         void writeChunk(ref ubyte[] pngData, string type, const(ubyte)[] data) const {
            import std.bitmanip : nativeToBigEndian;
            import std.digest.crc : crc32Of;
            import std.array : array;
            import std.range : retro;

            // Write chunk length
            pngData ~= nativeToBigEndian(cast(uint)data.length);

            // Calculate CRC of type and data
            ubyte[] crcData = cast(ubyte[])type ~ data;
            auto crc = crc32Of(crcData);

            // Write type, data, and CRC
            pngData ~= type;
            pngData ~= data;
            pngData ~= crc[].retro.array;
         }

         import std.bitmanip : nativeToBigEndian;

         auto imgSize = (qrSize + 2 * padding) * moduleSize;
         ubyte[] pngData;

         // PNG signature
         pngData ~= [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

         // IHDR chunk
         ubyte[] ihdr;
         ihdr.reserve(13);

         ihdr ~= nativeToBigEndian(cast(uint)imgSize);  // Width
         ihdr ~= nativeToBigEndian(cast(uint)imgSize);  // Height
         ihdr ~= [1, 3, 0, 0, 0];  // Bit depth (1), Color type (3 - indexed), Compression, Filter, Interlace
         writeChunk(pngData, "IHDR", ihdr);

         // PLTE chunk (color palette)
         ubyte[] plte;
         plte.reserve(6);

         plte ~= [cast(ubyte)br, cast(ubyte)bg, cast(ubyte)bb];  // Background color
         plte ~= [cast(ubyte)fr, cast(ubyte)fg, cast(ubyte)fb];  // Foreground color
         writeChunk(pngData, "PLTE", plte);

         // Image data
         ubyte[] idat;
         idat.reserve(((imgSize + 7) / 8 + 1) * imgSize);

         // Write the image data, one bit per pixel
         foreach (y; 0 .. imgSize) {
            idat ~= 0;  // Filter type for each scanline
            ubyte currentByte = 0;
            ubyte bitCount = 0;

            foreach (x; 0 .. imgSize) {
               auto qrX = (x / moduleSize) - padding;
               auto qrY = (y / moduleSize) - padding;

               bool isBlack = (qrX >= 0 && qrX < qrSize && qrY >= 0 && qrY < qrSize && getModule(qrX, qrY));
               currentByte = cast(ubyte)((currentByte << 1) | (isBlack ? 1 : 0));
               bitCount++;

               if (bitCount == 8) {
                  idat ~= currentByte;
                  currentByte = 0;
                  bitCount = 0;
               }
            }

            // Pad the last byte of the row if necessary
            if (bitCount > 0) {
               currentByte <<= (8 - bitCount);
               idat ~= currentByte;
            }
         }

         import std.zlib : compress;
         writeChunk(pngData, "IDAT", compress(idat,9));

         // IEND chunk
         writeChunk(pngData, "IEND", []);

         // Write to file
         import std.file : write;
         write(filename, pngData);
      }
   }
}
