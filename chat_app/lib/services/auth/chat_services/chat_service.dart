import 'dart:io';

import 'package:chat_app/language/locale_notifier.dart';
import 'package:chat_app/model/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatService extends ChangeNotifier {
  //get instance of auth and firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> readMsg(String senderId) async {
    try {
      //reset the unread messages field for the current user
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('contacts')
          .doc(senderId)
          .set({'unreadMessages': 0}, SetOptions(merge: true));

      //get the chat room id
      List<String> ids = [_auth.currentUser!.uid, senderId];
      ids.sort();
      String chatRoomId = ids.join("_");

      //query all messages from senderId to the current user
      QuerySnapshot querySnapshot = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: _auth.currentUser!.uid)
          .get();

      //update isRead field for each message
      for (DocumentSnapshot doc in querySnapshot.docs) {
        doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print('Error reading messages: $e');
    }
  }

  //send chat image
  Future<void> sendChatImage(String receiverId, File file) async {
    //getting image file extension
    final ext = file.path.split('.').last;

    //storage file ref with path
    final userId = _auth.currentUser!.uid;
    final ref = _storage
        .ref()
        .child('chat_images/$userId/${DateTime.now().millisecondsSinceEpoch}');

    //upload image to storage
    TaskSnapshot snapshot =
        await ref.putFile(file, SettableMetadata(contentType: 'image/$ext'));

    //print out the upload details
    print(
        'File uploaded. Total bytes: ${snapshot.totalBytes}, bytes transferred: ${snapshot.bytesTransferred}');

    //get image url
    final imageUrl = await ref.getDownloadURL();
    await sendMsg(receiverId, imageUrl, MessageType.image);
  }

  //SEND MESSAGE
  Future<void> sendMsg(String receiverId, String msg, MessageType type) async {
    try {
      //get current user info
      final String currentUserId = _auth.currentUser!.uid;
      final String currentUserEmail = _auth.currentUser!.email.toString();
      final Timestamp timestamp = Timestamp.now();

      //create a new message
      Message newMessage = Message(
        senderId: currentUserId,
        senderEmail: currentUserEmail,
        receiverId: receiverId,
        message: msg,
        type: type,
        timestamp: timestamp,
        isRead: false,
        isDelivered: false,
      );

      //construct chat room id from current user id and receiver id (sorted to ensure uniqueness)
      List<String> ids = [currentUserId, receiverId];
      ids.sort(); //sort the ids (this ensures the chat room id is always the same for any pair of people)
      String chatRoomId = ids.join(
          "_"); //combine the ids into a single string to use a chatroom id

      //add new message to database
      DocumentReference docRef = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage.toMap());

      //update isDelivered to true after the message has been sent to the database
      docRef.update({'isDelivered': true});

      

      //increment the unread messages field for the receiver
      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('contacts')
          .doc(currentUserId)
          .set({'unreadMessages': FieldValue.increment(1)},
              SetOptions(merge: true));
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  //REPLY MESSAGE
//   Future<void> replyMsg(String originalMessageId, String receiverId, String reply, MessageType type) async {
//   try {
//     // get current user info
//     final String currentUserId = _auth.currentUser!.uid;
//     final String currentUserEmail = _auth.currentUser!.email.toString();
//     final Timestamp timestamp = Timestamp.now();

//     // create a new message
//     Message newMessage = Message(
//       senderId: currentUserId,
//       senderEmail: currentUserEmail,
//       receiverId: receiverId,
//       message: reply,
//       type: type,
//       timestamp: timestamp,
//       isRead: false,
//       isDelivered: false,
//       isReplied: true, // this is a reply, so set isReplied to true
//     );

//     // construct chat room id from current user id and receiver id (sorted to ensure uniqueness)
//     List<String> ids = [currentUserId, receiverId];
//     ids.sort(); // sort the ids (this ensures the chat room id is always the same for any pair of people)
//     String chatRoomId = ids.join("_"); // combine the ids into a single string to use a chatroom id

//     // add new message to database
//     DocumentReference docRef = await _firestore
//         .collection('chat_rooms')
//         .doc(chatRoomId)
//         .collection('messages')
//         .add(newMessage.toMap());

//     // update isDelivered to true after the message has been sent to the database
//     docRef.update({'isDelivered': true});

//     // update isReplied to true for the original message
//     await _firestore
//         .collection('chat_rooms')
//         .doc(chatRoomId)
//         .collection('messages')
//         .doc(originalMessageId)
//         .update({'isReplied': true});

//     // increment the unread messages field for the receiver
//     await _firestore
//         .collection('users')
//         .doc(receiverId)
//         .collection('contacts')
//         .doc(currentUserId)
//         .set({'unreadMessages': FieldValue.increment(1)}, SetOptions(merge: true));
//   } catch (e) {
//     print('Error sending reply: $e');
//   }
// }

  //GET MESSAGE
  Stream<QuerySnapshot> getMsg(String userId, String otherUserId) {
    try {
      //construct chat room id from user ids (sorted to ensure it matches the id used when sending messages)
      List<String> ids = [userId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join("_");

      //get messages from database
      return _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: false) 
          .snapshots();
    } catch (e) {
      print('Error getting messages: $e');
      rethrow;
    }
  }


  //GET LAST MESSAGE
  Stream<QuerySnapshot> getLastMsg(String userId, String otherUserId) {
    try {
      //construct chat room id from user ids (sorted to ensure it matches the id used when sending messages)
      List<String> ids = [userId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join("_");

      //get messages from database
      return _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true) //sort messages by timestamp in descending order
          .limit(1) //get only the last message
          .snapshots();
    } catch (e) {
      print('Error getting messages: $e');
      rethrow;
    }
  }

  //GET IMAGE URL OF USER
  Future<String> getImageUrl(String userId) async {
    try {
      //get the image url from the database
      DocumentSnapshot doc =
          await _firestore.collection('imageUser').doc(userId).get();

      //check if the document exists and has data
      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          //return the image url
          return data['imageUrl'];
        }
      }
    } catch (e) {
      print('Error getting image url: $e');
      rethrow;
    }
    return '';
  }

  //DELETE IMAGE
  Future<void> deleteImage(String imageUrl) async {
    try {
      //get the image ref from the url
      Reference ref = _storage.refFromURL(imageUrl);

      //delete the image
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  //DELETE MESSAGE
  Future<void> deleteMsg(
      BuildContext context, String otherUserId, String msgId) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;

      final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);

      String translatedDeleteMsgTxt = lanNotifier.translate('messageDeleted');

      //construct chat room id from user ids (sorted to ensure it matches the id used when sending messages)
      List<String> ids = [currentUserId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join("_");

      //get the message to be deleted
      DocumentSnapshot doc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(msgId)
          .get();

      //store the original content
      String originalContent = (doc.data() as Map<String, dynamic>)['message'];

      //check if the message has already been deleted
      if ((doc.data() as Map<String, dynamic>)['isDeleted'] == true) {
        print('Message has already been deleted');
        return;
      }

      //delete message from database
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(msgId)
          .update({
        'message': translatedDeleteMsgTxt,
        'isDeleted': true,
      });

      //start a timer to delete the message from the database
      Future.delayed(Duration(seconds: 15), () async {
        //check if the message is still marked as to be deleted
        DocumentSnapshot doc = await _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages')
            .doc(msgId)
            .get();

        //if the message is still marked as to be deleted, delete it
        if ((doc.data() as Map<String, dynamic>)['isDeleted']) {
          await _firestore
              .collection('chat_rooms')
              .doc(chatRoomId)
              .collection('messages')
              .doc(msgId)
              .delete();
        } else {
          //if the message is no longer marked as to be deleted, undo the deletion
          await undoMsgDelete(otherUserId, msgId, originalContent);
        }
      });
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  //UNDO MESSAGE DELETION
  Future<void> undoMsgDelete(
      String otherUserId, String msgId, String originalContent) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;

      List<String> ids = [currentUserId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join("_");

      //Unmark the message
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(msgId)
          .update({
        'message': originalContent,
        'isDeleted': false,
      });
    } catch (e) {
      print('Error undoing message deletion: $e');
    }
  }

  //UPDATE MESSAGE
  Future<bool> updateMsg(
      String otherUserId, String msgId, String newMsg) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;

      //construct chat room id from user ids (sorted to ensure it matches the id used when sending messages)
      List<String> ids = [currentUserId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join("_");

      //get message from database
      DocumentSnapshot msgDoc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(msgId)
          .get();

      //get the updated field from the document
      bool updated =
          (msgDoc.data() as Map<String, dynamic>)['updated'] ?? false;

      //if the message has not been updated, update it
      if (!updated) {
        await _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages')
            .doc(msgId)
            .update({
          'message': newMsg,
          'updated': true,
        });
        return true;
      } else {
        print('Message has already been updated');
        return false;
      }
    } catch (e) {
      print('Error updating message: $e');
      return false;
    }
  }
}
