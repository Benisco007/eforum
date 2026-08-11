import 'package:cloud_firestore/cloud_firestore.dart';
import 'build_stats_model.dart';
import 'booster_model.dart';
import 'coach_model.dart';
import 'physical_data_model.dart';

class BuildModel {
  final String          buildId;
  final String          authorId;
  final String          playerName;
  final String?         playerCardURL;
  final int             overall;
  final String          position;
  final String          playStyle;
  final Map<String,int> positionRatings;
  final BuildStats      stats;
  final List<Booster>   boosters;
  final Coach?          coach;
  final List<String>    skills;
  final PhysicalData?   physicalData;
  final int             likesCount;
  final Timestamp       createdAt;

  const BuildModel({
    required this.buildId,
    required this.authorId,
    required this.playerName,
    this.playerCardURL,
    required this.overall,
    required this.position,
    required this.playStyle,
    this.positionRatings = const {},
    required this.stats,
    this.boosters    = const [],
    this.coach,
    this.skills      = const [],
    this.physicalData,
    this.likesCount  = 0,
    required this.createdAt,
  });

  factory BuildModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BuildModel(
      buildId:        doc.id,
      authorId:       d['authorId']    ?? '',
      playerName:     d['playerName']  ?? '',
      playerCardURL:  d['playerCardURL'],
      overall:        d['overall']     ?? 0,
      position:       d['position']    ?? '',
      playStyle:      d['playStyle']   ?? '',
      positionRatings: Map<String,int>.from(d['positionRatings'] ?? {}),
      stats:    BuildStats.fromMap(d['stats'] ?? {}),
      boosters: (d['boosters'] as List? ?? [])
                    .map((b) => Booster.fromMap(b)).toList(),
      coach:    d['coach'] != null ? Coach.fromMap(d['coach']) : null,
      skills:   List<String>.from(d['skills'] ?? []),
      physicalData: d['physicalData'] != null
                    ? PhysicalData.fromMap(d['physicalData']) : null,
      likesCount: d['likesCount'] ?? 0,
      createdAt:  d['createdAt']  ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'authorId':       authorId,
    'playerName':     playerName,
    'playerCardURL':  playerCardURL,
    'overall':        overall,
    'position':       position,
    'playStyle':      playStyle,
    'positionRatings':positionRatings,
    'stats':          stats.toMap(),
    'boosters':       boosters.map((b) => b.toMap()).toList(),
    'coach':          coach?.toMap(),
    'skills':         skills,
    'physicalData':   physicalData?.toMap(),
    'likesCount':     likesCount,
    'createdAt':      createdAt,
  };
}
