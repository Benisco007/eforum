import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/errors/app_exceptions.dart';

class AuthRepository {
  final FirebaseAuth     _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db  = FirebaseFirestore.instance;

  // Flux de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Inscription
  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Vérifier unicité du username
      final existing = await _db
          .collection(FirebaseConstants.users)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw AuthException('Ce nom d\'utilisateur est déjà pris.');
      }

      // Créer le compte Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );

      // Créer le document utilisateur dans Firestore
      final user = UserModel(
        uid:       cred.user!.uid,
        username:  username,
        email:     email,
        createdAt: Timestamp.now(),
      );
      await _db
          .collection(FirebaseConstants.users)
          .doc(user.uid)
          .set(user.toFirestore());

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code), code: e.code);
    }
  }

  // Connexion
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password,
      );
      final doc = await _db
          .collection(FirebaseConstants.users)
          .doc(cred.user!.uid)
          .get();
      if (!doc.exists) throw AuthException('Compte introuvable.');
      return UserModel.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code), code: e.code);
    }
  }

  // Déconnexion
  Future<void> logout() => _auth.signOut();

  // Récupérer le profil courant
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db
        .collection(FirebaseConstants.users)
        .doc(user.uid)
        .get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  // Traduction des erreurs Firebase
  String _mapFirebaseError(String code) => switch (code) {
    'email-already-in-use'  => 'Cet email est déjà utilisé.',
    'weak-password'         => 'Mot de passe trop faible (6 caractères min).',
    'user-not-found'        => 'Aucun compte avec cet email.',
    'wrong-password'        => 'Mot de passe incorrect.',
    'invalid-email'         => 'Email invalide.',
    'too-many-requests'     => 'Trop de tentatives. Réessaie plus tard.',
    _                       => 'Une erreur est survenue. Réessaie.',
  };
}
