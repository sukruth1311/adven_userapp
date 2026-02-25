import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:user_app/features/user/details_screen.dart';
import 'package:user_app/features/user/user_home_screen.dart';
import 'package:user_app/themes/app_theme.dart';
import 'package:user_app/themes/app_widgets.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String firestoreDocId;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.firestoreDocId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool loading = false;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _anim.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
    if (_otp.length == 6) _verifyOTP();
  }

  Future<void> _verifyOTP() async {
    if (_otp.length != 6) {
      AppSnackbar.show(
        context,
        "Enter the complete 6-digit OTP",
        isError: true,
      );
      return;
    }

    setState(() => loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otp,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception("Authentication failed");

      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.firestoreDocId);

      final userDoc = await userDocRef.get();
      final userData = userDoc.data() ?? <String, dynamic>{};
      final bool isFirstLogin = userData['isFirstLogin'] ?? true;

      await userDocRef.update({
        'firebaseUid': firebaseUser.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) =>
              isFirstLogin ? const DetailsScreen() : const UserHomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        e.message ?? "OTP Verification Failed",
        isError: true,
      );
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.small,
                    border: Border.all(color: AppColors.border),
                    color: AppColors.surface,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: size.height * 0.04),

                        // Icon
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: AppRadius.medium,
                          ),
                          child: const Icon(
                            Icons.lock_open_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),

                        const SizedBox(height: 28),

                        Text(
                          "Verify Your\nNumber",
                          style: AppTextStyles.displayLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Enter the 6-digit code sent to your phone",
                          style: AppTextStyles.bodyMedium,
                        ),

                        SizedBox(height: size.height * 0.05),

                        // OTP boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            6,
                            (i) => OtpBox(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              onChanged: (v) => _onOtpChanged(v, i),
                            ),
                          ),
                        ),

                        SizedBox(height: size.height * 0.05),

                        AppButton(
                          label: "Verify & Continue",
                          loading: loading,
                          onTap: _otp.length == 6 ? _verifyOTP : null,
                          icon: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),

                        const SizedBox(height: 24),

                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                text: "Didn't receive the code? ",
                                style: AppTextStyles.bodySmall,
                                children: [
                                  TextSpan(
                                    text: "Resend",
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
