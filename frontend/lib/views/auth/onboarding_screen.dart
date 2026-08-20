import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/router/app_router.dart';
import '../../widgets/common/grid_background.dart';
import '../../viewmodels/auth_viewmodel.dart';
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Données en mémoire locale (sauvegardées à l'étape 3)
  String _username = '';
  File? _selectedImage;
  String? _favPlayerName;

  // Étape 1 : Pseudo State
  final TextEditingController _usernameController = TextEditingController();
  Timer? _debounceTimer;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable; // null = pas encore vérifié, true = dispo, false = pris
  String? _usernameFormatError;

  // Étape 3 : Recherche de joueur State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> popularPlayers = const [
    {'name': 'Kylian Mbappé', 'overall': 97, 'position': 'AC'},
    {'name': 'Erling Haaland', 'overall': 96, 'position': 'AC'},
    {'name': 'Vinicius Jr', 'overall': 95, 'position': 'AG'},
    {'name': 'Pedri', 'overall': 93, 'position': 'MO'},
    {'name': 'Rodri', 'overall': 94, 'position': 'MDC'},
    {'name': 'Lamine Yamal', 'overall': 92, 'position': 'AD'},
    {'name': 'Jude Bellingham', 'overall': 94, 'position': 'MO'},
    {'name': 'Mohamed Salah', 'overall': 93, 'position': 'AD'},
    {'name': 'Harry Kane', 'overall': 92, 'position': 'AC'},
    {'name': 'Trent A-Arnold', 'overall': 91, 'position': 'DD'},
    {'name': 'Raphaël Varane', 'overall': 89, 'position': 'DC'},
    {'name': 'Sadio Mané', 'overall': 88, 'position': 'AG'},
  ];

  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounceTimer?.cancel();
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
        _usernameFormatError = null;
        _username = '';
      });
      return;
    }

    // Validation du format : ^[a-zA-Z0-9_]{3,20}$
    final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    if (!usernameRegex.hasMatch(trimmed)) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
        if (trimmed.length < 3 || trimmed.length > 20) {
          _usernameFormatError = 'Le pseudo doit contenir entre 3 et 20 caractères.';
        } else if (trimmed.contains(' ')) {
          _usernameFormatError = 'Le pseudo ne doit pas contenir d\'espaces.';
        } else {
          _usernameFormatError = 'Lettres, chiffres et _ uniquement.';
        }
        _username = '';
      });
      return;
    }

    setState(() {
      _usernameFormatError = null;
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
    });

    // Debounce de 600ms avant vérification Firestore
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: trimmed)
            .limit(1)
            .get();

        if (mounted) {
          setState(() {
            _isCheckingUsername = false;
            _isUsernameAvailable = querySnapshot.docs.isEmpty;
            if (_isUsernameAvailable == true) {
              _username = trimmed;
            } else {
              _username = '';
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isCheckingUsername = false;
            _isUsernameAvailable = true; // Fallback permissif si Firestore indisponible en dev
            _username = trimmed;
          });
        }
      }
    });
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Ferme la bottom sheet
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E1119),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  'Photo de profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFCDD5F0),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF00E676)),
                  title: const Text(
                    'Prendre une photo',
                    style: TextStyle(color: Color(0xFFCDD5F0), fontWeight: FontWeight.w600),
                  ),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF00E676)),
                  title: const Text(
                    'Choisir depuis la galerie',
                    style: TextStyle(color: Color(0xFFCDD5F0), fontWeight: FontWeight.w600),
                  ),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isSaving = true);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      if (mounted) {
        context.go(AppRoutes.login);
      }
      return;
    }

    try {
      // 1. Upload photo si sélectionnée (seulement si Storage activé)
            String? photoURL;
            if (_selectedImage != null) {
              photoURL = await StorageService().uploadAvatar(
                currentUser.uid,
                _selectedImage!,
              );
            }

      // 2. Mettre à jour le document users/{uid} dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'username': _username,
            'photoURL': photoURL,
            'favPlayerName': _favPlayerName,
            'onboardingCompleted': true,
            'updatedAt': Timestamp.now(),
          });

      // 3. Naviguer vers le feed
      await ref.read(authViewModelProvider.notifier).refreshUser();
      if (mounted) {
        context.go(AppRoutes.feed);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sauvegarde. Réessaie.'),
            backgroundColor: Color(0xFFEF5350),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090F),
      body: GridBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── En-tête : Barre de progression + Étape + Bouton Passer ──────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Étape ${_currentStep + 1} sur 3',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFCDD5F0),
                          ),
                        ),
                        const Spacer(),
                        if (_currentStep > 0)
                          GestureDetector(
                            onTap: _currentStep == 2 ? _completeOnboarding : _nextStep,
                            child: const Text(
                              'Passer',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF485070),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Barre 3 segments
                    Row(
                      children: List.generate(3, (index) {
                        final isActive = index <= _currentStep;
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF00E676) : const Color(0xFF1C2236),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // ── Contenu des étapes (PageView) ──────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Transition contrôlée
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildStep1Pseudo(),
                    _buildStep2Photo(),
                    _buildStep3FavPlayer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ÉTAPE 1 : Pseudo ────────────────────────────────────────────────────────
  Widget _buildStep1Pseudo() {
    final bool isPseudoValid = _isUsernameAvailable == true && _usernameFormatError == null && _username.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Illustration / Icône Gaming
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF131824),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1C2236)),
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                color: Color(0xFF00E676),
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Choisis ton pseudo',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFFCDD5F0),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'C\'est ainsi que la communauté te connaîtra.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFCDD5F0),
            ),
          ),
          const SizedBox(height: 32),

          // Label
          const Text(
            'NOM D\'UTILISATEUR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFFCDD5F0),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          // Champ de saisie
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF131824).withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _usernameFormatError != null
                    ? const Color(0xFFEF5350)
                    : (_isUsernameAvailable == true
                        ? const Color(0xFF00E676)
                        : const Color(0xFF1C2236)),
              ),
            ),
            child: TextField(
              controller: _usernameController,
              onChanged: _onUsernameChanged,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFFCDD5F0),
              ),
              decoration: InputDecoration(
                hintText: 'ex. ibra_efc',
                hintStyle: const TextStyle(color: Color(0xFFCDD5F0)),
                prefixIcon: const Icon(
                  Icons.alternate_email_rounded,
                  color: Color(0xFFCDD5F0),
                  size: 20,
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _isCheckingUsername
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF00E676),
                          ),
                        )
                      : (_isUsernameAvailable == true
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 22)
                          : (_isUsernameAvailable == false
                              ? const Icon(Icons.cancel_rounded, color: Color(0xFFEF5350), size: 22)
                              : null)),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Règles d'utilisation
          const Text(
            '• Entre 3 et 20 caractères\n• Lettres, chiffres et _ uniquement\n• Pas d\'espaces',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFCDD5F0),
              height: 1.5,
            ),
          ),

          if (_usernameFormatError != null) ...[
            const SizedBox(height: 12),
            Text(
              _usernameFormatError!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFEF5350),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_isUsernameAvailable == false) ...[
            const SizedBox(height: 12),
            const Text(
              'Ce pseudo est déjà pris.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFFEF5350),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 40),

          // Bouton Continuer (Étape 1)
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: isPseudoValid
                  ? [
                      const BoxShadow(
                        color: Color(0x4D00E676),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: isPseudoValid ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: const Color(0xFF07090F),
                disabledBackgroundColor: const Color(0xFF1C2236),
                disabledForegroundColor: const Color(0xFF485070),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continuer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ÉTAPE 2 : Photo ─────────────────────────────────────────────────────────
  Widget _buildStep2Photo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Ajoute ta photo de profil',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFFCDD5F0),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mets un visage sur ton compte. Tu pourras la changer plus tard.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFCDD5F0),
            ),
          ),
          const SizedBox(height: 48),

          // Grand cercle 120px centré
          Center(
            child: GestureDetector(
              onTap: _showImagePickerModal,
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2236),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00E676), width: 2),
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedImage == null
                        ? const Icon(
                            Icons.person_rounded,
                            size: 64,
                            color: Color(0xFFCDD5F0),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF07090F), width: 3),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF07090F),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 60),

          // Bouton Continuer (Étape 2)
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D00E676),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: const Color(0xFF07090F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continuer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _nextStep,
              child: const Text(
                'Passer cette étape',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFCDD5F0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ÉTAPE 3 : Joueur eFootball préféré ──────────────────────────────────────
  Widget _buildStep3FavPlayer() {
    final filteredPlayers = popularPlayers.where((player) {
      final name = (player['name'] as String).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Ton joueur préféré sur eFootball ?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFFCDD5F0),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Il apparaîtra sur ton profil pour que la communauté te connaisse mieux.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFCDD5F0),
            ),
          ),
          const SizedBox(height: 20),

          // Champ de recherche
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF131824),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1C2236)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(fontSize: 14, color: Color(0xFFCDD5F0)),
              decoration: const InputDecoration(
                hintText: 'Rechercher un joueur...',
                hintStyle: TextStyle(color: Color(0xFFCDD5F0)),
                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFFCDD5F0), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Grille de cartes de joueurs
          Expanded(
            child: GridView.builder(
              itemCount: filteredPlayers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final player = filteredPlayers[index];
                final isSelected = _favPlayerName == player['name'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _favPlayerName = isSelected ? null : player['name'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131824),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00E676) : const Color(0xFF1C2236),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            const Text('⚽', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player['name'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFCDD5F0),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        '${player['overall']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF00E676),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        player['position'],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF485070),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          const Positioned(
                            top: 0,
                            right: 0,
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF00E676),
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Bouton Terminer
          Container(
            width: double.infinity,
            height: 56,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D00E676),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: const Color(0xFF07090F),
                disabledBackgroundColor: const Color(0xFF1C2236),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF07090F),
                      ),
                    )
                  : const Text(
                      'Terminer et accéder à eForum',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
