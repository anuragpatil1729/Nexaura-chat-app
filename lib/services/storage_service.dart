
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(File image) async {
    try {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference reference = _storage.ref().child('images/$fileName');
      final UploadTask uploadTask = reference.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('Failed to upload image with error code: ${e.code}');
        print(e.message);
      }
      rethrow; // Re-throwing the exception to be handled by the UI.
    } catch (e) {
      if (kDebugMode) {
        print('An unexpected error occurred: $e');
      }
      rethrow;
    }
  }
}
