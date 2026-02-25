import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/widgets/app_button.dart';
import 'package:user_app/features/auth/otp_screen.dart';
import 'package:user_app/themes/app_theme.dart';
import 'package:user_app/themes/app_widgets.dart';
import '../../data/repositories/user_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final uidController = TextEditingController();
  final phoneController = TextEditingController();
  bool loading = false;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    uidController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final customUid = uidController.text.trim();
    String phone = phoneController.text.trim();

    if (customUid.isEmpty || phone.isEmpty) {
      AppSnackbar.show(
        context,
        "Please enter your UID and Phone number",
        isError: true,
      );
      return;
    }

    setState(() => loading = true);

    try {
      phone = phone.replaceAll(" ", "");
      if (phone.length == 10) phone = "+91$phone";
      if (phone.startsWith("91") && phone.length == 12) phone = "+$phone";
      if (!phone.startsWith("+")) throw Exception("Invalid phone format");

      final userDoc = await UserRepository().validateUID(
        customUid: customUid,
        phone: phone,
      );

      if (userDoc == null) {
        AppSnackbar.show(context, "Invalid UID or Phone number", isError: true);
        setState(() => loading = false);
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          AppSnackbar.show(
            context,
            e.message ?? "Verification failed",
            isError: true,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, anim, __) => OtpScreen(
                verificationId: verificationId,
                firestoreDocId: userDoc.id,
              ),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 350),
            ),
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      AppSnackbar.show(context, e.toString(), isError: true);
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.07),

                  // Brand icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: AppRadius.medium,
                    ),
                    child: const Icon(
                      Icons.flight_takeoff_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text("Welcome\nBack", style: AppTextStyles.displayLarge),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in to your member account",
                    style: AppTextStyles.bodyMedium,
                  ),

                  SizedBox(height: size.height * 0.055),

                  AppTextField(
                    controller: uidController,
                    label: "Member UID",
                    hint: "Enter your unique ID",
                    prefixIcon: Icons.badge_outlined,
                  ),

                  const SizedBox(height: 20),

                  AppTextField(
                    controller: phoneController,
                    label: "Phone Number",
                    hint: "10-digit mobile number",
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),

                  SizedBox(height: size.height * 0.05),

                  AppButton(
                    label: "Send OTP",
                    loading: loading,
                    onTap: _sendOTP,
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      "OTP will be sent to verify your registered number",
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
