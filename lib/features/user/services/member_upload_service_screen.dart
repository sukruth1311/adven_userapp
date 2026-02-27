import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemberUploadServiceScreen extends StatefulWidget {
  final String serviceType;
  final int maxMembers;

  const MemberUploadServiceScreen({
    super.key,
    required this.serviceType,
    required this.maxMembers,
  });

  @override
  State<MemberUploadServiceScreen> createState() =>
      _MemberUploadServiceScreenState();
}

class _MemberUploadServiceScreenState extends State<MemberUploadServiceScreen> {
  List<Map<String, dynamic>> members = [];
  bool isSubmitting = false;

  Future<String> uploadAadhar(File file) async {
    final ref = FirebaseStorage.instance.ref().child(
      "aadhar_documents/${DateTime.now().millisecondsSinceEpoch}.jpg",
    );

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> pickAadhar(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final url = await uploadAadhar(File(picked.path));

      setState(() {
        members[index]["aadharUrl"] = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aadhar uploaded successfully ✅")),
      );
    }
  }

  Future<void> submit() async {
    if (members.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Add at least one member")));
      return;
    }

    setState(() => isSubmitting = true);

    await FirebaseFirestore.instance.collection("service_requests").add({
      "userId": FirebaseAuth.instance.currentUser!.uid,
      "serviceType": widget.serviceType,
      "members": members,
      "status": "pending",
      "createdAt": Timestamp.now(),
    });

    setState(() => isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request submitted successfully 🎉")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.serviceType.toUpperCase())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text("Add Member"),
              onPressed: members.length < widget.maxMembers
                  ? () {
                      setState(() {
                        members.add({"name": "", "aadharUrl": null});
                      });
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                              labelText: "Member Name",
                            ),
                            onChanged: (value) {
                              members[index]["name"] = value;
                            },
                          ),
                          const SizedBox(height: 10),
                          member["aadharUrl"] == null
                              ? ElevatedButton(
                                  onPressed: () => pickAadhar(index),
                                  child: const Text("Upload Aadhar"),
                                )
                              : Column(
                                  children: [
                                    const Text(
                                      "Aadhar Uploaded ✅",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Image.network(
                                      member["aadharUrl"],
                                      height: 100,
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isSubmitting ? null : submit,
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Request"),
            ),
          ],
        ),
      ),
    );
  }
}
