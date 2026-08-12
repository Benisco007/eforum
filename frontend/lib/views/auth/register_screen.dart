import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/router/app_router.dart';
import '../../widgets/common/grid_background.dart';
import '../../widgets/common/eforum_logo.dart';

const String _googleSvgLogo = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.18 1.48-4.97 2.35-8.16 2.35-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late TapGestureRecognizer _termsRecognizer;
  bool _passwordVisible = false;
  bool _acceptedTerms = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _showTermsModal(context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _errorMessage = null);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validations locales sans le nom d'utilisateur (demandé ultérieurement)
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Remplis tous les champs.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Le mot de passe doit faire au moins 6 caractères.');
      return;
    }

    if (!_acceptedTerms) {
      setState(() => _errorMessage = 'Tu dois accepter les conditions d\'utilisation.');
      return;
    }

    // Pseudo temporaire généré à partir de l'email, l'utilisateur le configurera ensuite sur l'écran dédié
    final tempUsername = email.contains('@') ? email.split('@').first : 'user_${DateTime.now().millisecondsSinceEpoch}';

    await ref.read(authViewModelProvider.notifier).register(
          username: tempUsername,
          email: email,
          password: password,
        );
  }

  void _showTermsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1119),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2236),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Conditions d\'utilisation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFCDD5F0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: const Text(
                        '''CONDITIONS D'UTILISATION — eForum
Dernière mise à jour : août 2026

1. ACCEPTATION DES CONDITIONS
En vous inscrivant sur eForum, vous acceptez les présentes conditions d'utilisation dans leur intégralité. Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser l'application.

2. DESCRIPTION DU SERVICE
eForum est une plateforme communautaire mobile dédiée aux joueurs d'eFootball. Elle permet aux utilisateurs de publier des posts, partager des builds de joueurs, rejoindre des clans, discuter en messagerie privée et suivre d'autres membres de la communauté.

3. INSCRIPTION ET COMPTE
- Vous devez fournir des informations exactes lors de l'inscription.
- Vous êtes responsable de la confidentialité de votre mot de passe.
- Un seul compte par personne est autorisé.
- Vous devez avoir au moins 13 ans pour utiliser eForum.
- eForum se réserve le droit de suspendre ou supprimer tout compte en violation de ces conditions.

4. RÈGLES DE COMPORTEMENT
En utilisant eForum, vous vous engagez à ne pas :
- Publier du contenu haineux, discriminatoire ou offensant.
- Harceler, menacer ou intimider d'autres utilisateurs.
- Diffuser de fausses informations de manière intentionnelle.
- Utiliser l'application à des fins commerciales sans autorisation.
- Tenter de pirater, modifier ou perturber le fonctionnement de la plateforme.
- Usurper l'identité d'un autre utilisateur ou d'eForum.

5. CONTENU UTILISATEUR
- Vous conservez la propriété de votre contenu publié sur eForum.
- En publiant, vous accordez à eForum une licence non exclusive d'utilisation de ce contenu dans le cadre du service.
- eForum se réserve le droit de supprimer tout contenu jugé inapproprié sans préavis.

6. SIGNALEMENT ET MODÉRATION
eForum dispose d'un système de signalement. Tout abus répété du système de signalement pourra entraîner la suspension du compte. Les décisions de modération sont finales et prises par l'équipe administrative d'eForum.

7. PROTECTION DES DONNÉES
- Vos données personnelles (email, pseudonyme) sont stockées de manière sécurisée via Firebase (Google).
- Elles ne sont jamais vendues à des tiers.
- Vous pouvez demander la suppression de votre compte et de vos données à tout moment en contactant l'équipe eForum.

8. LIMITATION DE RESPONSABILITÉ
eForum est fourni "tel quel". Nous ne garantissons pas une disponibilité permanente du service. eForum ne peut être tenu responsable des contenus publiés par les utilisateurs.

9. MODIFICATIONS DES CONDITIONS
eForum se réserve le droit de modifier ces conditions à tout moment. Les utilisateurs seront notifiés des changements importants via l'application. La poursuite de l'utilisation après modification vaut acceptation des nouvelles conditions.

10. CONTACT
Pour toute question relative aux présentes conditions, contactez l'équipe eForum via la section "Support" de l'application.''',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFCDD5F0),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: const Color(0xFF07090F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Fermer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState is AuthLoading;

    // Écoute les erreurs
    ref.listen(authViewModelProvider, (previous, next) {
      if (next is AuthError) {
        setState(() => _errorMessage = next.message);
        ref.read(authViewModelProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF07090F),
      body: GridBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Retour / Logo
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFFCDD5F0),
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                
                const SizedBox(height: 16),
                const EForumLogo(size: 48, hasGlow: false),

                const SizedBox(height: 20),

                // Titre
                const Text(
                  'Rejoins le terrain 🏟️',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFCDD5F0),
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Crée ton compte et partage tes builds avec la\ncommunauté.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFCDD5F0),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 36),

                // ── Champ email ───────────────────────────────────────────
                _buildLabel('EMAIL'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hint: 'ton@email.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                // ── Champ mot de passe ────────────────────────────────────
                _buildLabel('MOT DE PASSE'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordController,
                  hint: '8 caractères minimum',
                  icon: Icons.lock_outline_rounded,
                  obscure: !_passwordVisible,
                  suffix: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFFCDD5F0),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Checkbox conditions ───────────────────────────────────
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _acceptedTerms = !_acceptedTerms;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131824).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1C2236)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _acceptedTerms
                                ? const Color(0xFF00E676)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _acceptedTerms
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFFCDD5F0),
                              width: 1.5,
                            ),
                          ),
                          child: _acceptedTerms
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Color(0xFF07090F),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'J\'accepte les ',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFCDD5F0),
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(
                                  text: 'conditions d\'utilisation',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF00E676),
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: _termsRecognizer,
                                ),
                                const TextSpan(
                                  text: ' et la politique de confidentialité d\'eForum.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Message d'erreur
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
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFFF5252),
                      ),
                    ),
                  ),

                const SizedBox(height: 28),

                // ── Bouton inscription avec glow ────────────────────────────
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
                    onPressed: isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: const Color(0xFF07090F),
                      disabledBackgroundColor: const Color(0xFF1C2236),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF07090F),
                            ),
                          )
                        : const Text(
                            'S\'inscrire',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Séparateur OU ─────────────────────────────────────────
                Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        color: Color(0xFF1C2236),
                        thickness: 1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OU',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFCDD5F0),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        color: Color(0xFF1C2236),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Bouton Google avec vrai logo SVG et SnackBar ──────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connexion Google bientôt disponible'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF131824),
                      foregroundColor: const Color(0xFFCDD5F0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFF1C2236)),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.string(
                          _googleSvgLogo,
                          width: 22,
                          height: 22,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continuer avec Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFCDD5F0),
                          ),
                        ),
                      ],
                    ),
                  ),
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
        color: Color(0xFFCDD5F0),
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
        color: const Color(0xFF131824).withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1C2236)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFFCDD5F0),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFCDD5F0)),
          prefixIcon: Icon(icon, color: const Color(0xFFCDD5F0), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}