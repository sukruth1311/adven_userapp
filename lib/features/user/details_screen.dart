import 'package:flutter/material.dart';
import 'package:user_app/features/user/user_home_screen.dart';
import 'package:user_app/themes/app_theme.dart';
import 'package:user_app/themes/app_widgets.dart';
import '../../data/repositories/user_repository.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen>
    with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  bool loading = false;

  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      AppSnackbar.show(context, "Please fill all fields", isError: true);
      return;
    }

    setState(() => loading = true);

    try {
      await UserRepository().updateUserDetails(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => const UserHomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
        (route) => false,
      );
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
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.07),

                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: AppRadius.medium,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.accent,
                    size: 26,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  "Complete\nYour Profile",
                  style: AppTextStyles.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  "We just need a couple of details to get you started",
                  style: AppTextStyles.bodyMedium,
                ),

                SizedBox(height: size.height * 0.055),

                AppTextField(
                  controller: nameController,
                  label: "Full Name",
                  hint: "Your full name",
                  prefixIcon: Icons.person_outline_rounded,
                ),

                const SizedBox(height: 20),

                AppTextField(
                  controller: emailController,
                  label: "Email Address",
                  hint: "your@email.com",
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: size.height * 0.05),

                AppButton(
                  label: "Continue",
                  loading: loading,
                  onTap: _saveDetails,
                  icon: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
