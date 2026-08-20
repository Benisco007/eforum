import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─── Handler background (doit être top-level) ─────────────────────────────────

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase est déjà initialisé dans main.dart
  debugPrint('🔔 Notif background : ${message.notification?.title}');
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION SERVICE
// ═══════════════════════════════════════════════════════════════════════════════

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  // ─── Initialiser le service ────────────────────────────────────────────────

  Future<void> initialize() async {
    // 1. Demander la permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('❌ Permission notifications refusée');
      return;
    }

    // 2. Configurer les notifications locales (Android)
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotif.initialize(initSettings);

    // 3. Créer le canal Android
    const androidChannel = AndroidNotificationChannel(
      'eforum_channel',
      'eForum Notifications',
      description: 'Notifications de la communauté eForum',
      importance: Importance.high,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // 4. Handler background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5. Handler foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 6. Handler tap notif (app en background)
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 7. Vérifier si app ouverte depuis une notif
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data);
    }

    debugPrint('✅ NotificationService initialisé');
  }

  // ─── Sauvegarder le token FCM dans Firestore ───────────────────────────────

  Future<void> saveTokenToFirestore(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Token FCM sauvegardé : ${token.substring(0, 20)}…');

      // Écouter les rafraîchissements du token
      _fcm.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde token FCM : $e');
    }
  }

  // ─── Supprimer le token à la déconnexion ───────────────────────────────────

  Future<void> deleteToken(String uid) async {
    try {
      await _fcm.deleteToken();
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
      debugPrint('✅ Token FCM supprimé');
    } catch (e) {
      debugPrint('❌ Erreur suppression token FCM : $e');
    }
  }

  // ─── Afficher une notification locale (app en foreground) ─────────────────

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('🔔 Notif foreground : ${notification.title}');

    await _localNotif.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'eforum_channel',
          'eForum Notifications',
          channelDescription: 'Notifications de la communauté eForum',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data.toString(),
    );
  }

  // ─── Gérer le tap sur une notif (app en background) ───────────────────────

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 Notif tapée depuis background : ${message.data}');
    _handleNotificationTap(message.data);
  }

  // ─── Navigation selon le type de notif ────────────────────────────────────

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final targetId = data['targetId'] as String?;

    debugPrint('🔔 Type: $type — Target: $targetId');

    // La navigation sera gérée par go_router
    // On stocke les données pour que l'app puisse naviguer au démarrage
    // Cette logique sera étendue avec un NavigationService si nécessaire
  }

  // ─── Créer une notif dans Firestore ───────────────────────────────────────
  // Utilisé pour les notifs in-app (likes, follows, commentaires...)

  static Future<void> createNotification({
    required String recipientId,
    required String type,
    required String senderId,
    required String senderName,
    required String targetType,
    required String targetId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': recipientId,
        'type': type,
        'senderId': senderId,
        'senderName': senderName,
        'targetType': targetType,
        'targetId': targetId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Erreur création notif : $e');
    }
  }
}