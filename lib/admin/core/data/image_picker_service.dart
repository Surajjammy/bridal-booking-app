import 'package:image_picker/image_picker.dart';

import '../domain/picked_image.dart';

/// Lets the admin choose a photo from their computer. The browser resizes
/// and compresses it before we ever see the bytes, so a 10 MB phone photo
/// uploads as a few hundred KB.
class ImagePickerService {
  static const double _maxDimension = 1600;
  static const int _quality = 80;

  final ImagePicker _picker;

  ImagePickerService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  Future<PickedImage?> pickOne() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: _quality,
    );
    return file == null ? null : _toPickedImage(file);
  }

  Future<PickedImage> _toPickedImage(XFile file) async {
    return PickedImage(bytes: await file.readAsBytes(), fileName: file.name);
  }
}
