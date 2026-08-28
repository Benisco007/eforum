import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'core/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  await NotificationService().initialize();
  await Supabase.initialize(
    url: 'https://pszmftlrthcnjmwsdgby.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBzem1mdGxydGhjbmptd3NkZ2J5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcxMzE4NTcsImV4cCI6MjEwMjcwNzg1N30.BkBTb2hUR8TjPjy_TW3WI8OykvXJS7f9Hb9VhOWzfmk',
  );
  runApp(const ProviderScope(child: EForumApp()));
}

class EForumApp extends ConsumerStatefulWidget {
  const EForumApp({super.key});

  @override
  ConsumerState<EForumApp> createState() => _EForumAppState();
}

class _EForumAppState extends ConsumerState<EForumApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Planifier la notification au premier démarrage
    NotificationService().scheduleInactivityNotification();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Si l'utilisateur revient sur l'application, on réinitialise le délai de 24h
      NotificationService().scheduleInactivityNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'eForum',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}