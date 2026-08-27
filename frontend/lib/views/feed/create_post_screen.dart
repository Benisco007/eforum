import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/services/storage_service.dart';
import '../builds/builds_screen.dart';
import '../polls/polls_screen.dart';

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

const int _maxChars = 280;

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _focusNode         = FocusNode();
  bool  _isPublishing      = false;
  File? _selectedImage;
  bool  _uploadingImage    = false;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int    get _charCount    => _contentController.text.length;
  bool   get _canPublish   => _charCount > 0 && _charCount <= _maxChars && !_isPublishing;
  double get _charProgress => math.min(_charCount / _maxChars, 1.0);

  Color get _counterColor {
    if (_charProgress >= 1.0)   return const Color(0xFFFF5252);
    if (_charProgress >= 0.85)  return _clan;
    return _mut;
  }

  // ─── Sélectionner une image ───────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080, imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _selectedImage = File(picked.path));
  }

  // ─── Publier ──────────────────────────────────────────────────────────────

  Future<void> _publish() async {
    if (!_canPublish) return;
    setState(() => _isPublishing = true);

    List<String> mediaURLs = [];
    if (_selectedImage != null) {
      setState(() => _uploadingImage = true);
      final url = await StorageService()
          .uploadPostImage(const Uuid().v4(), _selectedImage!);
      if (url != null) mediaURLs = [url];
      setState(() => _uploadingImage = false);
    }

    final success = await ref.read(feedViewModelProvider.notifier).createPost(
      content:   _contentController.text.trim(),
      mediaURLs: mediaURLs,
    );

    if (!mounted) return;

    if (success) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: _neon, size: 18),
          SizedBox(width: 8),
          Text('Post publié !', style: TextStyle(color: _txt)),
        ]),
        backgroundColor: _card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Erreur lors de la publication.',
            style: TextStyle(color: Color(0xFFFF5252))),
        backgroundColor: _card,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: _ink,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zone de rédaction
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(currentUser?.photoURL),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.username ?? 'joueur',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: _txt),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _contentController,
                              focusNode: _focusNode,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              style: const TextStyle(
                                  fontSize: 16, color: _txt, height: 1.55),
                              decoration: const InputDecoration(
                                hintText: 'Partage ton build, ton résultat, ton avis...',
                                hintStyle: TextStyle(
                                    color: _mut, fontSize: 16, height: 1.55),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Aperçu image sélectionnée
                  if (_selectedImage != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!,
                              width: double.infinity, height: 200, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: _txt, size: 16),
                            ),
                          ),
                        ),
                        if (_uploadingImage)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(child: CircularProgressIndicator(
                                  color: _neon, strokeWidth: 2)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Section "Ajouter au post"
                  _buildAddToPost(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
            child: const SizedBox(width: 40, height: 40,
                child: Icon(Icons.close_rounded, color: _txt, size: 22)),
          ),
          const Expanded(
            child: Center(child: Text('Nouveau post',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _txt))),
          ),
          GestureDetector(
            onTap: _canPublish ? _publish : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: _canPublish ? _neon : _neon.withOpacity(0.25),
                borderRadius: BorderRadius.circular(99),
              ),
              child: _isPublishing
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _ink))
                  : Text('Publier',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800,
                          color: _canPublish ? _ink : _neon.withOpacity(0.5))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoURL) {
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _neon.withOpacity(0.15),
        border: Border.all(color: _line),
        image: photoURL != null
            ? DecorationImage(image: NetworkImage(photoURL), fit: BoxFit.cover)
            : null,
      ),
      child: photoURL == null
          ? const Center(child: Icon(Icons.person_rounded, color: _neon, size: 22))
          : null,
    );
  }

  Widget _buildAddToPost() {
    final actions = [
      {'icon': Icons.image_outlined, 'label': 'Image',    'color': _neon},
      {'icon': Icons.bolt_outlined,  'label': 'Un build', 'color': _build},
      {'icon': Icons.poll_rounded,   'label': 'Sondage',  'color': _chat},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AJOUTER AU POST',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: _mut, letterSpacing: 2)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10, mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.2,
            children: actions.map((action) {
              final color  = action['color'] as Color;
              final label  = action['label'] as String;
              final isImage = label == 'Image';
              return GestureDetector(
                onTap: () {
                  if (label == 'Image') {
                    _pickImage();
                  } else if (label == 'Un build') {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const CreateBuildSheet(),
                    );
                  } else if (label == 'Sondage') {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const CreatePollSheet(),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isImage && _selectedImage != null
                        ? color.withOpacity(0.12)
                        : _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isImage && _selectedImage != null
                          ? color.withOpacity(0.4)
                          : _line),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(action['icon'] as IconData, color: color, size: 18),
                      const SizedBox(width: 8),
                      Text(label,
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600, color: _txt)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final remaining = _maxChars - _charCount;
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _line)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Icon(Icons.image_outlined, color: _neon, size: 22),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const CreateBuildSheet(),
              );
            },
            child: Icon(Icons.bolt_outlined, color: _build, size: 22),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const CreatePollSheet(),
              );
            },
            child: Icon(Icons.poll_rounded, color: _chat, size: 22),
          ),
          const Spacer(),
          if (_charCount > 0) ...[
            Text(
              remaining >= 0 ? '$remaining' : '${remaining.abs()} en trop',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: _counterColor),
            ),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 26, height: 26,
            child: CustomPaint(painter: _CircleProgressPainter(
                progress: _charProgress, color: _counterColor)),
          ),
        ],
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color  color;
  _CircleProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    canvas.drawCircle(center, radius,
        Paint()..color = _line..style = PaintingStyle.stroke..strokeWidth = 2.5);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 2 * math.pi * progress, false,
      Paint()
        ..color = color..style = PaintingStyle.stroke
        ..strokeWidth = 2.5..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) =>
      old.progress != progress || old.color != color;
}