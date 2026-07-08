import 'dart:convert';

import 'package:charset_converter/charset_converter.dart';

/// Table ESC/POS : CP864 (repli texte si le raster échoue).
const int kEscPosCodePageArabic864 = 28;

/// Table ESC/POS : Windows-1252 (latin).
const int kEscPosCodePageLatin = 16;

bool receiptLineContainsArabic(String text) {
  for (final r in text.runes) {
    if (r >= 0x0600 && r <= 0x06FF) return true;
    if (r >= 0xFB50 && r <= 0xFDFF) return true;
  }
  return false;
}

/// Accents FR uniquement (ne touche pas à l'arabe).
String latinizeFrenchAccents(String input) {
  const map = {
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'à': 'a',
    'ù': 'u',
    'ô': 'o',
    'î': 'i',
    'ç': 'c',
    'É': 'E',
    'À': 'A',
    '’': "'",
    '€': ' EUR',
  };
  final buf = StringBuffer();
  for (final r in input.runes) {
    final ch = String.fromCharCode(r);
    if (r < 128) {
      buf.write(ch);
    } else if (!receiptLineContainsArabic(ch)) {
      buf.write(map[ch] ?? ch);
    } else {
      buf.write(ch);
    }
  }
  return buf.toString();
}

Future<List<int>> encodeReceiptLineBytes(String line) async {
  if (receiptLineContainsArabic(line)) {
    final encoded = await CharsetConverter.encode('IBM864', line);
    if (encoded.isNotEmpty) {
      return <int>[
        0x1B,
        0x74,
        kEscPosCodePageArabic864,
        ...encoded,
        0x1B,
        0x74,
        kEscPosCodePageLatin,
      ];
    }
  }
  final safe = latinizeFrenchAccents(line);
  return Encoding.getByName('windows-1252')?.encode(safe) ?? latin1.encode(safe);
}
