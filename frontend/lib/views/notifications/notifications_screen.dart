import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/constants/firebase_constants.dart';

// ─── Couleurs eForum ──────────────────────────────────────────────────────────

const _ink     = Color(0xFF07090F);
const _surface = Color(0xFF0E1119);
const _card    = Color(0xFF131824);
const _line    = Color(0xFF1C2236);
const _neon    = Color(0xFF00E676);
const _txt     = Color(0xFFCDD5F0);
const _mut     = Color(0xFF485070);
const _clan    = Color(0xFFFFCC02);
const _build   = Color(0xFFCE93D8);

// ─── Metadata par type de notif ───────────────────────────────────────────────

class _NotifMeta {
  final IconData icon;
  final Color color;
  final String emoji;

  const _NotifMeta({
    required this.icon,
    required this.color,
    required this.emoji,
  });
}

const _notifMeta = {
  'follow':       _NotifMeta(icon: Icons.person_add_outlined,      color: Color(0xFF4FC3F7), emoji: '👤'),
  'like':         _NotifMeta(icon: Icons.favorite_rounded,          color: Color(0xFFFF5A7A), emoji: '❤️'),
  'comment':      _NotifMeta(icon: Icons.chat_bubble_outline_rounded, color: Color(0xFF00E676), emoji: '💬'),
  'repost':       _NotifMeta(icon: Icons.repeat_rounded,            color: Color(0xFFCE93D8), emoji: '🔁'),
  'announcement': _NotifMeta(icon: Icons.campaign_rounded,          color: Color(0xFFFFCC02), emoji: '📢'),
};

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATIONS SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: _ink,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),

          // ── Header ────────────────────────────────────────────────────────
          _buildHeader(context, currentUser?.uid),

          // ── Liste des notifications ───────────────────────────────────────
          Expanded(
            child: currentUser == null
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _neon, strokeWidth: 2),
                  )
                : _buildNotifList(currentUser.uid),
          ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, String? uid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          // Retour
          GestureDetector(
            onTap: () => context.pop(),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.chevron_left_rounded,
                color: _txt,
                size: 26,
              ),
            ),
          ),

          const SizedBox(width: 4),

          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: _txt,
            ),
          ),

          const Spacer(),

          // Tout lire
          if (uid != null)
            GestureDetector(
              onTap: () => _markAllAsRead(uid),
              child: const Text(
                'Tout lire',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _neon,
                ),
              ),
            ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ─── Liste des notifications depuis Firestore ──────────────────────────────

  Widget _buildNotifList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.notifications)
          .where('recipientId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _neon, strokeWidth: 2),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur de chargement',
              style: const TextStyle(color: _mut, fontSize: 13),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmpty();
        }

        // Séparer non-lues et lues
        final unread = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['read'] == false;
        }).toList();

        final read = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['read'] == true;
        }).toList();

        return ListView(
          children: [
            // Section "Nouvelles"
            if (unread.isNotEmpty) ...[
              _buildSectionLabel('Nouvelles'),
              ...unread.map((doc) => _NotifCard(
                    data: doc.data() as Map<String, dynamic>,
                    docId: doc.id,
                    isUnread: true,
                  )),
            ],

            // Section "Plus tôt"
            if (read.isNotEmpty) ...[
              _buildSectionLabel('Plus tôt'),
              ...read.map((doc) => _NotifCard(
                    data: doc.data() as Map<String, dynamic>,
                    docId: doc.id,
                    isUnread: false,
                  )),
            ],

            // Pied de liste
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Fin des notifications des 7 derniers jours.',
                  style: TextStyle(fontSize: 12.5, color: _mut),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Label de section ──────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _mut,
          letterSpacing: 2,
        ),
      ),
    );
  }

  // ─── État vide ─────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _neon.withOpacity(0.08),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: _neon,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _txt,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tes notifications apparaîtront ici.',
            style: TextStyle(fontSize: 13, color: _mut),
          ),
        ],
      ),
    );
  }

  // ─── Marquer tout comme lu ─────────────────────────────────────────────────

  Future<void> _markAllAsRead(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(FirebaseConstants.notifications)
          .where('recipientId', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (_) {}
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIF CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isUnread;

  const _NotifCard({
    required this.data,
    required this.docId,
    required this.isUnread,
  });

  String _buildText() {
    final type = data['type'] as String? ?? '';
    switch (type) {
      case 'follow':
        return 'a commencé à te suivre.';
      case 'like':
        return 'a aimé ton post.';
      case 'comment':
        return 'a commenté ton post.';
      case 'repost':
        return 'a republié ton post.';
      case 'announcement':
        return 'Nouvelle annonce officielle.';
      default:
        return 'a interagi avec toi.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String? ?? 'like';
    final meta = _notifMeta[type] ?? _notifMeta['like']!;
    final senderName = data['senderName'] as String? ?? 'Quelqu\'un';
    final createdAt = data['createdAt'];
    final DateTime? date = createdAt is Timestamp
        ? createdAt.toDate()
        : null;

    return GestureDetector(
      onTap: () {
        // Marquer comme lu
        FirebaseFirestore.instance
            .collection(FirebaseConstants.notifications)
            .doc(docId)
            .update({'read': true});
      },
      child: Container(
        decoration: BoxDecoration(
          color: isUnread ? _neon.withOpacity(0.04) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: _line)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône type
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: meta.color.withOpacity(0.11),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(meta.icon, color: meta.color, size: 18),
            ),

            const SizedBox(width: 12),

            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: senderName,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _txt,
                          ),
                        ),
                        TextSpan(
                          text: ' ${_buildText()}',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: _txt.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${meta.emoji} ${date != null ? timeago.format(date, locale: 'fr') : 'à l\'instant'}',
                    style: const TextStyle(fontSize: 12, color: _mut),
                  ),
                ],
              ),
            ),

            // Point non-lu
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(top: 4, left: 8),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _neon,
                  boxShadow: [
                    BoxShadow(
                      color: _neon.withOpacity(0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}