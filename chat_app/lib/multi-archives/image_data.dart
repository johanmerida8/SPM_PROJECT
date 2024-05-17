import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

final FirebaseStorage _storage = FirebaseStorage.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class StoreDataImage {
  Future<String> uploadImageToStorage(String childName, Uint8List file) async {
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String> saveData({
    required Uint8List file,
    required String userId,
  }) async {
    try {
      String folderPath = 'Images/';
      String imageUrl = await uploadImageToStorage(
        '$folderPath${DateTime.now().millisecondsSinceEpoch}', file);
      await _firestore.collection('chatImage').doc(userId).set({
        'imageChat': imageUrl,
        'id': userId,
      });
    } catch (e) {
      print(e);
    }
    return 'Success';
  } 
}
