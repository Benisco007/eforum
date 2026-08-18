import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole   { user, admin }
enum UserStatus { active, suspended, disabled }

class UserModel {
  final String     uid;
  final String     username;
  final String     email;
  final String?    photoURL;
  final String?    teamPhotoURL;
  final String?    favPlayerName;
  final String?    favPlayerCardURL;
  final String?    bio;
  final int        followersCount;
  final int        followingCount;
  final String?    clanId;
  final UserRole   role;
  final UserStatus status;
  final Timestamp  createdAt;
  final bool onboardingCompleted;

  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.photoURL,
    this.teamPhotoURL,
    this.favPlayerName,
    this.favPlayerCardURL,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.clanId,
    this.role   = UserRole.user,
    this.status = UserStatus.active,
    this.onboardingCompleted = false,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid:             doc.id,
      username:        d['username']        ?? '',
      email:           d['email']           ?? '',
      photoURL:        d['photoURL'],
      teamPhotoURL:    d['teamPhotoURL'],
      favPlayerName:   d['favPlayerName'],
      favPlayerCardURL:d['favPlayerCardURL'],
      bio:             d['bio'],
      followersCount:  d['followersCount']  ?? 0,
      followingCount:  d['followingCount']  ?? 0,
      clanId:          d['clanId'],
      role:   UserRole.values.firstWhere(
                (e) => e.name == d['role'], orElse: () => UserRole.user),
      status: UserStatus.values.firstWhere(
                (e) => e.name == d['status'], orElse: () => UserStatus.active),
      createdAt: d['createdAt'] ?? Timestamp.now(),
      onboardingCompleted: d['onboardingCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'username':        username,
    'email':           email,
    'photoURL':        photoURL,
    'teamPhotoURL':    teamPhotoURL,
    'favPlayerName':   favPlayerName,
    'favPlayerCardURL':favPlayerCardURL,
    'bio':             bio,
    'followersCount':  followersCount,
    'followingCount':  followingCount,
    'clanId':          clanId,
    'role':            role.name,
    'status':          status.name,
    'createdAt':       createdAt,
    'onboardingCompleted': onboardingCompleted,
  };

  UserModel copyWith({
    String? username, String? photoURL, String? teamPhotoURL,
    String? favPlayerName, String? favPlayerCardURL, String? bio,
    int? followersCount, int? followingCount, String? clanId,
    UserRole? role, UserStatus? status,
    bool? onboardingCompleted,
  }) => UserModel(
    uid: uid, email: email, createdAt: createdAt,
    username:        username        ?? this.username,
    photoURL:        photoURL        ?? this.photoURL,
    teamPhotoURL:    teamPhotoURL    ?? this.teamPhotoURL,
    favPlayerName:   favPlayerName   ?? this.favPlayerName,
    favPlayerCardURL:favPlayerCardURL?? this.favPlayerCardURL,
    bio:             bio             ?? this.bio,
    followersCount:  followersCount  ?? this.followersCount,
    followingCount:  followingCount  ?? this.followingCount,
    clanId:          clanId          ?? this.clanId,
    role:            role            ?? this.role,
    status:          status          ?? this.status,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
  );
}
