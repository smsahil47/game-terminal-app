import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as image;

// Keep the full website logo on a square canvas and remove isolated green
// edge pixels present in the source before launcher icons are scaled.
void main() {
  final source = image.decodeImage(
    File('assets/brand/logo.webp').readAsBytesSync(),
  );
  if (source == null) throw StateError('Unable to read the logo source.');

  for (final pixel in source) {
    final red = pixel.r.toInt();
    final green = pixel.g.toInt();
    final blue = pixel.b.toInt();
    if (pixel.a < 16 ||
        (green > 100 && green > red * 1.7 && green > blue * 1.35)) {
      pixel.setRgba(0, 0, 0, 0);
    }
  }

  final side = max(source.width, source.height);
  final square = image.Image(width: side, height: side, numChannels: 4);
  image.compositeImage(
    square,
    source,
    dstX: (side - source.width) ~/ 2,
    dstY: (side - source.height) ~/ 2,
  );
  File('assets/brand/app_icon.png').writeAsBytesSync(image.encodePng(square));

  // Apple requires an opaque icon. Blend explicitly against the app's dark
  // surface before the icon generator resizes it, avoiding bright alpha edges.
  final ios = image.Image(width: side, height: side, numChannels: 3);
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      final pixel = square.getPixel(x, y);
      final alpha = pixel.a / 255;
      ios.setPixelRgb(
        x,
        y,
        (pixel.r * alpha + 5 * (1 - alpha)).round(),
        (pixel.g * alpha + 7 * (1 - alpha)).round(),
        (pixel.b * alpha + 14 * (1 - alpha)).round(),
      );
    }
  }
  File('assets/brand/app_icon_ios.png').writeAsBytesSync(image.encodePng(ios));
}
