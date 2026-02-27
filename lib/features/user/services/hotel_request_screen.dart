// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:user_app/core/services/firestore_service.dart';
// import 'package:user_app/data/models/hotel_request.dart';
// import 'package:user_app/themes/app_theme.dart';
// import 'package:user_app/themes/app_widgets.dart';
// import 'package:uuid/uuid.dart';
// import 'package:user_app/features/user/main_navigation.dart';

// class HotelRequestScreen extends StatefulWidget {
//   const HotelRequestScreen({super.key});
//   @override
//   State<HotelRequestScreen> createState() => _HotelRequestScreenState();
// }

// class _HotelRequestScreenState extends State<HotelRequestScreen> {
//   final _locationCtrl = TextEditingController();
//   final _specialCtrl = TextEditingController();

//   DateTime? checkIn;
//   DateTime? checkOut;
//   bool isInternational = false;
//   String travelMode = 'Flight';
//   bool _loading = false;

//   // +/- counters
//   int _members = 1;

//   @override
//   void dispose() {
//     _locationCtrl.dispose();
//     _specialCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _pickCheckIn() async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: checkIn ?? now,
//       firstDate: now,
//       lastDate: DateTime(2030),
//       builder: (ctx, child) => Theme(
//         data: Theme.of(ctx).copyWith(
//           colorScheme: const ColorScheme.light(primary: AppColors.primary),
//         ),
//         child: child!,
//       ),
//     );
//     if (picked != null) {
//       setState(() {
//         checkIn = picked;
//         if (checkOut != null && checkOut!.isBefore(picked)) checkOut = null;
//       });
//     }
//   }

//   Future<void> _pickCheckOut() async {
//     if (checkIn == null) {
//       AppSnackbar.show(
//         context,
//         'Please select check-in date first',
//         isError: true,
//       );
//       return;
//     }
//     final base = checkIn!;
//     final safeInit = (checkOut != null && !checkOut!.isBefore(base))
//         ? checkOut!
//         : base.add(const Duration(days: 1));
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: safeInit,
//       firstDate: base,
//       lastDate: DateTime(2030),
//       builder: (ctx, child) => Theme(
//         data: Theme.of(ctx).copyWith(
//           colorScheme: const ColorScheme.light(primary: AppColors.primary),
//         ),
//         child: child!,
//       ),
//     );
//     if (picked != null) setState(() => checkOut = picked);
//   }

//   Future<void> _submit() async {
//     try {
//       setState(() => _loading = true);

//       if (_locationCtrl.text.trim().isEmpty)
//         throw Exception('Please enter a location');
//       if (checkIn == null) throw Exception('Please select check-in date');
//       if (checkOut == null) throw Exception('Please select check-out date');
//       if (checkOut!.isBefore(checkIn!))
//         throw Exception('Check-out must be after check-in');

//       final uid = FirebaseAuth.instance.currentUser?.uid;
//       if (uid == null) throw Exception('User not logged in');

//       final nights = checkOut!.difference(checkIn!).inDays;

//       final request = HotelRequest(
//         id: const Uuid().v4(),
//         userId: uid,
//         checkIn: checkIn!,
//         checkOut: checkOut!,
//         location: _locationCtrl.text.trim(),
//         isInternational: isInternational,
//         nights: nights,
//         members: _members,
//         travelMode: travelMode,
//         specialRequest: _specialCtrl.text.trim(),
//         status: 'pending',
//         createdAt: DateTime.now(),
//       );

//       await FirestoreService.instance.createHotelRequest(request);

//       if (mounted) {
//         _locationCtrl.clear();
//         _specialCtrl.clear();
//         setState(() {
//           checkIn = null;
//           checkOut = null;
//           isInternational = false;
//           travelMode = 'Flight';
//           _members = 1;
//         });
//         AppSnackbar.show(context, 'Hotel request submitted!', isSuccess: true);
//         await Future.delayed(const Duration(milliseconds: 600));
//         if (mounted)
//           Navigator.of(context).pushAndRemoveUntil(
//             MaterialPageRoute(builder: (_) => const MainScreen()),
//             (r) => false,
//           );
//       }
//     } catch (e) {
//       if (mounted) AppSnackbar.show(context, 'Error: $e', isError: true);
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final nights = (checkIn != null && checkOut != null)
//         ? checkOut!.difference(checkIn!).inDays
//         : 0;

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text('Hotel Request'),
//         backgroundColor: AppColors.surface,
//       ),
//       body: SingleChildScrollView(
//         physics: const BouncingScrollPhysics(),
//         padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Location
//             AppTextField(
//               controller: _locationCtrl,
//               label: 'Destination',
//               hint: 'City or Country',
//               prefixIcon: Icons.location_on_outlined,
//             ),

//             const SizedBox(height: 20),

//             // Dates row
//             Row(
//               children: [
//                 Expanded(
//                   child: DatePickerButton(
//                     label: 'Check-in',
//                     value: checkIn,
//                     onTap: _pickCheckIn,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: DatePickerButton(
//                     label: 'Check-out',
//                     value: checkOut,
//                     onTap: _pickCheckOut,
//                   ),
//                 ),
//               ],
//             ),

//             // Nights badge
//             if (nights > 0) ...[
//               const SizedBox(height: 12),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 14,
//                   vertical: 10,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColors.primarySurface,
//                   borderRadius: AppRadius.medium,
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.nights_stay_outlined,
//                       color: AppColors.primary,
//                       size: 18,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       '$nights nights',
//                       style: AppTextStyles.headingSmall.copyWith(
//                         color: AppColors.primary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],

//             const SizedBox(height: 20),

//             // International toggle
//             AppCard(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(
//                         Icons.flight_rounded,
//                         color: AppColors.primary,
//                         size: 18,
//                       ),
//                       const SizedBox(width: 10),
//                       Text(
//                         'International Travel',
//                         style: AppTextStyles.bodyLarge,
//                       ),
//                     ],
//                   ),
//                   Switch.adaptive(
//                     value: isInternational,
//                     onChanged: (v) => setState(() => isInternational = v),
//                     activeColor: AppColors.primary,
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Members +/- stepper
//             Text('NUMBER OF MEMBERS', style: AppTextStyles.labelUppercase),
//             const SizedBox(height: 10),
//             AppCard(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(
//                         Icons.people_rounded,
//                         color: AppColors.primary,
//                         size: 18,
//                       ),
//                       const SizedBox(width: 10),
//                       Text('Members', style: AppTextStyles.bodyLarge),
//                     ],
//                   ),
//                   Row(
//                     children: [
//                       _StepBtn(
//                         icon: Icons.remove_rounded,
//                         onTap: () {
//                           if (_members > 1) setState(() => _members--);
//                         },
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 18),
//                         child: Text(
//                           '$_members',
//                           style: AppTextStyles.headingMedium.copyWith(
//                             color: AppColors.primary,
//                           ),
//                         ),
//                       ),
//                       _StepBtn(
//                         icon: Icons.add_rounded,
//                         onTap: () {
//                           if (_members < 20) setState(() => _members++);
//                         },
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Travel mode
//             Text('TRAVEL MODE', style: AppTextStyles.labelUppercase),
//             const SizedBox(height: 10),
//             AppCard(
//               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
//               child: Row(
//                 children: ['Flight', 'Train', 'Bus'].map((mode) {
//                   final sel = travelMode == mode;
//                   return Expanded(
//                     child: GestureDetector(
//                       onTap: () => setState(() => travelMode = mode),
//                       child: AnimatedContainer(
//                         duration: const Duration(milliseconds: 200),
//                         margin: const EdgeInsets.all(4),
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         decoration: BoxDecoration(
//                           color: sel ? AppColors.primary : Colors.transparent,
//                           borderRadius: AppRadius.medium,
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               _modeIcon(mode),
//                               color: sel
//                                   ? Colors.white
//                                   : AppColors.textSecondary,
//                               size: 16,
//                             ),
//                             const SizedBox(width: 6),
//                             Text(
//                               mode,
//                               style: AppTextStyles.labelMedium.copyWith(
//                                 color: sel
//                                     ? Colors.white
//                                     : AppColors.textSecondary,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),

//             const SizedBox(height: 20),

//             // Special requests
//             AppTextField(
//               controller: _specialCtrl,
//               label: 'Special Requests (optional)',
//               hint: 'Any preferences or special needs...',
//               prefixIcon: Icons.notes_rounded,
//               maxLines: 3,
//             ),

//             const SizedBox(height: 32),

//             AppButton(
//               label: 'Submit Request',
//               loading: _loading,
//               onTap: _submit,
//               icon: const Icon(
//                 Icons.check_rounded,
//                 color: Colors.white,
//                 size: 18,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   IconData _modeIcon(String mode) {
//     switch (mode) {
//       case 'Train':
//         return Icons.train_rounded;
//       case 'Bus':
//         return Icons.directions_bus_rounded;
//       default:
//         return Icons.flight_rounded;
//     }
//   }
// }

// // ── STEPPER BUTTON ─────────────────────────────
// class _StepBtn extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onTap;
//   const _StepBtn({required this.icon, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 34,
//         height: 34,
//         decoration: BoxDecoration(
//           color: AppColors.primarySurface,
//           borderRadius: AppRadius.small,
//         ),
//         child: Icon(icon, color: AppColors.primary, size: 18),
//       ),
//     );
//   }
// }import 'dart:io';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:user_app/core/services/firestore_service.dart';
import 'package:user_app/data/models/hotel_request.dart';
import 'package:user_app/themes/app_theme.dart';
import 'package:user_app/themes/app_widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:user_app/features/user/main_navigation.dart';

// ══════════════════════════════════════════════════════════════════════
//  MERGED HOLIDAY + HOTEL REQUEST SCREEN
//
//  What this screen does:
//  ✅ Collects holiday details (destination, sub-destination, member name)
//  ✅ Collects hotel details (check-in/out, travel mode, international)
//  ✅ Adults + Children steppers separately
//  ✅ Uploads Aadhaar to Firebase Storage, saves URL in Firestore
//  ✅ Deducts holiday days from membership balance (Firestore transaction)
//  ✅ Enforces 90-day cooldown between requests
//  ✅ Shows live holiday balance and deduction preview
// ══════════════════════════════════════════════════════════════════════
class HotelRequestScreen extends StatefulWidget {
  const HotelRequestScreen({super.key});

  @override
  State<HotelRequestScreen> createState() => _HotelRequestScreenState();
}

class _HotelRequestScreenState extends State<HotelRequestScreen> {
  // ── Text controllers ─────────────────────────────────────────────
  final _locationCtrl = TextEditingController();
  final _subDestCtrl = TextEditingController();
  final _memberNameCtrl = TextEditingController();
  final _specialCtrl = TextEditingController();

  // ── Dates ────────────────────────────────────────────────────────
  DateTime? _checkIn;
  DateTime? _checkOut;
  DateTime? _travelDate;

  // ── Travellers ───────────────────────────────────────────────────
  int _adults = 1;
  int _kids = 0;

  // ── Options ──────────────────────────────────────────────────────
  bool _isInternational = false;
  String _travelMode = 'Flight';

  // ── Aadhaar file ─────────────────────────────────────────────────
  File? _aadharFile;
  bool _uploadingFile = false;

  // ── State flags ──────────────────────────────────────────────────
  bool _loading = false;

  // ── Membership data (fetched on init) ────────────────────────────
  bool _membershipActive = false;
  int _remainingHolidays = 0;
  String? _lastRequestDateStr; // ISO 8601 string
  bool _dataLoading = true;

  // ── Computed getters ─────────────────────────────────────────────
  int get _nights {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays;
  }

  int get _totalTravellers => _adults + _kids;

  bool get _canMakeRequest {
    if (_lastRequestDateStr == null) return true;
    final last = DateTime.tryParse(_lastRequestDateStr!);
    if (last == null) return true;
    return DateTime.now().difference(last).inDays >= 90;
  }

  int get _daysRemaining {
    if (_lastRequestDateStr == null) return 0;
    final last = DateTime.tryParse(_lastRequestDateStr!);
    if (last == null) return 0;
    final d = 90 - DateTime.now().difference(last).inDays;
    return d > 0 ? d : 0;
  }

  // ── Init ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchMembershipData();
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _subDestCtrl.dispose();
    _memberNameCtrl.dispose();
    _specialCtrl.dispose();
    super.dispose();
  }

  // ── Fetch membership info from Firestore ─────────────────────────
  Future<void> _fetchMembershipData() async {
    setState(() => _dataLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!mounted) return;
      final d = snap.data() ?? {};
      setState(() {
        _membershipActive = d['membershipActive'] ?? false;
        _remainingHolidays = d['remainingHolidays'] ?? 0;
        _lastRequestDateStr =
            d['lastHotelRequestDate']; // ISO string we save on submit
      });
    } finally {
      if (mounted) setState(() => _dataLoading = false);
    }
  }

  // ── Date pickers ─────────────────────────────────────────────────
  Future<void> _pickCheckIn() async {
    final now = DateTime.now();
    final p = await showDatePicker(
      context: context,
      initialDate: _checkIn ?? now,
      firstDate: now,
      lastDate: DateTime(2035),
      builder: _dateTheme,
    );
    if (p != null) {
      setState(() {
        _checkIn = p;
        if (_checkOut != null && _checkOut!.isBefore(p)) _checkOut = null;
      });
    }
  }

  Future<void> _pickCheckOut() async {
    if (_checkIn == null) {
      AppSnackbar.show(
        context,
        'Please select check-in date first',
        isError: true,
      );
      return;
    }
    final base = _checkIn!;
    final init = (_checkOut != null && !_checkOut!.isBefore(base))
        ? _checkOut!
        : base.add(const Duration(days: 1));
    final p = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: base,
      lastDate: DateTime(2035),
      builder: _dateTheme,
    );
    if (p != null) setState(() => _checkOut = p);
  }

  Future<void> _pickTravelDate() async {
    final now = DateTime.now();
    final p = await showDatePicker(
      context: context,
      initialDate: _travelDate ?? now,
      firstDate: now,
      lastDate: DateTime(2035),
      builder: _dateTheme,
    );
    if (p != null) setState(() => _travelDate = p);
  }

  Widget _dateTheme(BuildContext ctx, Widget? child) => Theme(
    data: Theme.of(ctx).copyWith(
      colorScheme: const ColorScheme.light(primary: AppColors.primary),
    ),
    child: child!,
  );

  // ── Pick Aadhaar ─────────────────────────────────────────────────
  Future<void> _pickAadhar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _aadharFile = File(result.files.single.path!));
    }
  }

  // ── Upload Aadhaar to Firebase Storage ───────────────────────────
  Future<String> _uploadAadhar(String requestId, String uid) async {
    setState(() => _uploadingFile = true);
    try {
      final ext = _aadharFile!.path.split('.').last;
      final ref = FirebaseStorage.instance.ref().child(
        'aadhar_documents/$uid/$requestId.$ext',
      );
      final task = await ref.putFile(_aadharFile!);
      return await task.ref.getDownloadURL();
    } finally {
      if (mounted) setState(() => _uploadingFile = false);
    }
  }

  // ── Submit ───────────────────────────────────────────────────────
  Future<void> _submit() async {
    // ── Validations ─────────────────────────────────────────────
    if (_locationCtrl.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Please enter destination', isError: true);
      return;
    }
    if (_subDestCtrl.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Please enter sub-destination', isError: true);
      return;
    }
    if (_memberNameCtrl.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Please enter member name', isError: true);
      return;
    }
    if (_checkIn == null) {
      AppSnackbar.show(context, 'Please select check-in date', isError: true);
      return;
    }
    if (_checkOut == null) {
      AppSnackbar.show(context, 'Please select check-out date', isError: true);
      return;
    }
    if (_travelDate == null) {
      AppSnackbar.show(context, 'Please select travel date', isError: true);
      return;
    }
    if (_aadharFile == null) {
      AppSnackbar.show(
        context,
        'Please upload Aadhaar document',
        isError: true,
      );
      return;
    }
    if (!_canMakeRequest) {
      AppSnackbar.show(
        context,
        'Next request allowed in $_daysRemaining days',
        isError: true,
      );
      return;
    }
    if (_membershipActive && _nights > _remainingHolidays) {
      AppSnackbar.show(
        context,
        'Only $_remainingHolidays holiday days left. Requested $_nights days.',
        isError: true,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');

      final requestId = const Uuid().v4();

      // 1. Upload Aadhaar and get URL
      final aadharUrl = await _uploadAadhar(requestId, uid);

      // 2. Build request object
      final request = HotelRequest(
        id: requestId,
        userId: uid,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
        location: _locationCtrl.text.trim(),
        isInternational: _isInternational,
        nights: _nights,
        members: _totalTravellers,
        travelMode: _travelMode,
        specialRequest: _specialCtrl.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
        subDestination: _subDestCtrl.text.trim(),
        memberName: _memberNameCtrl.text.trim(),
        totalDays: _nights,
        adults: _adults,
        kids: _kids,
        travelDate: _travelDate,
        aadharUrl: aadharUrl,
      );

      // 3. Save to Firestore hotel_requests collection
      await FirebaseFirestore.instance
          .collection('hotel_requests')
          .doc(requestId)
          .set(request.toJson());

      // 4. Deduct holiday days from membership balance (atomic transaction)
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        final data = snap.data() ?? {};

        final int currentUsed = data['usedHolidays'] ?? 0;
        final int currentRemaining = data['remainingHolidays'] ?? 0;

        final Map<String, dynamic> updates = {
          'lastHotelRequestDate': DateTime.now().toIso8601String(),
        };

        // Only deduct if member has active membership with holiday balance
        if (_membershipActive && _nights > 0) {
          updates['usedHolidays'] = currentUsed + _nights;
          updates['remainingHolidays'] = (currentRemaining - _nights).clamp(
            0,
            9999,
          );
        }

        tx.update(userRef, updates);
      });

      if (mounted) {
        AppSnackbar.show(
          context,
          _membershipActive && _nights > 0
              ? '✅ Request submitted! $_nights holiday days deducted.'
              : '✅ Request submitted successfully!',
          isSuccess: true,
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (r) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Holiday & Hotel Request'),
        backgroundColor: AppColors.surface,
        centerTitle: false,
        elevation: 0,
      ),
      body: _dataLoading
          ? const AppLoadingIndicator()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 90-day lock banner ──────────────────────────────
                  if (!_canMakeRequest) ...[
                    _InfoBanner(
                      message:
                          '⏳ You can submit your next request in $_daysRemaining days.\nOne request is allowed every 90 days.',
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Holiday balance display ─────────────────────────
                  if (_membershipActive) ...[
                    _HolidayBalanceCard(
                      remaining: _remainingHolidays,
                      requested: _nights,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ══════════════════════════════════════════════════
                  //  SECTION 1 — Destination
                  // ══════════════════════════════════════════════════
                  const _SecLabel('Destination Details'),
                  const SizedBox(height: 12),

                  AppTextField(
                    controller: _locationCtrl,
                    label: 'Destination',
                    hint: 'City or Country',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    controller: _subDestCtrl,
                    label: 'Sub Destination',
                    hint: 'Resort, area or specific attraction',
                    prefixIcon: Icons.near_me_outlined,
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    controller: _memberNameCtrl,
                    label: 'Primary Member Name',
                    hint: 'Name as on Aadhaar',
                    prefixIcon: Icons.person_outline_rounded,
                  ),

                  const SizedBox(height: 28),

                  // ══════════════════════════════════════════════════
                  //  SECTION 2 — Dates
                  // ══════════════════════════════════════════════════
                  const _SecLabel('Travel Dates'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DatePickerButton(
                          label: 'Check-in',
                          value: _checkIn,
                          onTap: _pickCheckIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DatePickerButton(
                          label: 'Check-out',
                          value: _checkOut,
                          onTap: _pickCheckOut,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  DatePickerButton(
                    label: 'Departure / Travel Date',
                    value: _travelDate,
                    onTap: _pickTravelDate,
                  ),

                  // Nights badge
                  if (_nights > 0) ...[
                    const SizedBox(height: 12),
                    _NightsBadge(
                      nights: _nights,
                      remaining: _remainingHolidays,
                      isMember: _membershipActive,
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ══════════════════════════════════════════════════
                  //  SECTION 3 — Travellers
                  // ══════════════════════════════════════════════════
                  const _SecLabel('Travellers'),
                  const SizedBox(height: 12),

                  AppCard(
                    child: Column(
                      children: [
                        // Adults
                        _TravellerRow(
                          label: 'Adults',
                          sublabel: 'Age 12 and above',
                          icon: Icons.person_rounded,
                          iconColor: AppColors.primary,
                          value: _adults,
                          min: 1,
                          max: 20,
                          onChanged: (v) => setState(() => _adults = v),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: const Divider(
                            color: AppColors.divider,
                            height: 1,
                          ),
                        ),

                        // Children
                        _TravellerRow(
                          label: 'Children',
                          sublabel: 'Age 2 to 11',
                          icon: Icons.child_care_rounded,
                          iconColor: AppColors.accent,
                          value: _kids,
                          min: 0,
                          max: 10,
                          onChanged: (v) => setState(() => _kids = v),
                          stepColor: AppColors.accent,
                        ),

                        const SizedBox(height: 12),

                        // Total pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: AppRadius.medium,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.group_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Total: $_totalTravellers traveller${_totalTravellers == 1 ? '' : 's'}'
                                '  (${_adults} adult${_adults == 1 ? '' : 's'}'
                                '${_kids > 0 ? ', $_kids child${_kids == 1 ? '' : 'ren'}' : ''})',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ══════════════════════════════════════════════════
                  //  SECTION 4 — Travel Options
                  // ══════════════════════════════════════════════════
                  const _SecLabel('Travel Options'),
                  const SizedBox(height: 12),

                  // International toggle
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.flight_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'International Travel',
                              style: AppTextStyles.bodyLarge,
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _isInternational,
                          onChanged: (v) =>
                              setState(() => _isInternational = v),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Travel mode segment
                  Text('TRAVEL MODE', style: AppTextStyles.labelUppercase),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: ['Flight', 'Train', 'Bus'].map((mode) {
                        final sel = _travelMode == mode;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _travelMode = mode),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: AppRadius.medium,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _modeIcon(mode),
                                    size: 16,
                                    color: sel
                                        ? Colors.white
                                        : AppColors.textSecondary,
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

                  const SizedBox(height: 28),

                  // ══════════════════════════════════════════════════
                  //  SECTION 5 — Documents
                  // ══════════════════════════════════════════════════
                  const _SecLabel('Documents'),
                  const SizedBox(height: 12),

                  // Aadhaar upload box
                  GestureDetector(
                    onTap: _pickAadhar,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _aadharFile != null
                            ? AppColors.primarySurface
                            : AppColors.surface,
                        borderRadius: AppRadius.medium,
                        border: Border.all(
                          color: _aadharFile != null
                              ? AppColors.primary
                              : AppColors.border,
                          width: _aadharFile != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _aadharFile != null
                                  ? AppColors.primary
                                  : AppColors.primarySurface,
                              borderRadius: AppRadius.small,
                            ),
                            child: Icon(
                              _aadharFile != null
                                  ? Icons.check_circle_rounded
                                  : Icons.upload_file_rounded,
                              color: _aadharFile != null
                                  ? Colors.white
                                  : AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aadhaar Document *',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _aadharFile != null
                                      ? _aadharFile!.path.split('/').last
                                      : 'Tap to upload  •  JPG, PNG or PDF',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: _aadharFile != null
                                        ? AppColors.primary
                                        : AppColors.textHint,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (_aadharFile != null)
                            GestureDetector(
                              onTap: () => setState(() => _aadharFile = null),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textHint,
                                  size: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Special requests
                  AppTextField(
                    controller: _specialCtrl,
                    label: 'Special Requests (optional)',
                    hint: 'Dietary needs, accessibility, preferences...',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 36),

                  // ══════════════════════════════════════════════════
                  //  SUBMIT BUTTON
                  // ══════════════════════════════════════════════════
                  AppButton(
                    label: !_canMakeRequest
                        ? 'Locked — Next in $_daysRemaining days'
                        : _loading || _uploadingFile
                        ? 'Uploading & Submitting...'
                        : 'Submit Request',
                    loading: _loading || _uploadingFile,
                    onTap: (!_canMakeRequest || _loading || _uploadingFile)
                        ? null
                        : _submit,
                    icon: const Icon(
                      Icons.send_rounded,
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

// ══════════════════════════════════════════════════════════════════════
//  HELPER WIDGETS — all self-contained, no missing dependencies
// ══════════════════════════════════════════════════════════════════════

/// Coloured section label with vertical bar
class _SecLabel extends StatelessWidget {
  final String text;
  const _SecLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: AppTextStyles.labelUppercase.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Red / orange info banner
class _InfoBanner extends StatelessWidget {
  final String message;
  final Color color;
  const _InfoBanner({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: AppRadius.medium,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Holiday balance card showing remaining vs requested days
class _HolidayBalanceCard extends StatelessWidget {
  final int remaining;
  final int requested;
  const _HolidayBalanceCard({required this.remaining, required this.requested});

  @override
  Widget build(BuildContext context) {
    final bool warn = requested > 0 && requested > remaining;
    final Color col = warn ? AppColors.error : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: col.withOpacity(0.07),
        borderRadius: AppRadius.medium,
        border: Border.all(color: col.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: col.withOpacity(0.12),
              borderRadius: AppRadius.small,
            ),
            child: Icon(Icons.beach_access_rounded, color: col, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Holiday Balance',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$remaining days available',
                  style: AppTextStyles.headingSmall.copyWith(color: col),
                ),
              ],
            ),
          ),
          if (requested > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: col,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                warn ? '⚠ Exceeds balance' : '− $requested days',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Nights badge with remaining balance info
class _NightsBadge extends StatelessWidget {
  final int nights;
  final int remaining;
  final bool isMember;
  const _NightsBadge({
    required this.nights,
    required this.remaining,
    required this.isMember,
  });

  @override
  Widget build(BuildContext context) {
    final bool warn = isMember && nights > remaining;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: warn
            ? AppColors.error.withOpacity(0.08)
            : AppColors.primarySurface,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: warn
              ? AppColors.error.withOpacity(0.3)
              : AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.nights_stay_outlined,
            color: warn ? AppColors.error : AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            '$nights nights / days',
            style: AppTextStyles.headingSmall.copyWith(
              color: warn ? AppColors.error : AppColors.primary,
            ),
          ),
          const Spacer(),
          if (isMember)
            Text(
              warn ? 'Insufficient balance!' : '$remaining remaining',
              style: AppTextStyles.bodySmall.copyWith(
                color: warn ? AppColors.error : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/// One traveller type row (Adults or Children)
class _TravellerRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color iconColor;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final Color? stepColor;

  const _TravellerRow({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.stepColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color col = stepColor ?? AppColors.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: AppRadius.small,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyLarge),
                Text(
                  sublabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),

        // +/- stepper
        Row(
          children: [
            _StepBtn(
              icon: Icons.remove_rounded,
              color: col,
              enabled: value > min,
              onTap: () => onChanged(value - 1),
            ),
            SizedBox(
              width: 46,
              child: Center(
                child: Text(
                  '$value',
                  style: AppTextStyles.headingMedium.copyWith(color: col),
                ),
              ),
            ),
            _StepBtn(
              icon: Icons.add_rounded,
              color: col,
              enabled: value < max,
              onTap: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}

/// The + / - button used in steppers
class _StepBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  const _StepBtn({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.12) : AppColors.border,
          borderRadius: AppRadius.small,
        ),
        child: Icon(
          icon,
          color: enabled ? color : AppColors.textHint,
          size: 18,
        ),
      ),
    );
  }
}
