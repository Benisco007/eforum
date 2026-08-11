import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String            conversationId;
  final List<String>      participants;
  final String?           lastMessage;
  final Timestamp?        lastMessageAt;
  final Map<String, int>  unreadCount;

  const ConversationModel({
    required this.conversationId,
    required this.participants,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = const {},
  });

  String otherParticipant(String myUid) =>
      participants.firstWhere((uid) => uid != myUid, orElse: () => '');

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      conversationId: doc.id,
      participants:   List<String>.from(d['participants'] ?? []),
      lastMessage:    d['lastMessage'],
      lastMessageAt:  d['lastMessageAt'],
      unreadCount:    Map<String,int>.from(d['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'participants': participants, 'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt, 'unreadCount': unreadCount,
  };
}
