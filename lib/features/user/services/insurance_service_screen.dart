import 'member_upload_service_screen.dart';
import 'package:flutter/material.dart';

class InsuranceServiceScreen extends StatelessWidget {
  final String userId;
  const InsuranceServiceScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return const MemberUploadServiceScreen(
      serviceType: "insurance",
      maxMembers: 4,
    );
  }
}
