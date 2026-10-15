import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref().child('profile_images/$uid.jpg');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteProfileImage(String uid) async {
    try {
      await _storage.ref().child('profile_images/$uid.jpg').delete();
    } catch (_) {
      // Ignore if file does not exist
    }
  }
}
