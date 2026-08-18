import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

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
const _chat    = Color(0xFFFF8A65);

// ─── Tendances mock ───────────────────────────────────────────────────────────

const _trending = [
  '#RamadanCup', '#MetaJanvier', '#TerangaFC',
  '#BuildGardien', '#GPFree', '#Div1',
  '#eFootball', '#BestBuild',
];

// ═══════════════════════════════════════════════════════════════════════════════
// SEARCH SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  late TabController _tabController;

  List<UserModel> _userResults = [];
  bool _isSearching = false;
  bool _hasQuery = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() => _hasQuery = query.isNotEmpty);

    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _userResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    try {
      final repo = UserRepository();
      final users = await repo.searchUsers(query);
      if (mounted) setState(() => _userResults = users);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _userResults = [];
      _hasQuery = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),

          // ── Header ────────────────────────────────────────────────────────
          _buildHeader(),

          // ── Tabs filtre ───────────────────────────────────────────────────
          if (_hasQuery) _buildFilterTabs(),

          // ── Contenu ───────────────────────────────────────────────────────
          Expanded(
            child: _hasQuery ? _buildResults() : _buildDiscover(),
          ),
        ],
      ),
    );
  }

  // ─── Header avec barre de recherche ────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          // Barre de recherche
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _line),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search_rounded, color: _neon, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: _txt,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Joueurs, builds, clans...',
                        hintStyle: TextStyle(color: _mut, fontSize: 14.5),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_hasQuery)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.close_rounded, color: _mut, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Bouton filtre
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _line),
            ),
            child: const Icon(Icons.tune_rounded, color: _mut, size: 20),
          ),
        ],
      ),
    );
  }

  // ─── Tabs filtre (Tout / Utilisateurs / Posts / Builds / Clans) ────────────

  Widget _buildFilterTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: _neon,
        unselectedLabelColor: _mut,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: _neon,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Tout'),
          Tab(text: 'Utilisateurs'),
          Tab(text: 'Posts'),
          Tab(text: 'Builds'),
          Tab(text: 'Clans'),
        ],
      ),
    );
  }

  // ─── Résultats de recherche ─────────────────────────────────────────────────

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: _neon, strokeWidth: 2),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Section utilisateurs
        if (_userResults.isNotEmpty) ...[
          _SectionTitle(label: 'Utilisateurs'),
          ..._userResults.map((user) => _UserResultCard(user: user)),
        ] else ...[
          const SizedBox(height: 60),
          const Center(
            child: Column(
              children: [
                Icon(Icons.search_off_rounded, color: _mut, size: 40),
                SizedBox(height: 12),
                Text(
                  'Aucun résultat',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _txt,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Essaie avec un autre terme.',
                  style: TextStyle(fontSize: 13, color: _mut),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Page découverte (sans recherche active) ────────────────────────────────

  Widget _buildDiscover() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tendances
        _SectionTitle(label: 'Tendances Afrique de l\'Ouest'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trending.map((tag) => _TrendingChip(tag: tag)).toList(),
        ),

        const SizedBox(height: 28),

        // Joueurs à suivre (mock)
        _SectionTitle(label: 'Joueurs à découvrir'),
        const SizedBox(height: 12),
        ..._mockPlayers.map((p) => _MockPlayerCard(player: p)),

        const SizedBox(height: 28),

        // Clans populaires (mock)
        _SectionTitle(label: 'Clans populaires'),
        const SizedBox(height: 12),
        ..._mockClans.map((c) => _MockClanCard(clan: c)),
      ],
    );
  }
}

// ─── Données mock ─────────────────────────────────────────────────────────────

const _mockPlayers = [
  {'username': 'ibra_efc', 'bio': 'Div. 1 · Dakar 🇸🇳', 'color': 0xFF00E676},
  {'username': 'awa_builds', 'bio': 'Créatrice de builds · Abidjan 🇨🇮', 'color': 0xFFCE93D8},
  {'username': 'kouassi99', 'bio': 'Top 100 Afrique · Div. 1', 'color': 0xFFFF8A65},
];

const _mockClans = [
  {'tag': 'TFC', 'name': 'Teranga FC 🇸🇳', 'members': '124', 'color': 0xFF00E676},
  {'tag': 'LDM', 'name': 'Lions du Mandé 🇲🇱', 'members': '176', 'color': 0xFFFFCC02},
  {'tag': 'EKS', 'name': 'Ekassa Squad 🇨🇮', 'members': '98', 'color': 0xFFCE93D8},
];

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS UTILITAIRES
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _mut,
        letterSpacing: 2,
      ),
    );
  }
}

class _TrendingChip extends StatelessWidget {
  final String tag;
  const _TrendingChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _line),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _txt,
        ),
      ),
    );
  }
}

class _UserResultCard extends ConsumerWidget {
  final UserModel user;
  const _UserResultCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/profile/${user.uid}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
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
                color: _neon.withOpacity(0.12),
                border: Border.all(color: _line),
                image: user.photoURL != null
                    ? DecorationImage(
                        image: NetworkImage(user.photoURL!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: user.photoURL == null
                  ? const Center(
                      child: Icon(Icons.person_rounded, color: _neon, size: 22),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _txt,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username} · ${user.followersCount} abonnés',
                    style: const TextStyle(fontSize: 12.5, color: _mut),
                  ),
                ],
              ),
            ),

            // Bouton voir profil
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _neon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _neon.withOpacity(0.3)),
              ),
              child: const Text(
                'Voir profil',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _neon,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockPlayerCard extends StatelessWidget {
  final Map<String, dynamic> player;
  const _MockPlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final color = Color(player['color'] as int);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: _line),
            ),
            child: Center(
              child: Icon(Icons.person_rounded, color: color, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['username'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _txt,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  player['bio'] as String,
                  style: const TextStyle(fontSize: 12.5, color: _mut),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _neon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _neon.withOpacity(0.3)),
            ),
            child: const Text(
              'Suivre',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _neon,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockClanCard extends StatelessWidget {
  final Map<String, dynamic> clan;
  const _MockClanCard({required this.clan});

  @override
  Widget build(BuildContext context) {
    final color = Color(clan['color'] as int);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                clan['tag'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clan['name'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _txt,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${clan['members']} membres',
                  style: const TextStyle(fontSize: 12.5, color: _mut),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              'Rejoindre',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}