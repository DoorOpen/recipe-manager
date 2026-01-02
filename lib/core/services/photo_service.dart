import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service to handle photo picking and storage for recipes
class PhotoService {
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from camera
  Future<String?> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveImage(image);
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick an image from gallery
  Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        return await _saveImage(image);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery (one at a time for compatibility)
  /// Note: For true multi-select, consider using file_picker package
  Future<List<String>> pickMultipleFromGallery({int maxImages = 5}) async {
    final List<String> savedPaths = [];

    for (int i = 0; i < maxImages; i++) {
      try {
        final String? path = await pickFromGallery();
        if (path != null) {
          savedPaths.add(path);
        } else {
          // User cancelled or error - stop picking
          break;
        }
      } catch (e) {
        print('Error picking image ${i + 1}: $e');
        break;
      }
    }

    return savedPaths;
  }

  /// Save image to app's documents directory and return the path
  Future<String?> _saveImage(XFile image) async {
    try {
      // Get app's documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String recipesDir = path.join(appDir.path, 'recipe_photos');

      // Create recipes directory if it doesn't exist
      final Directory recipePhotosDir = Directory(recipesDir);
      if (!await recipePhotosDir.exists()) {
        await recipePhotosDir.create(recursive: true);
      }

      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(image.path);
      final String fileName = 'recipe_$timestamp$extension';
      final String savedPath = path.join(recipesDir, fileName);

      // Copy file to app directory
      final File sourceFile = File(image.path);
      await sourceFile.copy(savedPath);

      return savedPath;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  /// Delete a photo from storage
  Future<bool> deletePhoto(String photoPath) async {
    try {
      final File file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting photo: $e');
      return false;
    }
  }

  /// Check if a photo file exists
  Future<bool> photoExists(String photoPath) async {
    try {
      final File file = File(photoPath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get file size of a photo in bytes
  Future<int> getPhotoSize(String photoPath) async {
    try {
      final File file = File(photoPath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
