import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BanquetServiceScreen extends StatefulWidget {
  final String userId;
  const BanquetServiceScreen({super.key, required this.userId});

  @override
  State<BanquetServiceScreen> createState() => _BanquetServiceScreenState();
}

class _BanquetServiceScreenState extends State<BanquetServiceScreen> {
  final areaController = TextEditingController();
  final pincodeController = TextEditingController();
  final capacityController = TextEditingController();
  DateTime? selectedDate;

  Future<void> submit() async {
    await FirebaseFirestore.instance.collection("immunity_requests").add({
      "userId": FirebaseAuth.instance.currentUser!.uid,
      "type": "banquetHall",
      "banquetDetails": {
        "area": areaController.text,
        "pincode": pincodeController.text,
        "capacity": capacityController.text,
        "date": selectedDate,
      },
      "status": "pending",
      "createdAt": Timestamp.now(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AC Banquet Hall")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: areaController,
              decoration: const InputDecoration(labelText: "Area"),
            ),
            TextField(
              controller: pincodeController,
              decoration: const InputDecoration(labelText: "Pincode"),
            ),
            TextField(
              controller: capacityController,
              decoration: const InputDecoration(labelText: "Capacity"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                selectedDate = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  initialDate: DateTime.now(),
                );
                setState(() {});
              },
              child: const Text("Select Date"),
            ),
            ElevatedButton(onPressed: submit, child: const Text("Submit")),
          ],
        ),
      ),
    );
  }
}
