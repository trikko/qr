/+
MIT License

Copyright (c) 2024-2026 Andrea Fontana

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
+/

import std.getopt;
import std.stdio;
import std.conv : to;
import std.string;
import std.file;
import std.path;

import qr;

enum VER = "v1.0.6";

/**
 * qrc: A versatile QR Code generator CLI tool.
 * Supports output to terminal (ASCII) and image files (PNG, SVG, PPM).
 */
int main(string[] args)
{
	// Default configuration values
	string output;
	string formatStr;
	int maskInt = -1;
	string eclStr = "LOW";
	int padding = 2;
	int moduleSize = 10;
	string foreground = "#000000";
	string background = "#FFFFFF";
	bool boostEcl = true;

	// Track if image-only options were explicitly provided
	bool sizeSet, fgSet, bgSet;

	// Parse command-line options using std.getopt
	GetoptResult helpInformation;
	try
	{
		helpInformation = getopt(
			args,
			"output|o", "Output file (if omitted, results are printed to stdout)", &output,
			"format|f", "Output format: png, svg, svgz, ppm, ascii, dense", &formatStr,
			"mask|m", "Mask pattern (0-7, or -1 for auto)", (string k, string v) {
				try { maskInt = v.to!int; }
				catch (Exception e) { throw new Exception("Invalid mask pattern: '" ~ v ~ "' is not a valid integer."); }
				if (maskInt < -1 || maskInt > 7) throw new Exception("Invalid mask pattern: " ~ v ~ ". Must be -1 to 7.");
			},
			"ecl|e", "Error correction level: low, medium_low, medium_high, high", (string k, string v) {
				switch (v.toLower)
				{
					case "low", "medium_low", "medium_high", "high": eclStr = v; break;
					default: throw new Exception("Unknown error correction level: " ~ v);
				}
			},
			"boost", "Boost error correction level (default: true). Use --boost=false to disable.", (string k, string v) {
				if (v.toLower == "true" || v == "1") boostEcl = true;
				else if (v.toLower == "false" || v == "0") boostEcl = false;
				else throw new Exception("Invalid value for --boost: " ~ v ~ ". Use true/false or 1/0.");
			},
			"padding|p", "Quiet zone size in modules (default: 2)", (string k, string v) {
				try { padding = v.to!int; }
				catch (Exception e) { throw new Exception("Invalid padding: '" ~ v ~ "' is not a valid integer."); }
				if (padding < 0) throw new Exception("Invalid padding: cannot be negative.");
			},
			"size|s", "Module size in pixels for images (default: 10)", (string k, string v) {
				try { moduleSize = v.to!int; }
				catch (Exception e) { throw new Exception("Invalid size: '" ~ v ~ "' is not a valid integer."); }
				if (moduleSize <= 0) throw new Exception("Invalid size: must be greater than 0.");
				sizeSet = true;
			},
			"fg", "Foreground color hex (e.g. #000000) (default: #000000)", (string k, string v) {
				validateColor(v, "foreground");
				foreground = v; fgSet = true;
			},
			"bg", "Background color hex (e.g. #FFFFFF) (default: #FFFFFF)", (string k, string v) {
				validateColor(v, "background");
				background = v; bgSet = true;
			},
		);
	}
	catch (GetOptException e)
	{
		stderr.writeln("Error: ", e.msg);
		stderr.writeln("Run with --help to see available options.");
		return 1;
	}
	catch (Exception e)
	{
		stderr.writeln("Error: ", e.msg);
		return 1;
	}

	// Display help message if requested or if no data is provided
	if (helpInformation.helpWanted || args.length < 2)
	{
		writeln("qrc " ~ VER ~ " - Your versatile QR Code generator");
		writeln("Usage: qrc [options] \"data\"");
		writeln();
		writeln("Examples:");
		writeln("  qrc \"hello world\"                # Print QR code to terminal");
		writeln("  qrc \"hello world\" -o qr.png      # Save as PNG image");
		writeln("  qrc \"data\" -f dense              # Use compact terminal representation");
		writeln("  qrc \"secret\" -f svg              # Print QR code as SVG");
		writeln();
		defaultGetoptPrinter("Options:", helpInformation.options);
		return helpInformation.helpWanted ? 0 : 1;
	}

	// Ensure only one free parameter (the data to encode) is provided.
	// This prevents ambiguity when data contains spaces but isn't quoted.
	if (args.length > 2)
	{
		stderr.writeln("Error: Too many free parameters. Please wrap your QR data in quotes if it contains spaces.");
		stderr.writeln("Found: ", args[1 .. $].join(" "));
		return 1;
	}

	string data = args[1];

	// Map input error correction level string to enum
	ErrorCorrectionLevel ecl = ErrorCorrectionLevel.LOW;
	switch (eclStr.toLower)
	{
		case "low": ecl = ErrorCorrectionLevel.LOW; break;
		case "medium_low": ecl = ErrorCorrectionLevel.MEDIUM_LOW; break;
		case "medium_high": ecl = ErrorCorrectionLevel.MEDIUM_HIGH; break;
		case "high": ecl = ErrorCorrectionLevel.HIGH; break;
		default: assert(0); // Should be caught by getopt validation
	}

	// Cast mask pattern
	Mask mask = cast(Mask) maskInt;

	// Attempt to create the QR Code object
	QrCode qr;
	try { qr = QrCode(data, ecl, mask, boostEcl); }
	catch (Exception e)
	{
		stderr.writeln("Error encoding QR code: ", e.msg);
		return 1;
	}

	// Normalize format string and detect it from extension if needed
	string f = formatStr.toLower.strip;
	if (f == "" && output != "")
	{
		auto ext = output.extension.toLower;

		switch(ext)
		{
			case ".png": f = "png"; break;
			case ".svg": f = "svg"; break;
			case ".svgz": f = "svgz"; break;
			case ".ppm": f = "ppm"; break;
			case ".txt": f = "ascii"; break;
			default:
			stderr.writeln("Unknown format: ", formatStr);
			return 1;
		}
	}

	// If ASCII/Terminal output is selected or no output file is specified
	if (f == "ascii" || f == "dense" || (f == "" && output == ""))
	{
		// Check for image-only options incompatible with text formats
		if (sizeSet || fgSet || bgSet)
		{
			stderr.writeln("Error: --size, --fg, and --bg are only available for image formats (png, svg, ppm).");
			return 1;
		}

		bool isDense = (f == "dense");
		string ascii = qr.toString(padding, isDense);

		if (output != "")
		{
			try { std.file.write(output, ascii); }
			catch (Exception e) { stderr.writeln("Error writing to file: ", e.msg); return 1; }
		}
		// Output directly to terminal
		else write(ascii);
	}
	// Handle binary image formats
	else
	{
		OutputFormat outFmt = OutputFormat.PNG;

		switch (f)
		{
			case "png": outFmt = OutputFormat.PNG; break;
			case "svg": outFmt = OutputFormat.SVG; break;
			case "svgz": outFmt = OutputFormat.SVGZ; break;
			case "ppm": outFmt = OutputFormat.PPM; break;
			default:
			stderr.writeln("Unknown format: ", formatStr);
			return 1;
		}

		try
		{
			// Generate raw bytes for the selected format
			ubyte[] bytes = qr.toBytes(moduleSize, padding, foreground, background, outFmt);

			if (output != "") std.file.write(output, bytes);
			else stdout.rawWrite(bytes); // Print binary data to stdout (raw write)
		}
		catch (Exception e)
		{
			stderr.writeln("Error generating output: ", e.msg);
			return 1;
		}
	}

	return 0;
}

/**
 * Validates a hex color string (e.g. #000000).
 * Throws an Exception if the color is invalid.
 */
void validateColor(string color, string name)
{
	if (color.length != 7 || color[0] != '#')
		throw new Exception("Invalid " ~ name ~ " color: '" ~ color ~ "'. Expected hex format #RRGGBB.");

	foreach (c; color[1 .. $])
	{
		if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')))
			throw new Exception("Invalid " ~ name ~ " color: '" ~ color ~ "'. Expected hex format #RRGGBB.");
	}
}
