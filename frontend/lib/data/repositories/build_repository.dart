import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/build_model.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/errors/app_exceptions.dart';

class BuildRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Créer un build ────────────────────────────────────────────────────────

  Future<void> createBuild(BuildModel build) async {
    try {
      await _db
          .collection(FirebaseConstants.builds)
          .doc(build.buildId)
          .set(build.toFirestore());
    } catch (e) {
      throw FirestoreException('Erreur lors de la création du build.');
    }
  }

  // ─── Tous les builds (fil global) ─────────────────────────────────────────

  Stream<List<BuildModel>> getAllBuilds() {
    return _db
        .collection(FirebaseConstants.builds)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(BuildModel.fromFirestore).toList());
  }

  // ─── Builds d'un user ─────────────────────────────────────────────────────

  Stream<List<BuildModel>> getUserBuilds(String uid) {
    return _db
        .collection(FirebaseConstants.builds)
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BuildModel.fromFirestore).toList());
    }

  // ─── Un build par ID ───────────────────────────────────────────────────────

  Future<BuildModel?> getBuildById(String buildId) async {
    final doc = await _db
        .collection(FirebaseConstants.builds)
        .doc(buildId)
        .get();
    return doc.exists ? BuildModel.fromFirestore(doc) : null;
  }

  // ─── Supprimer un build ────────────────────────────────────────────────────

  Future<void> deleteBuild(String buildId) async {
    await _db.collection(FirebaseConstants.builds).doc(buildId).delete();
  }

  // ─── Toggle like ───────────────────────────────────────────────────────────

  Future<void> toggleLike(String buildId, String userId) async {
    final likeRef = _db
        .collection(FirebaseConstants.builds)
        .doc(buildId)
        .collection('likes')
        .doc(userId);
    final buildRef = _db.collection(FirebaseConstants.builds).doc(buildId);
    final batch = _db.batch();
    final likeDoc = await likeRef.get();
    if (likeDoc.exists) {
      batch.delete(likeRef);
      batch.update(buildRef, {'likesCount': FieldValue.increment(-1)});
    } else {
      batch.set(likeRef, {'likedAt': Timestamp.now()});
      batch.update(buildRef, {'likesCount': FieldValue.increment(1)});
    }
    await batch.commit();
  }

  // ─── Vérifier si liké ─────────────────────────────────────────────────────

  Future<bool> isLiked(String buildId, String userId) async {
    final doc = await _db
        .collection(FirebaseConstants.builds)
        .doc(buildId)
        .collection('likes')
        .doc(userId)
        .get();
    return doc.exists;
  }
}