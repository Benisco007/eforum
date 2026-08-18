import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/router/app_router.dart';

// ─── Couleurs eForum ──────────────────────────────────────────────────────────

const _ink     = Color(0xFF07090F);
const _surface = Color(0xFF0E1119);
const _card    = Color(0xFF131824);
const _line    = Color(0xFF1C2236);
const _neon    = Color(0xFF00E676);
const _txt     = Color(0xFFCDD5F0);
const _mut     = Color(0xFF485070);
const _red     = Color(0xFFEF5350);
const _warn    = Color(0xFFFFAB40);
const _clan    = Color(0xFFFFCC02);

// ─── Couleur accent admin (bleu foncé — distinct du reste de l'app) ───────────
const _adminAccent = Color(0xFF448AFF);

// ═══════════════════════════════════════════════════════════════════════════════
// ADMIN DASHBOARD SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _navIndex = 0;

  final _tabs = const ['Dashboard', 'Utilisateurs', 'Signalements', 'Annonces'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          _buildHeader(context),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DashboardTab(),
                _UsersTab(),
                _ReportsTab(),
                _AnnouncementsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: const Border(bottom: BorderSide(color: _line)),
        boxShadow: [
          BoxShadow(
            color: _adminAccent.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          // Badge admin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _adminAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _adminAccent.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.shield_rounded, color: _adminAccent, size: 14),
                SizedBox(width: 6),
                Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _adminAccent,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Logo eForum
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'e',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _txt,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'Forum',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _neon,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bouton déconnexion
          GestureDetector(
            onTap: () => _confirmLogout(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _red.withOpacity(0.3)),
              ),
              child: const Icon(Icons.logout_rounded, color: _red, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tabs ──────────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: _adminAccent,
        unselectedLabelColor: _mut,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: _adminAccent,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  // ─── Confirm logout ────────────────────────────────────────────────────────

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _line),
        ),
        title: const Text(
          'Déconnexion',
          style: TextStyle(color: _txt, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Tu vas quitter le panneau administrateur.',
          style: TextStyle(color: _mut, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: _mut)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authViewModelProvider.notifier).logout();
            },
            child: const Text('Déconnexion',
                style: TextStyle(color: _red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ONGLET 1 — DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class _DashboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre section
          const _SectionTitle('Vue d\'ensemble'),
          const SizedBox(height: 12),

          // Grille stats
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                label: 'Utilisateurs',
                icon: Icons.people_alt_rounded,
                color: _neon,
                stream: FirebaseFirestore.instance
                    .collection(FirebaseConstants.users)
                    .snapshots()
                    .map((s) => s.docs.length.toString()),
              ),
              _StatCard(
                label: 'Posts',
                icon: Icons.dynamic_feed_rounded,
                color: _adminAccent,
                stream: FirebaseFirestore.instance
                    .collection(FirebaseConstants.posts)
                    .snapshots()
                    .map((s) => s.docs.length.toString()),
              ),
              _StatCard(
                label: 'Clans',
                icon: Icons.shield_rounded,
                color: _clan,
                stream: FirebaseFirestore.instance
                    .collection(FirebaseConstants.clans)
                    .snapshots()
                    .map((s) => s.docs.length.toString()),
              ),
              _StatCard(
                label: 'Signalements',
                icon: Icons.flag_rounded,
                color: _red,
                stream: FirebaseFirestore.instance
                    .collection(FirebaseConstants.reports)
                    .where('status', isEqualTo: 'pending')
                    .snapshots()
                    .map((s) => s.docs.length.toString()),
                urgent: true,
              ),
            ],
          ),

          const SizedBox(height: 24),
          const _SectionTitle('Accès rapides'),
          const SizedBox(height: 12),

          // Actions rapides
          _QuickAction(
            icon: Icons.flag_rounded,
            label: 'Traiter les signalements',
            sub: 'Voir les contenus signalés',
            color: _red,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _QuickAction(
            icon: Icons.campaign_rounded,
            label: 'Publier une annonce',
            sub: 'Visible par tous les membres',
            color: _warn,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _QuickAction(
            icon: Icons.manage_accounts_rounded,
            label: 'Gérer les utilisateurs',
            sub: 'Suspendre, désactiver un compte',
            color: _adminAccent,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _QuickAction(
            icon: Icons.shield_rounded,
            label: 'Gérer les clans',
            sub: 'Dissoudre un clan problématique',
            color: _clan,
            onTap: () {},
          ),

          const SizedBox(height: 24),
          const _SectionTitle('Activité récente'),
          const SizedBox(height: 12),
          _RecentActivity(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ONGLET 2 — UTILISATEURS
// ═══════════════════════════════════════════════════════════════════════════════

class _UsersTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all'; // all | active | suspended | disabled

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de recherche + filtres
        Container(
          color: _surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            children: [
              // Search
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _line),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search_rounded, color: _mut, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style:
                            const TextStyle(fontSize: 14, color: _txt),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher un utilisateur…',
                          hintStyle:
                              TextStyle(color: _mut, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Filtres pill
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in [
                      {'key': 'all', 'label': 'Tous'},
                      {'key': 'active', 'label': 'Actifs'},
                      {'key': 'suspended', 'label': 'Suspendus'},
                      {'key': 'disabled', 'label': 'Désactivés'},
                    ])
                      _FilterPill(
                        label: f['label']!,
                        active: _filter == f['key'],
                        onTap: () =>
                            setState(() => _filter = f['key']!),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Liste Firestore
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildQuery(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: _adminAccent, strokeWidth: 2),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              final query = _searchCtrl.text.toLowerCase();
              final filtered = query.isEmpty
                  ? docs
                  : docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return (data['username'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(query);
                    }).toList();

              if (filtered.isEmpty) {
                return _buildEmpty('Aucun utilisateur trouvé');
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final data =
                      filtered[i].data() as Map<String, dynamic>;
                  return _UserCard(
                    uid: filtered[i].id,
                    data: data,
                    onAction: () => setState(() {}),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    var q = FirebaseFirestore.instance
        .collection(FirebaseConstants.users)
        .orderBy('createdAt', descending: true)
        .limit(50);
    if (_filter != 'all') {
      q = q.where('status', isEqualTo: _filter) as Query<Map<String, dynamic>>;
    }
    return q.snapshots();
  }

  Widget _buildEmpty(String msg) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline_rounded,
                color: _mut, size: 40),
            const SizedBox(height: 12),
            Text(msg,
                style: const TextStyle(color: _mut, fontSize: 14)),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// ONGLET 3 — SIGNALEMENTS
// ═══════════════════════════════════════════════════════════════════════════════

class _ReportsTab extends StatefulWidget {
  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  String _statusFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtres
        Container(
          color: _surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in [
                  {'key': 'pending', 'label': 'En attente'},
                  {'key': 'reviewed', 'label': 'Traités'},
                  {'key': 'dismissed', 'label': 'Ignorés'},
                ])
                  _FilterPill(
                    label: f['label']!,
                    active: _statusFilter == f['key'],
                    color: _statusFilter == f['key']
                        ? (f['key'] == 'pending' ? _red : _neon)
                        : _adminAccent,
                    onTap: () =>
                        setState(() => _statusFilter = f['key']!),
                  ),
              ],
            ),
          ),
        ),

        // Liste signalements
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.reports)
                .where('status', isEqualTo: _statusFilter)
                .orderBy('createdAt', descending: true)
                .limit(30)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: _adminAccent, strokeWidth: 2),
                );
              }
              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _neon.withOpacity(0.08),
                        ),
                        child: const Icon(Icons.check_circle_outline_rounded,
                            color: _neon, size: 28),
                      ),
                      const SizedBox(height: 14),
                      const Text('Aucun signalement',
                          style: TextStyle(
                              color: _txt,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      const Text('La communauté est calme 👌',
                          style: TextStyle(color: _mut, fontSize: 13)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return _ReportCard(
                    reportId: docs[i].id,
                    data: data,
                    onRefresh: () => setState(() {}),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ONGLET 4 — ANNONCES
// ═══════════════════════════════════════════════════════════════════════════════

class _AnnouncementsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AnnouncementsTab> createState() =>
      _AnnouncementsTabState();
}

class _AnnouncementsTabState
    extends ConsumerState<_AnnouncementsTab> {
  final _contentCtrl = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone de rédaction
          const _SectionTitle('Nouvelle annonce'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _warn.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                // Badge annonce
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _warn.withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    border: Border(
                        bottom: BorderSide(
                            color: _warn.withOpacity(0.2))),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.campaign_rounded,
                          color: _warn, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'ANNONCE OFFICIELLE — Visible par tous',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _warn,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Zone texte
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: TextField(
                    controller: _contentCtrl,
                    maxLines: 6,
                    style:
                        const TextStyle(fontSize: 14, color: _txt),
                    decoration: const InputDecoration(
                      hintText:
                          'Rédige ton annonce ici… (mise à jour, événement, règle, etc.)',
                      hintStyle:
                          TextStyle(color: _mut, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Bouton publier
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _isPosting ? null : _publishAnnouncement,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  color: _isPosting
                      ? _warn.withOpacity(0.4)
                      : _warn,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _isPosting
                      ? []
                      : [
                          BoxShadow(
                            color: _warn.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Center(
                  child: _isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _ink,
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.send_rounded,
                                color: _ink, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Publier l\'annonce',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),
          const _SectionTitle('Annonces précédentes'),
          const SizedBox(height: 12),

          // Liste annonces passées
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.posts)
                .where('isAnnouncement', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                        color: _adminAccent, strokeWidth: 2),
                  ),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _line),
                  ),
                  child: const Center(
                    child: Text(
                      'Aucune annonce publiée',
                      style: TextStyle(color: _mut, fontSize: 14),
                    ),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _AnnouncementCard(
                    data: data,
                    docId: doc.id,
                    onDelete: () => setState(() {}),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _publishAnnouncement() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Écris quelque chose avant de publier.'),
          backgroundColor: _red,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);
    try {
      final currentUser = ref.read(currentUserProvider);
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.posts)
          .add({
        'authorId': currentUser?.uid ?? 'admin',
        'content': content,
        'mediaURLs': [],
        'likesCount': 0,
        'commentsCount': 0,
        'repostsCount': 0,
        'isAnnouncement': true,
        'isRepost': false,
        'originalPostId': null,
        'repostComment': null,
        'clanId': null,
        'createdAt': Timestamp.now(),
        'updatedAt': null,
      });

      _contentCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Annonce publiée avec succès !'),
            backgroundColor: _neon,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: _red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS RÉUTILISABLES
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Titre de section ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: _mut,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ─── Carte statistique ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Stream<String> stream;
  final bool urgent;

  const _StatCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.stream,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgent ? color.withOpacity(0.5) : _line,
          width: urgent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (urgent) ...[
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 6)
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<String>(
            stream: stream,
            builder: (context, snap) {
              return Text(
                snap.data ?? '—',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              );
            },
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _mut,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Accès rapide ─────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _txt,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(fontSize: 12, color: _mut),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _mut, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Activité récente ─────────────────────────────────────────────────────────

class _RecentActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.reports)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _line),
            ),
            child: const Center(
              child: Text('Aucune activité récente',
                  style: TextStyle(color: _mut, fontSize: 13)),
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: Column(
            children: docs.asMap().entries.map((e) {
              final data = e.value.data() as Map<String, dynamic>;
              final isLast = e.key == docs.length - 1;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(color: _line)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flag_rounded,
                          color: _red, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signalement — ${data['targetType'] ?? 'contenu'}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _txt,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data['reason'] ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: _mut),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(data['status'] ?? 'pending'),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ─── Carte utilisateur ────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  final VoidCallback onAction;

  const _UserCard({
    required this.uid,
    required this.data,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'active';
    final role = data['role'] ?? 'user';
    final isAdmin = role == 'admin';

    Color statusColor = switch (status) {
      'suspended' => _warn,
      'disabled'  => _red,
      _            => _neon,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _adminAccent.withOpacity(0.12),
              border: Border.all(
                color: isAdmin
                    ? _adminAccent.withOpacity(0.5)
                    : _line,
                width: isAdmin ? 2 : 1,
              ),
            ),
            child: data['photoURL'] != null
                ? ClipOval(
                    child: Image.network(
                      data['photoURL'],
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.person_rounded,
                    color: _mut, size: 22),
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '@${data['username'] ?? 'inconnu'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _txt,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _adminAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'admin',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _adminAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  data['email'] ?? '',
                  style: const TextStyle(fontSize: 12, color: _mut),
                ),
              ],
            ),
          ),

          // Status + actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(status),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showUserActions(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _line),
                  ),
                  child: const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _txt,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUserActions(BuildContext context) {
    final status = data['status'] ?? 'active';
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: _line),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '@${data['username'] ?? 'utilisateur'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _txt,
              ),
            ),
            const SizedBox(height: 16),

            if (status == 'active') ...[
              _BottomSheetAction(
                icon: Icons.pause_circle_outline_rounded,
                label: 'Suspendre le compte',
                color: _warn,
                onTap: () {
                  Navigator.pop(context);
                  _updateStatus('suspended');
                },
              ),
              const SizedBox(height: 10),
              _BottomSheetAction(
                icon: Icons.block_rounded,
                label: 'Désactiver le compte',
                color: _red,
                onTap: () {
                  Navigator.pop(context);
                  _updateStatus('disabled');
                },
              ),
            ] else ...[
              _BottomSheetAction(
                icon: Icons.check_circle_outline_rounded,
                label: 'Réactiver le compte',
                color: _neon,
                onTap: () {
                  Navigator.pop(context);
                  _updateStatus('active');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    await FirebaseFirestore.instance
        .collection(FirebaseConstants.users)
        .doc(uid)
        .update({'status': newStatus});
    onAction();
  }
}

// ─── Carte signalement ────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> data;
  final VoidCallback onRefresh;

  const _ReportCard({
    required this.reportId,
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final targetType = data['targetType'] ?? 'post';
    final isPending = (data['status'] ?? 'pending') == 'pending';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending ? _red.withOpacity(0.35) : _line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (targetType == 'post'
                          ? _adminAccent
                          : _warn)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  targetType == 'post'
                      ? Icons.article_outlined
                      : Icons.person_outline_rounded,
                  color:
                      targetType == 'post' ? _adminAccent : _warn,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    targetType == 'post'
                        ? 'Post signalé'
                        : 'Compte signalé',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _txt,
                    ),
                  ),
                  Text(
                    'ID : ${(data['targetId'] ?? '').toString().substring(0, 8)}…',
                    style:
                        const TextStyle(fontSize: 11, color: _mut),
                  ),
                ],
              ),
              const Spacer(),
              _StatusBadge(data['status'] ?? 'pending'),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: _line, height: 1),
          const SizedBox(height: 10),

          // Motif
          Row(
            children: [
              const Text(
                'Motif : ',
                style: TextStyle(fontSize: 12, color: _mut),
              ),
              Expanded(
                child: Text(
                  data['reason'] ?? 'Non précisé',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _txt,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'Ignorer',
                    color: _mut,
                    onTap: () => _resolve('dismissed'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'Traiter',
                    color: _neon,
                    onTap: () => _resolve('reviewed'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _resolve(String status) async {
    await FirebaseFirestore.instance
        .collection(FirebaseConstants.reports)
        .doc(reportId)
        .update({
      'status': status,
      'reviewedAt': Timestamp.now(),
    });
    onRefresh();
  }
}

// ─── Carte annonce existante ──────────────────────────────────────────────────

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.data,
    required this.docId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _warn.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_rounded,
                  color: _warn, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Annonce officielle',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _warn,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _delete(context),
                child: const Icon(Icons.delete_outline_rounded,
                    color: _red, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data['content'] ?? '',
            style: const TextStyle(
              fontSize: 13,
              color: _txt,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _line),
        ),
        title: const Text('Supprimer l\'annonce ?',
            style: TextStyle(
                color: _txt, fontWeight: FontWeight.w700)),
        content: const Text('Cette action est irréversible.',
            style: TextStyle(color: _mut, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Annuler', style: TextStyle(color: _mut)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(
                    color: _red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.posts)
          .doc(docId)
          .delete();
      onDelete();
    }
  }
}

// ─── Badge statut ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'suspended'  => ('Suspendu', _warn),
      'disabled'   => ('Désactivé', _red),
      'reviewed'   => ('Traité', _neon),
      'dismissed'  => ('Ignoré', _mut),
      'pending'    => ('En attente', _red),
      _             => ('Actif', _neon),
    };

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Pill filtre ──────────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;

  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
    this.color = _adminAccent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:
              active ? color.withOpacity(0.15) : _card,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? color.withOpacity(0.5) : _line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: active ? color : _mut,
          ),
        ),
      ),
    );
  }
}

// ─── Bouton action bottom sheet ───────────────────────────────────────────────

class _BottomSheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomSheetAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bouton action inline ─────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}