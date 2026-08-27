import 'package:cloud_firestore/cloud_firestore.dart';

class PollOption {
  final String id;
  final String text;
  final int    votes;

  const PollOption({required this.id, required this.text, this.votes = 0});

  factory PollOption.fromMap(Map<String, dynamic> m) => PollOption(
        id:    m['id']    ?? '',
        text:  m['text']  ?? '',
        votes: (m['votes'] as num? ?? 0).toInt(),
      );

  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'votes': votes};
}

class PollModel {
  final String            pollId;
  final String            authorId;
  final String            question;
  final List<PollOption>  options;
  final int               totalVotes;
  final Timestamp         createdAt;
  final Timestamp?        endsAt;   // null = pas d'expiration

  const PollModel({
    required this.pollId,
    required this.authorId,
    required this.question,
    required this.options,
    this.totalVotes = 0,
    required this.createdAt,
    this.endsAt,
  });

  bool get isExpired => endsAt != null && endsAt!.toDate().isBefore(DateTime.now());

  factory PollModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PollModel(
      pollId:     doc.id,
      authorId:   d['authorId']  ?? '',
      question:   d['question']  ?? '',
      options:    (d['options']  as List<dynamic>? ?? [])
                    .map((e) => PollOption.fromMap(Map<String, dynamic>.from(e)))
                    .toList(),
      totalVotes: (d['totalVotes'] as num? ?? 0).toInt(),
      createdAt:  d['createdAt'] ?? Timestamp.now(),
      endsAt:     d['endsAt'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'authorId':   authorId,
    'question':   question,
    'options':    options.map((o) => o.toMap()).toList(),
    'totalVotes': totalVotes,
    'createdAt':  createdAt,
    'endsAt':     endsAt,
  };
}
