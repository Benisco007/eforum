import 'package:cloud_firestore/cloud_firestore.dart';

class ClanModel {
  final String    clanId;
  final String    name;
  final String?   description;
  final String?   logoURL;
  final String?   bannerURL;
  final String    ownerId;
  final int       membersCount;
  final bool      isPrivate;
  final String    status;
  final Timestamp createdAt;

  const ClanModel({
    required this.clanId,
    required this.name,
    this.description,
    this.logoURL,
    this.bannerURL,
    required this.ownerId,
    this.membersCount = 1,
    this.isPrivate    = false,
    this.status       = 'active',
    required this.createdAt,
  });

  factory ClanModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ClanModel(
      clanId:       doc.id,
      name:         d['name']         ?? '',
      description:  d['description'],
      logoURL:      d['logoURL'],
      bannerURL:    d['bannerURL'],
      ownerId:      d['ownerId']      ?? '',
      membersCount: d['membersCount'] ?? 1,
      isPrivate:    d['isPrivate']    ?? false,
      status:       d['status']       ?? 'active',
      createdAt:    d['createdAt']    ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name, 'description': description,
    'logoURL': logoURL, 'bannerURL': bannerURL,
    'ownerId': ownerId, 'membersCount': membersCount,
    'isPrivate': isPrivate, 'status': status, 'createdAt': createdAt,
  };
}
