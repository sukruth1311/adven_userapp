import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user_app/themes/app_theme.dart';
import 'package:user_app/themes/app_widgets.dart';

// ══════════════════════════════════════════════════════════════════════
//  MEMBER UPLOAD SERVICE SCREEN
//  Used by: Gym, Swimming, Resort Pass, Event Pass, Insurance
//  Features:
//  • Adults + Children +/- steppers to set number of travellers
//  • Each member gets Name + Aadhaar upload
//  • Shows upload progress + success confirmation per member
//  • Nice UX with animated cards
// ══════════════════════════════════════════════════════════════════════
class MemberUploadServiceScreen extends StatefulWidget {
  final String serviceType;
  final int maxMembers;

  const MemberUploadServiceScreen({
    super.key,
    required this.serviceType,
    required this.maxMembers,
  });

  @override
  State<MemberUploadServiceScreen> createState() =>
      _MemberUploadServiceScreenState();
}

class _MemberUploadServiceScreenState extends State<MemberUploadServiceScreen> {
  int _adults = 1;
  int _children = 0;

  // Member entries: {name, aadharFile, aadharUrl, uploading, uploaded}
  List<Map<String, dynamic>> _members = [];

  bool _isSubmitting = false;

  int get _totalSlots => _adults + _children;
  int get _totalMax => widget.maxMembers;

  @override
  void initState() {
    super.initState();
    _syncMembers();
  }

  // ── Keep member list in sync with adult+child count ──────────────
  void _syncMembers() {
    final newTotal = _totalSlots;
    if (_members.length < newTotal) {
      while (_members.length < newTotal) {
        _members.add({
          'name': '',
          'aadharFile': null,
          'aadharUrl': null,
          'uploading': false,
          'uploaded': false,
          'isChild': _members.length >= _adults,
          'ctrl': TextEditingController(),
        });
      }
    } else if (_members.length > newTotal) {
      // Dispose removed controllers
      for (int i = newTotal; i < _members.length; i++) {
        (_members[i]['ctrl'] as TextEditingController?)?.dispose();
      }
      _members = _members.sublist(0, newTotal);
    }
    // Update isChild flags
    for (int i = 0; i < _members.length; i++) {
      _members[i]['isChild'] = i >= _adults;
    }
  }

  @override
  void dispose() {
    for (final m in _members) {
      (m['ctrl'] as TextEditingController?)?.dispose();
    }
    super.dispose();
  }

  // ── Pick aadhaar for a member ─────────────────────────────────────
  Future<void> _pickAadhar(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    setState(() {
      _members[index]['aadharFile'] = file;
      _members[index]['uploading'] = true;
      _members[index]['uploaded'] = false;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final ext = file.path.split('.').last;
      final ref = FirebaseStorage.instance.ref(
        'aadhar_documents/$uid/${widget.serviceType}_member_${index}_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _members[index]['aadharUrl'] = url;
          _members[index]['uploading'] = false;
          _members[index]['uploaded'] = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _members[index]['uploading'] = false;
          _members[index]['uploaded'] = false;
        });
        AppSnackbar.show(context, 'Upload failed: $e', isError: true);
      }
    }
  }

  // ── Submit ────────────────────────────────────────────────────────
  Future<void> _submit() async {
    // Validate all members have names
    for (int i = 0; i < _members.length; i++) {
      final ctrl = _members[i]['ctrl'] as TextEditingController;
      if (ctrl.text.trim().isEmpty) {
        AppSnackbar.show(
          context,
          'Please enter name for member ${i + 1}',
          isError: true,
        );
        return;
      }
    }

    // Validate all aadhaar uploaded
    for (int i = 0; i < _members.length; i++) {
      if (_members[i]['aadharUrl'] == null) {
        AppSnackbar.show(
          context,
          'Please upload Aadhaar for member ${i + 1}',
          isError: true,
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final membersData = _members
          .map(
            (m) => {
              'name': (m['ctrl'] as TextEditingController).text.trim(),
              'aadharUrl': m['aadharUrl'],
              'isChild': m['isChild'],
            },
          )
          .toList();

      await FirebaseFirestore.instance.collection('service_requests').add({
        'userId': uid,
        'serviceType': widget.serviceType,
        'members': membersData,
        'adults': _adults,
        'children': _children,
        'totalMembers': _totalSlots,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        AppSnackbar.show(
          context,
          '${widget.serviceType.toUpperCase()} request submitted!',
          isSuccess: true,
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        title: Text(widget.serviceType.toUpperCase()),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TRAVELLERS SECTION ──────────────────────────────────
            _SecLabel('Number of Travellers'),
            const SizedBox(height: 12),

            AppCard(
              child: Column(
                children: [
                  // Adults row
                  _CounterRow(
                    label: 'Adults',
                    sublabel: 'Age 12 and above',
                    icon: Icons.person_rounded,
                    iconColor: AppColors.primary,
                    value: _adults,
                    min: 1,
                    max: _totalMax - _children,
                    onChanged: (v) => setState(() {
                      _adults = v;
                      _syncMembers();
                    }),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: AppColors.divider, height: 1),
                  ),
                  // Children row
                  _CounterRow(
                    label: 'Children',
                    sublabel: 'Age 2 to 11',
                    icon: Icons.child_care_rounded,
                    iconColor: AppColors.accent,
                    value: _children,
                    min: 0,
                    max: _totalMax - _adults,
                    onChanged: (v) => setState(() {
                      _children = v;
                      _syncMembers();
                    }),
                    stepColor: AppColors.accent,
                  ),
                  const SizedBox(height: 12),
                  // Total pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
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
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total: $_totalSlots member${_totalSlots == 1 ? '' : 's'}'
                          '  ($_adults adult${_adults == 1 ? '' : 's'}'
                          '${_children > 0 ? ', $_children child${_children == 1 ? '' : 'ren'}' : ''})',
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

            // ── MEMBER DETAILS ──────────────────────────────────────
            _SecLabel('Member Details & Aadhaar'),
            const SizedBox(height: 4),
            Text(
              'Upload Aadhaar (JPG, PNG or PDF) for each member',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 14),

            // Member cards
            ...List.generate(_members.length, (i) {
              final m = _members[i];
              final isChild = m['isChild'] as bool;
              final ctrl = m['ctrl'] as TextEditingController;
              final bool uploading = m['uploading'] == true;
              final bool uploaded = m['uploaded'] == true;
              final String? url = m['aadharUrl'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card header
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isChild
                                  ? AppColors.accentLight
                                  : AppColors.primarySurface,
                              borderRadius: AppRadius.small,
                            ),
                            child: Icon(
                              isChild
                                  ? Icons.child_care_rounded
                                  : Icons.person_rounded,
                              color: isChild
                                  ? AppColors.accent
                                  : AppColors.primary,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isChild
                                ? 'Child ${i - _adults + 1}'
                                : 'Adult ${i + 1}',
                            style: AppTextStyles.headingSmall,
                          ),
                          const Spacer(),
                          if (uploaded)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Aadhaar Uploaded',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Name field
                      TextField(
                        controller: ctrl,
                        onChanged: (v) => _members[i]['name'] = v,
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Member Name *',
                          hintText: 'Enter full name as on Aadhaar',
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Aadhaar upload button
                      GestureDetector(
                        onTap: uploading ? null : () => _pickAadhar(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: uploaded
                                ? AppColors.success.withOpacity(0.07)
                                : AppColors.primarySurface,
                            borderRadius: AppRadius.medium,
                            border: Border.all(
                              color: uploaded
                                  ? AppColors.success.withOpacity(0.4)
                                  : AppColors.primary.withOpacity(0.2),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Status icon
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: uploaded
                                      ? AppColors.success
                                      : AppColors.primary,
                                  borderRadius: AppRadius.small,
                                ),
                                child: uploading
                                    ? const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        uploaded
                                            ? Icons.check_rounded
                                            : Icons.upload_file_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      uploading
                                          ? 'Uploading Aadhaar...'
                                          : uploaded
                                          ? 'Aadhaar Uploaded Successfully ✓'
                                          : 'Upload Aadhaar Document',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: uploading
                                            ? AppColors.textSecondary
                                            : uploaded
                                            ? AppColors.success
                                            : AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      uploading
                                          ? 'Please wait...'
                                          : uploaded
                                          ? 'Tap to change document'
                                          : 'JPG, PNG or PDF • Max 5MB',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Preview thumbnail for images
                              if (uploaded &&
                                  url != null &&
                                  !url.endsWith('.pdf'))
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    url,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 28),

            // Submit button
            AppButton(
              label: _isSubmitting ? 'Submitting...' : 'Submit Request',
              loading: _isSubmitting,
              onTap: _isSubmitting ? null : _submit,
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
}

// ── Section label ─────────────────────────────────────────────────
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
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          fontSize: 11,
        ),
      ),
    ],
  );
}

// ── Adults / Kids counter row ─────────────────────────────────────
class _CounterRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color iconColor;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final Color? stepColor;
  const _CounterRow({
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
        Row(
          children: [
            _StepBtn(
              icon: Icons.remove_rounded,
              color: col,
              enabled: value > min,
              onTap: () => onChanged(value - 1),
            ),
            SizedBox(
              width: 44,
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
