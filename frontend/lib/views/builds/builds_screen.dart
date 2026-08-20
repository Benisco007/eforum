import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../data/models/build_model.dart';
import '../../data/repositories/build_repository.dart';
import '../../core/constants/firebase_constants.dart';
import '../../data/models/booster_model.dart';
import '../../data/models/build_stats_model.dart';


// ─── Couleurs ─────────────────────────────────────────────────────────────────

const _ink     = Color(0xFF07090F);
const _surface = Color(0xFF0E1119);
const _card    = Color(0xFF131824);
const _line    = Color(0xFF1C2236);
const _neon    = Color(0xFF00E676);
const _txt     = Color(0xFFCDD5F0);
const _mut     = Color(0xFF485070);
const _build   = Color(0xFFCE93D8);

// ─── Données eFootball officielles ────────────────────────────────────────────

const kPositions = [
  'AC', 'SA', 'AG', 'AD', 'MO', 'MDF', 'MDC', 'MLG', 'MLD',
  'MDfG', 'MDfD', 'DC', 'DG', 'DD', 'GB'
];

const kPlayStyles = [
  'Attaquant de soutien', 'Opportuniste', 'Faux numéro 9',
  'Avant-centre classique', 'Ailier percutant', 'Meneur de jeu',
  'Boîte à buts', 'Récupérateur', 'Organisateur de jeu',
  'Défenseur agressif', 'Défenseur positionnel', 'Libéro',
  'Latéral offensif', 'Latéral défensif', 'Gardien sweeper',
];

const kBoosters = [
  'Shooting +1', 'Shooting +2', 'Shooting +3',
  'Dribbling +1', 'Dribbling +2', 'Dribbling +3',
  'Ball-carrying +1', 'Ball-carrying +2', 'Ball-carrying +3',
  'Passing +1', 'Passing +2', 'Passing +3',
  'Defending +1', 'Defending +2', 'Defending +3',
  'Speed +1', 'Physical +1',
];

const kSkills = [
  // Tir
  'Finition phénoménale', 'Frappe de loin', 'Tirs acrobatiques',
  'Frappe du cou-de-pied', 'Tirs montants', 'Tirs 1re intention',
  'Low Screamer',
  // Passe
  'Passes en une touche', 'Passe en profondeur', 'Passes lobées précises',
  'Centres précis', 'Weighted Pass',
  // Dribble
  'Effet longue distance', 'Magnetic Feet', 'Scissors Feint',
  'Double Touch', 'Flip Flap', 'Marseille Turn', 'Sombrero Turn',
  'Chop Turn', 'Cut Behind', 'Scotch Move',
  // Autre
  'Tête', 'Supériorité aérienne', 'Capitaine', 'Combativité',
  'Frappes de loin', 'Passe en profondeur', 'Aerial Fort',
  'Blitz Curler', 'Acceleration Burst', 'Attack Trigger',
];

// ─── Provider ─────────────────────────────────────────────────────────────────

final allBuildsProvider = StreamProvider<List<BuildModel>>((ref) {
  return BuildRepository().getAllBuilds();
});

final userBuildsProvider = StreamProvider.family<List<BuildModel>, String>((ref, uid) {
  return BuildRepository().getUserBuilds(uid);
});

// ═══════════════════════════════════════════════════════════════════════════════
// BUILDS SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class BuildsScreen extends ConsumerStatefulWidget {
  const BuildsScreen({super.key});

  @override
  ConsumerState<BuildsScreen> createState() => _BuildsScreenState();
}

class _BuildsScreenState extends ConsumerState<BuildsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

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
                _AllBuildsTab(),
                _MyBuildsTab(uid: currentUser?.uid ?? ''),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateBuildSheet(context),
        backgroundColor: _build,
        child: const Icon(Icons.add_rounded, color: _ink, size: 26),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          const Text(
            '⚙️ Builds',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _txt,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _build.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _build.withOpacity(0.35)),
            ),
            child: const Text(
              'eFootball 2026',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _build),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: _build,
        unselectedLabelColor: _mut,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        indicatorColor: _build,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        tabs: const [Tab(text: 'Tous les builds'), Tab(text: 'Mes builds')],
      ),
    );
  }

  void _showCreateBuildSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateBuildSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ONGLET TOUS LES BUILDS
// ═══════════════════════════════════════════════════════════════════════════════

class _AllBuildsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildsAsync = ref.watch(allBuildsProvider);
    return buildsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: _build, strokeWidth: 2)),
      error: (e, _) => Center(
          child: Text('Erreur : $e', style: const TextStyle(color: _mut))),
      data: (builds) {
        if (builds.isEmpty) return _emptyState();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: builds.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => BuildCard(build: builds[i]),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ONGLET MES BUILDS
// ═══════════════════════════════════════════════════════════════════════════════

class _MyBuildsTab extends ConsumerWidget {
  final String uid;
  const _MyBuildsTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (uid.isEmpty) return _emptyState();
    final buildsAsync = ref.watch(userBuildsProvider(uid));
    return buildsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: _build, strokeWidth: 2)),
      error: (e, _) => Center(
          child: Text('Erreur : $e', style: const TextStyle(color: _mut))),
      data: (builds) {
        if (builds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⚙️', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text('Tu n\'as pas encore de builds',
                    style: TextStyle(color: _txt, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Appuie sur + pour en créer un',
                    style: TextStyle(color: _mut, fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: builds.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => BuildCard(build: builds[i], showDelete: true),
        );
      },
    );
  }
}

Widget _emptyState() => const Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('⚙️', style: TextStyle(fontSize: 40)),
      SizedBox(height: 12),
      Text('Aucun build pour l\'instant',
          style: TextStyle(color: _txt, fontSize: 15, fontWeight: FontWeight.w700)),
      SizedBox(height: 6),
      Text('Sois le premier à partager un build !',
          style: TextStyle(color: _mut, fontSize: 13)),
    ],
  ),
);

// ═══════════════════════════════════════════════════════════════════════════════
// BUILD CARD
// ═══════════════════════════════════════════════════════════════════════════════

class BuildCard extends ConsumerStatefulWidget {
  final BuildModel build;
  final bool showDelete;
  const BuildCard({super.key, required this.build, this.showDelete = false});

  @override
  ConsumerState<BuildCard> createState() => _BuildCardState();
}

class _BuildCardState extends ConsumerState<BuildCard> {
  bool _liked = false;
  late int _likes;

  @override
  void initState() {
    super.initState();
    _likes = widget.build.likesCount;
    _checkLiked();
  }

  Future<void> _checkLiked() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final liked = await BuildRepository().isLiked(widget.build.buildId, user.uid);
    if (mounted) setState(() => _liked = liked);
  }

  Future<void> _toggleLike() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await BuildRepository().toggleLike(widget.build.buildId, user.uid);
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final build = widget.build;
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                // Overall badge
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: _build.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _build.withOpacity(0.4), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${build.overall}',
                        style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900, color: _build),
                      ),
                      const Text('OVR',
                          style: TextStyle(fontSize: 9, color: _mut, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        build.playerName,
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: _txt),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _PillBadge(label: build.position, color: _neon),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              build.playStyle,
                              style: const TextStyle(fontSize: 12, color: _mut),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.showDelete)
                  GestureDetector(
                    onTap: () => _confirmDelete(context),
                    child: const Icon(Icons.delete_outline_rounded, color: _mut, size: 20),
                  ),
              ],
            ),
          ),

          // ── Boosters ────────────────────────────────────────────────────────
          if (build.boosters.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: build.boosters.map((b) =>
                    _PillBadge(label: '⚡ ${b.name}', color: const Color(0xFFFFAB40))
                ).toList(),
              ),
            ),
          ],

          // ── Skills ──────────────────────────────────────────────────────────
          if (build.skills.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: build.skills.take(5).map((s) =>
                    _PillBadge(label: s, color: _mut)
                ).toList(),
              ),
            ),
          ],

          const Divider(color: _line, height: 1),

          // ── Footer ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                // Auteur
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection(FirebaseConstants.users)
                      .doc(build.authorId).get(),
                  builder: (_, snap) {
                    final data = snap.data?.data() as Map<String, dynamic>?;
                    final username = data?['username'] ?? '...';
                    final photoURL = data?['photoURL'] as String?;
                    return GestureDetector(
                      onTap: () => context.push('/profile/${build.authorId}'),
                      child: Row(
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _neon.withOpacity(0.12),
                              border: Border.all(color: _line),
                              image: photoURL != null
                                  ? DecorationImage(
                                      image: NetworkImage(photoURL), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: photoURL == null
                                ? const Icon(Icons.person_rounded, color: _neon, size: 13)
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Text('@$username',
                              style: const TextStyle(fontSize: 12, color: _mut)),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(),
                // Temps
                Text(
                  timeago.format(build.createdAt.toDate(), locale: 'fr'),
                  style: const TextStyle(fontSize: 11, color: _mut),
                ),
                const SizedBox(width: 14),
                // Like
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _liked ? const Color(0xFFFF5A7A) : _mut,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text('$_likes', style: const TextStyle(fontSize: 12, color: _mut)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _line),
        ),
        title: const Text('Supprimer ce build ?',
            style: TextStyle(color: _txt, fontWeight: FontWeight.w700)),
        content: const Text('Cette action est irréversible.',
            style: TextStyle(color: _mut, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: _mut)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await BuildRepository().deleteBuild(widget.build.buildId);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE BUILD SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class CreateBuildSheet extends ConsumerStatefulWidget {
  const CreateBuildSheet({super.key});

  @override
  ConsumerState<CreateBuildSheet> createState() => _CreateBuildSheetState();
}

class _CreateBuildSheetState extends ConsumerState<CreateBuildSheet> {
  final _playerNameCtrl = TextEditingController();
  final _overallCtrl    = TextEditingController();
  String _position   = kPositions.first;
  String _playStyle  = kPlayStyles.first;
  String? _booster1;
  String? _booster2;
  final Set<String> _selectedSkills = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _playerNameCtrl.dispose();
    _overallCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _playerNameCtrl.text.trim();
    final overallStr = _overallCtrl.text.trim();
    if (name.isEmpty || overallStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplis le nom et l\'overall.'),
            backgroundColor: Color(0xFFEF5350)));
      return;
    }
    final overall = int.tryParse(overallStr);
    if (overall == null || overall < 1 || overall > 130) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Overall invalide (1-130).'),
            backgroundColor: Color(0xFFEF5350)));
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);

    final boosters = [
      if (_booster1 != null) Booster(name: _booster1!, value: 0),
      if (_booster2 != null) Booster(name: _booster2!, value: 0),
    ];

    final build = BuildModel(
      buildId:    const Uuid().v4(),
      authorId:   user.uid,
      playerName: name,
      overall:    overall,
      position:   _position,
      playStyle:  _playStyle,
      stats: BuildStats(),
      boosters:   boosters,
      skills:     _selectedSkills.toList(),
      createdAt:  Timestamp.now(),
    );

    try {
      await BuildRepository().createBuild(build);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'),
            backgroundColor: const Color(0xFFEF5350)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: _line)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _line, borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text('Nouveau build',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _txt)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _isSaving ? null : _save,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: _isSaving ? _build.withOpacity(0.4) : _build,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _isSaving ? [] : [
                          BoxShadow(color: _build.withOpacity(0.35),
                              blurRadius: 12, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _ink))
                          : const Text('Publier',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Divider(color: _line),
            // Form
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  // ── Nom du joueur ──────────────────────────────────────────
                  _label('NOM DU JOUEUR'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _playerNameCtrl,
                    hint: 'Ex: Kylian Mbappé',
                    icon: Icons.sports_soccer_rounded,
                  ),
                  const SizedBox(height: 18),

                  // ── Overall ────────────────────────────────────────────────
                  _label('OVERALL'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _overallCtrl,
                    hint: 'Ex: 107',
                    icon: Icons.star_rounded,
                    keyboard: TextInputType.number,
                  ),
                  const SizedBox(height: 18),

                  // ── Poste + Style ──────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('POSTE'),
                            const SizedBox(height: 8),
                            _dropdown(
                              value: _position,
                              items: kPositions,
                              onChanged: (v) => setState(() => _position = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('STYLE'),
                            const SizedBox(height: 8),
                            _dropdown(
                              value: _playStyle,
                              items: kPlayStyles,
                              onChanged: (v) => setState(() => _playStyle = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Boosters ───────────────────────────────────────────────
                  _label('BOOSTERS (2 max)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _dropdown(
                          value: _booster1,
                          hint: 'Booster 1',
                          items: kBoosters,
                          onChanged: (v) => setState(() => _booster1 = v),
                          nullable: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dropdown(
                          value: _booster2,
                          hint: 'Booster 2',
                          items: kBoosters,
                          onChanged: (v) => setState(() => _booster2 = v),
                          nullable: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Compétences ────────────────────────────────────────────
                  Row(
                    children: [
                      _label('COMPÉTENCES'),
                      const SizedBox(width: 8),
                      Text('(${_selectedSkills.length} sélectionnées)',
                          style: const TextStyle(fontSize: 11, color: _mut)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: kSkills.map((skill) {
                      final selected = _selectedSkills.contains(skill);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) {
                            _selectedSkills.remove(skill);
                          } else {
                            _selectedSkills.add(skill);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? _build.withOpacity(0.15)
                                : _card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? _build.withOpacity(0.6)
                                  : _line,
                            ),
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? _build : _txt,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
          color: _mut, letterSpacing: 1.2));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 14, color: _txt),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _mut, fontSize: 14),
            prefixIcon: Icon(icon, color: _mut, size: 18),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      );

  Widget _dropdown({
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? hint,
    bool nullable = false,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: Text(hint ?? '', style: const TextStyle(color: _mut, fontSize: 13)),
            dropdownColor: _card,
            style: const TextStyle(color: _txt, fontSize: 13),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _mut, size: 18),
            isExpanded: true,
            items: [
              if (nullable)
                const DropdownMenuItem(value: null, child: Text('Aucun')),
              ...items.map((i) => DropdownMenuItem(value: i, child: Text(i))),
            ],
            onChanged: onChanged,
          ),
        ),
      );
}

// ─── Widgets utilitaires ──────────────────────────────────────────────────────

class _PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PillBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}