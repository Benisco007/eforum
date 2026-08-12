import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/common/grid_background.dart';
import '../widgets/common/eforum_logo.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../core/router/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _loadBar;

  bool _animationDone = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _loadBar = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward().whenComplete(_onAnimationComplete);
  }

  /// Appelé dès que la barre de chargement est remplie à 100 %.
  void _onAnimationComplete() {
    _animationDone = true;
    _tryNavigate(ref.read(authViewModelProvider));
  }

  /// Tente la navigation. Ne fait rien si :
  ///   - l'animation n'est pas encore terminée
  ///   - la navigation a déjà eu lieu
  ///   - l'auth est encore en chargement
  void _tryNavigate(AuthState authState) {
    if (!_animationDone || _hasNavigated || !mounted) return;
    if (authState is AuthAuthenticated) {
      _hasNavigated = true;
      context.go(AppRoutes.feed);
    } else if (authState is AuthUnauthenticated || authState is AuthError) {
      _hasNavigated = true;
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si l'animation est déjà terminée mais que l'auth était encore en chargement,
    // on navigue dès que l'état devient déterminé.
    ref.listen<AuthState>(authViewModelProvider, (_, next) {
      _tryNavigate(next);
    });
    
    return Scaffold(
      backgroundColor: const Color(0xFF07090F),
      body: GridBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                children: [
                  // Logo + titre
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          const EForumLogo(size: 86, hasGlow: true),

                          const SizedBox(height: 28),

                          // Titre
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'e',
                                  style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFCDD5F0),
                                    letterSpacing: -2,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Forum',
                                  style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF00E676),
                                    letterSpacing: -2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Séparateur avec ballon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 32,
                                height: 1,
                                color: const Color(0xFF1C2236),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(
                                  Icons.sports_soccer,
                                  color: Color(0xFF00E676),
                                  size: 16,
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 1,
                                color: const Color(0xFF1C2236),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Tagline
                          const Text(
                            'La communauté eFootball\nfrancophone',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF485070),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Barre de chargement ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 48),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: Container(
                            height: 5,
                            width: double.infinity,
                            color: const Color(0xFF1C2236),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _loadBar.value,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0x4D00E676),
                                      Color(0xFF00E676),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xB300E676),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'CHARGEMENT…',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF485070),
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}