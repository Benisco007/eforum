import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String    commentId;
  final String    authorId;
  final String    content;
  final int       likesCount;
  final Timestamp createdAt;

  const CommentModel({
    required this.commentId,
    required this.authorId,
    required this.content,
    this.likesCount = 0,
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CommentModel(
      commentId:  doc.id,
      authorId:   d['authorId']  ?? '',
      content:    d['content']   ?? '',
      likesCount: d['likesCount']?? 0,
      createdAt:  d['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'authorId':  authorId,
    'content':   content,
    'likesCount':likesCount,
    'createdAt': createdAt,
  };
}
