import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../viewmodels/feed_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../data/models/post_model.dart';
import '../../core/router/app_router.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';

// ─── Couleurs eForum ──────────────────────────────────────────────────────────

const _ink = Color(0xFF07090F);
const _surface = Color(0xFF0E1119);
const _card = Color(0xFF131824);
const _line = Color(0xFF1C2236);
const _neon = Color(0xFF00E676);
const _txt = Color(0xFFCDD5F0);
const _mut = Color(0xFF485070);
const _clan = Color(0xFFFFCC02);
const _build = Color(0xFFCE93D8);
const _chat = Color(0xFFFF8A65);

// ─── Données mock clans (stories) ─────────────────────────────────────────────

const _mockClans = [
  {'tag': 'TFC', 'name': 'Teranga FC', 'color': 0xFF00E676},
  {'tag': 'LDM', 'name': 'Lions Mandé', 'color': 0xFFFFCC02},
  {'tag': 'EKS', 'name': 'Ekassa', 'color': 0xFFCE93D8},
  {'tag': 'ABJ', 'name': 'Abidjan FC', 'color': 0xFFFF8A65},
  {'tag': 'LAG', 'name': 'Lagos Boys', 'color': 0xFF4FC3F7},
];

// ═══════════════════════════════════════════════════════════════════════════════
// FEED SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(feedViewModelProvider.notifier).switchTab(
              _tabController.index == 0 ? FeedTab.forYou : FeedTab.following,
            );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedViewModelProvider);

    return Scaffold(
      backgroundColor: _ink,
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _navIndex,
        children: [
          // Index 0: Accueil (Feed)
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              _buildHeader(context),
              _buildTabs(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildForYouTab(feedState),
                    _buildFollowingTab(feedState),
                  ],
                ),
              ),
            ],
          ),

          // Index 1: Recherche
          const SearchScreen(),

          // Index 2: Bouton + (plein écran via push)
          const SizedBox.expand(),

          // Index 3: Clans (placeholder)
          _buildClansPlaceholder(),

          // Index 4: Profil (sans bouton retour)
          const ProfileScreen(showBackButton: false),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
      child: Row(
        children: [
          // Logo + nom
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _neon,
                ),
                child: const Center(
                  child: Text(
                    'eF',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'e',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _txt,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: 'Forum',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _neon,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // Icône chat
          _HeaderIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            hasDot: true,
            dotColor: _chat,
            onTap: () {},
          ),

          // Icône notifications
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            badge: '3',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ─── Tabs ──────────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: _neon,
        unselectedLabelColor: _mut,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: _neon,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Pour toi'),
          Tab(text: 'Abonnements'),
        ],
      ),
    );
  }

  // ─── Onglet "Pour toi" ─────────────────────────────────────────────────────

  Widget _buildForYouTab(FeedState feedState) {
    // FeedInitial : le viewmodel vient de démarrer, chargement en cours
    if (feedState is FeedInitial) {
      return const Center(
        child: CircularProgressIndicator(color: _neon, strokeWidth: 2),
      );
    }

    return RefreshIndicator(
      color: _neon,
      backgroundColor: _card,
      onRefresh: () async {
        ref.read(feedViewModelProvider.notifier).loadFeed();
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: CustomScrollView(
        slivers: [
          // Stories clans
          SliverToBoxAdapter(child: _buildClanStories()),

          // Posts
          if (feedState is FeedLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: _neon, strokeWidth: 2),
              ),
            )
          else if (feedState is FeedError)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: _mut, size: 40),
                    const SizedBox(height: 12),
                    Text(feedState.message,
                        style: const TextStyle(color: _mut, fontSize: 13)),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          ref.read(feedViewModelProvider.notifier).loadFeed(),
                      child: const Text('Réessayer',
                          style: TextStyle(color: _neon)),
                    ),
                  ],
                ),
              ),
            )
          else if (feedState is FeedLoaded && feedState.posts.isEmpty)
            const SliverFillRemaining(child: _EmptyFeed())
          else if (feedState is FeedLoaded)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == feedState.posts.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Tu es à jour ',
                          style: TextStyle(color: _mut, fontSize: 12.5),
                        ),
                      ),
                    );
                  }
                  return PostCard(post: feedState.posts[index]);
                },
                childCount: feedState.posts.length + 1,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Onglet "Abonnements" ──────────────────────────────────────────────────

  Widget _buildFollowingTab(FeedState feedState) {
    if (feedState is FeedLoaded && feedState.posts.isEmpty) {
      return const _EmptyFollowing();
    }
    return _buildForYouTab(feedState);
  }

  // ─── Stories clans ─────────────────────────────────────────────────────────

  Widget _buildClanStories() {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _mockClans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final clan = _mockClans[index];
          final color = Color(clan['color'] as int);
          // Carré coloré sans texte — tag retiré
          return Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: color.withValues(alpha: 0.18),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
            ),
          );
        },
      ),
    );
  }

  // ─── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    final leftItems = [
      {'icon': Icons.home_rounded,   'label': 'Accueil',   'idx': 0},
      {'icon': Icons.search_rounded, 'label': 'Recherche', 'idx': 1},
    ];
    final rightItems = [
      {'icon': Icons.shield_outlined,        'label': 'Clans',  'idx': 3},
      {'icon': Icons.person_outline_rounded, 'label': 'Profil', 'idx': 4},
    ];

    Widget navItem(IconData icon, String label, int idx) {
      final isActive = _navIndex == idx;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _navIndex = idx),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? _neon : _mut, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? _neon : _mut,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // La barre flottante arr ondie : on utilise un ColoredBox transparent
    // pour que Scaffold connaisse la vraie hauteur occupée (marges incluses)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            top: 6,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ...leftItems.map((e) => navItem(
                  e['icon'] as IconData,
                  e['label'] as String,
                  e['idx'] as int,
                )),

                // Centre : Bouton +
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () => context.push(AppRoutes.createPost),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _neon,
                          boxShadow: [
                            BoxShadow(
                              color: _neon.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded, color: _ink, size: 28),
                      ),
                    ),
                  ),
                ),

                ...rightItems.map((e) => navItem(
                  e['icon'] as IconData,
                  e['label'] as String,
                  e['idx'] as int,
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Clans Placeholder ──────────────────────────────────────────────────────

  Widget _buildClansPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card,
                shape: BoxShape.circle,
                border: Border.all(color: _line),
              ),
              child: const Icon(Icons.shield_outlined, color: _neon, size: 54),
            ),
            const SizedBox(height: 20),
            const Text(
              'Clans eForum',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _txt,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rejoins ou crée un clan pour dominer le terrain !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _mut,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '(Bientôt disponible)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _neon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFAB(BuildContext context) {
    return const SizedBox.shrink(); // Le bouton + est dans la bottom nav
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// POST CARD
// ═══════════════════════════════════════════════════════════════════════════════

class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  const PostCard({super.key, required this.post});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _liked = false;
  bool _reposted = false;

  @override
  void initState() {
    super.initState();
    _checkInteractions();
  }

  Future<void> _checkInteractions() async {
    final vm = ref.read(feedViewModelProvider.notifier);
    final liked = await vm.isLiked(widget.post.postId);
    final reposted = await vm.isReposted(widget.post.postId);
    if (mounted) setState(() {
      _liked = liked;
      _reposted = reposted;
    });
  }

  Future<void> _toggleLike() async {
    setState(() => _liked = !_liked);
    await ref.read(feedViewModelProvider.notifier).toggleLike(widget.post.postId);
  }

  void _showRepostDialog() {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Republier',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _txt,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _line),
                ),
                child: TextField(
                  controller: commentController,
                  style: const TextStyle(color: _txt, fontSize: 14),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ajoute un commentaire (optionnel)…',
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
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await ref
                        .read(feedViewModelProvider.notifier)
                        .repostPost(
                          originalPostId: widget.post.postId,
                          repostComment: commentController.text.trim().isEmpty
                              ? null
                              : commentController.text.trim(),
                        );
                    if (success && mounted) {
                      setState(() => _reposted = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Post republié ✅'),
                          backgroundColor: _card,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _neon,
                    foregroundColor: _ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Republier',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Signature line verte — élément distinctif eForum
          Container(
            height: 1.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_neon, Colors.transparent],
                stops: [0.0, 0.6],
              ),
            ),
          ),

          // Label repost
          if (post.isRepost)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: const [
                  Icon(Icons.repeat_rounded, size: 13, color: _mut),
                  SizedBox(width: 5),
                  Text(
                    'a republié',
                    style: TextStyle(fontSize: 12, color: _mut),
                  ),
                ],
              ),
            ),

          // Badge annonce admin
          if (post.isAnnouncement)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _clan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _clan.withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_rounded, size: 13, color: _clan),
                  SizedBox(width: 5),
                  Text(
                    'Annonce officielle',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _clan,
                    ),
                  ),
                ],
              ),
            ),

          // Corps du post
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _neon.withOpacity(0.15),
                    border: Border.all(color: _line),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, color: _neon, size: 22),
                  ),
                ),

                const SizedBox(width: 12),

                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header : username + temps
                      Row(
                        children: [
                          const Text(
                            'joueur',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _txt,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeago.format(post.createdAt.toDate(), locale: 'fr'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _mut,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.more_horiz_rounded,
                              color: _mut, size: 20),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Texte du post
                      Text(
                        post.content,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: _txt,
                          height: 1.5,
                        ),
                      ),

                      // Commentaire repost
                      if (post.isRepost &&
                          post.repostComment != null &&
                          post.repostComment!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _line),
                          ),
                          child: Text(
                            post.repostComment!,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: _txt,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Actions (like, commentaire, repost) ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                // Like
                _ActionButton(
                  icon: _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '${post.likesCount + (_liked ? 1 : 0)}',
                  color: _liked ? const Color(0xFFFF5A7A) : _mut,
                  onTap: _toggleLike,
                ),

                const SizedBox(width: 20),

                // Commentaire
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.commentsCount}',
                  color: _mut,
                  onTap: () {},
                ),

                const SizedBox(width: 20),

                // Repost
                _ActionButton(
                  icon: Icons.repeat_rounded,
                  label: '${post.repostsCount + (_reposted ? 1 : 0)}',
                  color: _reposted ? _build : _mut,
                  onTap: _reposted ? null : _showRepostDialog,
                ),

                const Spacer(),

                // Partager
                Icon(Icons.ios_share_rounded, color: _mut, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS UTILITAIRES
// ═══════════════════════════════════════════════════════════════════════════════

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final bool hasDot;
  final Color dotColor;
  final String? badge;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    this.hasDot = false,
    this.dotColor = _neon,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          children: [
            Center(
              child: Icon(icon, color: _txt, size: 22),
            ),
            if (hasDot)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: Border.all(color: _ink, width: 1.5),
                  ),
                ),
              ),
            if (badge != null)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _neon,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _ink, width: 1.5),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.dynamic_feed_rounded,
                color: _neon, size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun post pour l\'instant',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _txt,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sois le premier à publier quelque chose !',
            style: TextStyle(fontSize: 13, color: _mut),
          ),
        ],
      ),
    );
  }
}

class _EmptyFollowing extends StatelessWidget {
  const _EmptyFollowing();

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.people_outline_rounded,
                color: _neon, size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun post encore',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _txt,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Tu ne suis personne pour l\'instant.\nAbonne-toi à des joueurs pour voir leurs posts ici.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _mut, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _neon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _neon.withOpacity(0.3)),
            ),
            child: const Text(
              'Découvrir des joueurs',
              style: TextStyle(
                fontSize: 13.5,
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