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
//  ROOT CAUSE of [cloud_firestore/invalid-argument]:
//  ─────────────────────────────────────────────────
//  Admin creates users with .add() → random Firestore doc ID.
//  The user's Firebase UID is stored as a FIELD (firebaseUid), NOT the doc ID.
//  Calling collection('users').doc(firebaseUid) points to a non-existent doc.
//  tx.update() on a non-existent doc → invalid-argument.
//
//  FIX: Query users by firebaseUid field to get the real doc reference,
//       then use that ref for both reads and updates.
// ══════════════════════════════════════════════════════════════════════
class HotelRequestScreen extends StatefulWidget {
  const HotelRequestScreen({super.key});

  @override
  State<HotelRequestScreen> createState() => _HotelRequestScreenState();
}

class _HotelRequestScreenState extends State<HotelRequestScreen> {
  final _locationCtrl = TextEditingController();
  final _subDestCtrl = TextEditingController();
  final _memberNameCtrl = TextEditingController();
  final _specialCtrl = TextEditingController();

  DateTime? _checkIn;
  DateTime? _checkOut;
  DateTime? _travelDate;

  int _adults = 1;
  int _kids = 0;

  bool _isInternational = false;
  String _travelMode = 'Flight';

  PlatformFile? _aadharPlatformFile;
  bool _uploadingFile = false;
  bool _loading = false;

  bool _membershipActive = false;
  int _remainingHolidays = 0;
  DateTime? _lastRequestDate;
  bool _dataLoading = true;

  // The actual Firestore doc reference (NOT .doc(firebaseUid))
  DocumentReference? _userDocRef;

  // ── Computed ─────────────────────────────────────────────────────
  int get _nights {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays;
  }

  int get _totalTravellers => _adults + _kids;

  bool get _canMakeRequest {
    if (_lastRequestDate == null) return true;
    return DateTime.now().difference(_lastRequestDate!).inDays >= 90;
  }

  int get _daysRemaining {
    if (_lastRequestDate == null) return 0;
    final d = 90 - DateTime.now().difference(_lastRequestDate!).inDays;
    return d > 0 ? d : 0;
  }

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

  // ── Fetch membership — query by firebaseUid field ─────────────────
  // FIX: Users are created with .add() so doc ID ≠ Firebase UID.
  //      We must WHERE firebaseUid == uid to find the right document.
  Future<void> _fetchMembershipData() async {
    setState(() => _dataLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Query by the firebaseUid FIELD, not the doc ID
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('firebaseUid', isEqualTo: uid)
          .limit(1)
          .get();

      if (!mounted) return;
      if (query.docs.isEmpty) return; // user doc not yet linked

      final doc = query.docs.first;
      _userDocRef = doc.reference; // ← save the real ref for later
      final d = doc.data();

      setState(() {
        _membershipActive = d['membershipActive'] ?? false;
        _remainingHolidays = d['remainingHolidays'] ?? 0;

        // Handle Timestamp or ISO string
        final raw = d['lastHotelRequestDate'];
        if (raw is Timestamp)
          _lastRequestDate = raw.toDate();
        else if (raw is String)
          _lastRequestDate = DateTime.tryParse(raw);
        else
          _lastRequestDate = null;
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
    if (p != null)
      setState(() {
        _checkIn = p;
        if (_checkOut?.isBefore(p) == true) _checkOut = null;
      });
  }

  Future<void> _pickCheckOut() async {
    if (_checkIn == null) {
      AppSnackbar.show(context, 'Select check-in first', isError: true);
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

  // ── Pick Aadhaar — bytes mode (no content URI issues) ────────────
  Future<void> _pickAadhar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null) return;
    final picked = result.files.single;
    if (picked.bytes != null) {
      setState(() => _aadharPlatformFile = picked);
    } else if (picked.path != null) {
      final file = File(picked.path!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        setState(
          () => _aadharPlatformFile = PlatformFile(
            name: picked.name,
            size: bytes.length,
            bytes: bytes,
          ),
        );
      }
    }
  }

  // ── Upload — putData(bytes), no file path needed ──────────────────
  Future<String> _uploadAadhar(String requestId, String uid) async {
    setState(() => _uploadingFile = true);
    try {
      final file = _aadharPlatformFile!;
      final ext = file.name.split('.').last.toLowerCase();
      final ref = FirebaseStorage.instance.ref().child(
        'aadhar_documents/$uid/$requestId.$ext',
      );
      final meta = SettableMetadata(
        contentType: ext == 'pdf' ? 'application/pdf' : 'image/$ext',
      );
      final task = await ref.putData(file.bytes!, meta);
      return await task.ref.getDownloadURL();
    } finally {
      if (mounted) setState(() => _uploadingFile = false);
    }
  }

  // ── Submit ───────────────────────────────────────────────────────
  Future<void> _submit() async {
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
    if (_aadharPlatformFile == null) {
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
        'Only $_remainingHolidays holiday days left. Requested $_nights.',
        isError: true,
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');

      final requestId = const Uuid().v4();

      // Step 1 — upload Aadhaar bytes
      final aadharUrl = await _uploadAadhar(requestId, uid);

      // Step 2 — build model
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

      // Step 3 — save hotel request (strip nulls to avoid invalid-argument)
      final payload = Map<String, dynamic>.from(request.toJson())
        ..removeWhere((_, v) => v == null);
      await FirebaseFirestore.instance
          .collection('hotel_requests')
          .doc(requestId)
          .set(payload);

      // Step 4 — update user doc using the REAL doc reference
      // FIX: _userDocRef was fetched by querying WHERE firebaseUid == uid
      //      so it points to the actual document (not .doc(uid) which is wrong)
      if (_userDocRef != null) {
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final snap = await tx.get(_userDocRef!);
          final d = snap.data() as Map<String, dynamic>? ?? {};
          final int used = d['usedHolidays'] ?? 0;
          final int remaining = d['remainingHolidays'] ?? 0;

          final Map<String, dynamic> updates = {
            'lastHotelRequestDate': Timestamp.fromDate(DateTime.now()),
          };

          if (_membershipActive && _nights > 0) {
            updates['usedHolidays'] = used + _nights;
            updates['remainingHolidays'] = (remaining - _nights).clamp(0, 9999);
          }

          tx.update(_userDocRef!, updates);
        });
      }
      // If _userDocRef is null, user doc not linked yet — skip deduction silently

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
                  if (!_canMakeRequest) ...[
                    _InfoBanner(
                      message:
                          '⏳ Next request in $_daysRemaining days.\nOne request allowed every 90 days.',
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_membershipActive) ...[
                    _HolidayBalanceCard(
                      remaining: _remainingHolidays,
                      requested: _nights,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // SECTION 1 — Destination
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
                    hint: 'Resort, area or attraction',
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

                  // SECTION 2 — Dates
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
                  if (_nights > 0) ...[
                    const SizedBox(height: 12),
                    _NightsBadge(
                      nights: _nights,
                      remaining: _remainingHolidays,
                      isMember: _membershipActive,
                    ),
                  ],
                  const SizedBox(height: 28),

                  // SECTION 3 — Travellers
                  const _SecLabel('Travellers'),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      children: [
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
                                '  ($_adults adult${_adults == 1 ? '' : 's'}'
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

                  // SECTION 4 — Travel Options
                  const _SecLabel('Travel Options'),
                  const SizedBox(height: 12),
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

                  // SECTION 5 — Documents
                  const _SecLabel('Documents'),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickAadhar,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _aadharPlatformFile != null
                            ? AppColors.primarySurface
                            : AppColors.surface,
                        borderRadius: AppRadius.medium,
                        border: Border.all(
                          color: _aadharPlatformFile != null
                              ? AppColors.primary
                              : AppColors.border,
                          width: _aadharPlatformFile != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _aadharPlatformFile != null
                                  ? AppColors.primary
                                  : AppColors.primarySurface,
                              borderRadius: AppRadius.small,
                            ),
                            child: Icon(
                              _aadharPlatformFile != null
                                  ? Icons.check_circle_rounded
                                  : Icons.upload_file_rounded,
                              color: _aadharPlatformFile != null
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
                                  _aadharPlatformFile != null
                                      ? _aadharPlatformFile!.name
                                      : 'Tap to upload  •  JPG, PNG or PDF',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: _aadharPlatformFile != null
                                        ? AppColors.primary
                                        : AppColors.textHint,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (_aadharPlatformFile != null)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _aadharPlatformFile = null),
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
                  AppTextField(
                    controller: _specialCtrl,
                    label: 'Special Requests (optional)',
                    hint: 'Dietary needs, accessibility, preferences...',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 36),

                  AppButton(
                    label: !_canMakeRequest
                        ? 'Locked — Next in $_daysRemaining days'
                        : (_loading || _uploadingFile
                              ? 'Uploading & Submitting...'
                              : 'Submit Request'),
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

// ── Widgets ───────────────────────────────────────────────────────

class _SecLabel extends StatelessWidget {
  final String text;
  const _SecLabel(this.text);
  @override
  Widget build(BuildContext context) => Row(
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

class _InfoBanner extends StatelessWidget {
  final String message;
  final Color color;
  const _InfoBanner({required this.message, required this.color});
  @override
  Widget build(BuildContext context) => Container(
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
            style: AppTextStyles.bodySmall.copyWith(color: color, height: 1.55),
          ),
        ),
      ],
    ),
  );
}

class _HolidayBalanceCard extends StatelessWidget {
  final int remaining, requested;
  const _HolidayBalanceCard({required this.remaining, required this.requested});
  @override
  Widget build(BuildContext context) {
    final warn = requested > 0 && requested > remaining;
    final col = warn ? AppColors.error : AppColors.primary;
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

class _NightsBadge extends StatelessWidget {
  final int nights, remaining;
  final bool isMember;
  const _NightsBadge({
    required this.nights,
    required this.remaining,
    required this.isMember,
  });
  @override
  Widget build(BuildContext context) {
    final warn = isMember && nights > remaining;
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
            '$nights nights',
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

class _TravellerRow extends StatelessWidget {
  final String label, sublabel;
  final IconData icon;
  final Color iconColor;
  final int value, min, max;
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
    final col = stepColor ?? AppColors.primary;
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: enabled ? color.withOpacity(0.12) : AppColors.border,
        borderRadius: AppRadius.small,
      ),
      child: Icon(icon, color: enabled ? color : AppColors.textHint, size: 18),
    ),
  );
}
