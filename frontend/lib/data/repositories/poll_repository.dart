import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poll_model.dart';

class PollRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  CollectionReference get _polls => _fs.collection('polls');

  // ─── Créer un sondage ─────────────────────────────────────────────────────

  Future<PollModel> createPoll({
    required String         authorId,
    required String         question,
    required List<String>   optionTexts,
    Duration?               duration,       // null = sans limite
  }) async {
    final docRef = _polls.doc();
    final now    = Timestamp.now();
    final options = optionTexts.asMap().entries.map((e) => PollOption(
      id:    'opt_${e.key}',
      text:  e.value,
      votes: 0,
    )).toList();

    final poll = PollModel(
      pollId:     docRef.id,
      authorId:   authorId,
      question:   question,
      options:    options,
      totalVotes: 0,
      createdAt:  now,
      endsAt:     duration != null
          ? Timestamp.fromDate(now.toDate().add(duration))
          : null,
    );

    await docRef.set(poll.toFirestore());
    return poll;
  }

  // ─── Voter ────────────────────────────────────────────────────────────────

  Future<void> vote({
    required String pollId,
    required String userId,
    required String optionId,
  }) async {
    final pollRef = _polls.doc(pollId);
    final voteRef = pollRef.collection('votes').doc(userId);

    await _fs.runTransaction((tx) async {
      final voteDoc = await tx.get(voteRef);
      if (voteDoc.exists) return;          // Déjà voté

      final pollDoc = await tx.get(pollRef);
      if (!pollDoc.exists) return;

      final data    = pollDoc.data() as Map<String, dynamic>;
      final options = List<Map<String, dynamic>>.from(
          (data['options'] as List).map((e) => Map<String, dynamic>.from(e)));

      final idx = options.indexWhere((o) => o['id'] == optionId);
      if (idx == -1) return;
      options[idx]['votes'] = (options[idx]['votes'] as int) + 1;

      tx.update(pollRef, {
        'options':    options,
        'totalVotes': FieldValue.increment(1),
      });
      tx.set(voteRef, {'optionId': optionId, 'votedAt': FieldValue.serverTimestamp()});
    });
  }

  // ─── Récupérer l'option choisie par l'user ────────────────────────────────

  Future<String?> getUserVote({required String pollId, required String userId}) async {
    final doc = await _polls.doc(pollId).collection('votes').doc(userId).get();
    if (!doc.exists) return null;
    return (doc.data() as Map<String, dynamic>)['optionId'] as String?;
  }

  // ─── Stream du feed global (sondages récents) ────────────────────────────

  Stream<List<PollModel>> getRecentPolls({int limit = 20}) {
    return _polls
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => PollModel.fromFirestore(d)).toList());
  }

  // ─── Stream d'un seul sondage ─────────────────────────────────────────────

  Stream<PollModel?> watchPoll(String pollId) {
    return _polls.doc(pollId).snapshots().map(
          (doc) => doc.exists ? PollModel.fromFirestore(doc) : null);
  }

  // ─── Supprimer un sondage ─────────────────────────────────────────────────

  Future<void> deletePoll({
    required String pollId,
    required String userId,
  }) async {
    final doc = await _polls.doc(pollId).get();
    if (!doc.exists) throw Exception('Sondage introuvable.');
    final data = doc.data() as Map<String, dynamic>;
    if (data['authorId'] != userId) {
      throw Exception('Tu n\'es pas autorisé à supprimer ce sondage.');
    }
    await _polls.doc(pollId).delete();
  }
}
