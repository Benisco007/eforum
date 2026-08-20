import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../data/repositories/user_repository.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/services/storage_service.dart';

const _ink     = Color(0xFF07090F);
const _surface = Color(0xFF0E1119);
const _card    = Color(0xFF131824);
const _line    = Color(0xFF1C2236);
const _neon    = Color(0xFF00E676);
const _txt     = Color(0xFFCDD5F0);
const _mut     = Color(0xFF485070);
const _red     = Color(0xFFFF5252);

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _usernameController  = TextEditingController();
  final _bioController       = TextEditingController();
  final _favPlayerController = TextEditingController();

  bool    _isSaving         = false;
  String? _errorMessage;
  String? _usernameError;
  bool    _checkingUsername = false;
  File?   _selectedImage;
  bool    _uploadingPhoto   = false;

  @override
  void initState() {
    super.initState();
    _prefillFields();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _favPlayerController.dispose();
    super.dispose();
  }

  void _prefillFields() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    _usernameController.text = user.username;
    _bioController.text      = user.bio ?? '';
    _favPlayerController.text = user.favPlayerName ?? '';
  }

  // ─── Pick & upload photo ──────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600, maxHeight: 600, imageQuality: 80,
    );
    if (picked == null) return;

    setState(() {
      _selectedImage  = File(picked.path);
      _uploadingPhoto = true;
    });

    final user = ref.read(currentUserProvider);
    if (user == null) { setState(() => _uploadingPhoto = false); return; }

    try {
      final url = await StorageService().uploadAvatar(user.uid, _selectedImage!);
      if (url != null) {
        await UserRepository().updateProfile(uid: user.uid, photoURL: url);
        await ref.read(authViewModelProvider.notifier).refreshUser();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo mise à jour ✅'),
              backgroundColor: Color(0xFF00E676)));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de l\'upload'),
              backgroundColor: Color(0xFFEF5350)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'),
            backgroundColor: const Color(0xFFEF5350)));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // ─── Vérification username ────────────────────────────────────────────────

  void _onUsernameChanged() {
    final username        = _usernameController.text.trim();
    final currentUsername = ref.read(currentUserProvider)?.username;

    setState(() => _usernameError = null);
    if (username.isEmpty || username == currentUsername) return;

    if (username.length < 3) {
      setState(() => _usernameError = 'Minimum 3 caractères'); return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username)) {
      setState(() => _usernameError = 'Lettres, chiffres et _ uniquement'); return;
    }

    setState(() => _checkingUsername = true);
    Future.delayed(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      if (_usernameController.text.trim() != username) return;
      final available = await UserRepository().isUsernameAvailable(username);
      if (!mounted) return;
      setState(() {
        _checkingUsername = false;
        _usernameError = available ? null : 'Ce pseudo est déjà pris';
      });
    });
  }

  // ─── Sauvegarder ──────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() { _errorMessage = null; _isSaving = true; });

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final username  = _usernameController.text.trim();
    final bio       = _bioController.text.trim();
    final favPlayer = _favPlayerController.text.trim();

    if (username.isEmpty) {
      setState(() { _errorMessage = 'Le pseudo ne peut pas être vide.'; _isSaving = false; });
      return;
    }
    if (_usernameError != null) {
      setState(() { _errorMessage = _usernameError; _isSaving = false; });
      return;
    }

    try {
      await UserRepository().updateProfile(
        uid:          user.uid,
        username:     username  != user.username           ? username  : null,
        bio:          bio       != (user.bio ?? '')        ? bio       : null,
        favPlayerName:favPlayer != (user.favPlayerName??'')? favPlayer : null,
      );
      await ref.read(authViewModelProvider.notifier).refreshUser();
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: _neon, size: 18),
            SizedBox(width: 8),
            Text('Profil mis à jour !', style: TextStyle(color: _txt)),
          ]),
          backgroundColor: _card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      setState(() { _errorMessage = 'Erreur : $e'; _isSaving = false; });
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    // Calcul de l'image à afficher dans l'avatar
    final DecorationImage? avatarImage = _selectedImage != null
        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
        : user?.photoURL != null
            ? DecorationImage(
                image: NetworkImage(
                    '${user!.photoURL}?t=${DateTime.now().millisecondsSinceEpoch}'),
                fit: BoxFit.cover)
            : null;

    return Scaffold(
      backgroundColor: _ink,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ───────────────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _uploadingPhoto ? null : _pickPhoto,
                      child: Stack(
                        children: [
                          Container(
                            width: 90, height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _neon.withOpacity(0.12),
                              border: Border.all(color: _line, width: 2),
                              image: avatarImage,
                            ),
                            child: _uploadingPhoto
                                ? const Center(child: CircularProgressIndicator(
                                    color: _neon, strokeWidth: 2))
                                : avatarImage == null
                                    ? const Center(child: Icon(
                                        Icons.person_rounded, color: _neon, size: 42))
                                    : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color: _neon, shape: BoxShape.circle,
                                border: Border.all(color: _ink, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: _ink, size: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(child: Text('Appuie pour changer',
                      style: TextStyle(fontSize: 11.5, color: _mut))),

                  const SizedBox(height: 28),

                  // ── Pseudo ────────────────────────────────────────────────
                  _buildLabel('Pseudo'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _usernameController,
                    hint: 'ibra_efc',
                    icon: Icons.person_outline_rounded,
                    suffix: _checkingUsername
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _mut))
                        : _usernameError == null &&
                                _usernameController.text.trim().length >= 3
                            ? const Icon(Icons.check_circle_rounded, color: _neon, size: 18)
                            : null,
                  ),
                  if (_usernameError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(_usernameError!,
                          style: const TextStyle(fontSize: 12, color: _red)),
                    ),

                  const SizedBox(height: 20),

                  // ── Bio ───────────────────────────────────────────────────
                  _buildLabel('Bio'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _bioController,
                    hint: 'Div. 1 · Bénin 🇧🇯 · Fan de eFootball',
                    icon: Icons.edit_outlined,
                    maxLines: 3,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${_bioController.text.length}/120',
                          style: const TextStyle(fontSize: 11, color: _mut)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Joueur préféré ────────────────────────────────────────
                  _buildLabel('Joueur eFootball préféré'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _favPlayerController,
                    hint: 'ex: Mbappé, Haaland, Vinicius Jr...',
                    icon: Icons.sports_soccer_rounded,
                  ),

                  const SizedBox(height: 12),

                  // ── Erreur ────────────────────────────────────────────────
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _red.withOpacity(0.4)),
                      ),
                      child: Text(_errorMessage!,
                          style: const TextStyle(fontSize: 13, color: _red)),
                    ),

                  const SizedBox(height: 32),

                  // ── Bouton sauvegarder ────────────────────────────────────
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _neon, foregroundColor: _ink,
                        disabledBackgroundColor: _line,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: _ink))
                          : const Text('Sauvegarder',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _line))),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const SizedBox(width: 44, height: 44,
                child: Icon(Icons.close_rounded, color: _txt, size: 22)),
          ),
          const Expanded(
            child: Center(child: Text('Modifier le profil',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _txt))),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: _txt, letterSpacing: 0.2));

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: TextField(
        controller: controller, maxLines: maxLines,
        style: const TextStyle(fontSize: 15, color: _txt),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _mut),
          prefixIcon: Icon(icon, color: _mut, size: 20),
          suffixIcon: suffix != null
              ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}