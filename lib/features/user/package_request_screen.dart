import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user_app/themes/app_theme.dart';
import 'package:user_app/themes/app_widgets.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/firestore_service.dart';

class PackageRequestScreen extends StatefulWidget {
  final String packageType;
  const PackageRequestScreen({super.key, required this.packageType});

  @override
  State<PackageRequestScreen> createState() => _PackageRequestScreenState();
}

class _PackageRequestScreenState extends State<PackageRequestScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _emailCtrl.text = user?.email ?? "";
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty) {
      AppSnackbar.show(context, "Please fill all fields", isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirestoreService.instance.createPackageRequest({
        "id": const Uuid().v4(),
        "userId": uid,
        "name": _nameCtrl.text.trim(),
        "email": _emailCtrl.text.trim(),
        "phone": _phoneCtrl.text.trim(),
        "packageType": widget.packageType,
        "status": "pending",
        "createdAt": DateTime.now(),
      });

      if (mounted) {
        AppSnackbar.show(
          context,
          "Request sent successfully!",
          isSuccess: true,
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Package Request"),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Package badge
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: AppColors.primarySurface,
              child: Row(
                children: [
                  const Icon(
                    Icons.luggage_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Selected Package",
                        style: AppTextStyles.labelUppercase,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.packageType,
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            AppTextField(
              controller: _nameCtrl,
              label: "Full Name",
              hint: "Your full name",
              prefixIcon: Icons.person_outline_rounded,
            ),

            const SizedBox(height: 20),

            AppTextField(
              controller: _emailCtrl,
              label: "Email Address",
              hint: "your@email.com",
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 20),

            AppTextField(
              controller: _phoneCtrl,
              label: "Phone Number",
              hint: "10-digit number",
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 32),

            AppButton(
              label: "Submit Request",
              loading: _loading,
              onTap: _submit,
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
