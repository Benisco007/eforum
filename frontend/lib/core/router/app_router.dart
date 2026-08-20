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
import '../../views/notifications/notifications_screen.dart';
import '../../views/clans/clan_screen.dart';
import '../../views/chat/chat_screen.dart';
import '../../views/admin/admin_screen.dart';
import '../../data/models/user_model.dart';
import '../../views/profile/edit_profile_screen.dart';
import '../../views/builds/builds_screen.dart';

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
  static const notifications = '/notifications';
  static const clans = '/clans'; 
  static const messages = '/messages';
  static const admin = '/admin';
  static const editProfile = '/edit-profile';
  static const builds = '/builds';
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
      final isAdmin      = state.matchedLocation == AppRoutes.admin;

      if (isAuthenticated && onAuthScreen) {
        final user = (authState as AuthAuthenticated).user;

        // Admin → panneau admin
        if (user.role == UserRole.admin) return AppRoutes.admin;

        // Onboarding déjà complété → feed
        if (user.onboardingCompleted) return AppRoutes.feed;

        // Premier login → onboarding
        return AppRoutes.onboarding;
      }

      // Non connecté et hors d'un écran auth → login
      if (!isAuthenticated && !onAuthScreen && !isOnboarding && !isAdmin) {
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
        path: '/profile/:uid',
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return ProfileScreen(uid: uid, showBackButton: true);
        },
      ),
      GoRoute(
        path: '/messages/:convId',
        builder: (context, state) {
          final convId       = state.pathParameters['convId']!;
          final otherUserId  = state.uri.queryParameters['otherUserId'] ?? '';
          final otherUsername= state.uri.queryParameters['otherUsername'] ?? '';
          return ChatScreen(
            conversationId: convId,
            otherUserId:    otherUserId,
            otherUsername:  otherUsername,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.messages,
        builder: (context, state) => const MessagesScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.clans,
        builder: (context, state) => const ClansScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.builds,
        builder: (context, state) => const BuildsScreen(),
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