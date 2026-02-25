// import 'package:flutter/material.dart';
// import '../../../data/models/app_user.dart';

// class MembershipCard extends StatelessWidget {
//   final AppUser user;

//   const MembershipCard({super.key, required this.user});

//   @override
//   Widget build(BuildContext context) {
//     final remainingHolidays = (user.holidayLimit - user.holidayUsed).clamp(
//       0,
//       user.holidayLimit,
//     );

//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(24),
//         gradient: const LinearGradient(
//           colors: [Color(0xff4F46E5), Color(0xff7C3AED)],
//         ),
//         boxShadow: [
//           BoxShadow(
//             blurRadius: 15,
//             color: Colors.deepPurple.withOpacity(0.3),
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ================= PACKAGE =================
//           Text(
//             "Package: ${user.membershipPackage ?? ''}",
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),

//           const SizedBox(height: 8),

//           Text(
//             "Amount Paid: ₹${user.amountPaid}",
//             style: const TextStyle(color: Colors.white70),
//           ),

//           const SizedBox(height: 8),

//           Text(
//             user.expiryDate != null
//                 ? "Expiry: ${user.expiryDate!.toLocal().toString().split(' ')[0]}"
//                 : "Expiry: Not Set",
//             style: const TextStyle(color: Colors.white70),
//           ),

//           const SizedBox(height: 16),

//           // ================= IMMUNITIES =================
//           const Text(
//             "Immunities:",
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//           ),

//           const SizedBox(height: 6),

//           ...user.immunities.entries
//               .where((e) => e.value)
//               .map(
//                 (e) => Text(
//                   "✓ ${e.key}",
//                   style: const TextStyle(color: Colors.white70),
//                 ),
//               ),

//           const SizedBox(height: 16),

//           // ================= HOLIDAY TRACKING =================
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 "Holidays Used: ${user.holidayUsed}",
//                 style: const TextStyle(color: Colors.white),
//               ),
//               Text(
//                 "Remaining: $remainingHolidays",
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 8),

//           ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: LinearProgressIndicator(
//               value: user.holidayLimit == 0
//                   ? 0
//                   : user.holidayUsed / user.holidayLimit,
//               minHeight: 8,
//               backgroundColor: Colors.white24,
//               valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
