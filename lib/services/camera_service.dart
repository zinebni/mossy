import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Service wrapping [ImagePicker] for capturing photos or selecting from gallery.
class CameraService {
  final ImagePicker _picker;
  String? _lastError;

  String? get lastError => _lastError;

  CameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Captures a photo using the device camera.
  Future<XFile?> takePhoto({
    double? maxWidth = 1800,
    double? maxHeight = 1800,
    int? imageQuality = 85,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    return pickImage(
      ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      preferredCameraDevice: preferredCameraDevice,
    );
  }

  /// Alias for [takePhoto] — picks image from camera.
  Future<XFile?> pickFromCamera() => takePhoto();

  /// Selects an image from the user's photo gallery.
  Future<XFile?> pickFromGallery({
    double? maxWidth = 1800,
    double? maxHeight = 1800,
    int? imageQuality = 85,
  }) async {
    return pickImage(
      ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Generic method to pick an image from the specified [ImageSource].
  Future<XFile?> pickImage(
    ImageSource source, {
    double? maxWidth = 1800,
    double? maxHeight = 1800,
    int? imageQuality = 85,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    _lastError = null;
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      );
      return file;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[Mossy] CameraService error picking image: $e');
      return null;
    }
  }
}
