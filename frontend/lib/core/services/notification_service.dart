import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ─── Constantes OneSignal ─────────────────────────────────────────────────────

class _OneSignalConfig {
  static const appId     = '73f7c7e9-bd2f-4ecf-ad4d-701f93be7651';
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION SERVICE
// ═══════════════════════════════════════════════════════════════════════════════

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ─── Initialiser OneSignal & Local Notifications ───────────────────────────

  Future<void> initialize() async {
    // 1. OneSignal
    OneSignal.Debug.setLogLevel(OSLogLevel.warn);
    OneSignal.initialize(_OneSignalConfig.appId);
    OneSignal.Notifications.requestPermission(true);
    debugPrint('✅ OneSignal initialisé');

    // 2. Local Notifications (Timezone & Init)
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotificationsPlugin.initialize(initSettings);
    debugPrint('✅ Notifications locales initialisées');
  }

  // ─── Planifier la notification d'inactivité (24h) ──────────────────────────

  Future<void> scheduleInactivityNotification() async {
    try {
      await _localNotificationsPlugin.cancel(999);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'inactivity_channel',
        'Inactivité',
        channelDescription: 'Rappels après inactivité prolongée',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));

      await _localNotificationsPlugin.zonedSchedule(
        999,
        'Tu as disparu un long moment... 🏟️',
        'Reviens et affronte les joueurs de la commu efootball !',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('⏰ Notification d\'inactivité planifiée pour le : $scheduledDate');
    } catch (e) {
      debugPrint('❌ Erreur planification notification d\'inactivité : $e');
    }
  }

  // ─── Annuler la notification d'inactivité ──────────────────────────────────

  Future<void> cancelInactivityNotification() async {
    try {
      await _localNotificationsPlugin.cancel(999);
      debugPrint('🚫 Notification d\'inactivité annulée');
    } catch (e) {
      debugPrint('❌ Erreur annulation notification d\'inactivité : $e');
    }
  }

  // ─── Sauvegarder le Player ID dans Firestore ──────────────────────────────

  Future<void> savePlayerIdToFirestore(String uid) async {
    try {
      final playerId = OneSignal.User.pushSubscription.id;
      if (playerId == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'oneSignalPlayerId': playerId,
        'oneSignalUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ OneSignal Player ID sauvegardé : $playerId');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde Player ID : $e');
    }
  }

  // ─── Supprimer le Player ID à la déconnexion ──────────────────────────────

  Future<void> clearPlayerId(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'oneSignalPlayerId': FieldValue.delete(),
      });
      OneSignal.logout();
      debugPrint('✅ OneSignal Player ID supprimé');
    } catch (e) {
      debugPrint('❌ Erreur suppression Player ID : $e');
    }
  }

  // ─── Envoyer une notification push ────────────────────────────────────────

  static Future<void> sendPushNotification({
    required String recipientUid,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Récupérer le Player ID du destinataire
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientUid)
          .get();

      final playerId = userDoc.data()?['oneSignalPlayerId'] as String?;
      if (playerId == null) return;

      // L'envoi OneSignal doit être effectué par un backend de confiance.
      debugPrint(
        '⚠️ Push OneSignal non envoyée côté client pour $recipientUid '
        '(playerId: $playerId, title: $title, body: $body, data: $data)',
      );
    } catch (e) {
      debugPrint('❌ Erreur envoi notification : $e');
    }
  }

  // ─── Créer une notif in-app dans Firestore ────────────────────────────────

  static Future<void> createNotification({
    required String recipientId,
    required String type,
    required String senderId,
    required String senderName,
    required String targetType,
    required String targetId,
  }) async {
    try {
      // Pas de notif à soi-même
      if (recipientId == senderId) return;

      // Créer dans Firestore
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

      // Envoyer la push notification
      final messages = {
        'like':         '$senderName a aimé ton post ❤️',
        'comment':      '$senderName a commenté ton post 💬',
        'follow':       '$senderName a commencé à te suivre 👤',
        'repost':       '$senderName a republié ton post 🔁',
        'announcement': 'Nouvelle annonce officielle eForum 📢',
      };

      final body = messages[type] ?? '$senderName a interagi avec toi';

      await sendPushNotification(
        recipientUid: recipientId,
        title: 'eForum',
        body: body,
        data: {
          'type': type,
          'targetId': targetId,
          'targetType': targetType,
          'senderId': senderId,
        },
      );
    } catch (e) {
      debugPrint('❌ Erreur création notif : $e');
    }
  }
}