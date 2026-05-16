import 'dart:convert';
import 'dart:typed_data';

import '../../data/models/order_model.dart';
import 'receipt_ticket_text.dart';

/// Profils d'encodage ESC/POS pour Xprinter XP-58 / XP-58IIT.
enum EscPosCodePage {
  /// CP437 (USA) — ESC t 0
  cp437(0),

  /// WPC1252 (Europe) — ESC t 16, recommandé pour le français.
  windows1252(16);

  const EscPosCodePage(this.escTValue);
  final int escTValue;
}

/// Ticket ESC/POS pour Xprinter XP-58IIT (mode RAW Windows).
Uint8List buildEscPosTicketBytes({
  required OrderDetailDto order,
  required String restaurantName,
  bool arabic = false,
  double discountFcfa = 0,
  EscPosCodePage codePage = EscPosCodePage.windows1252,
}) {
  final body = buildReceiptTicketText(
    order: order,
    restaurantName: restaurantName,
    arabic: arabic,
    discountFcfa: discountFcfa,
  );
  return _buildEscPosFromText(body, codePage: codePage, cutPaper: true);
}

/// Ticket test minimal : « Commande #123 - 2 Pizzas ».
Uint8List buildEscPosTestTicket({
  String line1 = 'Restaurant Al-Fakhir',
  String line2 = 'Commande #123 - 2 Pizzas',
  String line3 = 'Merci et bon appetit !',
}) {
  return _buildEscPosFromText(
    '$line1\n$line2\n$line3\n',
    codePage: EscPosCodePage.windows1252,
    cutPaper: true,
    emphasizeFirstLine: true,
  );
}

Uint8List _buildEscPosFromText(
  String text, {
  required EscPosCodePage codePage,
  required bool cutPaper,
  bool emphasizeFirstLine = false,
}) {
  final out = <int>[];

  // Initialisation imprimante (obligatoire après veille / job précédent).
  out.addAll([0x1B, 0x40]); // ESC @
  out.addAll([0x1B, 0x32]); // ESC 2 — espacement ligne par défaut
  out.addAll([0x1B, 0x74, codePage.escTValue]); // ESC t n — table caractères
  out.addAll([0x1B, 0x4D, 0x00]); // ESC M 0 — police A (12x24)
  out.addAll([0x1B, 0x21, 0x00]); // ESC ! 0 — normal

  final lines = text.split(RegExp(r'\r?\n'));
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.isEmpty) {
      out.add(0x0A);
      continue;
    }
    if (emphasizeFirstLine && i == 0) {
      out.addAll([0x1B, 0x21, 0x30]); // gras + double hauteur
    }
    out.addAll(_encodeLine(line, codePage));
    if (emphasizeFirstLine && i == 0) {
      out.addAll([0x1B, 0x21, 0x00]);
    }
    out.addAll([0x0D, 0x0A]); // CR LF — requis sur beaucoup de XP-58
  }

  out.addAll([0x1B, 0x64, 0x04]); // feed 4 lignes
  if (cutPaper) {
    out.addAll([0x1D, 0x56, 0x00]); // GS V 0 — coupe complète
  }
  return Uint8List.fromList(out);
}

List<int> _encodeLine(String line, EscPosCodePage codePage) {
  // Arabe / UTF-8 : translittération ASCII pour éviter octets multioctets non gérés.
  final safe = _latinizeIfNeeded(line);
  switch (codePage) {
    case EscPosCodePage.windows1252:
      return Encoding.getByName('windows-1252')?.encode(safe) ??
          latin1.encode(safe);
    case EscPosCodePage.cp437:
      return latin1.encode(safe);
  }
}

String _latinizeIfNeeded(String input) {
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
    if (ch.codeUnitAt(0) < 128) {
      buf.write(ch);
    } else {
      buf.write(map[ch] ?? '?');
    }
  }
  return buf.toString();
}
