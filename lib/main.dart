
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexaaura/firebase_options.dart';
import 'package:nexaaura/screens/chat_screen.dart';
import 'package:nexaaura/screens/login_screen.dart';
import 'package:nexaaura/services/notification_service.dart';
import 'package:nexaaura/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // We only initialize the listeners here, not save the token
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: cyberpunkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    print("--- Building AuthWrapper ---");
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User is logged in
        if (snapshot.hasData) {
          print("AuthWrapper: User is logged in. Navigating to ChatScreen.");
          _notificationService.saveTokenToDatabase(snapshot.data!);
          return const ChatScreen();
        }

        // User is not logged in
        if (snapshot.connectionState == ConnectionState.waiting) {
          print("AuthWrapper: Waiting for connection...");
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        print("AuthWrapper: User is not logged in. Navigating to LoginScreen.");
        return const LoginScreen();
      },
    );
  }
}
