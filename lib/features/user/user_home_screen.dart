// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:user_app/features/user/hotel_request_screen.dart';
// import 'package:user_app/features/user/reviews_screen.dart';

// import 'package:user_app/features/user/services/gym_service_screen.dart';
// import 'package:user_app/features/user/services/holiday_service_screen.dart';
// import 'package:user_app/features/user/services/pool_service_screen.dart';
// import 'package:user_app/features/user/services/resort_pass_screen.dart';
// import 'package:user_app/state/user_provider.dart';
// import 'package:user_app/state/user_stream.dart';
// import 'package:user_app/themes/app_theme.dart';
// import 'package:user_app/themes/app_widgets.dart';
// import 'details_screen.dart';

// class UserHomeScreen extends ConsumerWidget {
//   const UserHomeScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final userAsync = ref.watch(userDataProvider);

//     return userAsync.when(
//       loading: () => const Scaffold(
//         backgroundColor: AppColors.background,
//         body: AppLoadingIndicator(),
//       ),
//       error: (e, _) => Scaffold(
//         backgroundColor: AppColors.background,
//         body: Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
//       ),
//       data: (doc) {
//         if (doc == null) {
//           return const Scaffold(
//             backgroundColor: AppColors.background,
//             body: Center(
//               child: CircularProgressIndicator(color: AppColors.primary),
//             ),
//           );
//         }
//         final data = doc.data()!;
//         final userId = doc.id;
//         final bool isFirstLogin = data['isFirstLogin'] ?? true;
//         final bool membershipActive = data['membershipActive'] ?? false;
//         final String name = data['name'] ?? 'Member';

//         if (isFirstLogin) return const DetailsScreen();

//         return Scaffold(
//           backgroundColor: AppColors.background,
//           body: NestedScrollView(
//             headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
//               SliverAppBar(
//                 pinned: true,
//                 floating: false,
//                 elevation: innerBoxIsScrolled ? 3 : 0,
//                 shadowColor: Colors.black.withOpacity(0.08),
//                 backgroundColor: AppColors.surface,
//                 surfaceTintColor: Colors.transparent,
//                 automaticallyImplyLeading: false,
//                 titleSpacing: 20,
//                 toolbarHeight: 62,
//                 title: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text('Good day,', style: AppTextStyles.bodySmall),
//                     Text(name, style: AppTextStyles.headingSmall),
//                   ],
//                 ),
//                 actions: [
//                   Padding(
//                     padding: const EdgeInsets.only(right: 20),
//                     child: Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: AppColors.primarySurface,
//                         borderRadius: AppRadius.medium,
//                       ),
//                       child: const Icon(
//                         Icons.notifications_none_rounded,
//                         color: AppColors.primary,
//                         size: 22,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//             body: SafeArea(
//               top: false,
//               child: SingleChildScrollView(
//                 physics: const BouncingScrollPhysics(),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const SizedBox(height: 20),
//                       membershipActive
//                           ? _MembershipCard(data: data)
//                           : const _NoMemberBanner(),
//                       const SizedBox(height: 22),
//                       const _DestinationCarousel(),
//                       const SizedBox(height: 22),
//                       GradientBannerCard(
//                         title: 'Experience Adventure\nLike Never Before',
//                         subtitle: 'Personalized journeys, seamless planning.',
//                         colors: AppColors.heroBannerGradient,
//                         icon: Icons.explore_outlined,
//                       ),
//                       const SizedBox(height: 26),
//                       const SectionHeader(title: 'Our Services'),

//                       _ServicesRow(userId: userId),
//                       const SizedBox(height: 26),
//                       const SectionHeader(title: 'Popular Destinations'),
//                       const SizedBox(height: 14),
//                       _PopularDestinations(userId: userId),
//                       const SizedBox(height: 26),
//                       const SizedBox(height: 30),
//                       const Text(
//                         "Testimonials",
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),

//                       StreamBuilder<QuerySnapshot>(
//                         stream: FirebaseFirestore.instance
//                             .collection('reviews')
//                             .where('status', isEqualTo: 'approved')
//                             .snapshots(),
//                         builder: (context, snapshot) {
//                           if (!snapshot.hasData) {
//                             return const CircularProgressIndicator();
//                           }

//                           final reviews = snapshot.data!.docs;

//                           return Column(
//                             children: reviews.map((doc) {
//                               return Card(
//                                 child: ListTile(
//                                   leading: CircleAvatar(
//                                     backgroundImage: NetworkImage(
//                                       doc['imageUrl'],
//                                     ),
//                                   ),
//                                   title: Text(doc['name']),
//                                   subtitle: Text(doc['comment']),
//                                   trailing: Text("${doc['rating']} ⭐"),
//                                 ),
//                               );
//                             }).toList(),
//                           );
//                         },
//                       ),

//                       const SizedBox(height: 20),

//                       ElevatedButton(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const ReviewsScreen(),
//                             ),
//                           );
//                         },
//                         child: const Text("Write a Review"),
//                       ),
//                       const _OfferBanner(),
//                       const SizedBox(height: 32),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// // ── MEMBERSHIP CARD ──────────────────────────────────────────────────────────
// class _MembershipCard extends StatelessWidget {
//   final Map<String, dynamic> data;
//   const _MembershipCard({required this.data});

//   String _formatDate(DateTime dt) {
//     final d = dt.toLocal();
//     return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String name = data['membershipName'] ?? 'Premium';
//     final Timestamp? ts = data['expiryDate'];
//     final DateTime? expiry = ts?.toDate();
//     final List<String> packages = List<String>.from(
//       data['allocatedPackages'] ?? [],
//     );
//     final Map<String, dynamic> imm = Map<String, dynamic>.from(
//       data['immunities'] ?? {},
//     );
//     final List<String> activeImm = imm.entries
//         .where((e) => e.value == true)
//         .map((e) => e.key)
//         .toList();
//     final int totalHol = data['totalHolidays'] ?? 0;
//     final int usedHol = data['usedHolidays'] ?? 0;
//     final int remHol = data['remainingHolidays'] ?? 0;

//     return GestureDetector(
//       onTap: () => _openPopup(
//         context,
//         name: name,
//         expiry: expiry,
//         packages: packages,
//         imm: imm,
//         totalHol: totalHol,
//         usedHol: usedHol,
//         remHol: remHol,
//       ),
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(22),
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: AppColors.memberGradient,
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: AppRadius.large,
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.primary.withOpacity(0.35),
//               blurRadius: 20,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('Premium Membership', style: AppTextStyles.bodyWhiteMuted),
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.18),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         'ACTIVE',
//                         style: AppTextStyles.labelUppercase.copyWith(
//                           color: Colors.white,
//                           fontSize: 10,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Icon(
//                       Icons.info_outline_rounded,
//                       color: Colors.white.withOpacity(0.6),
//                       size: 16,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(name, style: AppTextStyles.headingWhite),
//             if (expiry != null) ...[
//               const SizedBox(height: 4),
//               Text(
//                 'Valid until ${_formatDate(expiry)}',
//                 style: AppTextStyles.bodyWhiteMuted,
//               ),
//             ],
//             if (activeImm.isNotEmpty || packages.isNotEmpty) ...[
//               const SizedBox(height: 16),
//               Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children: [
//                   ...activeImm
//                       .take(3)
//                       .map(
//                         (i) => AppChip(
//                           label: i,
//                           bgColor: Colors.white.withOpacity(0.18),
//                           textColor: Colors.white,
//                         ),
//                       ),
//                   ...packages
//                       .take(2)
//                       .map(
//                         (p) => AppChip(
//                           label: p,
//                           bgColor: Colors.white.withOpacity(0.18),
//                           textColor: Colors.white,
//                         ),
//                       ),
//                 ],
//               ),
//             ],
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Icon(
//                   Icons.touch_app_rounded,
//                   color: Colors.white.withOpacity(0.5),
//                   size: 12,
//                 ),
//                 const SizedBox(width: 5),
//                 Text(
//                   'Tap to view full details',
//                   style: AppTextStyles.bodyWhiteMuted.copyWith(fontSize: 11),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _openPopup(
//     BuildContext context, {
//     required String name,
//     required DateTime? expiry,
//     required List<String> packages,
//     required Map<String, dynamic> imm,
//     required int totalHol,
//     required int usedHol,
//     required int remHol,
//   }) {
//     showGeneralDialog(
//       context: context,
//       barrierDismissible: true,
//       barrierLabel: 'close',
//       barrierColor: Colors.black.withOpacity(0.55),
//       transitionDuration: const Duration(milliseconds: 380),
//       transitionBuilder: (ctx, anim, _, child) {
//         final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
//         return ScaleTransition(
//           scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
//           child: FadeTransition(opacity: anim, child: child),
//         );
//       },
//       pageBuilder: (ctx, _, __) => Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20),
//           child: _MembershipPopup(
//             name: name,
//             expiry: expiry,
//             packages: packages,
//             imm: imm,
//             totalHol: totalHol,
//             usedHol: usedHol,
//             remHol: remHol,
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ── GLASSMORPHISM POPUP ──────────────────────────────────────────────────────
// class _MembershipPopup extends StatelessWidget {
//   final String name;
//   final DateTime? expiry;
//   final List<String> packages;
//   final Map<String, dynamic> imm;
//   final int totalHol, usedHol, remHol;

//   const _MembershipPopup({
//     required this.name,
//     required this.expiry,
//     required this.packages,
//     required this.imm,
//     required this.totalHol,
//     required this.usedHol,
//     required this.remHol,
//   });

//   static const _fac = [
//     ('Travel Insurance', 'travelInsurance', Icons.health_and_safety_outlined),
//     ('Gym Access', 'gym', Icons.fitness_center_rounded),
//     ('Swimming Pool', 'swimmingPool', Icons.pool_rounded),
//     ('Compliment Plot', 'complimentPlot', Icons.villa_outlined),
//   ];

//   String _formatDate(DateTime dt) {
//     final d = dt.toLocal();
//     return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final double progress = totalHol > 0
//         ? (usedHol / totalHol).clamp(0.0, 1.0)
//         : 0.0;

//     /// 🔥 FILTER ONLY APPROVED IMMUNITIES
//     final approvedFacilities = _fac.where((f) => imm[f.$2] == true).toList();

//     return Material(
//       color: Colors.transparent,
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: AppRadius.extraLarge,
//           gradient: LinearGradient(
//             colors: [
//               AppColors.primary.withOpacity(0.96),
//               const Color(0xFF0F3D30).withOpacity(0.97),
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           border: Border.all(color: Colors.white.withOpacity(0.14)),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.primary.withOpacity(0.45),
//               blurRadius: 40,
//               spreadRadius: 2,
//               offset: const Offset(0, 14),
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// HEADER
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Premium Membership',
//                         style: AppTextStyles.bodyWhiteMuted,
//                       ),
//                       const SizedBox(height: 3),
//                       Text(
//                         name,
//                         style: AppTextStyles.displayMedium.copyWith(
//                           color: Colors.white,
//                           height: 1.1,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     width: 34,
//                     height: 34,
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.14),
//                       borderRadius: AppRadius.small,
//                     ),
//                     child: const Icon(
//                       Icons.close_rounded,
//                       color: Colors.white,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             if (expiry != null) ...[
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Icon(
//                     Icons.calendar_month_outlined,
//                     color: Colors.white.withOpacity(0.55),
//                     size: 13,
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     'Expires: ${_formatDate(expiry!)}',
//                     style: AppTextStyles.bodyWhiteMuted,
//                   ),
//                 ],
//               ),
//             ],

//             const SizedBox(height: 20),

//             /// STAT BOX
//             Container(
//               padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.1),
//                 borderRadius: AppRadius.medium,
//                 border: Border.all(color: Colors.white.withOpacity(0.1)),
//               ),
//               child: IntrinsicHeight(
//                 child: Row(
//                   children: [
//                     Expanded(child: _PStat('Total', '$totalHol days')),
//                     VerticalDivider(
//                       color: Colors.white.withOpacity(0.2),
//                       thickness: 1,
//                     ),
//                     Expanded(child: _PStat('Used', '$usedHol days')),
//                     VerticalDivider(
//                       color: Colors.white.withOpacity(0.2),
//                       thickness: 1,
//                     ),
//                     Expanded(child: _PStat('Left', '$remHol days')),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 18),

//             /// PROGRESS
//             Text(
//               'Holiday Usage',
//               style: AppTextStyles.labelUppercase.copyWith(
//                 color: Colors.white.withOpacity(0.55),
//               ),
//             ),
//             const SizedBox(height: 8),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(6),
//               child: LinearProgressIndicator(
//                 value: progress,
//                 minHeight: 8,
//                 backgroundColor: Colors.white.withOpacity(0.15),
//                 valueColor: const AlwaysStoppedAnimation<Color>(
//                   Color(0xFF4ECCA3),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             /// INCLUDED FACILITIES (ONLY APPROVED)
//             if (approvedFacilities.isNotEmpty) ...[
//               Text(
//                 'Included Facilities',
//                 style: AppTextStyles.labelUppercase.copyWith(
//                   color: Colors.white.withOpacity(0.55),
//                 ),
//               ),
//               const SizedBox(height: 12),

//               ...approvedFacilities.map((f) {
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 10),
//                   child: Row(
//                     children: [
//                       Icon(
//                         f.$3,
//                         color: Colors.white.withOpacity(0.7),
//                         size: 17,
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: Text(
//                           f.$1,
//                           style: AppTextStyles.bodyMedium.copyWith(
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                       const Icon(
//                         Icons.check_circle_rounded,
//                         color: Color(0xFF4ECCA3),
//                         size: 20,
//                       ),
//                     ],
//                   ),
//                 );
//               }),
//             ],

//             const SizedBox(height: 22),

//             /// CLOSE BUTTON
//             GestureDetector(
//               onTap: () => Navigator.pop(context),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 13),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.14),
//                   borderRadius: AppRadius.medium,
//                   border: Border.all(color: Colors.white.withOpacity(0.2)),
//                 ),
//                 child: Center(
//                   child: Text(
//                     'Close',
//                     style: AppTextStyles.buttonText.copyWith(
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _PStat extends StatelessWidget {
//   final String label, value;
//   const _PStat(this.label, this.value);
//   @override
//   Widget build(BuildContext context) => Column(
//     mainAxisAlignment: MainAxisAlignment.center,
//     children: [
//       Text(
//         value,
//         style: AppTextStyles.headingSmall.copyWith(
//           color: Colors.white,
//           fontSize: 13,
//         ),
//         textAlign: TextAlign.center,
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//       ),
//       const SizedBox(height: 2),
//       Text(
//         label,
//         style: AppTextStyles.bodySmall.copyWith(
//           color: Colors.white.withOpacity(0.55),
//           fontSize: 11,
//         ),
//         textAlign: TextAlign.center,
//       ),
//     ],
//   );
// }

// // ── NO MEMBERSHIP BANNER ──────────────────────────────────────────────────────
// class _NoMemberBanner extends StatelessWidget {
//   const _NoMemberBanner();
//   @override
//   Widget build(BuildContext context) {
//     return AppCard(
//       child: Row(
//         children: [
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: AppColors.accentLight,
//               borderRadius: AppRadius.small,
//             ),
//             child: const Icon(
//               Icons.info_outline_rounded,
//               color: AppColors.accent,
//               size: 22,
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('No Active Membership', style: AppTextStyles.headingSmall),
//                 const SizedBox(height: 2),
//                 Text(
//                   'Contact admin to activate your plan.',
//                   style: AppTextStyles.bodySmall,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── DESTINATION CAROUSEL (Infinite + No Side Gap) ─────────────────────────────
// class _DestinationCarousel extends StatefulWidget {
//   const _DestinationCarousel();

//   @override
//   State<_DestinationCarousel> createState() => _DestinationCarouselState();
// }

// class _DestinationCarouselState extends State<_DestinationCarousel> {
//   late final PageController _ctrl;
//   int _cur = 0;

//   static const _slides = [
//     _Slide(
//       imageUrl: 'images/mal.jpg',
//       title: 'Explore Maldives',
//       subtitle: 'Crystal clear waters & white sand beaches',
//     ),
//     _Slide(
//       imageUrl: 'images/ker.jpg',
//       title: 'Discover Kerala',
//       subtitle: "God's own country — backwaters & spices",
//     ),
//     _Slide(
//       imageUrl: 'images/raj.jpg',
//       title: 'Mystical Rajasthan',
//       subtitle: 'Forts, deserts & royal heritage',
//     ),
//     _Slide(
//       imageUrl: 'images/lad.jpg',
//       title: 'Ladakh Adventure',
//       subtitle: 'High altitude lakes & mountain passes',
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = PageController(
//       viewportFraction: 0.92,
//       initialPage: 1000, // start far for infinite feel
//     );
//     _cur = 1000;
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         SizedBox(
//           height: 170,
//           child: PageView.builder(
//             controller: _ctrl,
//             onPageChanged: (i) {
//               setState(() => _cur = i);
//             },
//             itemBuilder: (ctx, i) {
//               final index = i % _slides.length;
//               final s = _slides[index];

//               final isActive = i == _cur;

//               return AnimatedScale(
//                 scale: isActive ? 1.0 : 0.95,
//                 duration: const Duration(milliseconds: 350),
//                 curve: Curves.easeOut,
//                 child: Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 4),
//                   decoration: BoxDecoration(
//                     borderRadius: AppRadius.large,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.25),
//                         blurRadius: 18,
//                         offset: const Offset(0, 8),
//                       ),
//                     ],
//                   ),
//                   child: ClipRRect(
//                     borderRadius: AppRadius.large,
//                     child: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         Image.asset(s.imageUrl, fit: BoxFit.cover),

//                         // Gradient overlay
//                         Container(
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [
//                                 Colors.transparent,
//                                 Colors.black.withOpacity(0.7),
//                               ],
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                             ),
//                           ),
//                         ),

//                         // Text
//                         Padding(
//                           padding: const EdgeInsets.all(18),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisAlignment: MainAxisAlignment.end,
//                             children: [
//                               Text(
//                                 s.title,
//                                 style: AppTextStyles.headingMedium.copyWith(
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 s.subtitle,
//                                 style: AppTextStyles.bodySmall.copyWith(
//                                   color: Colors.white.withOpacity(0.9),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),

//         const SizedBox(height: 12),

//         // Dots indicator
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: List.generate(_slides.length, (i) {
//             final isActive = (_cur % _slides.length) == i;

//             return AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               margin: const EdgeInsets.symmetric(horizontal: 4),
//               width: isActive ? 20 : 6,
//               height: 6,
//               decoration: BoxDecoration(
//                 color: isActive ? AppColors.primary : AppColors.border,
//                 borderRadius: BorderRadius.circular(3),
//               ),
//             );
//           }),
//         ),
//       ],
//     );
//   }
// }

// class _Slide {
//   final String imageUrl, title, subtitle;
//   const _Slide({
//     required this.imageUrl,
//     required this.title,
//     required this.subtitle,
//   });
// }

// // ── SERVICES GRID (2 columns) ─────────────────────────────────────────────────
// class _ServicesRow extends StatelessWidget {
//   final String userId;
//   const _ServicesRow({required this.userId});

//   static const _svcs = [
//     _SI('Holiday', Icons.beach_access_rounded),
//     _SI('Hotel', Icons.hotel_rounded),
//     _SI('Gym', Icons.fitness_center_rounded),
//     _SI('Pool', Icons.pool_rounded),
//     _SI('Resort Pass', Icons.villa_rounded),
//   ];

//   void _nav(BuildContext ctx, String t) {
//     switch (t) {
//       case 'Holiday':
//         Navigator.push(
//           ctx,
//           MaterialPageRoute(builder: (_) => const HolidayServiceScreen()),
//         );
//         break;
//       case 'Hotel':
//         Navigator.push(
//           ctx,
//           MaterialPageRoute(builder: (_) => const HotelRequestScreen()),
//         );
//         break;
//       case 'Gym':
//         Navigator.push(
//           ctx,
//           MaterialPageRoute(builder: (_) => GymServiceScreen(userId: userId)),
//         );
//         break;
//       case 'Pool':
//         Navigator.push(
//           ctx,
//           MaterialPageRoute(builder: (_) => PoolServiceScreen(userId: userId)),
//         );
//         break;
//       case 'Resort Pass':
//         Navigator.push(
//           ctx,
//           MaterialPageRoute(builder: (_) => ResortPassScreen(userId: userId)),
//         );
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: _svcs.length,
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         mainAxisSpacing: 12,
//         crossAxisSpacing: 12,
//         childAspectRatio: 2.6,
//       ),
//       itemBuilder: (ctx, i) {
//         final s = _svcs[i];
//         return GestureDetector(
//           onTap: () => _nav(ctx, s.title),
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//             decoration: BoxDecoration(
//               color: AppColors.surface,
//               borderRadius: AppRadius.medium,
//               border: Border.all(color: AppColors.border),
//               boxShadow: AppShadows.subtle,
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 34,
//                   height: 34,
//                   decoration: BoxDecoration(
//                     color: AppColors.primarySurface,
//                     borderRadius: AppRadius.small,
//                   ),
//                   child: Icon(s.icon, color: AppColors.primary, size: 17),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     s.title,
//                     style: AppTextStyles.labelMedium.copyWith(
//                       color: AppColors.textPrimary,
//                       fontWeight: FontWeight.w600,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 const Icon(
//                   Icons.arrow_forward_ios_rounded,
//                   size: 10,
//                   color: AppColors.textHint,
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class _SI {
//   final String title;
//   final IconData icon;
//   const _SI(this.title, this.icon);
// }

// // ── POPULAR DESTINATIONS ──────────────────────────────────────────────────────
// class _PopularDestinations extends StatelessWidget {
//   final String userId;
//   const _PopularDestinations({required this.userId});
//   static const _d = [
//     _D('Goa', 'Beach', '🌊', Color(0xFF0F4C75)),
//     _D('Manali', 'Snow', '❄️', Color(0xFF1A6B5A)),
//     _D('Jaipur', 'Heritage', '🏰', Color(0xFFB5451B)),
//     _D('Ooty', 'Hills', '🌄', Color(0xFF2E7D32)),
//   ];
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       physics: const BouncingScrollPhysics(),
//       clipBehavior: Clip.none,
//       child: Row(
//         children: _d
//             .map(
//               (d) => GestureDetector(
//                 onTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => const HolidayServiceScreen(),
//                   ),
//                 ),
//                 child: Container(
//                   margin: const EdgeInsets.only(right: 12),
//                   width: 128,
//                   height: 148,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [d.c, d.c.withOpacity(0.72)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: AppRadius.large,
//                     boxShadow: [
//                       BoxShadow(
//                         color: d.c.withOpacity(0.3),
//                         blurRadius: 14,
//                         offset: const Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   padding: const EdgeInsets.all(14),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(d.em, style: const TextStyle(fontSize: 28)),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             d.n,
//                             style: AppTextStyles.headingSmall.copyWith(
//                               color: Colors.white,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 3,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               d.tag,
//                               style: AppTextStyles.bodySmall.copyWith(
//                                 color: Colors.white,
//                                 fontSize: 10,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             )
//             .toList(),
//       ),
//     );
//   }
// }

// class _D {
//   final String n, tag, em;
//   final Color c;
//   const _D(this.n, this.tag, this.em, this.c);
// }

// // ── OFFER BANNER ──────────────────────────────────────────────────────────────
// class _OfferBanner extends StatelessWidget {
//   const _OfferBanner();
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: AppColors.accentLight,
//         borderRadius: AppRadius.large,
//         border: Border.all(color: AppColors.accent.withOpacity(0.25)),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Special Offer 🎉',
//                   style: AppTextStyles.headingSmall.copyWith(
//                     color: AppColors.accent,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Exclusive member discounts on your next trip!',
//                   style: AppTextStyles.bodySmall,
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 12),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
//             decoration: BoxDecoration(
//               color: AppColors.accent,
//               borderRadius: AppRadius.small,
//             ),
//             child: Text(
//               'Explore',
//               style: AppTextStyles.labelMedium.copyWith(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/features/user/services/banquet_service_scree.dart';
import 'package:user_app/features/user/services/event_service_screen.dart';
import 'package:user_app/features/user/services/hotel_request_screen.dart';
import 'package:user_app/features/user/reviews_screen.dart';

import 'package:user_app/features/user/services/gym_service_screen.dart';
import 'package:user_app/features/user/services/insurance_service_screen.dart';

import 'package:user_app/features/user/services/pool_service_screen.dart';
import 'package:user_app/features/user/services/resort_pass_screen.dart';
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      membershipActive
                          ? _MembershipCard(data: data)
                          : const _NoMemberBanner(),
                      const SizedBox(height: 22),
                      const _DestinationCarousel(),
                      const SizedBox(height: 22),
                      GradientBannerCard(
                        title: 'Experience Adventure\nLike Never Before',
                        subtitle: 'Personalized journeys, seamless planning.',
                        colors: AppColors.heroBannerGradient,
                        icon: Icons.explore_outlined,
                      ),
                      const SizedBox(height: 26),
                      const SectionHeader(title: 'Our Services'),

                      _ServicesRow(userId: userId),
                      const SizedBox(height: 26),
                      const SectionHeader(title: 'Popular Destinations'),
                      const SizedBox(height: 14),
                      _PopularDestinations(userId: userId),
                      const SizedBox(height: 26),
                      const SizedBox(height: 30),
                      const Text(
                        "Testimonials",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('reviews')
                            .where('isApproved', isEqualTo: true)
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return const Center(
                              child: Text("Error loading reviews"),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text("No testimonials yet"),
                            );
                          }

                          final reviews = snapshot.data!.docs;

                          return Column(
                            children: reviews.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;

                              final String name = data['name'] ?? "User";
                              final String comment = data['comment'] ?? "";
                              final int rating = (data['rating'] ?? 0).toInt();
                              final String imageUrl = data['imageUrl'] ?? "";

                              return Card(
                                child: ListTile(
                                  leading: imageUrl.isNotEmpty
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            imageUrl,
                                          ),
                                        )
                                      : const CircleAvatar(
                                          child: Icon(Icons.person),
                                        ),
                                  title: Text(name),
                                  subtitle: Text(comment),
                                  trailing: Text("$rating ⭐"),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReviewsScreen(),
                            ),
                          );
                        },
                        child: const Text("Write a Review"),
                      ),
                      const _OfferBanner(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── MEMBERSHIP CARD ──────────────────────────────────────────────────────────
class _MembershipCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MembershipCard({required this.data});

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final String name = data['membershipName'] ?? 'Premium';
    final Timestamp? ts = data['expiryDate'];
    final DateTime? expiry = ts?.toDate();
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

    return GestureDetector(
      onTap: () => _openPopup(
        context,
        name: name,
        expiry: expiry,
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
            if (activeImm.isNotEmpty || packages.isNotEmpty) ...[
              const SizedBox(height: 16),
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

// ── GLASSMORPHISM POPUP ──────────────────────────────────────────────────────
class _MembershipPopup extends StatelessWidget {
  final String name;
  final DateTime? expiry;
  final List<String> packages;
  final Map<String, dynamic> imm;
  final int totalHol, usedHol, remHol;

  const _MembershipPopup({
    required this.name,
    required this.expiry,
    required this.packages,
    required this.imm,
    required this.totalHol,
    required this.usedHol,
    required this.remHol,
  });

  static const _fac = [
    (' Insurance', 'Insurance', Icons.health_and_safety_outlined),
    ('Gym Access', 'gym', Icons.fitness_center_rounded),
    ('Swimming Pool', 'swimmingPool', Icons.pool_rounded),
    ('Compliment Plot', 'complimentPlot', Icons.villa_outlined),
    ('Event pass', 'eventpass', Icons.event_available_rounded),
    ('Resort Access', 'resortAccess', Icons.beach_access_rounded),
    ('Banquet Access', 'banquetAccess', Icons.restaurant_menu_rounded),
  ];

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final double progress = totalHol > 0
        ? (usedHol / totalHol).clamp(0.0, 1.0)
        : 0.0;

    /// 🔥 FILTER ONLY APPROVED IMMUNITIES
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
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

            const SizedBox(height: 20),

            /// STAT BOX
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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

            /// PROGRESS
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

            const SizedBox(height: 20),

            /// INCLUDED FACILITIES (ONLY APPROVED)
            if (approvedFacilities.isNotEmpty) ...[
              Text(
                'Included Facilities',
                style: AppTextStyles.labelUppercase.copyWith(
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 12),

              ...approvedFacilities.map((f) {
                return Padding(
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
                );
              }),
            ],

            const SizedBox(height: 22),

            /// CLOSE BUTTON
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

// ── NO MEMBERSHIP BANNER ──────────────────────────────────────────────────────
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

// ── DESTINATION CAROUSEL (Infinite + No Side Gap) ─────────────────────────────
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
    _ctrl = PageController(
      viewportFraction: 0.92,
      initialPage: 1000, // start far for infinite feel
    );
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
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) {
              setState(() => _cur = i);
            },
            itemBuilder: (ctx, i) {
              final index = i % _slides.length;
              final s = _slides[index];

              final isActive = i == _cur;

              return AnimatedScale(
                scale: isActive ? 1.0 : 0.95,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.large,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.large,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(s.imageUrl, fit: BoxFit.cover),

                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),

                        // Text
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

        const SizedBox(height: 12),

        // Dots indicator
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

// ── SERVICES GRID (2 columns) ─────────────────────────────────────────────────
class _ServicesRow extends StatelessWidget {
  final String userId;
  const _ServicesRow({required this.userId});

  static const _svcs = [
    _SI('Hotel', Icons.hotel_rounded),
    _SI('Gym', Icons.fitness_center_rounded),
    _SI('Pool', Icons.pool_rounded),
    _SI('Event pass', Icons.event_available_rounded),
    _SI('Banquet', Icons.restaurant_menu_rounded),
    _SI('Insurance', Icons.health_and_safety),
    _SI('Resort Pass', Icons.villa_rounded),
  ];

  void _nav(BuildContext ctx, String t) {
    switch (t) {
      // case 'Holiday':
      //   Navigator.push(
      //     ctx,
      //     MaterialPageRoute(builder: (_) => const HotelRequestScreen()),
      //   );
      //   break;
      case 'Hotel':
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
      case 'Event pass':
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => EventPassServiceScreen(userId: userId),
          ),
        );
        break;
      case 'Banquet':
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => BanquetServiceScreen(userId: userId),
          ),
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
      case 'Resort Pass':
        Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => ResortPassScreen(userId: userId)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _svcs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.6,
      ),
      itemBuilder: (ctx, i) {
        final s = _svcs[i];
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
      },
    );
  }
}

class _SI {
  final String title;
  final IconData icon;
  const _SI(this.title, this.icon);
}

// ── POPULAR DESTINATIONS ──────────────────────────────────────────────────────
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
        children: _d
            .map(
              (d) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HotelRequestScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 128,
                  height: 148,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(d.em, style: const TextStyle(fontSize: 28)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.n,
                            style: AppTextStyles.headingSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
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
            )
            .toList(),
      ),
    );
  }
}

class _D {
  final String n, tag, em;
  final Color c;
  const _D(this.n, this.tag, this.em, this.c);
}

// ── OFFER BANNER ──────────────────────────────────────────────────────────────
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
