import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/tutorial_screen.dart';
import 'services/auth_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('has_seen_tutorial') ?? false;

    runApp(MyApp(
      hasSeenTutorial: hasSeenTutorial,
    ));
  } catch (e) {
    debugPrint('Critical error in main: $e');
    runApp(const MyAppFallback());
  }
}

class MyAppFallback extends StatelessWidget {
  const MyAppFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing app. Please restart.'),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final bool hasSeenTutorial;

  const MyApp({
    super.key,
    required this.hasSeenTutorial,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // WidgetsBindingObserver removed as we don't need to listen for app resume for App Open Ads anymore


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dance Imposter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: widget.hasSeenTutorial ? const AuthWrapper() : const TutorialScreen(isFirstLaunch: true),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
