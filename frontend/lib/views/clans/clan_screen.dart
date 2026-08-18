import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/auth_viewmodel.dart';

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

// ─── Données mock clans ───────────────────────────────────────────────────────

class _ClanData {
  final String tag, name, country, desc;
  final int members;
  final Color color;
  final bool isMember;

  const _ClanData({
    required this.tag,
    required this.name,
    required this.country,
    required this.desc,
    required this.members,
    required this.color,
    this.isMember = false,
  });
}

const _mockClans = [
  _ClanData(
    tag: 'TFC', name: 'Teranga FC', country: '🇸🇳',
    desc: 'Le clan sénégalais n°1 sur eFootball. Entraînements tous les soirs à 21h GMT. Recrutement ouvert aux 1800+ pts.',
    members: 248, color: _neon, isMember: true,
  ),
  _ClanData(
    tag: 'LDM', name: 'Lions du Mandé', country: '🇲🇱',
    desc: 'Clan malien élite. Compétitions hebdomadaires, ambiance soudée. Top 5 Afrique de l\'Ouest.',
    members: 176, color: _clan,
  ),
  _ClanData(
    tag: 'EKS', name: 'Ekassa Squad', country: '🇨🇮',
    desc: 'Les meilleurs joueurs ivoiriens réunis. Tactique, rigueur, victoire.',
    members: 134, color: _build,
  ),
  _ClanData(
    tag: 'ABJ', name: 'Abidjan FC', country: '🇨🇮',
    desc: 'Clan familial, ouvert à tous. Bonne ambiance garantie, niveau débutant à confirmé.',
    members: 98, color: Color(0xFFFF8A65),
  ),
  _ClanData(
    tag: 'LAG', name: 'Lagos Boys', country: '🇳🇬',
    desc: 'Nigerian pride. Fast plays, aggressive style. Recruiting top 2000+ only.',
    members: 312, color: Color(0xFF4FC3F7),
  ),
];

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

  List<_ClanData> get _filtered => _mockClans
      .where((c) =>
          c.name.toLowerCase().contains(_query) ||
          c.tag.toLowerCase().contains(_query) ||
          c.country.contains(_query))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          _buildHeader(),
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

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Column(
        children: [
          // Titre + bouton créer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: _clan, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Clans',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _txt,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _clan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '+ Créer un clan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _clan,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Barre de recherche
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
                        hintText: 'Rechercher un clan, un pays…',
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

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: _clan,
            unselectedLabelColor: _mut,
            labelStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500),
            indicatorColor: _clan,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Découvrir'),
              Tab(text: 'Mon clan'),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Onglet Découvrir ──────────────────────────────────────────────────────

  Widget _buildDiscoverTab() {
    final clans = _filtered;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Badge tendance
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _clan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '🔥 Tendance',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _clan,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Afrique de l\'Ouest · cette semaine',
              style: TextStyle(fontSize: 11.5, color: _mut),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Liste des clans
        ...clans.map((c) => _ClanCard(
              clan: c,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClanDetailScreen(clan: c),
                ),
              ),
            )),

        if (clans.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(
              child: Text(
                'Aucun clan trouvé.',
                style: TextStyle(color: _mut, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Onglet Mon clan ───────────────────────────────────────────────────────

  Widget _buildMyClanTab() {
    final myClan = _mockClans.firstWhere(
      (c) => c.isMember,
      orElse: () => _mockClans.first,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card mon clan
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClanDetailScreen(clan: myClan),
            ),
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
                // Bannière
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        myClan.color.withOpacity(0.3),
                        _ink,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                // Contenu
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -24),
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: myClan.color.withOpacity(0.5),
                                width: 2),
                            color: _ink,
                          ),
                          child: Center(
                            child: Text(
                              myClan.tag,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: myClan.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${myClan.name} ${myClan.country}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: _txt,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${myClan.members} membres · Tu es membre',
                              style: const TextStyle(
                                  fontSize: 12, color: _mut),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _neon.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: _neon.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined,
                                color: _neon, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Actif',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _neon,
                              ),
                            ),
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

        // Message un seul clan
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _clan.withOpacity(0.08),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: _clan, size: 24),
              ),
              const SizedBox(height: 12),
              const Text(
                'Un seul clan à la fois',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _txt,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tu appartiens déjà à un clan.\nQuitte-le pour en rejoindre un autre.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: _mut, height: 1.5),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _tabController.animateTo(0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _clan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: _clan.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Découvrir des clans',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _clan,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CLAN CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ClanCard extends StatelessWidget {
  final _ClanData clan;
  final VoidCallback onTap;

  const _ClanCard({required this.clan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _line),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: clan.color.withOpacity(0.1),
                      border: Border.all(
                          color: clan.color.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        clan.tag,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: clan.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${clan.name} ${clan.country}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: _txt,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.people_outline_rounded,
                                color: _mut, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '${clan.members} membres',
                              style: const TextStyle(
                                  fontSize: 12, color: _mut),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.emoji_events_outlined,
                                color: _mut, size: 13),
                            const SizedBox(width: 4),
                            const Text(
                              'Div. 1',
                              style: TextStyle(
                                  fontSize: 12, color: _mut),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          clan.desc,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: _txt.withOpacity(0.75),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _line)),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Avatars membres (mock)
                  ...List.generate(3, (i) => Container(
                    margin: EdgeInsets.only(left: i == 0 ? 0 : -6),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: [_neon, _build, _clan][i].withOpacity(0.2),
                      border: Border.all(color: _card, width: 2),
                    ),
                    child: Center(
                      child: Icon(Icons.person_rounded,
                          color: [_neon, _build, _clan][i], size: 12),
                    ),
                  )),
                  Container(
                    margin: const EdgeInsets.only(left: -6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _line,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: _card, width: 2),
                    ),
                    child: Text(
                      '+${clan.members - 3}',
                      style: const TextStyle(
                          fontSize: 10.5, color: _mut),
                    ),
                  ),

                  const Spacer(),

                  // Bouton rejoindre / membre
                  clan.isMember
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _neon.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _neon.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_rounded,
                                  color: _neon, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Membre',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _neon,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: clan.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Rejoindre',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
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
  final _ClanData clan;
  const ClanDetailScreen({super.key, required this.clan});

  @override
  ConsumerState<ClanDetailScreen> createState() => _ClanDetailScreenState();
}

class _ClanDetailScreenState extends ConsumerState<ClanDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _mockMembers = const [
    {'name': 'ibra_efc',    'role': 'Capitaine', 'color': 0xFFFFCC02},
    {'name': 'fatou_gg',    'role': 'Officier',  'color': 0xFF00E676},
    {'name': 'awa_builds',  'role': 'Officier',  'color': 0xFF00E676},
    {'name': 'yaya99',      'role': 'Membre',    'color': 0xFF485070},
    {'name': 'kouassi_fc',  'role': 'Membre',    'color': 0xFF485070},
    {'name': 'chris_plays', 'role': 'Membre',    'color': 0xFF485070},
  ];

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
    final clan = widget.clan;

    return Scaffold(
      backgroundColor: _ink,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _buildHeader(context, clan)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabDelegate(
              TabBar(
                controller: _tabController,
                labelColor: _clan,
                unselectedLabelColor: _mut,
                labelStyle: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w500),
                indicatorColor: _clan,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Posts du clan'),
                  Tab(text: 'Membres'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(),
            _buildMembersTab(),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, _ClanData clan) {
    return Column(
      children: [
        // Bannière
        Stack(
          children: [
            Container(
              height: 136,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    clan.color.withOpacity(0.35),
                    _ink,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Dégradé bas
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
            // Bouton retour
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: _CircleBtn(
                icon: Icons.chevron_left_rounded,
                onTap: () => context.pop(),
              ),
            ),
            // Bouton plus
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: _CircleBtn(
                icon: Icons.more_horiz_rounded,
                onTap: () {},
              ),
            ),
          ],
        ),

        // Infos
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Logo clan
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: clan.color.withOpacity(0.5), width: 2),
                        color: _ink,
                        boxShadow: [
                          BoxShadow(
                            color: clan.color.withOpacity(0.3),
                            blurRadius: 24,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          clan.tag,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: clan.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Boutons action
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        _OutlineBtn(
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),
                        _OutlineBtn(
                          label: clan.isMember ? 'Quitter' : 'Rejoindre',
                          onTap: () {},
                          color: clan.isMember ? null : clan.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              Transform.translate(
                offset: const Offset(0, -14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom
                    Row(
                      children: [
                        Text(
                          clan.name,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: _txt,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(clan.country,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _clan.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.emoji_events_outlined,
                                  color: _clan, size: 12),
                              SizedBox(width: 3),
                              Text(
                                'Div. 1',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _clan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      clan.desc,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: _txt.withOpacity(0.85),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Stats
                    Container(
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _line),
                      ),
                      child: Row(
                        children: [
                          _StatCell(
                              value: '${clan.members}',
                              label: 'Membres'),
                          Container(width: 1, height: 40, color: _line),
                          const _StatCell(value: '1 042', label: 'Posts'),
                          Container(width: 1, height: 40, color: _line),
                          const _StatCell(value: '#3', label: 'Classement'),
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

  // ─── Onglet Posts ──────────────────────────────────────────────────────────

  Widget _buildPostsTab() {
    return ListView(
      children: [
        // Zone de rédaction
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _neon.withOpacity(0.12),
                ),
                child: const Icon(Icons.person_rounded,
                    color: _neon, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _line),
                  ),
                  child: const Text(
                    'Écris quelque chose au clan…',
                    style: TextStyle(fontSize: 13, color: _mut),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Posts vides
        const Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.dynamic_feed_rounded, color: _mut, size: 36),
                SizedBox(height: 12),
                Text(
                  'Aucun post dans ce clan pour l\'instant.',
                  style: TextStyle(color: _mut, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Onglet Membres ────────────────────────────────────────────────────────

  Widget _buildMembersTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _mockMembers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final member = _mockMembers[index];
        final color = Color(member['color'] as int);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                ),
                child: Center(
                  child: Icon(Icons.person_rounded, color: color, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _txt,
                      ),
                    ),
                    Text(
                      '@${member['name']}',
                      style: const TextStyle(fontSize: 12, color: _mut),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  member['role'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.55),
        ),
        child: Icon(icon, color: _txt, size: 22),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;
  const _OutlineBtn({this.label, this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: color != null ? color!.withOpacity(0.1) : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color != null
              ? color!.withOpacity(0.3) : _line),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: _txt, size: 18)
              : Text(
                  label!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color ?? _txt,
                  ),
                ),
        ),
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
            Text(value,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w900, color: _txt)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11.5, color: _mut)),
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
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabDelegate old) => false;
}