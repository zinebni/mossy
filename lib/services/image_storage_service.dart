import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Centralized service for persisting, resolving, and syncing high-resolution
/// botanical specimen photos across local storage and Supabase Cloud Storage.
class ImageStorageService {
  final SupabaseService _supabaseService;

  ImageStorageService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  /// Saves a specimen photo to the permanent local documents directory.
  /// Returns the persistent local absolute path.
  Future<String> saveLocalSpecimen(String sourcePath, String discoveryId) async {
    try {
      if (kIsWeb) return sourcePath;
      final cleanSource = sourcePath.startsWith('file://')
          ? sourcePath.replaceFirst('file://', '')
          : sourcePath;
      final file = File(cleanSource);
      if (!await file.exists()) {
        return sourcePath;
      }
      final docsDir = await getApplicationDocumentsDirectory();
      final ext = sourcePath.contains('.')
          ? sourcePath.split('.').last.split('?').first
          : 'jpg';
      final targetPath = '${docsDir.path}/specimen_$discoveryId.$ext';
      final targetFile = File(targetPath);
      await file.copy(targetFile.path);
      return targetFile.path;
    } catch (e) {
      debugPrint('[Mossy] ImageStorageService.saveLocalSpecimen error: $e');
      return sourcePath;
    }
  }

  /// Synchronizes a local specimen photo to Supabase Storage bucket 'discovery-photos'.
  /// Returns public URL if successful, or null if offline/demo.
  Future<String?> uploadSpecimenToCloud({
    required String localPath,
    required String discoveryId,
    required String userId,
  }) async {
    try {
      if (_supabaseService.isDemoMode ||
          !_supabaseService.isInitialized ||
          _supabaseService.storage == null ||
          _supabaseService.auth?.currentUser == null) {
        return null;
      }

      final cleanPath = localPath.startsWith('file://')
          ? localPath.replaceFirst('file://', '')
          : localPath;
      final file = File(cleanPath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final storagePath = '$userId/discovery_$discoveryId.jpg';

      await _supabaseService.storage!
          .from('discovery-photos')
          .uploadBinary(storagePath, bytes,
              fileOptions: const FileOptions(upsert: true));

      final publicUrl = _supabaseService.storage!
          .from('discovery-photos')
          .getPublicUrl(storagePath);

      if (publicUrl.isNotEmpty) {
        return publicUrl;
      }
    } catch (e) {
      debugPrint('[Mossy] ImageStorageService cloud upload error: $e');
    }
    return null;
  }

  /// Resolves an image path, guaranteeing that local photos remain accessible
  /// even if app container UUID changes upon iOS/Android updates.
  static Future<String> resolveImagePath(String path) async {
    if (path.isEmpty ||
        path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }
    try {
      final clean =
          path.startsWith('file://') ? path.replaceFirst('file://', '') : path;
      final file = File(clean);
      if (await file.exists()) {
        return file.path;
      }
      // Check if file exists by filename in documents directory
      final filename = clean.split(RegExp(r'[/\\]')).last;
      final docsDir = await getApplicationDocumentsDirectory();
      final candidate = File('${docsDir.path}/$filename');
      if (await candidate.exists()) {
        return candidate.path;
      }
    } catch (e) {
      debugPrint('[Mossy] ImageStorageService.resolveImagePath error: $e');
    }
    return path;
  }

  /// Synchronously attempts to find local file path or returns original.
  static String resolveImagePathSync(String path) {
    if (path.isEmpty ||
        path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }
    final clean =
        path.startsWith('file://') ? path.replaceFirst('file://', '') : path;
    return clean;
  }

  /// Deletes a local specimen photo from storage when discovery is deleted.
  Future<void> deleteLocalSpecimen(String imagePath) async {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return;
    }
    try {
      final resolved = await resolveImagePath(imagePath);
      final file = File(resolved);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[Mossy] ImageStorageService.deleteLocalSpecimen error: $e');
    }
  }
}
