import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/errors/app_exceptions.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.posts);

  // ─── Créer un post ────────────────────────────────────────────────────────

  Future<PostModel> createPost({
    required String authorId,
    required String content,
    List<String> mediaURLs = const [],
    String? clanId,
  }) async {
    try {
      final docRef = _posts.doc();
      final now = Timestamp.now();
      final post = PostModel(
        postId: docRef.id,
        authorId: authorId,
        content: content,
        mediaURLs: mediaURLs,
        likesCount: 0,
        commentsCount: 0,
        repostsCount: 0,
        isRepost: false,
        originalPostId: null,
        repostComment: null,
        isAnnouncement: false,
        clanId: clanId,
        createdAt: now,
        updatedAt: null,
      );
      await docRef.set(post.toFirestore());
      return post;
    } catch (e) {
      throw FirestoreException('Impossible de créer le post : $e');
    }
  }

  // ─── Republier un post ────────────────────────────────────────────────────

  Future<PostModel> repostPost({
    required String authorId,
    required String originalPostId,
    String? repostComment,
  }) async {
    try {
      final docRef = _posts.doc();
      final now = Timestamp.now();
      final post = PostModel(
        postId: docRef.id,
        authorId: authorId,
        content: repostComment ?? '',
        mediaURLs: [],
        likesCount: 0,
        commentsCount: 0,
        repostsCount: 0,
        isRepost: true,
        originalPostId: originalPostId,
        repostComment: repostComment,
        isAnnouncement: false,
        clanId: null,
        createdAt: now,
        updatedAt: null,
      );

      final batch = _firestore.batch();
      batch.set(docRef, post.toFirestore());
      batch.update(_posts.doc(originalPostId), {
        'repostsCount': FieldValue.increment(1),
      });
      batch.set(
        _posts.doc(originalPostId).collection(FirebaseConstants.reposts).doc(authorId),
        {'repostedAt': FieldValue.serverTimestamp()},
      );

      await batch.commit();
      return post;
    } catch (e) {
      throw FirestoreException('Impossible de republier le post : $e');
    }
  }

  // ─── Fil "Pour toi" ───────────────────────────────────────────────────────

  Stream<List<PostModel>> getGlobalFeed({int limit = 20}) {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  // ─── Fil "Abonnements" ────────────────────────────────────────────────────

  Stream<List<PostModel>> getFollowingFeed({
    required List<String> followingIds,
    int limit = 20,
  }) {
    if (followingIds.isEmpty) return Stream.value([]);
    return _posts
        .where('authorId', whereIn: followingIds)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  // ─── Récupérer un post par ID ─────────────────────────────────────────────

  Future<PostModel?> getPostById(String postId) async {
    try {
      final doc = await _posts.doc(postId).get();
      if (!doc.exists) return null;
      return PostModel.fromFirestore(doc);
    } catch (e) {
      throw FirestoreException('Impossible de récupérer le post : $e');
    }
  }

  // ─── Liker / Unliker ──────────────────────────────────────────────────────

  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      final postRef = _posts.doc(postId);
      final likeRef = postRef.collection(FirebaseConstants.likes).doc(userId);

      await _firestore.runTransaction((transaction) async {
        final likeDoc = await transaction.get(likeRef);

        if (likeDoc.exists) {
          transaction.delete(likeRef);
          transaction.update(postRef, {
            'likesCount': FieldValue.increment(-1),
          });
        } else {
          transaction.set(likeRef, {
            'likedAt': FieldValue.serverTimestamp(),
          });
          transaction.update(postRef, {
            'likesCount': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      throw FirestoreException('Impossible de liker le post : $e');
    }
  }

  // ─── Vérifier si liké ────────────────────────────────────────────────────

  Future<bool> isLiked({
    required String postId,
    required String userId,
  }) async {
    final doc = await _posts
        .doc(postId)
        .collection(FirebaseConstants.likes)
        .doc(userId)
        .get();
    return doc.exists;
  }

  // ─── Vérifier si reposté ─────────────────────────────────────────────────

  Future<bool> isReposted({
    required String postId,
    required String userId,
  }) async {
    final doc = await _posts
        .doc(postId)
        .collection(FirebaseConstants.reposts)
        .doc(userId)
        .get();
    return doc.exists;
  }

  // ─── Ajouter un commentaire ───────────────────────────────────────────────

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final commentRef = _posts
          .doc(postId)
          .collection(FirebaseConstants.comments)
          .doc();

      final batch = _firestore.batch();
      batch.set(commentRef, {
        'commentId': commentRef.id,
        'postId': postId,
        'authorId': authorId,
        'content': content,
        'likesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'parentCommentId': parentCommentId,
      });
      batch.update(_posts.doc(postId), {
        'commentsCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      throw FirestoreException('Impossible d\'ajouter le commentaire : $e');
    }
  }

  // ─── Récupérer les commentaires ───────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getComments(String postId) {
    return _posts
        .doc(postId)
        .collection(FirebaseConstants.comments)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  // ─── Supprimer un post ────────────────────────────────────────────────────

  Future<void> deletePost({
    required String postId,
    required String userId,
  }) async {
    try {
      final doc = await _posts.doc(postId).get();
      if (!doc.exists) throw FirestoreException('Post introuvable.');
      final data = doc.data() as Map<String, dynamic>;
      if (data['authorId'] != userId) {
        throw FirestoreException('Tu n\'es pas autorisé à supprimer ce post.');
      }
      await _posts.doc(postId).delete();
    } catch (e) {
      throw FirestoreException('Impossible de supprimer le post : $e');
    }
  }

  // ─── Modifier un post ─────────────────────────────────────────────────────

  Future<void> updatePost({
    required String postId,
    required String userId,
    required String newContent,
  }) async {
    try {
      final doc = await _posts.doc(postId).get();
      if (!doc.exists) throw FirestoreException('Post introuvable.');
      final data = doc.data() as Map<String, dynamic>;
      if (data['authorId'] != userId) {
        throw FirestoreException('Tu n\'es pas autorisé à modifier ce post.');
      }
      await _posts.doc(postId).update({
        'content': newContent,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FirestoreException('Impossible de modifier le post : $e');
    }
  }

  // ─── Posts d'un utilisateur ───────────────────────────────────────────────

  Stream<List<PostModel>> getUserPosts(String userId) {
    return _posts
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }
}