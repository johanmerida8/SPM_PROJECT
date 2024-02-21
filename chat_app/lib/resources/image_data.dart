import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

final FirebaseStorage storage = FirebaseStorage.instance;
final FirebaseFirestore firestore = FirebaseFirestore.instance;

class StoreData {
  Future<String> uploadImgToStorage(String path, Uint8List file) async {
    try {
      Reference ref = storage.ref().child(path);
      UploadTask uploadTask = ref.putData(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image to storage: $e');
      return '';
    }
  }

  Future<String> saveData({required Uint8List file, required String userId}) async {
    try {
      String folderPath = 'UsersProfileImage/$userId/';
      String imageUrl = await uploadImgToStorage(
        '$folderPath${DateTime.now().millisecondsSinceEpoch}', file,
      );
      await firestore.collection('imageUser').doc(userId).set({
        'imageUrl': imageUrl,
        'userId': userId,
      });
    } catch (e, s) {
      print('Error saving data: $e');
      print('Stacktrace: $s');
    }
    return '';
  }

  //delete image from storage
  // Future<void> deleteImage(String path) async {
  //   try {
  //     await storage.ref().child(path).delete();
  //   } catch (e, s) {
  //     print('Error deleting image: $e');
  //     print('Stacktrace: $s');
  //   }
  // }
}