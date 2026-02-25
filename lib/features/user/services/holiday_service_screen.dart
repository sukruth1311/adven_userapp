import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firestore_service.dart';

class HolidayServiceScreen extends StatefulWidget {
  const HolidayServiceScreen({super.key});

  @override
  State<HolidayServiceScreen> createState() => _HolidayServiceScreenState();
}

class _HolidayServiceScreenState extends State<HolidayServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  final _destination = TextEditingController();
  final _subDestination = TextEditingController();
  final _totaldays = TextEditingController();
  final _members = TextEditingController();
  final _memberName = TextEditingController();

  DateTime? travelDate;
  File? aadharFile;

  bool loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (travelDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select travel date")),
      );
      return;
    }

    if (aadharFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload Aadhaar file")),
      );
      return;
    }

    try {
      setState(() => loading = true);

      // ✅ ALWAYS use Firebase UID directly
      final Uid = FirebaseAuth.instance.currentUser!.uid;

      await FirestoreService.instance.createHolidayRequest(
        userId: FirebaseAuth.instance.currentUser!.uid, // 🔥 FIXED HERE
        destination: _destination.text.trim(),
        subDestination: _subDestination.text.trim(),
        totalDays: int.parse(_totaldays.text.trim()),
        members: int.parse(_members.text.trim()),
        memberName: _memberName.text.trim(),
        travelDate: travelDate!,
        aadharFile: aadharFile!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Holiday Request Submitted")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _destination.dispose();
    _subDestination.dispose();
    _totaldays.dispose();
    _members.dispose();
    _memberName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Holiday Service Request"),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field("Destination", _destination),
            _field("Sub Destination", _subDestination),
            _field("Number of Members", _members, isNumber: true),
            _field("Member Name", _memberName),
            _field("Total Days", _totaldays, isNumber: true),

            const SizedBox(height: 16),

            /// Travel Date
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  setState(() => travelDate = picked);
                }
              },
              label: Text(
                travelDate == null
                    ? "Select Travel Date"
                    : "Travel Date: ${travelDate!.toString().split(" ")[0]}",
              ),
            ),

            const SizedBox(height: 12),

            /// Aadhaar Upload
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                );

                if (result != null) {
                  setState(() {
                    aadharFile = File(result.files.single.path!);
                  });
                }
              },
              label: Text(
                aadharFile == null ? "Upload Aadhaar" : "File Selected ✓",
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit Request",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Please enter $label";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
