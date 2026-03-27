import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // CompanySelectionScreen import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;

  Future<void> handleAuth() async {
    try {
      if (emailController.text.isEmpty ||
          passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter email & password")),
        );
        return;
      }

      if (isLogin) {
        // 🔐 LOGIN
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        // 🆕 SIGNUP
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }

      // ✅ SUCCESS → NEXT SCREEN
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CompanySelectionScreen(),
        ),
      );
    } catch (e) {
      print("🔥 ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? "Login" : "Signup"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 📧 EMAIL
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // 🔑 PASSWORD
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 🔥 LOGIN / SIGNUP BUTTON
            ElevatedButton(
              onPressed: handleAuth,
              child: Text(isLogin ? "Login" : "Signup"),
            ),

            const SizedBox(height: 10),

            // 🔄 SWITCH LOGIN / SIGNUP
            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                });
              },
              child: Text(isLogin
                  ? "Don't have account? Signup"
                  : "Already have account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}