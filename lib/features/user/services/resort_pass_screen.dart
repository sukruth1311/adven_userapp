import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ResortPassScreen extends StatefulWidget {
  final String userId;

  const ResortPassScreen({super.key, required this.userId});

  @override
  State<ResortPassScreen> createState() => _ResortPassScreenState();
}

class _ResortPassScreenState extends State<ResortPassScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final aadhaarController = TextEditingController();

  bool loading = false;

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    await FirebaseFirestore.instance.collection("service_requests").add({
      "userId": widget.userId,
      "serviceType": "resort_pass",
      "name": nameController.text,
      "aadhaar": aadhaarController.text,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Resort Pass Request Submitted")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Resort Pass Service Request")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (v) => v == null || v.isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: aadhaarController,
                decoration: const InputDecoration(labelText: "Aadhaar Number"),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.length != 12 ? "Enter valid Aadhaar" : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: loading ? null : _submitRequest,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Request"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
