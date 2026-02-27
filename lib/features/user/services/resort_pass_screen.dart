import 'member_upload_service_screen.dart';
import 'package:flutter/material.dart';

class ResortPassScreen extends StatelessWidget {
  final String userId;
  const ResortPassScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return const MemberUploadServiceScreen(
      serviceType: "resortPass",
      maxMembers: 4,
    );
  }
}
