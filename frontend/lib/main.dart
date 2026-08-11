import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';

// TODO: générer firebase_options.dart avec FlutterFire CLI
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: EFootyApp()));
}

class EFootyApp extends StatelessWidget {
  const EFootyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eFooty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // TODO: brancher go_router
      home: const Scaffold(
        body: Center(
          child: Text('eFooty — En construction 🚧',
            style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
