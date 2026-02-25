import 'dart:io';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final commentController = TextEditingController();
  double rating = 3;
  File? imageFile;
  bool isLoading = false;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  Future<String> uploadImage() async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('reviewImages')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putFile(imageFile!);
    return await ref.getDownloadURL();
  }

  Future<void> submitReview() async {
    if (commentController.text.isEmpty || imageFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All fields required")));
      return;
    }

    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser!;
    final imageUrl = await uploadImage();

    await FirebaseFirestore.instance.collection('reviews').add({
      'userId': user.uid,
      'name': user.email,
      'imageUrl': imageUrl,
      'rating': rating,
      'comment': commentController.text,
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Review Submitted for Approval")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Write Review")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: imageFile == null
                  ? Container(
                      height: 120,
                      width: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.add_a_photo),
                    )
                  : Image.file(imageFile!, height: 120),
            ),

            const SizedBox(height: 20),

            Slider(
              value: rating,
              min: 1,
              max: 5,
              divisions: 4,
              label: rating.toString(),
              onChanged: (val) {
                setState(() {
                  rating = val;
                });
              },
            ),

            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: "Say Something"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : submitReview,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Submit Review"),
            ),
          ],
        ),
      ),
    );
  }
}
