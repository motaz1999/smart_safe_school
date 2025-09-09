import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class ImageService {
  static const String _profileImagePathKey = 'student_profile_image_path';
  
  /// Picks an image from gallery or camera
  static Future<String?> pickImage({bool fromCamera = false}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
      );
      
      return image?.path;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
  
  /// Saves an image to the app's documents directory
  static Future<String?> saveImageLocally(String imagePath, String fileName) async {
    try {
      // Get the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      
      // Create a unique file name
      final String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      // Create the full file path
      final String filePath = path.join(directory.path, uniqueFileName);
      
      // Copy the image to the app's directory
      final File originalImage = File(imagePath);
      final File savedImage = await originalImage.copy(filePath);
      
      // Save the file path to shared preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImagePathKey, savedImage.path);
      
      return savedImage.path;
    } catch (e) {
      debugPrint('Error saving image locally: $e');
      return null;
    }
  }
  
  /// Gets the saved profile image path
  static Future<String?> getSavedProfileImagePath() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_profileImagePathKey);
    } catch (e) {
      debugPrint('Error getting saved image path: $e');
      return null;
    }
  }
  
  /// Deletes the saved profile image
  static Future<bool> deleteSavedProfileImage() async {
    try {
      // Get the saved image path
      final String? imagePath = await getSavedProfileImagePath();
      
      if (imagePath != null) {
        // Delete the image file
        final File imageFile = File(imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
        
        // Remove the path from shared preferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove(_profileImagePathKey);
        
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error deleting saved image: $e');
      return false;
    }
  }
  
  /// Checks if a saved profile image exists
  static Future<bool> savedProfileImageExists() async {
    try {
      final String? imagePath = await getSavedProfileImagePath();
      
      if (imagePath != null) {
        final File imageFile = File(imagePath);
        return await imageFile.exists();
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking if saved image exists: $e');
      return false;
    }
  }
}