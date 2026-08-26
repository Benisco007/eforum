import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../viewmodels/auth_viewmodel.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';
import '../../core/constants/firebase_constants.dart';

const _ink     = Color(0xFF07090F);
const _surface = Color(0xFF0E1119);
const _card    = Color(0xFF131824);
const _line    = Color(0xFF1C2236);
const _neon    = Color(0xFF00E676);
const _txt     = Color(0xFFCDD5F0);
const _mut     = Color(0xFF485070);

// ═══════════════════════════════════════════════════════════════════════════════
// COMMENTS SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class CommentsScreen extends ConsumerStatefulWidget {
  final PostModel post;
  const CommentsScreen({super.key, required this.post});

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final _commentController = TextEditingController();
  final _scrollController  = ScrollController();
  bool _isSending = false;
  String? _replyToCommentId;
  String? _replyToUsername;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSending) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSending = true);
    _commentController.clear();

    try {
      await PostRepository().addComment(
            postId:          widget.post.postId,
            authorId:        currentUser.uid,
            content:         content,
            parentCommentId: _replyToCommentId,
            );
            setState(() {
            _replyToCommentId = null;
            _replyToUsername  = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
            child: ListView(
              controller: _scrollController,
              children: [
                _buildPostSummary(),
                const Divider(color: _line, height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    'COMMENTAIRES · ${widget.post.commentsCount}',
                    style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: _mut, letterSpacing: 2,
                    ),
                  ),
                ),
                _buildCommentsList(),
              ],
            ),
          ),
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const SizedBox(
              width: 44, height: 44,
              child: Icon(Icons.chevron_left_rounded, color: _txt, size: 26),
            ),
          ),
          const Text(
            'Commentaires',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _txt),
          ),
        ],
      ),
    );
  }

  Widget _buildPostSummary() {
    final post = widget.post;
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection(FirebaseConstants.users)
          .doc(post.authorId)
          .get(),
      builder: (context, snap) {
        final data     = snap.data?.data() as Map<String, dynamic>?;
        final username = data?['username'] as String? ?? '...';
        final photoURL = data?['photoURL'] as String?;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 40,
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
                    ? const Center(child: Icon(Icons.person_rounded, color: _neon, size: 20))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(username,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: _txt)),
                        const SizedBox(width: 6),
                         Text(
                          '${timeago.format(post.createdAt.toDate(), locale: 'fr')}${post.updatedAt != null ? ' (modifié)' : ''}',
                          style: const TextStyle(fontSize: 12, color: _mut),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(post.content,
                        style: const TextStyle(fontSize: 14, color: _txt, height: 1.5),
                        maxLines: 4, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.favorite_border_rounded, color: _mut, size: 14),
                        const SizedBox(width: 4),
                        Text('${post.likesCount}',
                            style: const TextStyle(fontSize: 12, color: _mut)),
                        const SizedBox(width: 12),
                        const Icon(Icons.chat_bubble_outline_rounded, color: _neon, size: 14),
                        const SizedBox(width: 4),
                        Text('${post.commentsCount} commentaires',
                            style: const TextStyle(fontSize: 12, color: _neon)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.posts)
          .doc(widget.post.postId)
          .collection(FirebaseConstants.comments)
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: _neon, strokeWidth: 2)),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Text('💬', style: TextStyle(fontSize: 36)),
                  SizedBox(height: 12),
                  Text('Aucun commentaire pour l\'instant.',
                      style: TextStyle(color: _mut, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('Sois le premier à réagir !',
                      style: TextStyle(color: _mut, fontSize: 12)),
                ],
              ),
            ),
          );
        }
        // Séparer commentaires racine et réponses
final roots   = docs.where((d) => (d.data() as Map)['parentCommentId'] == null).toList();
final replies = docs.where((d) => (d.data() as Map)['parentCommentId'] != null).toList();

return Column(
  children: roots.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    final children = replies.where((r) =>
        (r.data() as Map)['parentCommentId'] == doc.id).toList();
        return Column(
        children: [
            _CommentCard(
            commentId: doc.id,
            postId:    widget.post.postId,
            data:      data,
            onReply:   (commentId, username) {
                setState(() {
                _replyToCommentId = commentId;
                _replyToUsername  = username;
                });
            },
            ),
            // Réponses imbriquées avec indentation
            ...children.map((child) {
            final childData = child.data() as Map<String, dynamic>;
            return Padding(
                padding: const EdgeInsets.only(left: 48),
                child: _CommentCard(
                commentId: child.id,
                postId:    widget.post.postId,
                data:      childData,
                onReply:   (commentId, username) {
                    setState(() {
                    _replyToCommentId = commentId;
                    _replyToUsername  = username;
                    });
                },
                ),
            );
            }),
        ],
        );
    }).toList(),
        );
      },
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            if (_replyToUsername != null)
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                color: _surface,
                border: Border(top: BorderSide(color: _line)),
                ),
                child: Row(
                children: [
                    const Icon(Icons.reply_rounded, color: _neon, size: 14),
                    const SizedBox(width: 6),
                    Text(
                    'Réponse à @$_replyToUsername',
                    style: const TextStyle(fontSize: 12, color: _neon, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    GestureDetector(
                    onTap: () => setState(() {
                        _replyToCommentId = null;
                        _replyToUsername  = null;
                    }),
                    child: const Icon(Icons.close_rounded, color: _mut, size: 16),
                    ),
                ],
                ),
            ),
        Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _line)),
      ),
      padding: EdgeInsets.fromLTRB(
        12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _neon.withOpacity(0.12),
              border: Border.all(color: _line),
              image: currentUser?.photoURL != null
                  ? DecorationImage(
                      image: NetworkImage(currentUser!.photoURL!), fit: BoxFit.cover)
                  : null,
            ),
            child: currentUser?.photoURL == null
                ? const Center(child: Icon(Icons.person_rounded, color: _neon, size: 18))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 40, maxHeight: 100),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: TextField(
                controller: _commentController,
                maxLines: null,
                style: const TextStyle(fontSize: 14, color: _txt),
                decoration: const InputDecoration(
                  hintText: 'Ajoute un commentaire…',
                  hintStyle: TextStyle(color: _mut, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSending ? null : _sendComment,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _neon,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(color: _neon.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 4)),
                ],
              ),
              child: _isSending
                  ? const Center(
                      child: SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: _ink, size: 18),
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
// COMMENT CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _CommentCard extends StatelessWidget {
  final String commentId;
  final String postId;
  final Map<String, dynamic> data;
  final void Function(String commentId, String username) onReply;

  const _CommentCard({
    required this.commentId,
    required this.postId,
    required this.data,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final authorId  = data['authorId'] as String? ?? '';
    final content   = data['content']  as String? ?? '';
    final createdAt = data['createdAt'];
    final DateTime? date = createdAt is Timestamp ? createdAt.toDate() : null;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(authorId).get(),
      builder: (context, snap) {
        final userData = snap.data?.data() as Map<String, dynamic>?;
        final username = userData?['username'] as String? ?? '...';
        final photoURL = userData?['photoURL'] as String?;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _line)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.push('/profile/$authorId'),
                child: Container(
                  width: 36, height: 36,
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
                      ? const Center(child: Icon(Icons.person_rounded, color: _neon, size: 18))
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/profile/$authorId'),
                          child: Text(username,
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w700, color: _txt)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          date != null
                              ? timeago.format(date, locale: 'fr')
                              : 'à l\'instant',
                          style: const TextStyle(fontSize: 11.5, color: _mut),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(content,
                        style: const TextStyle(fontSize: 14, color: _txt, height: 1.45)),
                    const SizedBox(height: 6),
                    Row(
                    children: [
                        _CommentLikeButton(
                        commentId:    commentId,
                        postId:       postId,
                        initialLikes: (data['likesCount'] as num? ?? 0).toInt(),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                        onTap: () => onReply(commentId, username),
                        child: const Text('Répondre',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _neon)),
                        ),
                    ],
                    ),
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
// COMMENT LIKE BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _CommentLikeButton extends ConsumerStatefulWidget {
  final String commentId;
  final String postId;
  final int    initialLikes;

  const _CommentLikeButton({
    required this.commentId,
    required this.postId,
    required this.initialLikes,
  });

  @override
  ConsumerState<_CommentLikeButton> createState() => _CommentLikeButtonState();
}

class _CommentLikeButtonState extends ConsumerState<_CommentLikeButton> {
  bool _liked = false;
  late int _likes;

  @override
  void initState() {
    super.initState();
    _likes = widget.initialLikes;
    _checkLiked();
  }

  Future<void> _checkLiked() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    final doc = await FirebaseFirestore.instance
        .collection(FirebaseConstants.posts)
        .doc(widget.postId)
        .collection(FirebaseConstants.comments)
        .doc(widget.commentId)
        .collection('likes')
        .doc(currentUser.uid)
        .get();
    if (mounted) setState(() => _liked = doc.exists);
  }

  Future<void> _toggleLike() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final likeRef = FirebaseFirestore.instance
        .collection(FirebaseConstants.posts)
        .doc(widget.postId)
        .collection(FirebaseConstants.comments)
        .doc(widget.commentId)
        .collection('likes')
        .doc(currentUser.uid);

    final commentRef = FirebaseFirestore.instance
        .collection(FirebaseConstants.posts)
        .doc(widget.postId)
        .collection(FirebaseConstants.comments)
        .doc(widget.commentId);

    final batch = FirebaseFirestore.instance.batch();

    if (_liked) {
      batch.delete(likeRef);
      batch.update(commentRef, {'likesCount': FieldValue.increment(-1)});
      setState(() { _liked = false; _likes--; });
    } else {
      batch.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
      batch.update(commentRef, {'likesCount': FieldValue.increment(1)});
      setState(() { _liked = true; _likes++; });
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: _toggleLike,
          child: Icon(
            _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: _liked ? const Color(0xFFFF5A7A) : _mut,
            size: 14,
          ),
        ),
        const SizedBox(width: 4),
        Text('$_likes', style: const TextStyle(fontSize: 12, color: _mut)),
      ],
    );
  }
}