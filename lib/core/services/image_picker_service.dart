import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Show image source picker dialog
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final image = await pickImageFromGallery();
                  Navigator.of(context).pop(image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final image = await pickImageFromCamera();
                  Navigator.of(context).pop(image);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Upload image to Firebase Storage
  static Future<String?> uploadImageToStorage(
    File imageFile,
    String folderPath,
    String fileName,
  ) async {
    try {
      print('🔍 ImagePickerService: Starting upload to Firebase Storage...');
      print('🔍 ImagePickerService: File path: ${imageFile.path}');
      print('🔍 ImagePickerService: File size: ${await imageFile.length()} bytes');
      print('🔍 ImagePickerService: Folder: $folderPath, Filename: $fileName');
      
      // Create reference to the file location
      final storageRef = _storage.ref().child('$folderPath/$fileName');
      print('🔍 ImagePickerService: Storage reference created');

      // Upload the file
      print('🔍 ImagePickerService: Starting upload task...');
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      print('🔍 ImagePickerService: Waiting for upload to complete...');
      final snapshot = await uploadTask;
      print('🔍 ImagePickerService: Upload completed! Bytes transferred: ${snapshot.bytesTransferred}');

      // Get download URL
      print('🔍 ImagePickerService: Getting download URL...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('🔍 ImagePickerService: Download URL obtained: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('❌ ImagePickerService: Error uploading image: $e');
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Generate unique filename for image
  static String generateImageFileName(String userId, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${userId}_$timestamp.$extension';
  }

  /// Delete image from Firebase Storage
  static Future<bool> deleteImageFromStorage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return true;

      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Compress image if needed
  static Future<File?> compressImage(File imageFile) async {
    try {
      // For now, return the original file
      // In a production app, you might want to add image compression here
      return imageFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageFile;
    }
  }
}
