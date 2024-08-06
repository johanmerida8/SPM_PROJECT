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
  Map<String, String>? reactions;

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
    this.reactions,
  });

  //convert to a map
  Map<String, dynamic> toMap() {
    String typeStr = 'text';
    switch (type) {
      case MessageType.text:
        typeStr = 'text';
        break;
      case MessageType.image:
        typeStr = 'image';
        break;
      case MessageType.document:
        typeStr = 'document';
        break;
      case MessageType.audio:
        typeStr = 'audio';
        break;
    }

    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'type': typeStr,
      'timestamp': timestamp,
      'msgSentTime': msgSentTime,
      'isRead': isRead,
      'isDelivered': isDelivered,
      'reactions': reactions,
    };
  }

}

enum MessageType { text, image, document, audio}
