import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<String?> uploadImage(String folder, XFile file) async {
    try {
      debugPrint('StorageService: preparing to upload ${file.name}');

      final ref = _storage.ref().child(
          '$folder/${DateTime.now().millisecondsSinceEpoch}_${file.name}');

      final metadata = SettableMetadata(
        contentType: file.mimeType ?? 'image/jpeg',
      );

      UploadTask uploadTask;

      if (kIsWeb) {
        final data = await file.readAsBytes();
        uploadTask = ref.putData(data, metadata);
      } else {
        final ioFile = File(file.path);
        uploadTask = ref.putFile(ioFile, metadata);
      }

      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 120), // Increased timeout for mobile
        onTimeout: () {
          debugPrint('StorageService: Upload timed out!');
          if (uploadTask.snapshot.state == TaskState.running) {
            uploadTask.cancel();
          }
          throw FirebaseException(
              plugin: 'firebase_storage',
              code: 'timeout',
              message: 'Upload timed out');
        },
      );

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow; // Allow UI to handle error
    }
  }

  Future<XFile?> pickImage(ImageSource source) async {
    try {
      return await _picker.pickImage(
          source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
}
