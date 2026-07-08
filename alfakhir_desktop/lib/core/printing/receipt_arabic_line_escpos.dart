import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import 'receipt_escpos_encoding.dart';

/// Famille déclarée dans pubspec.yaml (fonts:) + repli FontLoader.
const String kReceiptArabicFontFamily = 'ReceiptArabic';

/// Largeur papier XP-58 (58 mm) en points à 203 dpi.
const int kReceiptTextRasterWidthPx = 384;

/// Taille visuelle alignée sur Font A ESC/POS (~24 dots de haut) :
/// les polices arabes (Traditional Arabic) ont un glyphe optiquement plus petit
/// que le corps déclaré — on compense avec une taille plus grande.
const double kReceiptArabicFontSize = 44;

/// Rendu bitmap des lignes arabes (XP-58 : pas de charset texte).
final class ReceiptArabicLineEscpos {
  ReceiptArabicLineEscpos._();

  static bool _fontReady = false;

  static Future<void> preload() async {
    if (_fontReady) return;
    await _ensureFontRegistered();
    _fontReady = await _verifyArabicRenders();
  }

  static Future<void> _ensureFontRegistered() async {
    if (_fontReady) return;

    const assetPaths = [
      'assets/fonts/TraditionalArabic.ttf',
      'assets/fonts/ReceiptArabic-segoeui.ttf',
    ];
    for (final path in assetPaths) {
      try {
        final data = await rootBundle.load(path);
        final loader = FontLoader(kReceiptArabicFontFamily)
          ..addFont(Future.value(data));
        await loader.load();
        if (await _probeRender()) return;
      } catch (_) {}
    }

    if (!Platform.isWindows) return;
    const winFonts = [
      r'C:\Windows\Fonts\trado.ttf',
      r'C:\Windows\Fonts\tahoma.ttf',
      r'C:\Windows\Fonts\segoeui.ttf',
      r'C:\Windows\Fonts\arial.ttf',
    ];
    for (final path in winFonts) {
      final file = File(path);
      if (!file.existsSync()) continue;
      try {
        final bytes = await file.readAsBytes();
        final loader = FontLoader(kReceiptArabicFontFamily)
          ..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
        await loader.load();
        if (await _probeRender()) return;
      } catch (_) {}
    }
  }

  /// Vérifie que la police dessine bien de l'arabe (pas des « ? »).
  static Future<bool> _probeRender() async {
    final w = _measureTextWidth('شاي');
    return w != null && w > 12;
  }

  static Future<bool> _verifyArabicRenders() async {
    return _probeRender();
  }

  static TextStyle get _arabicStyle => const TextStyle(
        fontFamily: kReceiptArabicFontFamily,
        fontSize: kReceiptArabicFontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.05,
        color: Color(0xFF000000),
      );

  static double? _measureTextWidth(String sample) {
    final tp = TextPainter(
      text: TextSpan(text: sample, style: _arabicStyle),
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: kReceiptTextRasterWidthPx.toDouble());
    if (tp.width < 2) return null;
    final plain = tp.text?.toPlainText() ?? '';
    if (plain.contains('?') && !sample.contains('?')) return null;
    return tp.width;
  }

  static Future<Uint8List?> encodeLine(String text) async {
    final t = text.trim();
    if (t.isEmpty || !receiptLineContainsArabic(t)) return null;
    await preload();
    if (!_fontReady) return null;
    return _textToRasterEscPos(t);
  }

  static Future<Uint8List?> _textToRasterEscPos(String text) async {
    try {
      final tp = TextPainter(
        text: TextSpan(text: text, style: _arabicStyle),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
      )..layout(maxWidth: kReceiptTextRasterWidthPx.toDouble());

      if (tp.width < 2 || tp.height < 2) return null;

      // Même hauteur visuelle que Font A ESC/POS (~24–30 dots) après scale 1x.
      final w = tp.width.ceil().clamp(8, kReceiptTextRasterWidthPx);
      final h = (tp.height.ceil() + 6).clamp(28, 200);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      tp.paint(canvas, const Offset(0, 2));

      final picture = recorder.endRecording();
      final image = await picture.toImage(w, h);
      picture.dispose();

      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final iw = image.width;
      final ih = image.height;
      image.dispose();
      if (rgba == null || iw <= 0 || ih <= 0) return null;

      final widthBytes = (iw + 7) ~/ 8;
      final raster = Uint8List(widthBytes * ih);
      var hasInk = false;
      for (var y = 0; y < ih; y++) {
        for (var x = 0; x < iw; x++) {
          final i = (y * iw + x) * 4;
          final lum = 0.299 * rgba.getUint8(i) +
              0.587 * rgba.getUint8(i + 1) +
              0.114 * rgba.getUint8(i + 2);
          // Seuil plus bas = traits arabes plus noirs / plus lisibles.
          if (lum < 180) {
            hasInk = true;
            final idx = y * widthBytes + (x ~/ 8);
            raster[idx] |= 0x80 >> (x % 8);
          }
        }
      }
      if (!hasInk) return null;

      // GS v 0 m=0 : raster 1x (pas de réduction 0.5x qui rapetissait l'arabe).
      return Uint8List.fromList([
        0x1B, 0x61, 0x00,
        0x1D, 0x76, 0x30, 0x00,
        widthBytes & 0xFF,
        (widthBytes >> 8) & 0xFF,
        ih & 0xFF,
        (ih >> 8) & 0xFF,
        ...raster,
      ]);
    } catch (_) {
      return null;
    }
  }
}

/// Nom AR en bitmap uniquement — jamais de repli texte « ??? ».
Future<List<int>> encodeReceiptLineWithOptionalRaster(String line) async {
  if (!receiptLineContainsArabic(line)) {
    return encodeReceiptLineBytes(line);
  }

  final raster = await ReceiptArabicLineEscpos.encodeLine(line.trim());
  if (raster != null && raster.isNotEmpty) {
    return raster.toList();
  }
  return const [];
}
