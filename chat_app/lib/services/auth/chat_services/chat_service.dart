import 'package:chat_app/model/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatService extends ChangeNotifier {
  //get instance of auth and firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //SEND MESSAGE
  Future<void> sendMsg(String receiverId, String msg) async {
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
          timestamp: timestamp);

      //construct chat room id from current user id and receiver id (sorted to ensure uniqueness)
      List<String> ids = [currentUserId, receiverId];
      ids.sort(); //sort the ids (this ensures the chat room id is always the same for any pair of people)
      String chatRoomId = ids.join(
          "_"); //combine the ids into a single string to use a chatroom id

      //add new message to database
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage.toMap());
    } catch (e) {
      print('Error sending message: $e');
    }
  }

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

  //DELETE MESSAGE
  Future<void> deleteMsg(String otherUserId, String msgId, String senderTranslateDeleteMsgTxt, String receiverTranslateDeleteMsgTxt) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;

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
            'message': currentUserId == otherUserId ? receiverTranslateDeleteMsgTxt : senderTranslateDeleteMsgTxt,
            'isDeleted': true,
          });

      //start a timer to delete the message from the database
      Future.delayed(Duration(seconds: 10), () async {
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
  Future<void> undoMsgDelete(String otherUserId, String msgId, String originalContent) async {
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
