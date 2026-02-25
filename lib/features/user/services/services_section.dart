// import 'package:flutter/material.dart';
// import 'gym_service_screen.dart';
// import 'pool_service_screen.dart';
// import 'resort_pass_screen.dart';

// class ServicesSection extends StatelessWidget {
//   const ServicesSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: GridView.count(
//         crossAxisCount: 2,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         children: [
//           _serviceCard(
//             context,
//             icon: Icons.fitness_center,
//             title: "Gym",
//             color: Colors.deepPurple,
//             screen: const GymServiceScreen(),
//           ),

//           _serviceCard(
//             context,
//             icon: Icons.pool,
//             title: "Pool",
//             color: Colors.blue,
//             screen: const PoolServiceScreen(),
//           ),

//           _serviceCard(
//             context,
//             icon: Icons.card_membership,
//             title: "Resort Pass",
//             color: Colors.green,
//             screen: const ResortPassScreen(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _serviceCard(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required Color color,
//     required Widget screen,
//   }) {
//     return InkWell(
//       onTap: () {
//         Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
//           boxShadow: [
//             BoxShadow(
//               blurRadius: 8,
//               color: color.withOpacity(0.3),
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 40, color: Colors.white),
//             const SizedBox(height: 12),
//             Text(
//               title,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
