import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../data/models/clan_model.dart';
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

// ─── Couleurs par index (pour les clans sans couleur définie) ─────────────────

const _clanColors = [
  Color(0xFF00E676),
  Color(0xFFFFCC02),
  Color(0xFFCE93D8),
  Color(0xFFFF8A65),
  Color(0xFF4FC3F7),
  Color(0xFFEF5350),
  Color(0xFF66BB6A),
];

Color _colorForClan(String clanId) {
  final index = clanId.codeUnits.fold(0, (a, b) => a + b) % _clanColors.length;
  return _clanColors[index];
}

Future<void> _leaveCurrentClan(String oldClanId, String uid) async {
  final batch = FirebaseFirestore.instance.batch();
  final oldClanRef = FirebaseFirestore.instance.collection(FirebaseConstants.clans).doc(oldClanId);

  final membersSnap = await oldClanRef.collection(FirebaseConstants.members).get();
  final realCount = membersSnap.docs.length;

  batch.delete(oldClanRef.collection(FirebaseConstants.members).doc(uid));
  batch.update(oldClanRef, {'membersCount': realCount > 1 ? realCount - 1 : 0});
  await batch.commit();
}

// ─── Providers ───────────────────────────────────────────────────────────────

final clansProvider = StreamProvider<List<ClanModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirebaseConstants.clans)
      .where('status', isEqualTo: 'active')
      .orderBy('membersCount', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => ClanModel.fromFirestore(doc)).toList());
});

final myClanProvider = StreamProvider<ClanModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser?.clanId == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection(FirebaseConstants.clans)
      .doc(currentUser!.clanId!)
      .snapshots()
      .map((doc) => doc.exists ? ClanModel.fromFirestore(doc) : null);
});

// ═══════════════════════════════════════════════════════════════════════════════
// CLANS LIST SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class ClansScreen extends ConsumerStatefulWidget {
  const ClansScreen({super.key});

  @override
  ConsumerState<ClansScreen> createState() => _ClansScreenState();
}

class _ClansScreenState extends ConsumerState<ClansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(
        () => setState(() => _query = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiscoverTab(),
                _buildMyClanTab(),
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
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: _clan, size: 20),
                const SizedBox(width: 8),
                const Text('Clans',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _txt)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showCreateClanDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _clan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('+ Créer un clan',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _clan)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
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
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14, color: _txt),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un clan…',
                        hintStyle: TextStyle(color: _mut, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: _clan,
            unselectedLabelColor: _mut,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            indicatorColor: _clan,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: const [Tab(text: 'Découvrir'), Tab(text: 'Mon clan')],
          ),
        ],
      ),
    );
  }

  // ─── Onglet Découvrir ──────────────────────────────────────────────────────

  Widget _buildDiscoverTab() {
    final clansAsync = ref.watch(clansProvider);
    final currentUser = ref.watch(currentUserProvider);

    return clansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _neon, strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Erreur : $e', style: const TextStyle(color: _mut))),
      data: (clans) {
        final filtered = clans.where((c) =>
            c.name.toLowerCase().contains(_query) ||
            c.clanId.toLowerCase().contains(_query)).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _clan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🔥 Tendance',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _clan)),
                ),
                const SizedBox(width: 8),
                const Text('Afrique de l\'Ouest · cette semaine',
                    style: TextStyle(fontSize: 11.5, color: _mut)),
              ],
            ),
            const SizedBox(height: 12),

            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: Text('Aucun clan trouvé.', style: TextStyle(color: _mut, fontSize: 13))),
              )
            else
              ...filtered.map((clan) => _ClanCard(
                clan: clan,
                isMember: currentUser?.clanId == clan.clanId,
                color: _colorForClan(clan.clanId),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ClanDetailScreen(clanId: clan.clanId)),
                ),
              )),
          ],
        );
      },
    );
  }

  // ─── Onglet Mon clan ───────────────────────────────────────────────────────

  Widget _buildMyClanTab() {
    final myClanAsync = ref.watch(myClanProvider);
    final currentUser = ref.watch(currentUserProvider);

    return myClanAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _neon, strokeWidth: 2)),
      error: (e, _) => Center(child: Text('Erreur : $e', style: const TextStyle(color: _mut))),
      data: (myClan) {
        if (myClan == null || currentUser?.clanId == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _clan.withOpacity(0.08)),
                    child: const Icon(Icons.shield_outlined, color: _clan, size: 30),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tu n\'es dans aucun clan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _txt)),
                  const SizedBox(height: 8),
                  const Text('Rejoins ou crée un clan pour jouer en équipe.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: _mut, height: 1.5)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _tabController.animateTo(0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _clan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _clan.withOpacity(0.3)),
                      ),
                      child: const Text('Découvrir des clans',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _clan)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final color = _colorForClan(myClan.clanId);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ClanDetailScreen(clanId: myClan.clanId)),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _neon.withOpacity(0.25)),
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  children: [
                    Container(
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.3), _ink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -24),
                            child: Container(
                              width: 58, height: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: color.withOpacity(0.5), width: 2),
                                color: _ink,
                              ),
                              child: Center(
                                child: Text(
                                  myClan.name.substring(0, myClan.name.length > 3 ? 3 : myClan.name.length).toUpperCase(),
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(myClan.name,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _txt)),
                                const SizedBox(height: 2),
                                Text('${myClan.membersCount} membres · Tu es membre',
                                    style: const TextStyle(fontSize: 12, color: _mut)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _neon.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _neon.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.shield_outlined, color: _neon, size: 12),
                                SizedBox(width: 4),
                                Text('Actif', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _neon)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _clan.withOpacity(0.08)),
                    child: const Icon(Icons.shield_outlined, color: _clan, size: 24),
                  ),
                  const SizedBox(height: 12),
                  const Text('Un seul clan à la fois',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _txt)),
                  const SizedBox(height: 6),
                  const Text('Tu appartiens déjà à un clan.\nQuitte-le pour en rejoindre un autre.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: _mut, height: 1.5)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _tabController.animateTo(0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _clan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _clan.withOpacity(0.3)),
                      ),
                      child: const Text('Découvrir des clans',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _clan)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Dialog créer un clan ──────────────────────────────────────────────────

  void _showCreateClanDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isCreating = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Créer un clan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _txt)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
                  child: TextField(
                    controller: nameController,
                    style: const TextStyle(color: _txt, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Nom du clan',
                      hintStyle: TextStyle(color: _mut),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
                  child: TextField(
                    controller: descController,
                    style: const TextStyle(color: _txt, fontSize: 14),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Description du clan',
                      hintStyle: TextStyle(color: _mut),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isCreating ? null : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      final currentUser = ref.read(currentUserProvider);
                      if (currentUser == null) return;

                      // Vérifier si l'utilisateur est dans un clan qui existe vraiment
                      if (currentUser.clanId != null) {
                        final oldClanDoc = await FirebaseFirestore.instance
                            .collection(FirebaseConstants.clans)
                            .doc(currentUser.clanId)
                            .get();

                        if (!oldClanDoc.exists) {
                          // Le clan a été supprimé manuellement : nettoyer le clanId du user
                          await FirebaseFirestore.instance
                              .collection(FirebaseConstants.users)
                              .doc(currentUser.uid)
                              .update({'clanId': null});
                          await ref.read(authViewModelProvider.notifier).refreshUser();
                        } else {
                          // Le clan existe bien → demander confirmation
                          final confirm = await showDialog<bool>(
                            context: ctx,
                            builder: (_) => AlertDialog(
                              backgroundColor: _card,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: _line),
                              ),
                              title: const Text('Créer un nouveau clan ?',
                                  style: TextStyle(color: _txt, fontWeight: FontWeight.w700)),
                              content: const Text(
                                'Créer un clan te fera automatiquement quitter ton clan actuel.',
                                style: TextStyle(color: _mut, fontSize: 14, height: 1.5),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Annuler', style: TextStyle(color: _mut)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Créer quand même',
                                      style: TextStyle(color: _clan, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                          // Quitter l'ancien clan
                          await _leaveCurrentClan(currentUser.clanId!, currentUser.uid);
                        }
                      }

                      setModalState(() => isCreating = true);

                      try {
                        final docRef = FirebaseFirestore.instance.collection(FirebaseConstants.clans).doc();
                        final batch = FirebaseFirestore.instance.batch();

                        batch.set(docRef, {
                          'clanId': docRef.id,
                          'name': name,
                          'description': descController.text.trim(),
                          'logoURL': null,
                          'bannerURL': null,
                          'ownerId': currentUser.uid,
                          'membersCount': 1,
                          'isPrivate': false,
                          'status': 'active',
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        batch.set(
                          docRef.collection(FirebaseConstants.members).doc(currentUser.uid),
                          {'uid': currentUser.uid, 'role': 'owner', 'joinedAt': FieldValue.serverTimestamp()},
                        );

                        batch.update(
                          FirebaseFirestore.instance.collection(FirebaseConstants.users).doc(currentUser.uid),
                          {'clanId': docRef.id},
                        );

                        await batch.commit();
                        await ref.read(authViewModelProvider.notifier).refreshUser();

                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setModalState(() => isCreating = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _clan,
                      foregroundColor: _ink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isCreating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _ink))
                        : const Text('Créer le clan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CLAN CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ClanCard extends StatelessWidget {
  final ClanModel clan;
  final bool isMember;
  final Color color;
  final VoidCallback onTap;

  const _ClanCard({
    required this.clan,
    required this.isMember,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tag = clan.name.substring(0, clan.name.length > 3 ? 3 : clan.name.length).toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isMember ? color.withOpacity(0.4) : _line),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: color.withOpacity(0.1),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(tag, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(clan.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _txt),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.people_outline_rounded, color: _mut, size: 13),
                            const SizedBox(width: 4),
                            Text('${clan.membersCount} membres',
                                style: const TextStyle(fontSize: 12, color: _mut)),
                          ],
                        ),
                        if (clan.description != null && clan.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(clan.description!,
                              style: TextStyle(fontSize: 12.5, color: _txt.withOpacity(0.75), height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: _line))),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: _mut, size: 13),
                  const SizedBox(width: 4),
                  Text(clan.isPrivate ? 'Privé' : 'Ouvert',
                      style: const TextStyle(fontSize: 12, color: _mut)),
                  const Spacer(),
                  isMember
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _neon.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _neon.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_rounded, color: _neon, size: 12),
                              SizedBox(width: 4),
                              Text('Membre', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _neon)),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                          child: const Text('Rejoindre',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _ink)),
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

// ═══════════════════════════════════════════════════════════════════════════════
// CLAN DETAIL SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class ClanDetailScreen extends ConsumerStatefulWidget {
  final String clanId;
  const ClanDetailScreen({super.key, required this.clanId});

  @override
  ConsumerState<ClanDetailScreen> createState() => _ClanDetailScreenState();
}

class _ClanDetailScreenState extends ConsumerState<ClanDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ClanModel? _clan;
  bool _isLoading = true;
  bool _isMember = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClan() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirebaseConstants.clans)
          .doc(widget.clanId)
          .get();
      if (doc.exists && mounted) {
        final currentUser = ref.read(currentUserProvider);
        setState(() {
          _clan = ClanModel.fromFirestore(doc);
          _isMember = currentUser?.clanId == widget.clanId;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinClan() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || _isJoining) return;

    // Si déjà dans un clan, vérifier qu'il existe avant d'avertir
    if (currentUser.clanId != null && currentUser.clanId != widget.clanId) {
      final oldClanDoc = await FirebaseFirestore.instance
          .collection(FirebaseConstants.clans)
          .doc(currentUser.clanId)
          .get();

      if (!oldClanDoc.exists) {
        // Clan supprimé manuellement → nettoyer sans avertissement
        await FirebaseFirestore.instance
            .collection(FirebaseConstants.users)
            .doc(currentUser.uid)
            .update({'clanId': null});
        await ref.read(authViewModelProvider.notifier).refreshUser();
      } else {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _line),
            ),
            title: const Text('Changer de clan ?',
                style: TextStyle(color: _txt, fontWeight: FontWeight.w700)),
            content: const Text(
              'Rejoindre ce clan te fera automatiquement quitter ton clan actuel. Cette action est irréversible.',
              style: TextStyle(color: _mut, fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler', style: TextStyle(color: _mut)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Changer de clan',
                    style: TextStyle(color: Color(0xFFFFCC02), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
        if (confirm != true) return;

        // Quitter l'ancien clan d'abord
        await _leaveCurrentClan(currentUser.clanId!, currentUser.uid);
      }
    }

    setState(() => _isJoining = true);

    try {
      final clanRef = FirebaseFirestore.instance.collection(FirebaseConstants.clans).doc(widget.clanId);

      // Compter les vrais membres actuels
      final membersSnap = await clanRef.collection(FirebaseConstants.members).get();
      final realCount = membersSnap.docs.length;

      final batch = FirebaseFirestore.instance.batch();
      batch.set(
        clanRef.collection(FirebaseConstants.members).doc(currentUser.uid),
        {'uid': currentUser.uid, 'role': 'member', 'joinedAt': FieldValue.serverTimestamp()},
      );
      batch.update(clanRef, {'membersCount': realCount + 1});
      batch.update(
        FirebaseFirestore.instance.collection(FirebaseConstants.users).doc(currentUser.uid),
        {'clanId': widget.clanId},
      );

      await batch.commit();
      await ref.read(authViewModelProvider.notifier).refreshUser();

      if (mounted) setState(() { _isMember = true; _isJoining = false; });
    } catch (_) {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _leaveClan() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final clanRef = FirebaseFirestore.instance.collection(FirebaseConstants.clans).doc(widget.clanId);

    // Compter les vrais membres avant suppression
    final membersSnap = await clanRef.collection(FirebaseConstants.members).get();
    final realCount = membersSnap.docs.length;

    final batch = FirebaseFirestore.instance.batch();
    batch.delete(clanRef.collection(FirebaseConstants.members).doc(currentUser.uid));
    batch.update(clanRef, {'membersCount': realCount > 1 ? realCount - 1 : 0});
    batch.update(
      FirebaseFirestore.instance.collection(FirebaseConstants.users).doc(currentUser.uid),
      {'clanId': null},
    );

    await batch.commit();
    await ref.read(authViewModelProvider.notifier).refreshUser();

    if (mounted) setState(() => _isMember = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _ink,
        body: Center(child: CircularProgressIndicator(color: _neon, strokeWidth: 2)),
      );
    }

    if (_clan == null) {
      return Scaffold(
        backgroundColor: _ink,
        appBar: AppBar(
          backgroundColor: _ink,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: _txt),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Clan introuvable', style: TextStyle(color: _mut))),
      );
    }

    final clanModel = _clan!;
    final color = _colorForClan(clanModel.clanId);
    final tag = clanModel.name.substring(0, clanModel.name.length > 3 ? 3 : clanModel.name.length).toUpperCase();

    return Scaffold(
      backgroundColor: _ink,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _buildHeader(context, clanModel, color, tag)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFFFCC02),
                unselectedLabelColor: _mut,
                labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                indicatorColor: const Color(0xFFFFCC02),
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                tabs: const [Tab(text: 'Posts du clan'), Tab(text: 'Membres')],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(clanModel),
            _buildMembersTab(clanModel),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ClanModel clan, Color color, String tag) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 136,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.35), _ink],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 70,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [_ink, Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: _CircleBtn(icon: Icons.chevron_left_rounded, onTap: () => context.pop()),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      width: 76, height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.5), width: 2),
                        color: _ink,
                        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 24, spreadRadius: -4)],
                      ),
                      child: Center(
                        child: Text(tag, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: _isJoining ? null : (_isMember ? _showLeaveConfirm : _joinClan),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _isMember ? Colors.transparent : color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _isMember ? _line : color),
                        ),
                        child: _isJoining
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _neon))
                            : Text(
                                _isMember ? 'Quitter' : 'Rejoindre',
                                style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: _isMember ? _txt : _ink,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              Transform.translate(
                offset: const Offset(0, -14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(clan.name,
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: _txt, letterSpacing: -0.3)),
                    const SizedBox(height: 8),
                    if (clan.description != null && clan.description!.isNotEmpty)
                      Text(clan.description!,
                          style: TextStyle(fontSize: 13.5, color: _txt.withOpacity(0.85), height: 1.5)),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
                      child: Row(
                        children: [
                          _StatCell(value: '${clan.membersCount}', label: 'Membres'),
                          Container(width: 1, height: 40, color: _line),
                          _StatCell(value: clan.isPrivate ? 'Privé' : 'Ouvert', label: 'Type'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLeaveConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _line)),
        title: const Text('Quitter le clan ?', style: TextStyle(color: _txt, fontWeight: FontWeight.w700)),
        content: const Text('Tu pourras le rejoindre à nouveau plus tard.', style: TextStyle(color: _mut, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: _mut))),
          TextButton(
            onPressed: () { Navigator.pop(context); _leaveClan(); },
            child: const Text('Quitter', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab(ClanModel clan) {
    final currentUser = ref.read(currentUserProvider);

    return Column(
      children: [
        // Zone de création de post
        Container(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _line))),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _neon.withOpacity(0.12),
                  image: currentUser?.photoURL != null
                      ? DecorationImage(
                          image: NetworkImage(currentUser!.photoURL!),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: currentUser?.photoURL == null
                    ? const Icon(Icons.person_rounded,
                        color: _neon, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showClanPostDialog(clan.clanId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _line),
                    ),
                    child: const Text('Écris quelque chose au clan…',
                        style: TextStyle(fontSize: 13, color: _mut)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Liste des posts du clan (stream Firestore)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('clans')
                .doc(clan.clanId)
                .collection('posts')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.dynamic_feed_rounded,
                          color: _mut, size: 36),
                      SizedBox(height: 12),
                      Text('Aucun post dans ce clan pour l\'instant.',
                          style: TextStyle(color: _mut, fontSize: 13)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return _ClanPostTile(data: data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showClanPostDialog(String clanId) {
    final controller = TextEditingController();
    bool isPosting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Post dans le clan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                        color: _txt)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _line),
                  ),
                  child: TextField(
                    controller: controller,
                    maxLines: 4,
                    autofocus: true,
                    style: const TextStyle(color: _txt, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Partage quelque chose avec ton clan…',
                      hintStyle: TextStyle(color: _mut),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: isPosting ? null : () async {
                      final content = controller.text.trim();
                      if (content.isEmpty) return;
                      setModalState(() => isPosting = true);

                      final currentUser = ref.read(currentUserProvider);
                      if (currentUser == null) return;

                      try {
                        await FirebaseFirestore.instance
                            .collection('clans')
                            .doc(clanId)
                            .collection('posts')
                            .add({
                          'authorId': currentUser.uid,
                          'content': content,
                          'createdAt': FieldValue.serverTimestamp(),
                          'likesCount': 0,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (_) {
                        setModalState(() => isPosting = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC02),
                      foregroundColor: _ink,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isPosting
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2,
                                color: _ink))
                        : const Text('Publier dans le clan',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMembersTab(ClanModel clan) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.clans)
          .doc(clan.clanId)
          .collection(FirebaseConstants.members)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _neon, strokeWidth: 2));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('Aucun membre.', style: TextStyle(color: _mut)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final uid = data['uid'] as String? ?? '';
            final role = data['role'] as String? ?? 'member';
            final Color roleColor = role == 'owner'
                ? const Color(0xFFFFCC02)
                : role == 'admin'
                    ? _neon
                    : _mut;
            final roleLabel = role == 'owner'
                ? 'Capitaine'
                : role == 'admin'
                    ? 'Officier'
                    : 'Membre';

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection(FirebaseConstants.users).doc(uid).get(),
              builder: (context, snap) {
                final userData = snap.data?.data() as Map<String, dynamic>?;
                final username = userData?['username'] as String? ?? '...';
                final photoURL = userData?['photoURL'] as String?;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profile/$uid'),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _neon.withOpacity(0.12),
                            image: photoURL != null
                                ? DecorationImage(image: NetworkImage(photoURL), fit: BoxFit.cover)
                                : null,
                          ),
                          child: photoURL == null
                              ? const Center(child: Icon(Icons.person_rounded, color: _neon, size: 20))
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(username, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _txt)),
                            Text('@$username', style: const TextStyle(fontSize: 12, color: _mut)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: roleColor.withOpacity(0.3)),
                        ),
                        child: Text(roleLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: roleColor)),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ClanPostTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ClanPostTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final authorId = data['authorId'] as String? ?? '';
    final content  = data['content']  as String? ?? '';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(FirebaseConstants.users).doc(authorId).get(),
      builder: (context, snap) {
        final userData = snap.data?.data() as Map<String, dynamic>?;
        final username = userData?['username'] as String? ?? '...';
        final photoURL = userData?['photoURL'] as String?;

        return Container(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _line))),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _neon.withOpacity(0.12),
                  image: photoURL != null
                      ? DecorationImage(
                          image: NetworkImage(photoURL), fit: BoxFit.cover)
                      : null,
                ),
                child: photoURL == null
                    ? const Icon(Icons.person_rounded,
                        color: _neon, size: 18)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username,
                        style: const TextStyle(fontSize: 13.5,
                            fontWeight: FontWeight.w700, color: _txt)),
                    const SizedBox(height: 4),
                    Text(content,
                        style: const TextStyle(fontSize: 14,
                            color: _txt, height: 1.45)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS UTILITAIRES
// ═══════════════════════════════════════════════════════════════════════════════

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.55)),
        child: Icon(icon, color: _txt, size: 22),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value, label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _txt)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11.5, color: _mut)),
          ],
        ),
      ),
    );
  }
}

class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabDelegate(this.tabBar);

  @override double get minExtent => tabBar.preferredSize.height + 1;
  @override double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      decoration: const BoxDecoration(color: _ink, border: Border(bottom: BorderSide(color: _line))),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabDelegate old) => false;
}