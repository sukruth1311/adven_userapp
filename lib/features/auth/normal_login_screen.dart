import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NormalLoginScreen extends StatefulWidget {
  const NormalLoginScreen({super.key});

  @override
  State<NormalLoginScreen> createState() => _NormalLoginScreenState();
}

class _NormalLoginScreenState extends State<NormalLoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        children: [
          _field("Email", emailCtrl),
          _field("Password", passCtrl, obscure: true),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: loading ? null : login,
            child: loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Login"),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String hint,
    TextEditingController ctrl, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );
  }
}
