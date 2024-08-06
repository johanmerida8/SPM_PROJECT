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

    //get the current time
    final Timestamp messageSentTime = Timestamp.now();

    await sendMsg(receiverId, imageUrl, MessageType.image, messageSentTime);
  }

  //send chat document
  Future<void> sendChatDocument(String receiverId, File file) async {
    //getting document file extension
    final ext = file.path.split('.').last;

    //storage file ref with path
    final userId = _auth.currentUser!.uid;
    final ref = _storage.ref().child(
        'chat_documents/$userId/${DateTime.now().millisecondsSinceEpoch}');

    //upload document to storage
    TaskSnapshot snapshot =
        await ref.putFile(file, SettableMetadata(contentType: 'document/$ext'));

    //print out the upload details
    print(
        'File uploaded. Total bytes: ${snapshot.totalBytes}, bytes transferred: ${snapshot.bytesTransferred}');

    //get document url
    final documentUrl = await ref.getDownloadURL();

    //get the current time
    final Timestamp messageSentTime = Timestamp.now();

    //send the message with the document url
    await sendMsg(
        receiverId, documentUrl, MessageType.document, messageSentTime);
  }

  //send chat audio
  Future<void> sendChatAudio(String receiverId, File file) async {
    //getting audio file extension
    final ext = file.path.split('.').last;

    //storage file ref with path
    final userId = _auth.currentUser!.uid;
    final ref = _storage.ref().child(
        'chat_audios/$userId/${DateTime.now().millisecondsSinceEpoch}.$ext');

    //upload audio to storage
    TaskSnapshot snapshot =
        await ref.putFile(file, SettableMetadata(contentType: 'audio/$ext'));

    //print out the upload details
    print(
        'File uploaded. Total bytes: ${snapshot.totalBytes}, bytes transferred: ${snapshot.bytesTransferred}');

    //get audio url
    final audioUrl = await ref.getDownloadURL();

    //get the current time
    final Timestamp messageSentTime = Timestamp.now();

    //send the message with the audio url
    await sendMsg(receiverId, audioUrl, MessageType.audio, messageSentTime);
  }

  //GET ALL USER EXCEPT BLOCKED USERS

  //SEND MESSAGE
  Future<void> sendMsg(String receiverId, String msg, MessageType type,
      Timestamp messageSentTime) async {
    try {
      //get current user info
      final String currentUserId = _auth.currentUser!.uid;
      final String currentUserEmail = _auth.currentUser!.email.toString();

      //create a new message
      Message newMessage = Message(
        senderId: currentUserId,
        senderEmail: currentUserEmail,
        receiverId: receiverId,
        message: msg,
        msgSentTime: messageSentTime,
        type: type,
        timestamp: messageSentTime,
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

  //REPORT USER
  Future<void> reportUser(String msgId, String userId) async {
    try {
      final currentUser = _auth.currentUser;
      final report = {
        'reportedBy': currentUser!.uid,
        'messageId': msgId,
        'messageOwnerId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('reports').add(report);
    } catch (e) {
      print('Error reporting user: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Remove contact from current user's contact list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('contacts')
          .doc(userId)
          .delete();

      // Remove contact from the other user's contact list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(currentUser.uid)
          .delete();
      
      notifyListeners(); // Notify listeners if you're using ChangeNotifier
    }
  } catch (e) {
    print('Error deleting user: $e');
  }
}

  //BLOCK USER
  Future<void> blockUser(String userId) async {
    try {
      final currentUser = _auth.currentUser;

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('blockedContacts')
          .doc(userId)
          .set({});
      notifyListeners();
    } catch (e) {
      print('Error blocking user: $e');
    }
  }

  //UNBLOCK USER
  Future<void> unblockUser(String blockedUserId) async {
    try {
      final currentUser = _auth.currentUser;

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('blockedContacts')
          .doc(blockedUserId)
          .delete();
    } catch (e) {
      print('Error unblocking user: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getBlockedUsers(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('blockedContacts')
        .snapshots()
        .asyncMap((snapshot) async {
      final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();

      final userDocs = await Future.wait(blockedUserIds
          .map((id) => _firestore.collection('users').doc(id).get()));

      //return the user data as a list of maps
      return userDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  //GET ALL USER CONTACT EXCEPT BLOCKED USERS
  Stream<List<Map<String, dynamic>>> getUsersExcludingBlockedUsers() {
    try {
      //get the user's contacts
      return _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('contacts')
          .snapshots()
          .asyncMap((snapshot) async {
        //get the user's blocked contacts
        final blockedUserIds = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('blockedContacts')
            .get()
            //get the ids of the blocked users
            .then((value) => value.docs.map((doc) => doc.id).toList());
        //get the user data for each contact
        final userDocs = await Future.wait(snapshot.docs
            //filter out the blocked users
            .where((doc) => !blockedUserIds.contains(doc.id))
            //get the user data
            .map((doc) => _firestore.collection('users').doc(doc.id).get()));

        //return the user data as a list of maps
        return userDocs
            //convert the user data to a map
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print('Error getting users: $e');
      rethrow;
    }
  }

  Stream<List<DocumentSnapshot>> getUserContactsExcludingBlocked() {
  return _firestore
      //get the user's contacts
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('contacts')
      .orderBy('name')
      .snapshots()
      //filter out the blocked users
      .asyncMap((contactsSnapshot) async {
      //get the ids of the blocked users
    final blockedUserIds = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('blockedContacts')
        .get()
        //get the ids of the blocked users
        .then((blockedSnapshot) => blockedSnapshot.docs.map((doc) => doc.id).toSet());
      //filter out the blocked users
    final filteredContacts = contactsSnapshot.docs
        .where((contactDoc) => !blockedUserIds.contains(contactDoc.id))
        .toList();
      //return the filtered contacts
    return filteredContacts;
  });
}

  //GET USERS EXCEPT BLOCKED USERS
  Stream<QuerySnapshot> getUserContacts() {
    try {
      return _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('contacts')
          .orderBy('name')
          .snapshots();

      // 
    } catch (e) {
      print('Error getting users: $e');
      rethrow;
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

  //react to a message (add and update)
  Future<void> reactToMsg(String otherUserId, String msgId, String reactionId,
      String emojiMsg) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;

      //construct chat room id from user ids (sorted to ensure it matches the id used when sending messages)
      List<String> ids = [currentUserId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join("_");

      //get the message from the database
      DocumentSnapshot doc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(msgId)
          .get();

      //get the reactions field from the document
      Map<String, dynamic>? reactions =
          (doc.data() as Map<String, dynamic>)['reactions'];

      //if the reactions field is null, create a new map
      if (reactions == null) {
        reactions = {};
      }

      //if the user has already reacted to the message, update the reaction
      if (reactions.containsKey(currentUserId)) {
        reactions[currentUserId] = {
          'reactionId': reactionId,
          'emojiMsg': emojiMsg,
        };

        //update the reactions field in the database
        await _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages')
            .doc(msgId)
            .update({'reactions': reactions});
      } else {
        //if the user has not reacted to the message, add a new reaction
        reactions[currentUserId] = {
          'reactionId': reactionId,
          'emojiMsg': emojiMsg,
        };

        //update the reactions field in the database
        await _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages')
            .doc(msgId)
            .update({'reactions': reactions});
      }
    } catch (e) {
      print('Error reacting to message: $e');
    }
  }

  //remove reaction from a message
  Future<void> removeReaction(String otherUserId, String msgId) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;

      //construct chat room id from user ids (sorted to ensure it matches the id used when sending messages)
      List<String> ids = [currentUserId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join("_");

      //get the message from the database
      DocumentSnapshot doc = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(msgId)
          .get();

      //get the reactions field from the document
      Map<String, dynamic>? reactions =
          (doc.data() as Map<String, dynamic>)['reactions'];

      //if the reactions field is null, return
      if (reactions == null) {
        return;
      }

      //if the user has reacted to the message, remove the reaction
      if (reactions.containsKey(currentUserId)) {
        reactions.remove(currentUserId);

        //update the reactions field in the database
        await _firestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .collection('messages')
            .doc(msgId)
            .update({'reactions': reactions});
      }
    } catch (e) {
      print('Error removing reaction: $e');
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
          .orderBy('timestamp',
              descending: true) //sort messages by timestamp in descending order
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
