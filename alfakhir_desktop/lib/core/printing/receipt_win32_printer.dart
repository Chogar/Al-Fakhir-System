import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

bool sendRawToWindowsPrinter(String printerName, List<int> bytes) {
  if (bytes.isEmpty) return false;
  final name = printerName.toNativeUtf16();
  final phPrinter = calloc<IntPtr>();
  try {
    if (OpenPrinter(name, phPrinter, nullptr) == 0) return false;
    final hPrinter = phPrinter.value;

    final docName = 'Al-Fakhir'.toNativeUtf16();
    final dataType = 'RAW'.toNativeUtf16();
    final docInfo = calloc<DOC_INFO_1>()
      ..ref.pDocName = docName
      ..ref.pOutputFile = nullptr
      ..ref.pDatatype = dataType;

    if (StartDocPrinter(hPrinter, 1, docInfo) == 0) {
      calloc.free(docName);
      calloc.free(dataType);
      calloc.free(docInfo);
      ClosePrinter(hPrinter);
      return false;
    }
    if (StartPagePrinter(hPrinter) == 0) {
      EndDocPrinter(hPrinter);
      calloc.free(docName);
      calloc.free(dataType);
      calloc.free(docInfo);
      ClosePrinter(hPrinter);
      return false;
    }

    final buffer = calloc<Uint8>(bytes.length);
    final written = calloc<Uint32>();
    var ok = false;
    try {
      buffer.asTypedList(bytes.length).setAll(0, bytes);
      final w = WritePrinter(hPrinter, buffer, bytes.length, written);
      ok = w != 0 && written.value >= bytes.length;
    } finally {
      calloc.free(buffer);
      calloc.free(written);
    }

    EndPagePrinter(hPrinter);
    EndDocPrinter(hPrinter);
    ClosePrinter(hPrinter);
    calloc.free(docName);
    calloc.free(dataType);
    calloc.free(docInfo);
    return ok;
  } finally {
    calloc.free(name);
    calloc.free(phPrinter);
  }
}
