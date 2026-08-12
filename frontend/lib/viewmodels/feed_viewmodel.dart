import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/post_model.dart';
import '../data/repositories/post_repository.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_viewmodel.dart';

// ─── États du feed ────────────────────────────────────────────────────────────

abstract class FeedState {}

class FeedInitial extends FeedState {}

class FeedLoading extends FeedState {}

class FeedLoaded extends FeedState {
  final List<PostModel> posts;
  final bool hasMore;
  FeedLoaded({required this.posts, this.hasMore = true});
}

class FeedError extends FeedState {
  final String message;
  FeedError(this.message);
}

// ─── Onglets du feed ──────────────────────────────────────────────────────────

enum FeedTab { forYou, following }

// ─── ViewModel ───────────────────────────────────────────────────────────────

class FeedViewModel extends StateNotifier<FeedState> {
  final PostRepository _postRepository;
  final String? _currentUserId;
  List<String> _followingIds = [];
  FeedTab _currentTab = FeedTab.forYou;
  StreamSubscription<List<PostModel>>? _feedSubscription;

  FeedViewModel(this._postRepository, this._currentUserId)
      : super(FeedInitial()) {
    loadFeed();
  }

  FeedTab get currentTab => _currentTab;

  // ─── Changer d'onglet ──────────────────────────────────────────────────────

  void switchTab(FeedTab tab) {
    if (_currentTab == tab) return;
    _currentTab = tab;
    loadFeed();
  }

  // ─── Charger le feed selon l'onglet actif ─────────────────────────────────

  void loadFeed() {
    state = FeedLoading();
    _feedSubscription?.cancel();

    final stream = _currentTab == FeedTab.forYou
        ? _postRepository.getGlobalFeed()
        : _postRepository.getFollowingFeed(followingIds: _followingIds);

    _feedSubscription = stream.listen(
      (posts) => state = FeedLoaded(posts: posts),
      onError: (e) => state = FeedError('Impossible de charger le fil : $e'),
    );
  }

  // ─── Mettre à jour les IDs suivis (pour l'onglet Abonnements) ─────────────

  void updateFollowingIds(List<String> ids) {
    _followingIds = ids;
    if (_currentTab == FeedTab.following) loadFeed();
  }

  // ─── Liker / Unliker ──────────────────────────────────────────────────────

  Future<void> toggleLike(String postId) async {
    if (_currentUserId == null) return;
    try {
      await _postRepository.toggleLike(
        postId: postId,
        userId: _currentUserId!,
      );
    } catch (_) {}
  }

  // ─── Vérifier si l'user a liké un post ───────────────────────────────────

  Future<bool> isLiked(String postId) async {
    if (_currentUserId == null) return false;
    return _postRepository.isLiked(postId: postId, userId: _currentUserId!);
  }

  // ─── Vérifier si l'user a reposté un post ────────────────────────────────

  Future<bool> isReposted(String postId) async {
    if (_currentUserId == null) return false;
    return _postRepository.isReposted(postId: postId, userId: _currentUserId!);
  }

  // ─── Créer un post ────────────────────────────────────────────────────────

  Future<bool> createPost({
    required String content,
    List<String> mediaURLs = const [],
    String? clanId,
  }) async {
    if (_currentUserId == null) return false;
    try {
      await _postRepository.createPost(
        authorId: _currentUserId!,
        content: content,
        mediaURLs: mediaURLs,
        clanId: clanId,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Republier un post ────────────────────────────────────────────────────

  Future<bool> repostPost({
    required String originalPostId,
    String? repostComment,
  }) async {
    if (_currentUserId == null) return false;
    try {
      await _postRepository.repostPost(
        authorId: _currentUserId!,
        originalPostId: originalPostId,
        repostComment: repostComment,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Supprimer un post ────────────────────────────────────────────────────

  Future<bool> deletePost(String postId) async {
    if (_currentUserId == null) return false;
    try {
      await _postRepository.deletePost(
        postId: postId,
        userId: _currentUserId!,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _feedSubscription?.cancel();
    super.dispose();
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository();
});

final feedViewModelProvider =
    StateNotifierProvider<FeedViewModel, FeedState>((ref) {
  final postRepository = ref.watch(postRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  return FeedViewModel(postRepository, currentUser?.uid);
});

/// Provider pour l'onglet actif du feed
final feedTabProvider = Provider<FeedTab>((ref) {
  final vm = ref.watch(feedViewModelProvider.notifier);
  return vm.currentTab;
});

/// Provider pour les likes — cache local pour éviter trop d'appels Firestore
final likedPostsProvider =
    StateProvider<Map<String, bool>>((ref) => {});