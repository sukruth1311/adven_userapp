import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/features/user/reviews_screen.dart';
import 'package:user_app/features/user/services/banquet_service_scree.dart';
import 'package:user_app/features/user/services/event_service_screen.dart';
import 'package:user_app/features/user/services/hotel_request_screen.dart';
import 'package:user_app/features/user/services/gym_service_screen.dart';
import 'package:user_app/features/user/services/pool_service_screen.dart';
import 'package:user_app/features/user/services/resort_pass_screen.dart';
import 'package:user_app/features/user/services/insurance_service_screen.dart';
import 'package:user_app/state/user_provider.dart';
import 'package:user_app/state/user_stream.dart';
import 'package:user_app/themes/app_theme.dart';
import 'package:user_app/themes/app_widgets.dart';
import 'details_screen.dart';

class UserHomeScreen extends ConsumerWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: AppLoadingIndicator(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
      ),
      data: (doc) {
        if (doc == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final data = doc.data()!;
        final userId = doc.id;
        final bool isFirstLogin = data['isFirstLogin'] ?? true;
        final bool membershipActive = data['membershipActive'] ?? false;
        final String name = data['name'] ?? 'Member';

        final Map<String, dynamic> immunities = Map<String, dynamic>.from(
          data['immunities'] ?? {},
        );

        if (isFirstLogin) return const DetailsScreen();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                floating: false,
                elevation: innerBoxIsScrolled ? 3 : 0,
                shadowColor: Colors.black.withOpacity(0.08),
                backgroundColor: AppColors.surface,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                titleSpacing: 20,
                toolbarHeight: 62,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Good day,', style: AppTextStyles.bodySmall),
                    Text(name, style: AppTextStyles.headingSmall),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: AppRadius.medium,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            body: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          membershipActive
                              ? _MembershipCard(data: data)
                              : const _NoMemberBanner(),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),

                    const _DestinationCarousel(),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18),
                          GradientBannerCard(
                            title: 'Experience Adventure\nLike Never Before',
                            subtitle:
                                'Personalized journeys, seamless planning.',
                            colors: AppColors.heroBannerGradient,
                            icon: Icons.explore_outlined,
                          ),
                          const SizedBox(height: 26),
                          const SectionHeader(title: 'Our Services'),
                          _ServicesGrid(
                            userId: userId,
                            immunities: immunities,
                            membershipActive: membershipActive,
                          ),
                          const SizedBox(height: 26),
                          const SectionHeader(title: 'Popular Destinations'),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: _PopularDestinations(userId: userId),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 26),
                          _TestimonialsSection(
                            onWriteReview: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReviewsScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const _OfferBanner(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
//  MEMBERSHIP CARD
// ════════════════════════════════════════════════════════════
class _MembershipCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MembershipCard({required this.data});

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // Returns icon + color for the trip type
  static _TripStyle _tripStyle(String type) {
    switch (type) {
      case 'India + Asia':
        return _TripStyle(Icons.language_rounded, const Color(0xFF2E7D32));
      case 'India + International':
        return _TripStyle(Icons.public_rounded, const Color(0xFF9C27B0));
      default:
        return _TripStyle(Icons.flag_rounded, const Color(0xFF1565C0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = data['membershipName'] ?? 'Premium';
    final Timestamp? ts = data['expiryDate'];
    final DateTime? expiry = ts?.toDate();
    final String tripType = data['tripType'] ?? 'India';
    final List<String> packages = List<String>.from(
      data['allocatedPackages'] ?? [],
    );
    final Map<String, dynamic> imm = Map<String, dynamic>.from(
      data['immunities'] ?? {},
    );
    final List<String> activeImm = imm.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();
    final int totalHol = data['totalHolidays'] ?? 0;
    final int usedHol = data['usedHolidays'] ?? 0;
    final int remHol = data['remainingHolidays'] ?? 0;

    final ts2 = _tripStyle(tripType);

    return GestureDetector(
      onTap: () => _openPopup(
        context,
        name: name,
        expiry: expiry,
        tripType: tripType,
        packages: packages,
        imm: imm,
        totalHol: totalHol,
        usedHol: usedHol,
        remHol: remHol,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.memberGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.large,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: label + ACTIVE badge + info icon ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Premium Membership', style: AppTextStyles.bodyWhiteMuted),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: AppTextStyles.labelUppercase.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white.withOpacity(0.6),
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(name, style: AppTextStyles.headingWhite),
            if (expiry != null) ...[
              const SizedBox(height: 4),
              Text(
                'Valid until ${_formatDate(expiry)}',
                style: AppTextStyles.bodyWhiteMuted,
              ),
            ],

            const SizedBox(height: 12),

            // ── Trip type pill ─────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(ts2.icon, color: Colors.white, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    tripType,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            if (activeImm.isNotEmpty || packages.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...activeImm
                      .take(3)
                      .map(
                        (i) => AppChip(
                          label: i,
                          bgColor: Colors.white.withOpacity(0.18),
                          textColor: Colors.white,
                        ),
                      ),
                  ...packages
                      .take(2)
                      .map(
                        (p) => AppChip(
                          label: p,
                          bgColor: Colors.white.withOpacity(0.18),
                          textColor: Colors.white,
                        ),
                      ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 12,
                ),
                const SizedBox(width: 5),
                Text(
                  'Tap to view full details',
                  style: AppTextStyles.bodyWhiteMuted.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openPopup(
    BuildContext context, {
    required String name,
    required DateTime? expiry,
    required String tripType,
    required List<String> packages,
    required Map<String, dynamic> imm,
    required int totalHol,
    required int usedHol,
    required int remHol,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 380),
      transitionBuilder: (ctx, anim, _, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _MembershipPopup(
            name: name,
            expiry: expiry,
            tripType: tripType,
            packages: packages,
            imm: imm,
            totalHol: totalHol,
            usedHol: usedHol,
            remHol: remHol,
          ),
        ),
      ),
    );
  }
}

// Helper model
class _TripStyle {
  final IconData icon;
  final Color color;
  const _TripStyle(this.icon, this.color);
}

// ════════════════════════════════════════════════════════════
//  MEMBERSHIP POPUP
// ════════════════════════════════════════════════════════════
class _MembershipPopup extends StatelessWidget {
  final String name;
  final DateTime? expiry;
  final String tripType;
  final List<String> packages;
  final Map<String, dynamic> imm;
  final int totalHol, usedHol, remHol;

  const _MembershipPopup({
    required this.name,
    required this.expiry,
    required this.tripType,
    required this.packages,
    required this.imm,
    required this.totalHol,
    required this.usedHol,
    required this.remHol,
  });

  // Keys match membership_allocation_screen.dart exactly
  static const _fac = [
    ('Insurance', 'Insurance', Icons.health_and_safety_outlined),
    ('Gym Access', 'Gym', Icons.fitness_center_rounded),
    ('Swimming Pool', 'SwimmingPool', Icons.pool_rounded),
    ('Compliment Plot', 'ComplimentPlot', Icons.villa_outlined),
    ('Event Pass', 'Eventpass', Icons.confirmation_number_rounded),
    ('Resort Access', 'ResortAccess', Icons.villa_rounded),
    ('Banquet Hall', 'BanquetAccess', Icons.meeting_room_rounded),
  ];

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // Trip type → icon + background color
  IconData _tripIcon() {
    switch (tripType) {
      case 'India + Asia':
        return Icons.language_rounded;
      case 'India + International':
        return Icons.public_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  Color _tripAccentColor() {
    switch (tripType) {
      case 'India + Asia':
        return const Color(0xFF66BB6A);
      case 'India + International':
        return const Color(0xFFCE93D8);
      default:
        return const Color(0xFF90CAF9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = totalHol > 0
        ? (usedHol / totalHol).clamp(0.0, 1.0)
        : 0.0;
    final approvedFacilities = _fac.where((f) => imm[f.$2] == true).toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.extraLarge,
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.96),
              const Color(0xFF0F3D30).withOpacity(0.97),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.45),
              blurRadius: 40,
              spreadRadius: 2,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: membership name + close ───────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Membership',
                          style: AppTextStyles.bodyWhiteMuted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          name,
                          style: AppTextStyles.displayMedium.copyWith(
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: AppRadius.small,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              if (expiry != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.white.withOpacity(0.55),
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Expires: ${_formatDate(expiry!)}',
                      style: AppTextStyles.bodyWhiteMuted,
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // ── Trip Type badge ────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: AppRadius.medium,
                  border: Border.all(
                    color: _tripAccentColor().withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _tripAccentColor().withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _tripIcon(),
                        color: _tripAccentColor(),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRIP TYPE',
                          style: AppTextStyles.labelUppercase.copyWith(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tripType,
                          style: AppTextStyles.headingSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Holiday stats bar ──────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: AppRadius.medium,
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(child: _PStat('Total', '$totalHol days')),
                      VerticalDivider(
                        color: Colors.white.withOpacity(0.2),
                        thickness: 1,
                      ),
                      Expanded(child: _PStat('Used', '$usedHol days')),
                      VerticalDivider(
                        color: Colors.white.withOpacity(0.2),
                        thickness: 1,
                      ),
                      Expanded(child: _PStat('Left', '$remHol days')),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              Text(
                'Holiday Usage',
                style: AppTextStyles.labelUppercase.copyWith(
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4ECCA3),
                  ),
                ),
              ),

              // ── Included facilities ────────────────────────
              if (approvedFacilities.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Included Facilities',
                  style: AppTextStyles.labelUppercase.copyWith(
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 12),
                ...approvedFacilities.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          f.$3,
                          color: Colors.white.withOpacity(0.7),
                          size: 17,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f.$1,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF4ECCA3),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // ── Close button ───────────────────────────────
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: AppRadius.medium,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text(
                      'Close',
                      style: AppTextStyles.buttonText.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PStat extends StatelessWidget {
  final String label, value;
  const _PStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        value,
        style: AppTextStyles.headingSmall.copyWith(
          color: Colors.white,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: Colors.white.withOpacity(0.55),
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

// ════════════════════════════════════════════════════════════
//  NO MEMBERSHIP BANNER
// ════════════════════════════════════════════════════════════
class _NoMemberBanner extends StatelessWidget {
  const _NoMemberBanner();
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: AppRadius.small,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No Active Membership', style: AppTextStyles.headingSmall),
                const SizedBox(height: 2),
                Text(
                  'Contact admin to activate your plan.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  DESTINATION CAROUSEL
// ════════════════════════════════════════════════════════════
class _DestinationCarousel extends StatefulWidget {
  const _DestinationCarousel();
  @override
  State<_DestinationCarousel> createState() => _DestinationCarouselState();
}

class _DestinationCarouselState extends State<_DestinationCarousel> {
  late final PageController _ctrl;
  int _cur = 0;

  static const _slides = [
    _Slide(
      imageUrl: 'images/mal.jpg',
      title: 'Explore Maldives',
      subtitle: 'Crystal clear waters & white sand beaches',
    ),
    _Slide(
      imageUrl: 'images/ker.jpg',
      title: 'Discover Kerala',
      subtitle: "God's own country — backwaters & spices",
    ),
    _Slide(
      imageUrl: 'images/raj.jpg',
      title: 'Mystical Rajasthan',
      subtitle: 'Forts, deserts & royal heritage',
    ),
    _Slide(
      imageUrl: 'images/lad.jpg',
      title: 'Ladakh Adventure',
      subtitle: 'High altitude lakes & mountain passes',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 0.92, initialPage: 1000);
    _cur = 1000;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _cur = i),
            itemBuilder: (ctx, i) {
              final s = _slides[i % _slides.length];
              final isActive = i == _cur;
              return AnimatedScale(
                scale: isActive ? 1.0 : 0.95,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.large,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.large,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(s.imageUrl, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.65),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                s.title,
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.subtitle,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final isActive = (_cur % _slides.length) == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _Slide {
  final String imageUrl, title, subtitle;
  const _Slide({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  });
}

// ════════════════════════════════════════════════════════════
//  SERVICES GRID
// ════════════════════════════════════════════════════════════
class _ServicesGrid extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> immunities;
  final bool membershipActive;

  const _ServicesGrid({
    required this.userId,
    required this.immunities,
    required this.membershipActive,
  });

  List<_SI> _buildVisible() {
    final all = [
      _SI('Holiday', null, Icons.beach_access_rounded),
      _SI('Gym', 'gym', Icons.fitness_center_rounded),
      _SI('Pool', 'swimmingPool', Icons.pool_rounded),
      _SI('Resort Pass', 'resortAccess', Icons.villa_rounded),
      _SI('Insurance', 'Insurance', Icons.health_and_safety_rounded),
      _SI('Event Pass', 'eventpass', Icons.confirmation_number_rounded),
      _SI('Banquet Hall', 'banquetAccess', Icons.meeting_room_rounded),
    ];

    return all.where((s) {
      if (s.immunityKey == null) return true;
      if (!membershipActive) return false;
      return immunities[s.immunityKey!] == true;
    }).toList();
  }

  void _nav(BuildContext ctx, String title) {
    switch (title) {
      case 'Holiday':
        Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const HotelRequestScreen()),
        );
        break;
      case 'Gym':
        Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => GymServiceScreen(userId: userId)),
        );
        break;
      case 'Pool':
        Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => PoolServiceScreen(userId: userId)),
        );
        break;
      case 'Resort Pass':
        Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => ResortPassScreen(userId: userId)),
        );
        break;
      case 'Insurance':
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => InsuranceServiceScreen(userId: userId),
          ),
        );
        break;
      case 'Event Pass':
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => EventPassServiceScreen(userId: userId),
          ),
        );
        break;
      case 'Banquet Hall':
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => BanquetServiceScreen(userId: userId),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _buildVisible();

    if (visible.length <= 1) {
      return Column(
        children: [
          if (visible.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visible.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.6,
              ),
              itemBuilder: (ctx, i) => _buildTile(ctx, visible[i]),
            ),
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.6,
      ),
      itemBuilder: (ctx, i) => _buildTile(ctx, visible[i]),
    );
  }

  Widget _buildTile(BuildContext ctx, _SI s) {
    return GestureDetector(
      onTap: () => _nav(ctx, s.title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.medium,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: AppRadius.small,
              ),
              child: Icon(s.icon, color: AppColors.primary, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.title,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 10,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _SI {
  final String title;
  final String? immunityKey;
  final IconData icon;
  const _SI(this.title, this.immunityKey, this.icon);
}

// ════════════════════════════════════════════════════════════
//  POPULAR DESTINATIONS
// ════════════════════════════════════════════════════════════
class _PopularDestinations extends StatelessWidget {
  final String userId;
  const _PopularDestinations({required this.userId});

  static const _d = [
    _D('Goa', 'Beach', '🌊', Color(0xFF0F4C75)),
    _D('Manali', 'Snow', '❄️', Color(0xFF1A6B5A)),
    _D('Jaipur', 'Heritage', '🏰', Color(0xFFB5451B)),
    _D('Ooty', 'Hills', '🌄', Color(0xFF2E7D32)),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          ..._d.map(
            (d) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HotelRequestScreen()),
              ),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                width: 140,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [d.c, d.c.withOpacity(0.72)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.large,
                  boxShadow: [
                    BoxShadow(
                      color: d.c.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      d.em,
                      style: const TextStyle(fontSize: 36),
                      textAlign: TextAlign.center,
                    ),
                    Column(
                      children: [
                        Text(
                          d.n,
                          style: AppTextStyles.headingSmall.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            d.tag,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}

class _D {
  final String n, tag, em;
  final Color c;
  const _D(this.n, this.tag, this.em, this.c);
}

// ════════════════════════════════════════════════════════════
//  OFFER BANNER
// ════════════════════════════════════════════════════════════
class _OfferBanner extends StatelessWidget {
  const _OfferBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Special Offer 🎉',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Exclusive member discounts on your next trip!',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: AppRadius.small,
            ),
            child: Text(
              'Explore',
              style: AppTextStyles.labelMedium.copyWith(
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

// ════════════════════════════════════════════════════════════
//  TESTIMONIALS SECTION
// ════════════════════════════════════════════════════════════
class _TestimonialsSection extends StatelessWidget {
  final VoidCallback onWriteReview;
  const _TestimonialsSection({required this.onWriteReview});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                'Testimonial',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Our Clients Feedback',
                style: AppTextStyles.headingLarge.copyWith(fontSize: 22),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('isApproved', isEqualTo: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No reviews yet. Be the first!',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              );
            }
            return SizedBox(
              height: 320,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _ReviewCard(data: d);
                },
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Write a Review',
            onTap: onWriteReview,
            icon: const Icon(
              Icons.rate_review_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  REVIEW CARD
// ════════════════════════════════════════════════════════════
class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReviewCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final String name = data['name'] ?? 'Member';
    final String comment = data['comment'] ?? '';
    final int rating = (data['rating'] ?? 5).toInt();
    final String? imageUrl = data['imageUrl'];

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _AvatarPlaceholder(name),
                    )
                  : _AvatarPlaceholder(name),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.accent,
                        size: 17,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      comment,
                      style: AppTextStyles.bodySmall.copyWith(
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          name,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '"',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 32,
                          height: 0.9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  final String name;
  const _AvatarPlaceholder(this.name);
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.primarySurface,
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'M',
        style: AppTextStyles.displayMedium.copyWith(
          color: AppColors.primary.withOpacity(0.6),
        ),
      ),
    ),
  );
}
