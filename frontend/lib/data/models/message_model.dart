import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String    messageId;
  final String    senderId;
  final String    content;
  final Timestamp sentAt;
  final bool      read;

  const MessageModel({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.read = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      messageId: doc.id,
      senderId:  d['senderId'] ?? '',
      content:   d['content']  ?? '',
      sentAt:    d['sentAt']   ?? Timestamp.now(),
      read:      d['read']     ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId, 'content': content,
    'sentAt': sentAt, 'read': read,
  };
}
