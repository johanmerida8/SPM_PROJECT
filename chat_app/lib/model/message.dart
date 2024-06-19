import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final MessageType type;
  final Timestamp timestamp;
  final Timestamp msgSentTime;
  bool isRead;
  bool isDelivered;

  Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.msgSentTime,
    this.isRead = false,
    this.isDelivered = false,
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
      'msgSentTime': msgSentTime,
      'isRead': isRead,
      'isDelivered': isDelivered,
    };
  }
}

enum MessageType { text, image }
