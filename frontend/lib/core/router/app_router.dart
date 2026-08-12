import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../views/splash_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/auth/register_screen.dart';
import '../../views/auth/onboarding_screen.dart';
import '../../views/feed/feed_screen.dart';
import '../../views/feed/create_post_screen.dart';
import '../../views/profile/profile_screen.dart';
import '../../views/search/search_screen.dart';

// ─── Noms des routes ──────────────────────────────────────────────────────────

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const feed = '/feed';
  static const createPost = '/create-post';
  static const profile = '/profile';
  static const search = '/search';
}

// ─── RouterNotifier ───────────────────────────────────────────────────────────
// Pont entre Riverpod et GoRouter : notifie GoRouter de réévaluer
// son redirect à chaque changement d'état d'authentification.

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authViewModelProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;

  AuthState get authState => _ref.read(authViewModelProvider);
}

final _routerNotifierProvider = ChangeNotifierProvider<_RouterNotifier>(
  (ref) => _RouterNotifier(ref),
);

// ─── Router ───────────────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(_routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = notifier.authState;

      final isAuthenticated = authState is AuthAuthenticated;
      final isInitial      = authState is AuthInitial;
      final isLoading      = authState is AuthLoading;

      // Pendant le chargement initial → rester sur le splash
      if (isInitial || isLoading) return AppRoutes.splash;

      final onAuthScreen =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.splash;

      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;

      // Si l'utilisateur vient de s'inscrire ou est connecté sur un écran d'auth → onboarding
      if (isAuthenticated && onAuthScreen) {
        return AppRoutes.onboarding;
      }

      // Non connecté et hors d'un écran auth → login
      if (!isAuthenticated && !onAuthScreen && !isOnboarding) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.feed,
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: AppRoutes.createPost,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      backgroundColor: Color(0xFF07090F),
      body: Center(
        child: Text(
          'Page introuvable',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    ),
  );
});