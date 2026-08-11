import 'package:cloud_firestore/cloud_firestore.dart';

enum NotifType { follow, like, comment, repost, announcement }

class NotificationModel {
  final String    notifId;
  final String    recipientId;
  final NotifType type;
  final String?   senderId;
  final String?   targetType;
  final String?   targetId;
  final bool      read;
  final Timestamp createdAt;

  const NotificationModel({
    required this.notifId,
    required this.recipientId,
    required this.type,
    this.senderId,
    this.targetType,
    this.targetId,
    this.read = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      notifId:     doc.id,
      recipientId: d['recipientId'] ?? '',
      type: NotifType.values.firstWhere(
              (e) => e.name == d['type'],
              orElse: () => NotifType.like),
      senderId:   d['senderId'],
      targetType: d['targetType'],
      targetId:   d['targetId'],
      read:       d['read']      ?? false,
      createdAt:  d['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'recipientId': recipientId, 'type': type.name,
    'senderId': senderId,       'targetType': targetType,
    'targetId': targetId,       'read': read,
    'createdAt': createdAt,
  };
}
