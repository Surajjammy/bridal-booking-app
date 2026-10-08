import 'dart:typed_data';

/// An image chosen by the admin, already resized and compressed.
class PickedImage {
  final Uint8List bytes;
  final String fileName;

  const PickedImage({required this.bytes, required this.fileName});
}
