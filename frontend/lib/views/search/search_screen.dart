import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';
import '../../data/models/clan_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/constants/firebase_constants.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../clans/clan_screen.dart' show ClanDetailScreen;

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

const _palette = [
  Color(0xFF00E676), Color(0xFFFFCC02), Color(0xFFCE93D8),
  Color(0xFFFF8A65), Color(0xFF4FC3F7), Color(0xFFEF5350), Color(0xFF66BB6A),
];

Color _colorFor(String id) {
  final index = id.codeUnits.fold(0, (a, b) => a + b) % _palette.length;
  return _palette[index];
}

final topUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(FirebaseConstants.users)
      .orderBy("followersCount", descending: true)
      .limit(10)
      .get();
  return snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
});

final topClansProvider = FutureProvider<List<ClanModel>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(FirebaseConstants.clans)
      .where("status", isEqualTo: "active")
      .orderBy("membersCount", descending: true)
      .limit(8)
      .get();
  return snap.docs.map((doc) => ClanModel.fromFirestore(doc)).toList();
});

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
  List<ClanModel> _clanResults = [];
  bool _isSearching = false;
  bool _hasQuery = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      setState(() { _userResults = []; _clanResults = []; _isSearching = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    try {
      final users = await UserRepository().searchUsers(query);
      final clanSnap = await FirebaseFirestore.instance
          .collection(FirebaseConstants.clans)
          .where("status", isEqualTo: "active")
          .where("name", isGreaterThanOrEqualTo: query)
          .where("name", isLessThanOrEqualTo: "${query}\uf8ff")
          .limit(10)
          .get();
      final clans = clanSnap.docs.map((d) => ClanModel.fromFirestore(d)).toList();
      if (mounted) setState(() { _userResults = users; _clanResults = clans; });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() { _userResults = []; _clanResults = []; _hasQuery = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          _buildHeader(),
          if (_hasQuery) _buildFilterTabs(),
          Expanded(child: _hasQuery ? _buildResults() : _buildDiscover()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(color: _ink, border: Border(bottom: BorderSide(color: _line))),
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _line)),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search_rounded, color: _neon, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: const TextStyle(fontSize: 14.5, color: _txt),
                decoration: const InputDecoration(
                  hintText: "Joueurs, clans...",
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
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _line))),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: _neon,
        unselectedLabelColor: _mut,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        indicatorColor: _neon,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        tabs: const [Tab(text: "Tout"), Tab(text: "Utilisateurs"), Tab(text: "Clans")],
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) return const Center(child: CircularProgressIndicator(color: _neon, strokeWidth: 2));
    final hasUsers = _userResults.isNotEmpty;
    final hasClans = _clanResults.isNotEmpty;
    if (!hasUsers && !hasClans) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: _mut, size: 40),
            SizedBox(height: 12),
            Text("Aucun resultat", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _txt)),
            SizedBox(height: 6),
            Text("Essaie avec un autre terme.", style: TextStyle(fontSize: 13, color: _mut)),
          ],
        ),
      );
    }
    return TabBarView(
      controller: _tabController,
      children: [
        ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
          if (hasUsers) ...[const _SectionTitle(label: "Utilisateurs"), ..._userResults.take(3).map((u) => _UserResultCard(user: u))],
          if (hasClans) ...[const SizedBox(height: 8), const _SectionTitle(label: "Clans"), ..._clanResults.take(3).map((c) => _ClanResultCard(clan: c))],
        ]),
        ListView(padding: const EdgeInsets.symmetric(vertical: 8),
          children: hasUsers ? _userResults.map((u) => _UserResultCard(user: u)).toList() : [const _EmptyTab(label: "Aucun utilisateur trouve")]),
        ListView(padding: const EdgeInsets.symmetric(vertical: 8),
          children: hasClans ? _clanResults.map((c) => _ClanResultCard(clan: c)).toList() : [const _EmptyTab(label: "Aucun clan trouve")]),
      ],
    );
  }

  Widget _buildDiscover() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(label: "Joueurs a decouvrir"),
        const SizedBox(height: 12),
        Consumer(builder: (context, ref, _) {
          return ref.watch(topUsersProvider).when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: _neon, strokeWidth: 2))),
            error: (e, _) => Text("Erreur : $e", style: const TextStyle(color: _mut)),
            data: (users) => users.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text("Aucun joueur pour l'instant.", style: TextStyle(color: _mut, fontSize: 13)))
                : Column(children: users.map((u) => _UserDiscoverCard(user: u)).toList()),
          );
        }),
        const SizedBox(height: 28),
        const _SectionTitle(label: "Clans populaires"),
        const SizedBox(height: 12),
        Consumer(builder: (context, ref, _) {
          return ref.watch(topClansProvider).when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: _neon, strokeWidth: 2))),
            error: (e, _) => Text("Erreur : $e", style: const TextStyle(color: _mut)),
            data: (clans) => clans.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text("Aucun clan pour l'instant.", style: TextStyle(color: _mut, fontSize: 13)))
                : Column(children: clans.map((c) => _ClanDiscoverCard(clan: c)).toList()),
          );
        }),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
    child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _mut, letterSpacing: 2)),
  );
}

class _EmptyTab extends StatelessWidget {
  final String label;
  const _EmptyTab({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Center(child: Text(label, style: const TextStyle(color: _mut, fontSize: 13))),
  );
}

class _Avatar extends StatelessWidget {
  final String? photoURL;
  final String name;
  final double size;
  const _Avatar({required this.photoURL, required this.name, required this.size});
  @override
  Widget build(BuildContext context) {
    final color = _colorFor(name);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        border: Border.all(color: _line),
        image: photoURL != null ? DecorationImage(image: NetworkImage(photoURL!), fit: BoxFit.cover) : null,
      ),
      child: photoURL == null ? Center(child: Icon(Icons.person_rounded, color: color, size: size * 0.5)) : null,
    );
  }
}

class _GreenPill extends StatelessWidget {
  final String label;
  const _GreenPill({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(color: _neon.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: _neon.withOpacity(0.3))),
    child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _neon)),
  );
}

class _ClanPill extends StatelessWidget {
  final String label;
  final Color color;
  const _ClanPill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
    child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
  );
}

class _UserResultCard extends ConsumerWidget {
  final UserModel user;
  const _UserResultCard({required this.user});
  @override
  Widget build(BuildContext context, WidgetRef ref) => GestureDetector(
    onTap: () => context.push('/profile/${user.uid}'),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
      child: Row(children: [
        _Avatar(photoURL: user.photoURL, name: user.username, size: 44),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.username, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _txt)),
          const SizedBox(height: 2),
          Text("@${user.username} . ${user.followersCount} abonnes", style: const TextStyle(fontSize: 12.5, color: _mut)),
        ])),
        const _GreenPill(label: "Voir profil"),
      ]),
    ),
  );
}

class _UserDiscoverCard extends ConsumerWidget {
  final UserModel user;
  const _UserDiscoverCard({required this.user});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelf = ref.watch(currentUserProvider)?.uid == user.uid;
    return GestureDetector(
      onTap: () => context.push('/profile/${user.uid}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
        child: Row(children: [
          _Avatar(photoURL: user.photoURL, name: user.username, size: 44),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.username, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _txt)),
            const SizedBox(height: 2),
            Text(
              (user.bio?.isNotEmpty ?? false) ? user.bio! : "${user.followersCount} abonnes",
              style: const TextStyle(fontSize: 12.5, color: _mut), maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ])),
          if (!isSelf) const _GreenPill(label: "Voir profil"),
        ]),
      ),
    );
  }
}

class _ClanResultCard extends StatelessWidget {
  final ClanModel clan;
  const _ClanResultCard({required this.clan});
  @override
  Widget build(BuildContext context) {
    final color = _colorFor(clan.clanId);
    final tag = clan.name.substring(0, clan.name.length > 3 ? 3 : clan.name.length).toUpperCase();
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClanDetailScreen(clanId: clan.clanId))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
            child: Center(child: Text(tag, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(clan.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _txt)),
            const SizedBox(height: 2),
            Text("${clan.membersCount} membres", style: const TextStyle(fontSize: 12.5, color: _mut)),
          ])),
          _ClanPill(label: "Voir", color: color),
        ]),
      ),
    );
  }
}

class _ClanDiscoverCard extends StatelessWidget {
  final ClanModel clan;
  const _ClanDiscoverCard({required this.clan});
  @override
  Widget build(BuildContext context) {
    final color = _colorFor(clan.clanId);
    final tag = clan.name.substring(0, clan.name.length > 3 ? 3 : clan.name.length).toUpperCase();
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClanDetailScreen(clanId: clan.clanId))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
            child: Center(child: Text(tag, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(clan.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _txt)),
            const SizedBox(height: 2),
            Text(
              (clan.description?.isNotEmpty ?? false) ? clan.description! : "${clan.membersCount} membres",
              style: const TextStyle(fontSize: 12.5, color: _mut), maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ])),
          _ClanPill(label: "Rejoindre", color: color),
        ]),
      ),
    );
  }
}