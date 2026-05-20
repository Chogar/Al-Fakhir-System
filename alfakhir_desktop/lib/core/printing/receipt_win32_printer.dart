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
    if (StartDocPrinter(hPrinter, 1, docInfo) == 0) return false;
    if (StartPagePrinter(hPrinter) == 0) return false;
    final buffer = calloc<Uint8>(bytes.length);
    final written = calloc<Uint32>();
    try {
      buffer.asTypedList(bytes.length).setAll(0, bytes);
      final ok = WritePrinter(hPrinter, buffer, bytes.length, written);
      return ok != 0 && written.value >= bytes.length;
    } finally {
      calloc.free(buffer);
      calloc.free(written);
      calloc.free(docName);
      calloc.free(dataType);
      calloc.free(docInfo);
      EndPagePrinter(hPrinter);
      EndDocPrinter(hPrinter);
      ClosePrinter(hPrinter);
    }
  } finally {
    calloc.free(name);
    calloc.free(phPrinter);
  }
}
