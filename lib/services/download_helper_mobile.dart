import 'dart:io';

Future<void> saveAndDownloadFile(List<int> bytes, String fileName) async {
  try {
    final Directory? downloadsDir = Directory('/storage/emulated/0/Download');
    final String path = (downloadsDir != null && downloadsDir.existsSync())
        ? '${downloadsDir.path}/$fileName'
        : '${Directory.systemTemp.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes);
  } catch (e) {
    final file = File('${Directory.systemTemp.path}/$fileName');
    await file.writeAsBytes(bytes);
  }
}
