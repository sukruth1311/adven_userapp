import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/state/user_provider.dart';
import 'package:user_app/state/user_stream.dart';
import 'package:user_app/themes/app_theme.dart';
import 'package:user_app/themes/app_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider);
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.surface,
      ),
      body: userAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (doc) {
          final data = doc?.data() ?? {};
          final String name = data['name'] ?? 'Member';
          final String email = data['email'] ?? firebaseUser?.email ?? '';
          final String phone = data['phone'] ?? '';
          final String customUid = data['customUid'] ?? '';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar card
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.memberGradient,
                          ),
                          borderRadius: AppRadius.medium,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'M',
                            style: AppTextStyles.displayMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: AppTextStyles.headingSmall),
                            const SizedBox(height: 3),
                            Text(
                              email.isEmpty ? 'No email' : email,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (customUid.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                'UID: $customUid',
                                style: AppTextStyles.labelUppercase.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Account info
                const _SectionLabel('Account Information'),
                AppCard(
                  child: Column(
                    children: [
                      _InfoTile(
                        icon: Icons.person_outline_rounded,
                        label: 'Full Name',
                        value: name,
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _InfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: email.isEmpty ? '—' : email,
                      ),
                      if (phone.isNotEmpty) ...[
                        const Divider(height: 1, color: AppColors.divider),
                        _InfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: phone,
                        ),
                      ],
                      if (customUid.isNotEmpty) ...[
                        const Divider(height: 1, color: AppColors.divider),
                        _InfoTile(
                          icon: Icons.badge_outlined,
                          label: 'Member ID',
                          value: customUid,
                          isLast: true,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Activity
                const _SectionLabel('Activity'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: _LegalTile(
                    title: 'My Request History',
                    icon: Icons.history_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserHistoryScreen(),
                      ),
                    ),
                    isLast: true,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Legal
                const _SectionLabel('Legal'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _LegalTile(
                        title: 'Terms & Conditions',
                        icon: Icons.gavel_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TermsScreen(),
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                        color: AppColors.divider,
                      ),
                      _LegalTile(
                        title: 'Privacy Policy',
                        icon: Icons.privacy_tip_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyScreen(),
                          ),
                        ),
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Sign out
                AppOutlinedButton(
                  label: 'Sign Out',
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                  onTap: () async => await FirebaseAuth.instance.signOut(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: AppTextStyles.labelUppercase.copyWith(
        color: AppColors.textSecondary,
      ),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isLast;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LegalTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLast;
  const _LegalTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isLast = false,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: AppRadius.small,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.textHint,
            size: 14,
          ),
        ],
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  USER HISTORY SCREEN
// ════════════════════════════════════════════════════════════
class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({super.key});
  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _future = _loadAll(uid);
  }

  Future<List<Map<String, dynamic>>> _loadAll(String uid) async {
    final results = <Map<String, dynamic>>[];

    // Hotel requests
    try {
      final snap = await FirebaseFirestore.instance
          .collection('hotel_requests')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      for (final d in snap.docs) {
        final raw = d.data();
        final ts = raw['createdAt'];
        results.add({
          'type': 'Hotel',
          'icon': Icons.hotel_rounded,
          'title': raw['location'] ?? 'Hotel Request',
          'subtitle':
              'Check-in: ${_fmtTs(raw['checkIn'])}  •  ${raw['nights'] ?? '?'} nights',
          'status': raw['status'] ?? 'pending',
          'createdAt': ts is Timestamp ? ts.toDate() : null,
        });
      }
    } catch (_) {}

    // Service requests
    try {
      final snap = await FirebaseFirestore.instance
          .collection('service_requests')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      for (final d in snap.docs) {
        final raw = d.data();
        final type = raw['serviceType'] ?? 'Service';
        final ts = raw['createdAt'];
        results.add({
          'type': type,
          'icon': _svcIcon(type),
          'title': '${type[0].toUpperCase()}${type.substring(1)} Request',
          'subtitle': raw['memberName'] != null
              ? 'Member: ${raw['memberName']}'
              : '',
          'status': raw['status'] ?? 'pending',
          'createdAt': ts is Timestamp ? ts.toDate() : null,
        });
      }
    } catch (_) {}

    // Sort newest first
    results.sort((a, b) {
      final da = a['createdAt'] as DateTime?;
      final db = b['createdAt'] as DateTime?;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    return results;
  }

  String _fmtTs(dynamic ts) {
    if (ts == null) return '—';
    if (ts is Timestamp) return ts.toDate().toLocal().toString().split(' ')[0];
    return '—';
  }

  IconData _svcIcon(String t) {
    switch (t.toLowerCase()) {
      case 'holiday':
        return Icons.beach_access_rounded;
      case 'gym':
        return Icons.fitness_center_rounded;
      case 'swimming pool':
        return Icons.pool_rounded;
      case 'resort pass':
        return Icons.villa_rounded;
      default:
        return Icons.miscellaneous_services_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Requests'),
        backgroundColor: AppColors.surface,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return const AppLoadingIndicator();

          if (!snap.hasData || snap.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 60,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No requests yet',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hotel, holiday and service requests\nwill appear here.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            );
          }

          final items = snap.data!;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
              setState(() => _future = _loadAll(uid));
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _HistoryCard(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _HistoryCard({required this.item});

  static const _months = [
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

  String _fmtDate(DateTime dt) =>
      '${dt.day} ${_months[dt.month - 1]} ${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final String status = item['status'] ?? 'pending';
    final DateTime? dt = item['createdAt'];
    Color sBg, sTxt;
    switch (status) {
      case 'approved':
        sBg = AppColors.success.withOpacity(0.12);
        sTxt = AppColors.success;
        break;
      case 'rejected':
        sBg = AppColors.error.withOpacity(0.12);
        sTxt = AppColors.error;
        break;
      default:
        sBg = AppColors.warning.withOpacity(0.12);
        sTxt = AppColors.warning;
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: AppRadius.small,
            ),
            child: Icon(
              item['icon'] as IconData? ?? Icons.receipt_long_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'] as String? ?? '',
                        style: AppTextStyles.headingSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppChip(
                      label: status.toUpperCase(),
                      bgColor: sBg,
                      textColor: sTxt,
                    ),
                  ],
                ),
                if ((item['subtitle'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    item['subtitle'] as String,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                  ),
                ],
                if (dt != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _fmtDate(dt),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  TERMS & CONDITIONS
// ════════════════════════════════════════════════════════════
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    _LS(
      '1. Non-Refundable Vacation Privileges',
      'The member understands and agrees that vacation privilege charges are strictly non-refundable under any circumstances.',
    ),

    _LS(
      '2. Service Role Clarification',
      'ADVENTRA PRIVILEGE SERVICES is not involved in renting or selling vacation holidays. The company acts solely as a facilitator of membership-based services.',
    ),

    _LS(
      '3. Visa Assistance Disclaimer',
      'ADVENTRA PRIVILEGE SERVICES may provide visa assistance for assigned privilege services. Visa processing fees shall be borne by the client. The company is not responsible for visa approvals, rejections, or delays.',
    ),

    _LS(
      '4. Jurisdiction & Dispute Resolution',
      'All disputes arising out of or in relation to this agreement shall be subject to the exclusive jurisdiction of the courts including District/State/Magistrate/Consumer Forums located in Hyderabad alone.',
    ),

    _LS(
      '5. Peak Season Booking – Goa (Dec 25–31)',
      'For holiday bookings in Goa between December 25th and December 31st, booking requests must be submitted at least 60 days in advance to ensure availability.',
    ),

    _LS(
      '6. General Booking Timeline',
      'Booking requests must be made 30 to 45 days prior to the intended travel date. Last-minute bookings are subject to availability of rooms and cannot be guaranteed.',
    ),

    _LS(
      '7. Multiple Destination Disclosure',
      'Members must mention multiple preferred destinations at the time of booking to increase the chances of availability on requested dates.',
    ),

    _LS(
      '8. Maintenance Clearance Requirement',
      'Holiday privileges can be utilized only after clearance of all applicable Annual Maintenance Charges (AMC).',
    ),

    _LS(
      '9. Holiday Usage Policy',
      'Holiday benefits may be utilized under use/save/borrow/split options as per the applicable membership plan terms.',
    ),

    _LS(
      '10. Gap Between Holiday Bookings',
      'There must be a minimum gap of 3 months between two holiday bookings. Early booking before completion of the gap period may result in service charges.',
    ),

    _LS(
      '11. Payment Policy',
      'All payments must be transferred only to the official ADVENTRA PRIVILEGE SERVICES QR Code or company account after confirmation via official customer care. Payments made to any third-party individual accounts will not be considered valid.',
    ),
  ];

  @override
  Widget build(BuildContext context) => _LegalPage(
    title: 'Terms & Conditions',
    updated: 'February 25, 2025',
    sections: _sections,
  );
}

// ════════════════════════════════════════════════════════════
//  PRIVACY POLICY
// ════════════════════════════════════════════════════════════
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = [
    _LS(
      '1. Information We Collect',
      'We collect information you provide when registering for an account, including your name, email address, phone number, and device information. We also collect information about your use of the App, including service requests, booking history, and feature preferences.',
    ),
    _LS(
      '2. How We Use Your Information',
      'We use your personal information to provide and improve our services, process your bookings and requests, communicate with you about your account, and comply with legal obligations. We may send promotional materials only with your explicit consent.',
    ),
    _LS(
      '3. Information Sharing',
      'We do not sell your personal information to third parties. We may share your information with service providers who assist in delivering our services (such as hotel and travel partners), and with law enforcement when required by law.',
    ),
    _LS(
      '4. Data Security',
      'We implement industry-standard security measures including encryption, secure servers, and regular audits. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security of your data.',
    ),
    _LS(
      '5. Data Retention',
      'We retain your personal information for as long as necessary to provide our services and comply with legal obligations. Account data is retained for the duration of your membership plus the period required by applicable law after termination.',
    ),
    _LS(
      '6. Your Rights',
      'You have the right to access, correct, or request deletion of your personal data (subject to legal requirements). You may also object to processing or request portability of your data. Contact us through the App to exercise any of these rights.',
    ),
    _LS(
      '7. Cookies & Tracking',
      'Our App may use cookies and similar tracking technologies to enhance your experience and analyze usage patterns. You can control cookie settings through your device settings, though this may affect some App functionality.',
    ),
    _LS(
      "8. Children's Privacy",
      'Our App is not intended for users under 18 years of age. We do not knowingly collect personal information from minors. If we become aware of such collection, we will delete the data promptly.',
    ),
    _LS(
      '9. Changes to This Policy',
      'We may update this Privacy Policy from time to time. We will notify you of material changes by updating the date at the top and, where appropriate, by in-app notification. Continued use of the App after changes constitutes acceptance.',
    ),
    _LS(
      '10. Contact Us',
      'For questions about this Privacy Policy or our data practices, please contact our Data Protection Officer at privacy@travelapp.com or through the contact form in the App.',
    ),
  ];

  @override
  Widget build(BuildContext context) => _LegalPage(
    title: 'Privacy Policy',
    updated: 'February 25, 2025',
    sections: _sections,
  );
}

// ── Shared legal page layout ────────────────────────────────
class _LegalPage extends StatelessWidget {
  final String title, updated;
  final List<_LS> sections;
  const _LegalPage({
    required this.title,
    required this.updated,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title), backgroundColor: AppColors.surface),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              color: AppColors.primarySurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Last updated: $updated',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...sections.expand(
              (s) => [
                Text(s.h, style: AppTextStyles.headingSmall),
                const SizedBox(height: 8),
                Text(
                  s.b,
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.7,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LS {
  final String h, b;
  const _LS(this.h, this.b);
}
