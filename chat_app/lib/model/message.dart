import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final MessageType type;
  final Timestamp timestamp;
  bool isRead;
  bool isDelivered;
  bool isReplied;

  Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.isDelivered = false,
    this.isReplied = false,
  });

  //convert to a map
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'type': type == MessageType.image ? 'image' : 'text',
      'timestamp': timestamp,
      'isRead': isRead,
      'isDelivered': isDelivered,
      'isReplied': isReplied,
    };
  }
}

enum MessageType { text, image }
