import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:user_app/core/services/firestore_service.dart';
import 'package:user_app/data/models/hotel_request.dart';
import 'package:user_app/themes/app_theme.dart';
import 'package:user_app/themes/app_widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:user_app/features/user/main_navigation.dart';

class HotelRequestScreen extends StatefulWidget {
  const HotelRequestScreen({super.key});
  @override
  State<HotelRequestScreen> createState() => _HotelRequestScreenState();
}

class _HotelRequestScreenState extends State<HotelRequestScreen> {
  final _locationCtrl = TextEditingController();
  final _specialCtrl = TextEditingController();

  DateTime? checkIn;
  DateTime? checkOut;
  bool isInternational = false;
  String travelMode = 'Flight';
  bool _loading = false;

  // +/- counters
  int _members = 1;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _specialCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCheckIn() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: checkIn ?? now,
      firstDate: now,
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        checkIn = picked;
        if (checkOut != null && checkOut!.isBefore(picked)) checkOut = null;
      });
    }
  }

  Future<void> _pickCheckOut() async {
    if (checkIn == null) {
      AppSnackbar.show(
        context,
        'Please select check-in date first',
        isError: true,
      );
      return;
    }
    final base = checkIn!;
    final safeInit = (checkOut != null && !checkOut!.isBefore(base))
        ? checkOut!
        : base.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: safeInit,
      firstDate: base,
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => checkOut = picked);
  }

  Future<void> _submit() async {
    try {
      setState(() => _loading = true);

      if (_locationCtrl.text.trim().isEmpty)
        throw Exception('Please enter a location');
      if (checkIn == null) throw Exception('Please select check-in date');
      if (checkOut == null) throw Exception('Please select check-out date');
      if (checkOut!.isBefore(checkIn!))
        throw Exception('Check-out must be after check-in');

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      final nights = checkOut!.difference(checkIn!).inDays;

      final request = HotelRequest(
        id: const Uuid().v4(),
        userId: uid,
        checkIn: checkIn!,
        checkOut: checkOut!,
        location: _locationCtrl.text.trim(),
        isInternational: isInternational,
        nights: nights,
        members: _members,
        travelMode: travelMode,
        specialRequest: _specialCtrl.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await FirestoreService.instance.createHotelRequest(request);

      if (mounted) {
        _locationCtrl.clear();
        _specialCtrl.clear();
        setState(() {
          checkIn = null;
          checkOut = null;
          isInternational = false;
          travelMode = 'Flight';
          _members = 1;
        });
        AppSnackbar.show(context, 'Hotel request submitted!', isSuccess: true);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (r) => false,
          );
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nights = (checkIn != null && checkOut != null)
        ? checkOut!.difference(checkIn!).inDays
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hotel Request'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location
            AppTextField(
              controller: _locationCtrl,
              label: 'Destination',
              hint: 'City or Country',
              prefixIcon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 20),

            // Dates row
            Row(
              children: [
                Expanded(
                  child: DatePickerButton(
                    label: 'Check-in',
                    value: checkIn,
                    onTap: _pickCheckIn,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DatePickerButton(
                    label: 'Check-out',
                    value: checkOut,
                    onTap: _pickCheckOut,
                  ),
                ),
              ],
            ),

            // Nights badge
            if (nights > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: AppRadius.medium,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.nights_stay_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$nights nights',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // International toggle
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.flight_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'International Travel',
                        style: AppTextStyles.bodyLarge,
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: isInternational,
                    onChanged: (v) => setState(() => isInternational = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Members +/- stepper
            Text('NUMBER OF MEMBERS', style: AppTextStyles.labelUppercase),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text('Members', style: AppTextStyles.bodyLarge),
                    ],
                  ),
                  Row(
                    children: [
                      _StepBtn(
                        icon: Icons.remove_rounded,
                        onTap: () {
                          if (_members > 1) setState(() => _members--);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          '$_members',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      _StepBtn(
                        icon: Icons.add_rounded,
                        onTap: () {
                          if (_members < 20) setState(() => _members++);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Travel mode
            Text('TRAVEL MODE', style: AppTextStyles.labelUppercase),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: ['Flight', 'Train', 'Bus'].map((mode) {
                  final sel = travelMode == mode;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => travelMode = mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : Colors.transparent,
                          borderRadius: AppRadius.medium,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _modeIcon(mode),
                              color: sel
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              mode,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: sel
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Special requests
            AppTextField(
              controller: _specialCtrl,
              label: 'Special Requests (optional)',
              hint: 'Any preferences or special needs...',
              prefixIcon: Icons.notes_rounded,
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            AppButton(
              label: 'Submit Request',
              loading: _loading,
              onTap: _submit,
              icon: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'Train':
        return Icons.train_rounded;
      case 'Bus':
        return Icons.directions_bus_rounded;
      default:
        return Icons.flight_rounded;
    }
  }
}

// ── STEPPER BUTTON ─────────────────────────────
class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: AppRadius.small,
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
    );
  }
}
