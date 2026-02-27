import 'member_upload_service_screen.dart';
import 'package:flutter/material.dart';

class EventPassServiceScreen extends StatelessWidget {
  final String userId;
  const EventPassServiceScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return const MemberUploadServiceScreen(
      serviceType: "eventPass",
      maxMembers: 4,
    );
  }
}
