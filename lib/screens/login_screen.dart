
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:nexaaura/models/user_model.dart';
import 'package:nexaaura/screens/register_screen.dart';
import 'package:nexaaura/services/firestore_service.dart';
import 'package:nexaaura/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
    }
  }

  Future<void> _signInWithGoogle() async {
    // ... (logic remains the same)
  }

  Future<void> _signInWithFacebook() async {
    // ... (logic remains the same)
  }

  @override
  Widget build(BuildContext context) {
    print("--- Building LoginScreen ---"); // Diagnostic print
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: darkGrey,
              borderRadius: BorderRadius.circular(0),
              boxShadow: const [
                BoxShadow(
                  color: neonMagenta, 
                  blurRadius: 20,
                  spreadRadius: -10,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('NEXAURA', style: Theme.of(context).appBarTheme.titleTextStyle),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ));
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: "Don\'t have an account? ",
                      style: TextStyle(color: lightGrey),
                      children: <TextSpan>[
                        TextSpan(text: 'Register', style: TextStyle(color: neonCyan, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Or connect with', style: TextStyle(color: lightGrey)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(onPressed: _signInWithGoogle, icon: const Icon(Icons.android, color: neonCyan, size: 40)), // Replace with actual logo
                    const SizedBox(width: 24),
                    IconButton(onPressed: _signInWithFacebook, icon: const Icon(Icons.facebook, color: neonCyan, size: 40)), // Replace with actual logo
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
