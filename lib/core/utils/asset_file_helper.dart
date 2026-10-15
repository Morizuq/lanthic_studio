import 'dart:io';

class AssetFileHelper {
  const AssetFileHelper._();

  /// Minimum byte size for an image file to be considered a real rendered asset.
  /// Dummy mock 1x1 stubs are typically under 100 bytes.
  static const int minimumRealAssetBytes = 500;

  static bool isRealRenderedAsset(File? file) {
    if (file == null) return false;
    try {
      return file.existsSync() && file.lengthSync() > minimumRealAssetBytes;
    } catch (_) {
      return false;
    }
  }
}
