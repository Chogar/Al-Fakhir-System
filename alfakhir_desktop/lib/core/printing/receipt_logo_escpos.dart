import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Logo restaurant pour ticket thermique 58 mm (~384 px).
const String kRestaurantLogoAsset = 'assets/images/restaurant_logo.jpg';
/// 256 px : ticket plus léger → envoi RAW plus rapide sur XP-58.
const int kReceiptLogoWidthPx = 256;

/// Cache des octets ESC/POS (alignement centré + raster GS v 0).
class ReceiptLogoEscPos {
  ReceiptLogoEscPos._();

  static Uint8List? _cached;

  static Uint8List? get bytes => _cached;

  static Future<void> preload() async {
    _cached ??= await _buildEscPosRaster();
  }

  static Future<Uint8List?> _buildEscPosRaster() async {
    try {
      final data = await rootBundle.load(kRestaurantLogoAsset);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: kReceiptLogoWidthPx,
      );
      final frame = await codec.getNextFrame();
      final img = frame.image;
      final w = img.width;
      final h = img.height;
      final rgba = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      img.dispose();
      if (rgba == null || w <= 0 || h <= 0) return null;

      final widthBytes = (w + 7) ~/ 8;
      final raster = Uint8List(widthBytes * h);

      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final i = (y * w + x) * 4;
          final r = rgba.getUint8(i);
          final g = rgba.getUint8(i + 1);
          final b = rgba.getUint8(i + 2);
          final lum = 0.299 * r + 0.587 * g + 0.114 * b;
          if (lum < 150) {
            final idx = y * widthBytes + (x ~/ 8);
            raster[idx] |= 0x80 >> (x % 8);
          }
        }
      }

      final xL = widthBytes & 0xFF;
      final xH = (widthBytes >> 8) & 0xFF;
      final yL = h & 0xFF;
      final yH = (h >> 8) & 0xFF;

      return Uint8List.fromList([
        0x1B, 0x61, 0x01, // centrer
        0x1D, 0x76, 0x30, 0x00, // GS v 0 raster
        xL, xH, yL, yH,
        ...raster,
        0x0A,
        0x1B, 0x61, 0x00, // aligner à gauche
      ]);
    } catch (_) {
      return null;
    }
  }
}
