import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportTargetType { post, user }
enum ReportStatus     { pending, reviewed, dismissed }

class ReportModel {
  final String           reportId;
  final String           reporterId;
  final ReportTargetType targetType;
  final String           targetId;
  final String           reason;
  final ReportStatus     status;
  final Timestamp        createdAt;
  final Timestamp?       reviewedAt;
  final String?          reviewedBy;

  const ReportModel({
    required this.reportId,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.status     = ReportStatus.pending,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReportModel(
      reportId:   doc.id,
      reporterId: d['reporterId'] ?? '',
      targetType: ReportTargetType.values.firstWhere(
                    (e) => e.name == d['targetType'],
                    orElse: () => ReportTargetType.post),
      targetId:   d['targetId']   ?? '',
      reason:     d['reason']     ?? '',
      status:     ReportStatus.values.firstWhere(
                    (e) => e.name == d['status'],
                    orElse: () => ReportStatus.pending),
      createdAt:  d['createdAt']  ?? Timestamp.now(),
      reviewedAt: d['reviewedAt'],
      reviewedBy: d['reviewedBy'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'reporterId': reporterId, 'targetType': targetType.name,
    'targetId': targetId,   'reason': reason,
    'status': status.name,  'createdAt': createdAt,
    'reviewedAt': reviewedAt, 'reviewedBy': reviewedBy,
  };
}
