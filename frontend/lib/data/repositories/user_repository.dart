import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/errors/app_exceptions.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.users);

  // ─── Récupérer un utilisateur par UID ────────────────────────────────────

  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw FirestoreException('Impossible de récupérer l\'utilisateur : $e');
    }
  }

  // ─── Stream d'un utilisateur (temps réel) ────────────────────────────────

  Stream<UserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // ─── Mettre à jour le profil ──────────────────────────────────────────────

  Future<void> updateProfile({
    required String uid,
    String? username,
    String? photoURL,
    String? teamPhotoURL,
    String? bio,
    String? favPlayerName,
    String? favPlayerCard,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (photoURL != null) data['photoURL'] = photoURL;
      if (teamPhotoURL != null) data['teamPhotoURL'] = teamPhotoURL;
      if (bio != null) data['bio'] = bio;
      if (favPlayerName != null) data['favPlayerName'] = favPlayerName;
      if (favPlayerCard != null) data['favPlayerCard'] = favPlayerCard;

      if (data.isEmpty) return;
      await _users.doc(uid).update(data);
    } catch (e) {
      throw FirestoreException('Impossible de mettre à jour le profil : $e');
    }
  }

  // ─── Vérifier la disponibilité d'un username ──────────────────────────────

  Future<bool> isUsernameAvailable(String username) async {
    final query = await _users
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  // ─── Suivre / Ne plus suivre un utilisateur ───────────────────────────────

  Future<void> toggleFollow({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final followingRef = _users
          .doc(currentUserId)
          .collection(FirebaseConstants.following)
          .doc(targetUserId);

      final followerRef = _users
          .doc(targetUserId)
          .collection(FirebaseConstants.followers)
          .doc(currentUserId);

      final isFollowing = (await followingRef.get()).exists;
      final batch = _firestore.batch();

      if (isFollowing) {
        // Unfollow
        batch.delete(followingRef);
        batch.delete(followerRef);
        batch.update(_users.doc(currentUserId), {
          'followingCount': FieldValue.increment(-1),
        });
        batch.update(_users.doc(targetUserId), {
          'followersCount': FieldValue.increment(-1),
        });
      } else {
        // Follow
        batch.set(followingRef, {'followedAt': FieldValue.serverTimestamp()});
        batch.set(followerRef, {'followedAt': FieldValue.serverTimestamp()});
        batch.update(_users.doc(currentUserId), {
          'followingCount': FieldValue.increment(1),
        });
        batch.update(_users.doc(targetUserId), {
          'followersCount': FieldValue.increment(1),
        });
      }

      await batch.commit();
    } catch (e) {
      throw FirestoreException('Impossible de suivre/ne plus suivre : $e');
    }
  }

  // ─── Vérifier si on suit un utilisateur ──────────────────────────────────

  Future<bool> isFollowing({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final doc = await _users
        .doc(currentUserId)
        .collection(FirebaseConstants.following)
        .doc(targetUserId)
        .get();
    return doc.exists;
  }

  // ─── Récupérer la liste des IDs suivis ───────────────────────────────────

  Future<List<String>> getFollowingIds(String uid) async {
    try {
      final snap = await _users
          .doc(uid)
          .collection(FirebaseConstants.following)
          .get();
      return snap.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw FirestoreException('Impossible de récupérer les abonnements : $e');
    }
  }

  // ─── Recherche d'utilisateurs par username ────────────────────────────────

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return [];
      final snap = await _users
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();
      return snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw FirestoreException('Impossible de rechercher les utilisateurs : $e');
    }
  }

  // ─── Suspendre / Réactiver un compte (admin) ──────────────────────────────

  Future<void> updateUserStatus({
    required String uid,
    required String status,
  }) async {
    try {
      await _users.doc(uid).update({'status': status});
    } catch (e) {
      throw FirestoreException('Impossible de mettre à jour le statut : $e');
    }
  }
}