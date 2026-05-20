import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Largeur ticket thermique 58 mm.
const double kReceiptPaperWidthMm = 58;

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
  'Printer usb printer port',
  'USB Printer Port',
  'XP-58',
];

/// Préférence locale : imprimante ticket.
final class ReceiptPrinterConfig {
  ReceiptPrinterConfig._();

  static const _prefsKey = 'receipt_printer_name';

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
    await _writeConfigFile(name);
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
    final fromFile = await _readConfigFile();
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

  static Future<String?> _readConfigFile() async {
    final paths = _configFilePaths();
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final line = (await file.readAsString()).trim().split('\n').first.trim();
      if (line.isNotEmpty && !line.startsWith('#')) {
        return line;
      }
    }
    return null;
  }

  static Future<void> _writeConfigFile(String name) async {
    if (!Platform.isWindows) return;
    for (final path in _configFilePaths()) {
      try {
        final dir = File(path).parent;
        if (!dir.existsSync()) {
          await dir.create(recursive: true);
        }
        await File(path).writeAsString('$name\n', flush: true);
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
