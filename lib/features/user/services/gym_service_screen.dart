import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GymServiceScreen extends StatefulWidget {
  final String userId;

  const GymServiceScreen({super.key, required this.userId});

  @override
  State<GymServiceScreen> createState() => _GymServiceScreenState();
}

class _GymServiceScreenState extends State<GymServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final aadhaarController = TextEditingController();

  bool loading = false;

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    await FirebaseFirestore.instance.collection("service_requests").add({
      "userId": widget.userId,
      "serviceType": "gym",
      "name": nameController.text,
      "aadhaar": aadhaarController.text,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Gym Request Submitted")));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gym Service Request")),
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
