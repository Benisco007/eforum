import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../viewmodels/feed_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../data/models/post_model.dart';
import '../../data/models/build_model.dart';
import '../../data/models/user_model.dart';
import '../../core/router/app_router.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../../data/repositories/user_repository.dart';
import 'comments_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../builds/builds_screen.dart';
import '../clans/clan_screen.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

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


// ─── Provider profil auteur ───────────────────────────────────────────────────

final userProfileProvider =
    FutureProvider.family<UserModel?, String>((ref, uid) async {
  final repo = UserRepository();
  return repo.getUserById(uid);
});
final unreadNotificationsProvider = StreamProvider<int>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('notifications')
      .where('recipientId', isEqualTo: currentUser.uid)
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snap) => snap.docs.length);
});

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
          const SearchScreen(),
          const SizedBox.shrink(),
          const ClansScreen(),
          const ProfileScreen(showBackButton: false),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: _neon),
            child: const Center(
              child: Text('eF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _ink)),
            ),
          ),
          const SizedBox(width: 10),
          RichText(
            text: const TextSpan(children: [
              TextSpan(text: 'e', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _txt, letterSpacing: -0.5)),
              TextSpan(text: 'Forum', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _neon, letterSpacing: -0.5)),
            ]),
          ),
          const Spacer(),
          _HeaderIconButton(icon: Icons.chat_bubble_outline_rounded, hasDot: true, dotColor: _chat, onTap: () => context.push(AppRoutes.messages)),
          Consumer(
            builder: (context, ref, _) {
              final count = ref.watch(unreadNotificationsProvider).valueOrNull ?? 0;
              return _HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                badge: count > 0 ? '$count' : null,
                onTap: () => context.push(AppRoutes.notifications),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(color: _ink, border: Border(bottom: BorderSide(color: _line))),
      child: TabBar(
        controller: _tabController,
        labelColor: _neon,
        unselectedLabelColor: _mut,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        indicatorColor: _neon,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        tabs: const [Tab(text: 'Pour toi'), Tab(text: 'Abonnements')],
      ),
    );
  }

  Widget _buildForYouTab(FeedState feedState) {
    if (feedState is FeedInitial) {
      return const Center(child: CircularProgressIndicator(color: _neon, strokeWidth: 2));
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
          if (feedState is FeedLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: _neon, strokeWidth: 2)))
          else if (feedState is FeedError)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: _mut, size: 40),
                    const SizedBox(height: 12),
                    Text(feedState.message, style: const TextStyle(color: _mut, fontSize: 13)),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.read(feedViewModelProvider.notifier).loadFeed(),
                      child: const Text('Réessayer', style: TextStyle(color: _neon)),
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
                      child: Center(child: Text('Tu es à jour ✅', style: TextStyle(color: _mut, fontSize: 12.5))),
                    );
                  }
                  final item = feedState.posts[index];
                  if (item is PostModel) {
                    return PostCard(post: item);
                  } else if (item is BuildModel) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: BuildCard(build: item),
                    );
                  }
                  return const SizedBox.shrink();
                },
                childCount: feedState.posts.length + 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFollowingTab(FeedState feedState) {
    if (feedState is FeedLoaded && feedState.posts.isEmpty) return const _EmptyFollowing();
    return _buildForYouTab(feedState);
  }


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
              Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400, color: isActive ? _neon : _mut)),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).padding.bottom + 12, top: 6),
          child: Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _line),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 6))],
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ...leftItems.map((e) => navItem(e['icon'] as IconData, e['label'] as String, e['idx'] as int)),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () => context.push(AppRoutes.createPost),
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, color: _neon,
                          boxShadow: [BoxShadow(color: _neon.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)],
                        ),
                        child: const Icon(Icons.add_rounded, color: _ink, size: 28),
                      ),
                    ),
                  ),
                ),
                ...rightItems.map((e) => navItem(e['icon'] as IconData, e['label'] as String, e['idx'] as int)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClansPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _card, shape: BoxShape.circle, border: Border.all(color: _line)),
              child: const Icon(Icons.shield_outlined, color: _neon, size: 54),
            ),
            const SizedBox(height: 20),
            const Text('Clans eForum', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _txt)),
            const SizedBox(height: 8),
            const Text('Rejoins ou crée un clan pour dominer le terrain !', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _mut)),
            const SizedBox(height: 6),
            const Text('(Bientôt disponible)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _neon)),
          ],
        ),
      ),
    );
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
  bool _initialLiked = false;
  bool _reposted = false;
  bool _initialReposted = false;
  bool _interactionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkInteractions();
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.postId != widget.post.postId) _checkInteractions();
  }

  Future<void> _checkInteractions() async {
    final vm = ref.read(feedViewModelProvider.notifier);
    final liked = await vm.isLiked(widget.post.postId);
    final reposted = await vm.isReposted(widget.post.postId);
    if (mounted) {
      setState(() {
        _liked = liked;
        _initialLiked = liked;
        _reposted = reposted;
        _initialReposted = reposted;
        _interactionsLoaded = true;
      });
    }
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Republier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _txt)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
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
                    final success = await ref.read(feedViewModelProvider.notifier).repostPost(
                      originalPostId: widget.post.postId,
                      repostComment: commentController.text.trim().isEmpty ? null : commentController.text.trim(),
                    );
                    if (success && mounted) {
                      setState(() => _reposted = true);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post republié', style: TextStyle(color: _txt)), backgroundColor: _card));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _neon, foregroundColor: _ink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: const Text('Republier', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareMenu() {
    final author = ref.read(userProfileProvider(widget.post.authorId)).valueOrNull;
    final username = author?.username ?? 'un joueur';
    final content = widget.post.content;
    final shareText = '"$username" sur eForum : "$content"';

    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(4)),
            ),
            ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: _neon.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.share_rounded, color: _neon, size: 18),
              ),
              title: const Text('Partager via...', style: TextStyle(color: _txt, fontWeight: FontWeight.w600, fontSize: 14.5)),
              onTap: () {
                Navigator.pop(ctx);
                Share.share(shareText);
              },
            ),
            ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: _build.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.copy_rounded, color: _build, size: 18),
              ),
              title: const Text('Copier le lien du post', style: TextStyle(color: _txt, fontWeight: FontWeight.w600, fontSize: 14.5)),
              onTap: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(ClipboardData(text: 'https://eforum.com/posts/${widget.post.postId}'));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lien copié dans le presse-papiers', style: TextStyle(color: _txt)),
                      backgroundColor: _card,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    final int likeDelta = _interactionsLoaded ? ((_liked ? 1 : 0) - (_initialLiked ? 1 : 0)) : 0;
    final int displayLikes = (post.likesCount + likeDelta).clamp(0, 999999);
    final int repostDelta = _interactionsLoaded ? ((_reposted ? 1 : 0) - (_initialReposted ? 1 : 0)) : 0;
    final int displayReposts = (post.repostsCount + repostDelta).clamp(0, 999999);

    // Profil auteur depuis Firestore
    final author = ref.watch(userProfileProvider(post.authorId)).valueOrNull;

    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Signature line verte
          Container(
            height: 1.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_neon, Colors.transparent], stops: [0.0, 0.6]),
            ),
          ),

          // Label repost
          if (post.isRepost)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(children: [
                const Icon(Icons.repeat_rounded, size: 13, color: _mut),
                const SizedBox(width: 5),
                Text('${author?.username ?? '...'} a republié', style: const TextStyle(fontSize: 12, color: _mut)),
              ]),
            ),

          // Badge annonce
          if (post.isAnnouncement)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _clan.withOpacity(0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: _clan.withOpacity(0.4))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.campaign_rounded, size: 13, color: _clan),
                SizedBox(width: 5),
                Text('Annonce officielle', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _clan)),
              ]),
            ),

          // Corps
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar cliquable
                GestureDetector(
                  onTap: () => context.push('/profile/${post.authorId}'),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _neon.withOpacity(0.15),
                      border: Border.all(color: _line),
                      image: author?.photoURL != null
                          ? DecorationImage(image: NetworkImage(author!.photoURL!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: author?.photoURL == null
                        ? const Center(child: Icon(Icons.person_rounded, color: _neon, size: 22))
                        : null,
                  ),
                ),

                const SizedBox(width: 12),

                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.push('/profile/${post.authorId}'),
                            child: Text(
                              author?.username ?? '...',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _txt),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${timeago.format(post.createdAt.toDate(), locale: 'fr')}${post.updatedAt != null ? ' (modifié)' : ''}',
                            style: const TextStyle(fontSize: 12, color: _mut),
                          ),
                          const Spacer(),
                          _PostMenuButton(post: widget.post),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (post.content.isNotEmpty)
                        Text(post.content, style: const TextStyle(fontSize: 14.5, color: _txt, height: 1.5)),
                      if (post.mediaURLs.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              post.mediaURLs.first,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: _card,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(color: _neon, strokeWidth: 2),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      if (post.isRepost && post.repostComment != null && post.repostComment!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
                          child: Text(post.repostComment!, style: const TextStyle(fontSize: 13.5, color: _txt, height: 1.4)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                _ActionButton(
                  icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: '$displayLikes',
                  color: _liked ? const Color(0xFFFF5A7A) : _mut,
                  onTap: _toggleLike,
                ),
                const SizedBox(width: 20),
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.commentsCount}',
                  color: _mut,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentsScreen(post: post),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                _ActionButton(icon: Icons.repeat_rounded, label: '$displayReposts', color: _reposted ? _build : _mut, onTap: _reposted ? null : _showRepostDialog),
                const Spacer(),
                GestureDetector(
                  onTap: _showShareMenu,
                  child: const Icon(Icons.ios_share_rounded, color: _mut, size: 18),
                ),
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

  const _HeaderIconButton({required this.icon, this.hasDot = false, this.dotColor = _neon, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40, height: 40,
        child: Stack(
          children: [
            Center(child: Icon(icon, color: _txt, size: 22)),
            if (hasDot)
              Positioned(right: 6, top: 6, child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor, border: Border.all(color: _ink, width: 1.5)))),
            if (badge != null)
              Positioned(right: 2, top: 2, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: _neon, borderRadius: BorderRadius.circular(99), border: Border.all(color: _ink, width: 1.5)),
                child: Text(badge!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _ink)),
              )),
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

  const _ActionButton({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
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
          Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: _neon.withOpacity(0.08)), child: const Icon(Icons.dynamic_feed_rounded, color: _neon, size: 30)),
          const SizedBox(height: 16),
          const Text('Aucun post pour l\'instant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _txt)),
          const SizedBox(height: 8),
          const Text('Sois le premier à publier quelque chose !', style: TextStyle(fontSize: 13, color: _mut)),
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
          Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: _neon.withOpacity(0.08)), child: const Icon(Icons.people_outline_rounded, color: _neon, size: 30)),
          const SizedBox(height: 16),
          const Text('Aucun post encore', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _txt)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text('Tu ne suis personne pour l\'instant.\nAbonne-toi à des joueurs pour voir leurs posts ici.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _mut, height: 1.5)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: _neon.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _neon.withOpacity(0.3))),
            child: const Text('Découvrir des joueurs', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _neon)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MENU ... POST (Modifier / Supprimer)
// ═══════════════════════════════════════════════════════════════════════════════

class _PostMenuButton extends ConsumerWidget {
  final PostModel post;
  const _PostMenuButton({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser?.uid == post.authorId;

    return GestureDetector(
      onTap: () {
        if (isOwner) {
          _showOwnerMenu(context, ref);
        } else {
          _showGuestMenu(context, ref);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: const Icon(Icons.more_horiz_rounded, color: _mut, size: 20),
      ),
    );
  }

  // ─── Menu propriétaire (Modifier / Supprimer) ──────────────────────────────

  void _showOwnerMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(4)),
            ),
            // Modifier
            ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: _neon.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.edit_rounded, color: _neon, size: 18),
              ),
              title: const Text('Modifier le post', style: TextStyle(color: _txt, fontWeight: FontWeight.w600, fontSize: 14.5)),
              onTap: () {
                Navigator.pop(ctx);
                _showEditDialog(context, ref);
              },
            ),
            // Supprimer
            ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: const Color(0xFFEF5350).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF5350), size: 18),
              ),
              title: const Text('Supprimer le post', style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.w600, fontSize: 14.5)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Menu visiteur (Signaler) ──────────────────────────────────────────────

  void _showGuestMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(4)),
            ),
            ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: const Color(0xFFFFAB40).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.flag_outlined, color: Color(0xFFFFAB40), size: 18),
              ),
              title: const Text('Signaler ce post', style: TextStyle(color: Color(0xFFFFAB40), fontWeight: FontWeight.w600, fontSize: 14.5)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post signalé. Merci !', style: TextStyle(color: _txt)), backgroundColor: _card),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Dialog modification ───────────────────────────────────────────────────

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: post.content);
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const Text('Modifier le post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _txt)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _line)),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: _txt, fontSize: 14.5, height: 1.5),
                  maxLines: 6,
                  autofocus: true,
                  decoration: const InputDecoration(
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
                    final newContent = controller.text.trim();
                    if (newContent.isEmpty) return;
                    Navigator.pop(ctx);
                    final success = await ref.read(feedViewModelProvider.notifier).updatePost(
                      postId: post.postId,
                      newContent: newContent,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Post modifié' : 'Erreur lors de la modification', style: const TextStyle(color: _txt)),
                          backgroundColor: _card,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _neon,
                    foregroundColor: _ink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Confirmation suppression ──────────────────────────────────────────────

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce post ?', style: TextStyle(color: _txt, fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Cette action est irréversible.', style: TextStyle(color: _mut, fontSize: 13.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: _mut, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(feedViewModelProvider.notifier).deletePost(post.postId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Post supprimé' : 'Erreur lors de la suppression', style: const TextStyle(color: _txt)),
                    backgroundColor: _card,
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}