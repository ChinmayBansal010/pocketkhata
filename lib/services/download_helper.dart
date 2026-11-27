import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart'
    if (dart.library.io) 'download_helper_mobile.dart';

class DownloadHelper {
  static Future<void> saveAndDownload(List<int> bytes, String fileName) async {
    await saveAndDownloadFile(bytes, fileName);
  }
}
