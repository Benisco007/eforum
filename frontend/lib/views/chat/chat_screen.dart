import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/constants/firebase_constants.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';

// ─── Couleurs eForum ──────────────────────────────────────────────────────────

const _ink     = Color(0xFF07090F);
const _surface = Color(0xFF0E1119);
const _card    = Color(0xFF131824);
const _line    = Color(0xFF1C2236);
const _neon    = Color(0xFF00E676);
const _txt     = Color(0xFFCDD5F0);
const _mut     = Color(0xFF485070);
const _chat    = Color(0xFFFF8A65);

// ─── Générer un conversationId stable depuis deux UIDs ────────────────────────

String generateConversationId(String uid1, String uid2) {
  final sorted = [uid1, uid2]..sort();
  final bytes = utf8.encode('${sorted[0]}_${sorted[1]}');
  return md5.convert(bytes).toString();
}

// ═══════════════════════════════════════════════════════════════════════════════
// MESSAGES LIST SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
          Expanded(
            child: currentUser == null
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _neon, strokeWidth: 2))
                : _buildConversationList(currentUser.uid),
          ),
        ],
      ),
      floatingActionButton: currentUser == null
          ? null
          : GestureDetector(
              onTap: () => _showNewMessageSheet(context, currentUser.uid),
              child: _buildFAB(),
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
          // Titre
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.chevron_left_rounded,
                        color: _txt, size: 26),
                  ),
                ),
                const Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _txt,
                  ),
                ),
                const Spacer(),
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
                        hintText: 'Rechercher une conversation…',
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

          // Tabs pill
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: ['Tous', 'Non lus'].asMap().entries.map((e) {
                final isActive = _tabController.index == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _tabController.index = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _chat.withOpacity(0.15)
                          : _card,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: isActive
                            ? _chat.withOpacity(0.5)
                            : _line,
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isActive ? _chat : _mut,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Liste conversations Firestore ─────────────────────────────────────────
Widget _buildConversationList(String uid) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection(FirebaseConstants.conversations)
        .where('participants', arrayContains: uid)
        .limit(30)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(color: _neon, strokeWidth: 2),
        );
      }

      final docs = snapshot.data?.docs ?? [];

      var filtered = [...docs];
      if (_tabController.index == 1) {
        filtered = filtered.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final unreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[uid] ?? 0;
          return unreadCount > 0;
        }).toList();
      }

      if (filtered.isEmpty) {
        return _buildEmpty();
      }

      // Tri côté client — évite le flash causé par orderBy + serverTimestamp
      final sorted = [...filtered];
      sorted.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aTs = aData['lastMessageAt'];
        final bTs = bData['lastMessageAt'];
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        final aDate = (aTs as Timestamp).toDate();
        final bDate = (bTs as Timestamp).toDate();
        return bDate.compareTo(aDate);
      });

      return ListView(
        children: [
          ...sorted.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _ConvCard(
              data: data,
              currentUserId: uid,
              onTap: () {
                final participants =
                    List<String>.from(data['participants'] ?? []);
                final otherId = participants.firstWhere(
                    (id) => id != uid,
                    orElse: () => '');
                if (otherId.isEmpty) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      conversationId: doc.id,
                      otherUserId: otherId,
                      otherUsername: data['otherUsername'] ?? 'Joueur',
                    ),
                  ),
                );
              },
            );
          }),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                '🔒 Les messages sont chiffrés entre membres eForum',
                style: TextStyle(fontSize: 12.5, color: _mut),
              ),
            ),
          ),
        ],
      );
    },
  );
}
  
  // ─── État vide ─────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _chat.withOpacity(0.08),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: _chat, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune conversation',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _txt),
          ),
          const SizedBox(height: 8),
          const Text(
            'Envoie un message à un joueur\npour démarrer une conversation.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _mut, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ─── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _chat,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _chat.withOpacity(0.55),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.add_rounded,
          color: Color(0xFF2A0D02), size: 28),
    );
  }

  void _showNewMessageSheet(BuildContext context, String currentUserId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewConversationSheet(currentUserId: currentUserId),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NEW CONVERSATION SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _NewConversationSheet extends StatefulWidget {
  final String currentUserId;
  const _NewConversationSheet({required this.currentUserId});

  @override
  State<_NewConversationSheet> createState() => _NewConversationSheetState();
}

class _NewConversationSheetState extends State<_NewConversationSheet> {
  final _ctrl = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _searching = false;
  bool _loadingFollowing = true;
  List<UserModel> _followingUsers = [];

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadFollowing() async {
    try {
      final followingIds = await UserRepository().getFollowingIds(widget.currentUserId);
      if (followingIds.isEmpty) {
        if (mounted) setState(() => _loadingFollowing = false);
        return;
      }
      final List<UserModel> users = [];
      for (final id in followingIds) {
        final u = await UserRepository().getUserById(id);
        if (u != null) users.add(u);
      }
      if (mounted) {
        setState(() {
          _followingUsers = users;
          _loadingFollowing = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFollowing = false);
    }
  }

  Future<void> _onSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await UserRepository().searchUsers(q);
      final filteredResults = results.where((u) => u.uid != widget.currentUserId).toList();
      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _startConversation(UserModel otherUser) async {
    final ids = [widget.currentUserId, otherUser.uid]..sort();
    final convId = '${ids[0]}_${ids[1]}';

    final ref = FirebaseFirestore.instance
        .collection(FirebaseConstants.conversations)
        .doc(convId);
    
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'participants': [widget.currentUserId, otherUser.uid],
        'lastMessage': null,
        'lastMessageAt': null,
        'unreadCount': {widget.currentUserId: 0, otherUser.uid: 0},
      });
    }

    if (mounted) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convId,
            otherUserId: otherUser.uid,
            otherUsername: otherUser.username,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isSearching = _ctrl.text.trim().isNotEmpty;
    final displayList = isSearching ? _searchResults : _followingUsers;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nouveau message',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _txt),
          ),
          const SizedBox(height: 16),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, color: _mut, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(fontSize: 14, color: _txt),
                    onChanged: _onSearch,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un joueur par son nom...',
                      hintStyle: TextStyle(color: _mut, fontSize: 13.5),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'RÉSULTATS DE RECHERCHE' : 'ABONNEMENTS',
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _mut, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _searching || (_loadingFollowing && !isSearching)
                ? const Center(child: CircularProgressIndicator(color: _chat, strokeWidth: 2))
                : displayList.isEmpty
                    ? Center(
                        child: Text(
                          isSearching ? 'Aucun joueur trouvé' : 'Abonne-toi à des joueurs pour leur écrire',
                          style: const TextStyle(color: _mut, fontSize: 13.5),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final user = displayList[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _neon.withOpacity(0.12),
                                border: Border.all(color: _line),
                                image: user.photoURL != null
                                    ? DecorationImage(image: NetworkImage(user.photoURL!), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: user.photoURL == null
                                  ? const Icon(Icons.person_rounded, color: _neon, size: 18)
                                  : null,
                            ),
                            title: Text(
                              user.username,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _txt),
                            ),
                            subtitle: Text(
                              '@${user.username}',
                              style: const TextStyle(fontSize: 12, color: _mut),
                            ),
                            onTap: () => _startConversation(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONVERSATION CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ConvCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String currentUserId;
  final VoidCallback onTap;

  const _ConvCard({
    required this.data,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[currentUserId] ?? 0;
    final hasUnread = unreadCount > 0;
    final lastMessage = data['lastMessage'] as String? ?? '';
    final lastMessageAt = data['lastMessageAt'];
    final DateTime? date = lastMessageAt is Timestamp
        ? lastMessageAt.toDate()
        : null;
    final participants = List<String>.from(data['participants'] ?? []);
      final otherUserId = participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: hasUnread ? _neon.withOpacity(0.035) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: _line)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar avec point en ligne
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _neon.withOpacity(0.12),
                    border: Border.all(color: _line),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: _neon, size: 24),
                ),
                if (hasUnread)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _neon,
                        border: Border.all(color: _ink, width: 2.5),
                      ),
                    ),
                  ),
              ],
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
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserId)
                            .get(),
                        builder: (context, snap) {
                          String name = '...';
                          if (snap.hasData && snap.data!.exists) {
                            final d = snap.data!.data() as Map<String, dynamic>?;
                            name = d?['username'] as String? ?? 'Joueur';
                          }
                          return Text(
                            name,
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: _txt),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                    if (date != null)
                      Text(
                        timeago.format(date, locale: 'fr'),
                        style: const TextStyle(fontSize: 11.5, color: _mut),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lastMessage,
                        style: TextStyle(
                          fontSize: 13,
                          color: hasUnread ? _txt.withOpacity(0.9) : _mut,
                          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _neon,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF05210F),
                          ),
                        ),
                      ),
                  ],
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
// CHAT SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUsername;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final batch = FirebaseFirestore.instance.batch();
      final convRef = FirebaseFirestore.instance
          .collection(FirebaseConstants.conversations)
          .doc(widget.conversationId);

      final msgRef = convRef
          .collection(FirebaseConstants.messages)
          .doc();

      batch.set(msgRef, {
        'messageId': msgRef.id,
        'conversationId': widget.conversationId,
        'senderId': currentUser.uid,
        'content': content,
        'sentAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      batch.set(convRef, {
        'participants': [currentUser.uid, widget.otherUserId],
        'lastMessage': content,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'otherUsername': widget.otherUsername,
        'unreadCount': {
          widget.otherUserId: FieldValue.increment(1),
          currentUser.uid: 0,
        },
      }, SetOptions(merge: true));

      await batch.commit();

      // Scroll vers le bas
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: _ink,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),

          // ── Header ────────────────────────────────────────────────────────
          _buildHeader(context),

          // ── Messages ──────────────────────────────────────────────────────
          Expanded(
            child: currentUser == null
                ? const SizedBox()
                : _buildMessages(currentUser.uid),
          ),

          // ── Zone de saisie ────────────────────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: const BoxDecoration(
      color: _ink,
      border: Border(bottom: BorderSide(color: _line)),
    ),
    child: Row(
      children: [
        // Retour
        GestureDetector(
          onTap: () => context.pop(),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.chevron_left_rounded, color: _txt, size: 26),
          ),
        ),

        // Avatar
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _chat.withOpacity(0.15),
            border: Border.all(color: _line),
          ),
          child: const Icon(Icons.person_rounded, color: _chat, size: 20),
        ),

        const SizedBox(width: 10),

        // Nom + handle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUsername,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _txt,
                ),
              ),
              Text(
                '@${widget.otherUsername}',
                style: const TextStyle(fontSize: 11.5, color: _mut),
              ),
            ],
          ),
        ),

        // Menu
        GestureDetector(
          onTap: () {},
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.more_horiz_rounded, color: _mut, size: 22),
          ),
        ),
      ],
    ),
  );
}

  // ─── Liste des messages ────────────────────────────────────────────────────

  Widget _buildMessages(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.conversations)
          .doc(widget.conversationId)
          .collection(FirebaseConstants.messages)
          .orderBy('sentAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _neon, strokeWidth: 2),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👋', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 12),
                Text(
                  'Dis bonjour à ${widget.otherUsername} !',
                  style: const TextStyle(color: _mut, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: docs.length + 1,
          itemBuilder: (context, index) {
            // Label date
            if (index == 0) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _DateLabel(label: "Aujourd'hui"),
                ),
              );
            }

            final data = docs[index - 1].data() as Map<String, dynamic>;
            final isMe = data['senderId'] == currentUserId;
            final content = data['content'] as String? ?? '';
            final sentAt = data['sentAt'];
            final DateTime? date =
                sentAt is Timestamp ? sentAt.toDate() : null;

            return _MessageBubble(
              content: content,
              isMe: isMe,
              time: date != null
                  ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                  : '',
            );
          },
        );
      },
    );
  }

  // ─── Barre de saisie ───────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _line)),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bouton image
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _line),
            ),
            child: const Icon(Icons.image_outlined, color: _mut, size: 20),
          ),

          const SizedBox(width: 8),

          // Champ texte
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                style: const TextStyle(fontSize: 14, color: _txt),
                decoration: const InputDecoration(
                  hintText: 'Écris un message…',
                  hintStyle: TextStyle(color: _mut, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Bouton envoyer
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _neon,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _neon.withOpacity(0.55),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isSending
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _ink,
                        ),
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Color(0xFF05210F), size: 20),
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

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final String time;

  const _MessageBubble({
    required this.content,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar interlocuteur
              if (!isMe) ...[
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _chat.withOpacity(0.15),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: _chat, size: 14),
                ),
              ],

              // Bulle
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.74,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? _neon : _card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: _line),
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? const Color(0xFF05210F) : _txt,
                      fontWeight: isMe ? FontWeight.w500 : FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Heure
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isMe ? 0 : 32,
              right: 0,
            ),
            child: Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(fontSize: 10.5, color: _mut),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_rounded, color: _neon, size: 13),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  final String label;
  const _DateLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: _mut,
        ),
      ),
    );
  }
}