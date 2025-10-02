
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickAndProcessImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 85,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile == null) {
        return null;
      }

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        final compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          quality: quality,
          minHeight: maxHeight,
          minWidth: maxWidth,
        );
        return XFile.fromData(
          compressedBytes,
          name: pickedFile.name,
          mimeType: pickedFile.mimeType,
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final targetPath = p.join(
          tempDir.path,
          '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
        );

        final XFile? result = await FlutterImageCompress.compressAndGetFile(
          pickedFile.path,
          targetPath,
          quality: quality,
          minWidth: maxWidth,
          minHeight: maxHeight,
        );

        return result;
      }
    } catch (e) {
      print('Error picking and processing image: $e');
      return null;
    }
  }
}
