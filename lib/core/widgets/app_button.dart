// import 'package:flutter/material.dart';

// class AppButton extends StatelessWidget {
//   final String label;
//   final VoidCallback onPressed;
//   final bool isLoading;
//   final Color? backgroundColor;
//   final double? padding;

//   const AppButton({
//     super.key,
//     required this.label,
//     required this.onPressed,
//     this.isLoading = false,
//     this.backgroundColor,
//     this.padding = 14.0,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: isLoading ? null : onPressed,
//       style: ElevatedButton.styleFrom(
//         padding: EdgeInsets.symmetric(vertical: padding!),
//         backgroundColor: backgroundColor,
//       ),
//       child: isLoading
//           ? const CircularProgressIndicator(color: Colors.white)
//           : Text(label),
//     );
//   }
// }
