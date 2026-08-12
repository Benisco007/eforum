import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../data/models/user_model.dart';
import '../../data/models/post_model.dart';
import '../feed/feed_screen.dart' show PostCard;

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

// ═══════════════════════════════════════════════════════════════════════════════
// PROFILE SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  const ProfileScreen({super.key, this.showBackButton = true});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final feedState = ref.watch(feedViewModelProvider);

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: _ink,
        body: Center(
          child: CircularProgressIndicator(color: _neon, strokeWidth: 2),
        ),
      );
    }

    final userPosts = feedState is FeedLoaded
        ? feedState.posts
            .where((p) => p.authorId == currentUser.uid)
            .toList()
        : <PostModel>[];

    return Scaffold(
      backgroundColor: _ink,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _buildHeader(context, currentUser, userPosts.length),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: _neon,
                unselectedLabelColor: _mut,
                labelStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: _neon,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Builds'),
                  Tab(text: 'Clans'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(userPosts),
            _buildBuildsTab(),
            _buildClansTab(currentUser),
          ],
        ),
      ),
    );
  }

  // ─── Header complet ────────────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context, UserModel user, int postsCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Bannière ────────────────────────────────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Bannière
            Container(
              height: 148,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _card,
                image: user.teamPhotoURL != null
                    ? DecorationImage(
                        image: NetworkImage(user.teamPhotoURL!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: user.teamPhotoURL == null
                  ? Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0D1F14), Color(0xFF0A0F1E)],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.shield_outlined,
                          color: _neon.withOpacity(0.15),
                          size: 60,
                        ),
                      ),
                    )
                  : null,
            ),

            // Dégradé bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
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
            if (widget.showBackButton)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 12,
                child: _CircleButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => context.pop(),
                ),
              ),

            // Bouton settings
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: _CircleButton(
                icon: Icons.settings_outlined,
                onTap: () {},
              ),
            ),

            // Badge clan
            if (user.clanId != null)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _clan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _clan.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('⚔️', style: TextStyle(fontSize: 11)),
                      SizedBox(width: 5),
                      Text(
                        'Membre du clan',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _clan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        // ── Identité ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + boutons action
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar avec ring
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _ink, width: 4),
                      ),
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _neon.withOpacity(0.15),
                          image: user.photoURL != null
                              ? DecorationImage(
                                  image: NetworkImage(user.photoURL!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user.photoURL == null
                            ? const Center(
                                child: Icon(Icons.person_rounded,
                                    color: _neon, size: 38),
                              )
                            : null,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Boutons
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        _OutlineButton(
                          label: 'Modifier le profil',
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _neon,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.people_outline_rounded,
                              color: _ink, size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Nom + handle
              Transform.translate(
                offset: const Offset(0, -20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom
                    Row(
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: _txt,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Badge vérifié si admin
                        if (user.role == UserRole.admin)
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _neon,
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: _ink, size: 10),
                          ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: _mut,
                      ),
                    ),

                    // Bio
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        user.bio!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _txt,
                          height: 1.5,
                        ),
                      ),
                    ],

                    // Chips stats
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatChip(label: 'Div. 1', color: _neon,
                            icon: Icons.emoji_events_outlined),
                        _StatChip(label: '0 builds', color: _build,
                            icon: Icons.bolt_outlined),
                        _StatChip(label: '🔥 En forme', color: _chat),
                      ],
                    ),

                    // Stats posts / abonnés / abonnements
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _line),
                      ),
                      child: Row(
                        children: [
                          _StatCell(
                              value: '$postsCount', label: 'Posts'),
                          Container(width: 1, height: 40, color: _line),
                          _StatCell(
                              value: '${user.followersCount}',
                              label: 'Abonnés'),
                          Container(width: 1, height: 40, color: _line),
                          _StatCell(
                              value: '${user.followingCount}',
                              label: 'Abonnements'),
                        ],
                      ),
                    ),

                    // Joueur préféré
                    if (user.favPlayerName != null) ...[
                      const SizedBox(height: 16),
                      _buildFavPlayer(user),
                    ],

                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Joueur préféré ────────────────────────────────────────────────────────

  Widget _buildFavPlayer(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_build.withOpacity(0.1), Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _build.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          // Card placeholder
          Container(
            width: 54,
            height: 74,
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _line),
            ),
            child: const Center(
              child: Icon(Icons.person_outline_rounded,
                  color: _build, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.favPlayerName!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _txt,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Joueur préféré',
                  style: TextStyle(fontSize: 12.5, color: _mut),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _neon,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '⚡',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Voir les builds',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _build,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Onglet Posts ──────────────────────────────────────────────────────────

  Widget _buildPostsTab(List<PostModel> posts) {
    if (posts.isEmpty) {
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
              child: const Icon(Icons.edit_outlined, color: _neon, size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'Aucun post encore',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _txt),
            ),
            const SizedBox(height: 6),
            const Text(
              'Partage ton premier post !',
              style: TextStyle(fontSize: 13, color: _mut),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) => PostCard(post: posts[index]),
    );
  }

  // ─── Onglet Builds ─────────────────────────────────────────────────────────

  Widget _buildBuildsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _build.withOpacity(0.08),
            ),
            child: const Icon(Icons.bolt_outlined, color: _build, size: 28),
          ),
          const SizedBox(height: 14),
          const Text(
            'Aucun build encore',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _txt),
          ),
          const SizedBox(height: 6),
          const Text(
            'Crée et partage tes configurations !',
            style: TextStyle(fontSize: 13, color: _mut),
          ),
          const SizedBox(height: 20),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _build.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _build.withOpacity(0.3)),
            ),
            child: const Text(
              '+ Créer un build',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _build,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Onglet Clans ──────────────────────────────────────────────────────────

  Widget _buildClansTab(UserModel user) {
    if (user.clanId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _clan.withOpacity(0.08),
              ),
              child: const Icon(Icons.shield_outlined, color: _clan, size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'Aucun clan',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _txt),
            ),
            const SizedBox(height: 6),
            const Text(
              'Rejoins ou crée un clan pour jouer en équipe.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _mut, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _clan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _clan.withOpacity(0.3)),
              ),
              child: const Text(
                'Explorer les clans',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _clan,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
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
                  color: _clan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    '⚔️',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon clan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _txt,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Membre',
                      style: TextStyle(fontSize: 12, color: _mut),
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
                  border: Border.all(color: _neon.withOpacity(0.3)),
                ),
                child: const Text(
                  'Voir',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _neon,
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
// WIDGETS UTILITAIRES
// ═══════════════════════════════════════════════════════════════════════════════

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.55),
        ),
        child: Icon(icon, color: _txt, size: 20),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _txt,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;

  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: _txt,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: _mut),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatChip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 1;

  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}