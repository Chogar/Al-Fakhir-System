import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Envoi RAW vers l'imprimante Windows (API native, sans PowerShell).
bool sendRawToWindowsPrinter(String printerName, List<int> bytes) {
  if (bytes.isEmpty) return false;

  final name = printerName.toNativeUtf16();
  final phPrinter = calloc<IntPtr>();
  if (OpenPrinter(name, phPrinter, nullptr) == 0) {
    calloc.free(name);
    calloc.free(phPrinter);
    return false;
  }

  final hPrinter = phPrinter.value;
  final docName = 'Al-Fakhir'.toNativeUtf16();
  final dataType = 'RAW'.toNativeUtf16();
  final docInfo = calloc<DOC_INFO_1>()
    ..ref.pDocName = docName
    ..ref.pOutputFile = nullptr
    ..ref.pDatatype = dataType;

  var success = false;

  if (StartDocPrinter(hPrinter, 1, docInfo) != 0 &&
      StartPagePrinter(hPrinter) != 0) {
    final buffer = calloc<Uint8>(bytes.length);
    final written = calloc<Uint32>();
    buffer.asTypedList(bytes.length).setAll(0, bytes);
    if (WritePrinter(hPrinter, buffer, bytes.length, written) != 0 &&
        written.value > 0) {
      success = true;
    }
    calloc.free(buffer);
    calloc.free(written);
    EndPagePrinter(hPrinter);
    EndDocPrinter(hPrinter);
  }

  ClosePrinter(hPrinter);
  calloc.free(docName);
  calloc.free(dataType);
  calloc.free(docInfo);
  calloc.free(name);
  calloc.free(phPrinter);
  return success;
}
