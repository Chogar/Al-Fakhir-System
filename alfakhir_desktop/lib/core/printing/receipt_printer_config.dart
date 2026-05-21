import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Largeur ticket thermique 58 mm.
const double kReceiptPaperWidthMm = 58;

/// Tiroir-caisse RJ11 (série GS/GF-405, compatible ESC/POS).
const String kCashDrawerModelGf405 = 'GF-405';

/// Noms connus (XP-58, USB Generic PostScript, etc.).
const List<String> kReceiptPrinterNameHints = [
  'printer usb printer port',
  'usb printer port',
  'generic postscript',
  'xp-58iit',
  'xp-58',
  'xprinter',
  '58iit',
];

/// Noms exacts a essayer en priorite (fichier config + defauts usine).
const List<String> kReceiptPrinterExactNames = [
  'XP-58C',
  'XP-58',
  'Printer usb printer port',
  'USB Printer Port',
];

/// Impulsion tiroir RJ11 (broche ESC/POS + durées en ms).
final class CashDrawerKickParams {
  const CashDrawerKickParams({
    required this.pin,
    this.onMs = 50,
    this.offMs = 500,
    this.bothPins = false,
  });

  final int pin;
  final int onMs;
  final int offMs;
  final bool bothPins;
}

/// Préférence locale : imprimante ticket + tiroir GF-405.
final class ReceiptPrinterConfig {
  ReceiptPrinterConfig._();

  static const _prefsKey = 'receipt_printer_name';
  static const _prefsDrawerPin = 'cash_drawer_pin';
  static const _prefsDrawerModel = 'cash_drawer_model';

  static bool isVirtualPrinter(String name) {
    final n = name.toLowerCase();
    return n.contains('pdf') ||
        n.contains('xps') ||
        n.contains('fax') ||
        n.contains('onenote') ||
        n.contains('send to') ||
        n.contains('envoyer vers') ||
        n.contains('microsoft print');
  }

  static Future<void> savePrinterName(String name) async {
    if (isVirtualPrinter(name)) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey, name);
    await _writeConfigFile(printerName: name);
  }

  static Future<String?> savedPrinterName() async {
    final p = await SharedPreferences.getInstance();
    final name = p.getString(_prefsKey);
    if (name == null || name.isEmpty || isVirtualPrinter(name)) {
      await p.remove(_prefsKey);
      return null;
    }
    return name;
  }

  static Future<String?> resolveThermalPrinterName() async {
    final fromFile = await _readPrinterFromConfigFile();
    if (fromFile != null && await _printerExistsOnWindows(fromFile)) {
      await savePrinterName(fromFile);
      return fromFile;
    }

    final saved = await savedPrinterName();
    if (saved != null && await _printerExistsOnWindows(saved)) {
      return saved;
    }

    for (final exact in kReceiptPrinterExactNames) {
      if (await _printerExistsOnWindows(exact)) {
        await savePrinterName(exact);
        return exact;
      }
    }

    if (Platform.isWindows) {
      final fromOs = await _resolvePrinterNameFromWindows();
      if (fromOs != null) {
        await savePrinterName(fromOs);
        return fromOs;
      }
    }

    return fromFile ?? kReceiptPrinterExactNames.first;
  }

  /// Paramètres d'ouverture du tiroir (GF-405 : broche 0, impulsion ~100 ms).
  static Future<CashDrawerKickParams> cashDrawerKickParams() async {
    final file = await _readConfigEntries();
    final p = await SharedPreferences.getInstance();

    final model = (p.getString(_prefsDrawerModel) ?? file['drawer_model'])
        ?.trim()
        .toUpperCase();
    final pinFromPrefs = p.getInt(_prefsDrawerPin);
    final pin = pinFromPrefs == 0 || pinFromPrefs == 1
        ? pinFromPrefs!
        : _parsePin(file['drawer_pin']) ?? 0;

    final isGf405 = model == kCashDrawerModelGf405 ||
        model == 'GS-405' ||
        model == 'GS-405A' ||
        model == 'GS-405D';

    final onMs = int.tryParse(file['drawer_on_ms'] ?? '') ??
        (isGf405 ? 100 : 50);
    final offMs = int.tryParse(file['drawer_off_ms'] ?? '') ??
        (isGf405 ? 500 : 500);
    final bothPinsRaw = (file['drawer_both_pins'] ?? '').trim().toLowerCase();
    final bothPins = bothPinsRaw == '1' ||
        bothPinsRaw == 'true' ||
        (bothPinsRaw.isEmpty && isGf405);

    return CashDrawerKickParams(
      pin: pin,
      onMs: onMs.clamp(20, 500),
      offMs: offMs.clamp(100, 2000),
      bothPins: bothPins,
    );
  }

  static Future<int> cashDrawerPin() async {
    return (await cashDrawerKickParams()).pin;
  }

  static Future<String?> _readPrinterFromConfigFile() async {
    final entries = await _readConfigEntries();
    return entries['printer'];
  }

  static Future<Map<String, String>> _readConfigEntries() async {
    final out = <String, String>{};
    for (final path in _configFilePaths()) {
      final file = File(path);
      if (!file.existsSync()) continue;
      var printerLine = '';
      for (final raw in (await file.readAsString()).split('\n')) {
        final t = raw.trim();
        if (t.isEmpty || t.startsWith('#')) continue;
        final lower = t.toLowerCase();
        if (lower.startsWith('drawer_')) {
          final eq = t.indexOf('=');
          if (eq > 0) {
            out[t.substring(0, eq).trim().toLowerCase()] =
                t.substring(eq + 1).trim();
          }
          continue;
        }
        if (!lower.contains('=')) {
          printerLine = t;
        }
      }
      if (printerLine.isNotEmpty) {
        out['printer'] = printerLine;
      }
      if (out.isNotEmpty) return out;
    }
    return out;
  }

  static int? _parsePin(String? raw) {
    final v = int.tryParse(raw?.trim() ?? '');
    if (v == 0 || v == 1) return v;
    return null;
  }

  static Future<void> _writeConfigFile({required String printerName}) async {
    if (!Platform.isWindows) return;
    final existing = await _readConfigEntries();
    final lines = <String>[
      printerName.trim(),
      if (existing['drawer_model'] != null)
        'drawer_model=${existing['drawer_model']}'
      else
        'drawer_model=$kCashDrawerModelGf405',
      'drawer_pin=${existing['drawer_pin'] ?? '0'}',
      if (existing['drawer_on_ms'] != null)
        'drawer_on_ms=${existing['drawer_on_ms']}',
      if (existing['drawer_off_ms'] != null)
        'drawer_off_ms=${existing['drawer_off_ms']}',
      if (existing['drawer_both_pins'] != null)
        'drawer_both_pins=${existing['drawer_both_pins']}',
    ];
    final body = '${lines.join('\n')}\n';
    for (final path in _configFilePaths()) {
      try {
        final dir = File(path).parent;
        if (!dir.existsSync()) {
          await dir.create(recursive: true);
        }
        await File(path).writeAsString(body, flush: true);
        return;
      } catch (_) {}
    }
  }

  static List<String> _configFilePaths() {
    final local = Platform.environment['LOCALAPPDATA'];
    return [
      if (local != null)
        '$local\\Programs\\Al-Fakhir\\receipt_printer.txt',
      r'C:\Users\AL FAKHIR\Documents\Al-Fakhir System\install\receipt_printer.txt',
    ];
  }

  static Future<bool> _printerExistsOnWindows(String name) async {
    if (!Platform.isWindows) return false;
    try {
      final esc = name.replaceAll("'", "''");
      final result = await Process.run(
        'powershell.exe',
        [
          '-NoProfile',
          '-Command',
          "if (Get-Printer -Name '$esc' -ErrorAction SilentlyContinue) { 'yes' }",
        ],
        runInShell: false,
      );
      return (result.stdout as String).trim().toLowerCase() == 'yes';
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _resolvePrinterNameFromWindows() async {
    try {
      final result = await Process.run(
        'powershell.exe',
        [
          '-NoProfile',
          '-Command',
          r'''
$q = Get-Printer | Where-Object {
  $_.Name -notmatch 'PDF|XPS|Fax|OneNote' -and (
    $_.Name -like '*58*' -or $_.Name -like '*XP*' -or $_.Name -like '*XPrinter*' -or
    $_.Name -like '*USB*' -or $_.Name -like '*printer port*' -or
    $_.DriverName -like '*PostScript*' -or $_.DriverName -like '*Generic*'
  )
} | Select-Object -First 1 -ExpandProperty Name
if ($q) { $q }
''',
        ],
        runInShell: false,
      );
      if (result.exitCode != 0) return null;
      final found = (result.stdout as String).trim();
      if (found.isEmpty || isVirtualPrinter(found)) return null;
      return found;
    } catch (_) {
      return null;
    }
  }
}
