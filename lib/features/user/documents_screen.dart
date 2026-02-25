import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_app/themes/app_theme.dart';
import 'package:user_app/themes/app_widgets.dart';
import '../../../core/services/firestore_service.dart';

import '../../../data/models/user_document.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Documents"),
        backgroundColor: AppColors.surface,
      ),
      body: StreamBuilder<List<UserDocument>>(
        stream: FirestoreService.instance.streamUserDocuments(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final docs = snapshot.data!;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 56,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No documents yet",
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Your documents will appear here.",
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _docColor(doc.type).withOpacity(0.12),
                        borderRadius: AppRadius.small,
                      ),
                      child: Icon(
                        _docIcon(doc.type),
                        color: _docColor(doc.type),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc.title, style: AppTextStyles.headingSmall),
                          const SizedBox(height: 3),
                          Text(
                            doc.type.toUpperCase(),
                            style: AppTextStyles.labelUppercase,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _openPdf(doc.fileUrl),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: AppRadius.small,
                        ),
                        child: Text(
                          "View",
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _docIcon(String type) {
    switch (type) {
      case "hotel":
        return Icons.hotel_rounded;
      case "membership":
        return Icons.card_membership_rounded;
      case "insurance":
        return Icons.health_and_safety_rounded;
      default:
        return Icons.picture_as_pdf_rounded;
    }
  }

  Color _docColor(String type) {
    switch (type) {
      case "hotel":
        return const Color(0xFF3B82F6);
      case "membership":
        return AppColors.primary;
      case "insurance":
        return AppColors.accent;
      default:
        return AppColors.error;
    }
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not open document");
    }
  }
}
