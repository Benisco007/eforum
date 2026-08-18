import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/router/app_router.dart';
import '../../widgets/common/grid_background.dart';
import '../../widgets/common/eforum_logo.dart';

// ─── Couleurs ─────────────────────────────────────────────────────────────────

const _ink    = Color(0xFF07090F);
const _card   = Color(0xFF131824);
const _line   = Color(0xFF1C2236);
const _neon   = Color(0xFF00E676);
const _txt    = Color(0xFFCDD5F0);
const _mut    = Color(0xFF485070);
const _red    = Color(0xFFFF5252);

// ─── Clés SharedPreferences ───────────────────────────────────────────────────

const _kRememberMe = 'remember_me';
const _kSavedEmail = 'saved_email';

// ═══════════════════════════════════════════════════════════════════════════════
// LOGIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool    _passwordVisible = false;
  bool    _rememberMe      = false;
  bool    _isLoading       = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Charger email sauvegardé ──────────────────────────────────────────────

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_kRememberMe) ?? false;
    if (remember) {
      final email = prefs.getString(_kSavedEmail) ?? '';
      setState(() {
        _rememberMe = true;
        _emailController.text = email;
      });
    }
  }

  // ─── Sauvegarder / effacer email ──────────────────────────────────────────

  Future<void> _saveCredentials(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool(_kRememberMe, true);
      await prefs.setString(_kSavedEmail, email);
    } else {
      await prefs.remove(_kRememberMe);
      await prefs.remove(_kSavedEmail);
    }
  }

  // ─── Connexion ─────────────────────────────────────────────────────────────

  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
      _isLoading    = true;
    });

    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Remplis tous les champs.';
        _isLoading    = false;
      });
      return;
    }

    try {
      await ref.read(authViewModelProvider.notifier).login(
        email: email,
        password: password,
      );

      // Succès — sauvegarder si "se souvenir de moi"
      await _saveCredentials(email);

    } catch (_) {
      // Les erreurs sont gérées via ref.listen ci-dessous
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Mot de passe oublié ───────────────────────────────────────────────────

  void _showForgotPassword() {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    String? dialogError;
    bool    sending = false;
    bool    sent    = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _line),
          ),
          title: const Text(
            'Mot de passe oublié',
            style: TextStyle(
              color: _txt,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!sent) ...[
                const Text(
                  'Entre ton adresse email. Tu recevras un lien pour réinitialiser ton mot de passe.',
                  style: TextStyle(color: _mut, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _line),
                  ),
                  child: TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: _txt, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'ton@email.com',
                      hintStyle: TextStyle(color: _mut),
                      prefixIcon: Icon(Icons.mail_outline_rounded,
                          color: _mut, size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    dialogError!,
                    style: const TextStyle(color: _red, fontSize: 12),
                  ),
                ],
              ] else ...[
                // État succès
                const Center(
                  child: Icon(Icons.mark_email_read_outlined,
                      color: _neon, size: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Email envoyé ! Vérifie ta boîte de réception et clique sur le lien pour réinitialiser ton mot de passe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _txt, fontSize: 13, height: 1.5),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                sent ? 'Fermer' : 'Annuler',
                style: const TextStyle(color: _mut),
              ),
            ),
            if (!sent)
              TextButton(
                onPressed: sending
                    ? null
                    : () async {
                        final email = emailCtrl.text.trim();
                        if (email.isEmpty) {
                          setDialogState(
                              () => dialogError = 'Entre ton email.');
                          return;
                        }
                        setDialogState(() {
                          sending     = true;
                          dialogError = null;
                        });
                        final error = await ref
                            .read(authViewModelProvider.notifier)
                            .resetPassword(email);
                        if (error == null) {
                          setDialogState(() => sent = true);
                        } else {
                          setDialogState(() {
                            sending     = false;
                            dialogError =
                                'Aucun compte trouvé avec cet email.';
                          });
                        }
                      },
                child: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _neon),
                      )
                    : const Text(
                        'Envoyer',
                        style: TextStyle(
                          color: _neon,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    // Écoute les erreurs — affiche le message SANS passer par clearError()
    ref.listen(authViewModelProvider, (previous, next) {
      if (next is AuthError) {
        setState(() {
          _errorMessage = next.message;
          _isLoading    = false;
        });
        // On ne call plus clearError() ici — ça causait le flash vers splash
      }
    });

    return Scaffold(
      backgroundColor: _ink,
      body: GridBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Logo
                const EForumLogo(size: 48, hasGlow: false),
                const SizedBox(height: 20),

                // Titre
                const Text(
                  'Bon retour ! ⚽',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: _txt,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Connecte-toi pour retrouver ton clan et tes builds.',
                  style: TextStyle(fontSize: 14, color: _txt, height: 1.5),
                ),
                const SizedBox(height: 36),

                // ── Email ─────────────────────────────────────────────────
                _buildLabel('EMAIL'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hint: 'ibrahim.diallo@mail.sn',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // ── Mot de passe ──────────────────────────────────────────
                _buildLabel('MOT DE PASSE'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordController,
                  hint: '•••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscure: !_passwordVisible,
                  suffix: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _txt,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Se souvenir de moi + Mot de passe oublié ─────────────
                Row(
                  children: [
                    // Se souvenir de moi
                    GestureDetector(
                      onTap: () =>
                          setState(() => _rememberMe = !_rememberMe),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _rememberMe
                                  ? _neon
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: _rememberMe ? _neon : _mut,
                                width: 1.5,
                              ),
                            ),
                            child: _rememberMe
                                ? const Icon(Icons.check_rounded,
                                    color: _ink, size: 13)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Se souvenir de moi',
                            style: TextStyle(
                              fontSize: 13,
                              color: _txt,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Mot de passe oublié
                    GestureDetector(
                      onTap: _showForgotPassword,
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _neon,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Message d'erreur ──────────────────────────────────────
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x22FF5252),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x66FF5252)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: _red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                fontSize: 13, color: _red),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Bouton connexion ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x4D00E676),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _neon,
                      foregroundColor: _ink,
                      disabledBackgroundColor: _line,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: _ink,
                            ),
                          )
                        : const Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Carte communauté ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _ink,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _line),
                        ),
                        child: const Icon(Icons.sports_soccer,
                            color: _neon, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rejoignez des passionnés dès maintenant !',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _txt,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Sénégal · Mali · Côte d\'Ivoire · Bénin',
                              style:
                                  TextStyle(fontSize: 11, color: _mut),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── Lien inscription ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Pas encore de compte ? ',
                      style: TextStyle(fontSize: 14, color: _txt),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.register),
                      child: const Text(
                        'S\'inscrire',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _neon,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: _txt,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(fontSize: 15, color: _txt),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _mut),
          prefixIcon: Icon(icon, color: _txt, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}