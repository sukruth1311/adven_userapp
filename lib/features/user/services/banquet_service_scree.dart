import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:user_app/themes/app_theme.dart';
import 'package:user_app/themes/app_widgets.dart';

class BanquetServiceScreen extends StatefulWidget {
  final String userId;
  const BanquetServiceScreen({super.key, required this.userId});

  @override
  State<BanquetServiceScreen> createState() => _BanquetServiceScreenState();
}

class _BanquetServiceScreenState extends State<BanquetServiceScreen> {
  final _areaCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  DateTime? _selectedDate;
  bool _loading = false;

  @override
  void dispose() {
    _areaCtrl.dispose();
    _pincodeCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final area = _areaCtrl.text.trim();
    final pincode = _pincodeCtrl.text.trim();
    final capacity = _capacityCtrl.text.trim();

    if (area.isEmpty) {
      AppSnackbar.show(context, 'Please enter area / location', isError: true);
      return;
    }
    if (pincode.isEmpty || pincode.length != 6) {
      AppSnackbar.show(context, 'Enter a valid 6-digit pincode', isError: true);
      return;
    }
    if (_selectedDate == null) {
      AppSnackbar.show(context, 'Please select an event date', isError: true);
      return;
    }
    if (capacity.isEmpty) {
      AppSnackbar.show(
        context,
        'Please enter required capacity',
        isError: true,
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // ✅ FIX 1: Use FirebaseAuth UID (what admin queries by)
      final uid = FirebaseAuth.instance.currentUser?.uid ?? widget.userId;

      // ✅ FIX 2: Save to 'service_requests' (same collection admin reads)
      // ✅ FIX 3: serviceType = 'banquetHall' (matches admin _services list)
      await FirebaseFirestore.instance.collection('service_requests').add({
        'userId': uid,
        'serviceType': 'banquetHall', // ← must match admin query exactly
        'area': area,
        'pincode': pincode,
        'capacity': int.tryParse(capacity) ?? capacity,
        'date': Timestamp.fromDate(_selectedDate!),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        AppSnackbar.show(
          context,
          'Banquet hall request submitted!',
          isSuccess: true,
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _fmtDate(DateTime dt) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AC Banquet Hall'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info banner ──────────────────────────────────────────────────
            AppCard(
              color: AppColors.primarySurface,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: AppRadius.medium,
                    ),
                    child: const Icon(
                      Icons.meeting_room_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AC Banquet Hall',
                          style: AppTextStyles.headingSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Fill in venue details and preferred date',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            _Label('VENUE DETAILS'),

            // Area
            AppTextField(
              controller: _areaCtrl,
              label: 'Area / Location',
              hint: 'e.g. Banjara Hills, Hyderabad',
              prefixIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 14),

            // Pincode
            AppTextField(
              controller: _pincodeCtrl,
              label: 'Pincode',
              hint: '6-digit pincode',
              prefixIcon: Icons.pin_drop_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),

            // Capacity
            AppTextField(
              controller: _capacityCtrl,
              label: 'Required Capacity (persons)',
              hint: 'e.g. 200',
              prefixIcon: Icons.people_rounded,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),

            // ── Date picker ──────────────────────────────────────────────────
            _Label('EVENT DATE'),
            GestureDetector(
              onTap: _pickDate,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: _selectedDate != null
                      ? AppColors.primarySurface
                      : AppColors.surface,
                  borderRadius: AppRadius.medium,
                  border: Border.all(
                    color: _selectedDate != null
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  boxShadow: AppShadows.subtle,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: _selectedDate != null
                          ? AppColors.primary
                          : AppColors.textHint,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? _fmtDate(_selectedDate!)
                            : 'Tap to select event date',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _selectedDate != null
                              ? AppColors.primary
                              : AppColors.textHint,
                          fontWeight: _selectedDate != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (_selectedDate != null)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 18,
                      )
                    else
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            AppButton(
              label: 'Submit Banquet Hall Request',
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
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: AppTextStyles.labelUppercase),
  );
}
