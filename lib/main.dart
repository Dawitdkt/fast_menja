import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/navigation/app_router.dart';
import 'core/services/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local storage
  final localStorage = LocalStorageService();
  await localStorage.init();
  
  // Load questions from assets
  await localStorage.loadQuestionsFromAssets();

  runApp(
    ProviderScope(
      child: const FastMenjaApp(),
    ),
  );
}

class FastMenjaApp extends StatelessWidget {
  const FastMenjaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fast Menja',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 2,
        ),
      ),
      routerConfig: goRouterProvider,
    );
  }
}
