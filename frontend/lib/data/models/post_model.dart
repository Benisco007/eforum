import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String       postId;
  final String       authorId;
  final String       content;
  final List<String> mediaURLs;
  final int          likesCount;
  final int          commentsCount;
  final int          repostsCount;
  final bool         isAnnouncement;
  final bool         isRepost;
  final String?      originalPostId;
  final String?      repostComment;
  final String?      clanId;
  final Timestamp    createdAt;
  final Timestamp?   updatedAt;

  const PostModel({
    required this.postId,
    required this.authorId,
    required this.content,
    this.mediaURLs     = const [],
    this.likesCount    = 0,
    this.commentsCount = 0,
    this.repostsCount  = 0,
    this.isAnnouncement = false,
    this.isRepost      = false,
    this.originalPostId,
    this.repostComment,
    this.clanId,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isOriginal => !isRepost;

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PostModel(
      postId:         doc.id,
      authorId:       d['authorId']       ?? '',
      content:        d['content']        ?? '',
      mediaURLs:      List<String>.from(d['mediaURLs'] ?? []),
      likesCount:     d['likesCount']     ?? 0,
      commentsCount:  d['commentsCount']  ?? 0,
      repostsCount:   d['repostsCount']   ?? 0,
      isAnnouncement: d['isAnnouncement'] ?? false,
      isRepost:       d['isRepost']       ?? false,
      originalPostId: d['originalPostId'],
      repostComment:  d['repostComment'],
      clanId:         d['clanId'],
      createdAt:      d['createdAt']      ?? Timestamp.now(),
      updatedAt:      d['updatedAt'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'authorId':       authorId,
    'content':        content,
    'mediaURLs':      mediaURLs,
    'likesCount':     likesCount,
    'commentsCount':  commentsCount,
    'repostsCount':   repostsCount,
    'isAnnouncement': isAnnouncement,
    'isRepost':       isRepost,
    'originalPostId': originalPostId,
    'repostComment':  repostComment,
    'clanId':         clanId,
    'createdAt':      createdAt,
    'updatedAt':      updatedAt,
  };
}
