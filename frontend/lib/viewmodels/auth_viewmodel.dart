import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';
import '../core/services/notification_service.dart';

// ─── États possibles de l'authentification ───────────────────────────────────

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// ─── ViewModel ───────────────────────────────────────────────────────────────

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthViewModel(this._repository) : super(AuthInitial()) {
    _checkCurrentUser();
  }

  /// Vérifie si un utilisateur est déjà connecté au démarrage
  Future<void> _checkCurrentUser() async {
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = AuthUnauthenticated();
      }
    } catch (_) {
      state = AuthUnauthenticated();
    }
  }

  /// Inscription avec email + mot de passe
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = AuthLoading();
    try {
      final user = await _repository.register(
        username: username,
        email: email,
        password: password,
      );
      state = AuthAuthenticated(user);
      NotificationService().saveTokenToFirestore(user.uid);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Connexion avec email + mot de passe
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = AuthLoading();
    try {
      final user = await _repository.login(
        email: email,
        password: password,
      );
      state = AuthAuthenticated(user);
      NotificationService().saveTokenToFirestore(user.uid);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    state = AuthLoading();
    try {
      await _repository.logout();
      if (state is AuthAuthenticated) {
        final uid = (state as AuthAuthenticated).user.uid;
        await NotificationService().deleteToken(uid);
      }
      state = AuthUnauthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Réinitialise l'erreur sans changer l'état d'auth
  void clearError() {
    if (state is AuthError) {
      state = AuthUnauthenticated();
    }
  }

  /// Rafraîchit le UserModel depuis Firestore (après onboarding par ex.)
  Future<void> refreshUser() async {
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) state = AuthAuthenticated(user);
    } catch (_) {}
  }

  /// Envoi d'un email de réinitialisation du mot de passe
  Future<String?> resetPassword(String email) async {
    try {
      await _repository.resetPassword(email: email);
      return null; // null = succès
    } catch (e) {
      return e.toString();
    }
  }
}

// ─── Providers Riverpod ───────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthViewModel(repository);
});

/// Provider pratique pour savoir si l'utilisateur est connecté
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider) is AuthAuthenticated;
});

/// Provider pour accéder directement à l'utilisateur connecté (nullable)
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authViewModelProvider);
  if (authState is AuthAuthenticated) return authState.user;
  return null;
});
