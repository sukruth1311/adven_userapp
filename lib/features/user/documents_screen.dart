import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user_app/features/user/widgets/in_app_doc_viewer.dart';
import 'package:user_app/themes/app_theme.dart';
import 'package:user_app/themes/app_widgets.dart';
import '../../../core/services/firestore_service.dart';
import '../../../data/models/user_document.dart';

// ══════════════════════════════════════════════════════════════════════
//  DOCUMENTS SCREEN  (User App)
//  • Streams docs uploaded by admin for this user
//  • Opens PDFs & images IN-APP (no Chrome / external browser)
// ══════════════════════════════════════════════════════════════════════
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Documents'),
        backgroundColor: AppColors.surface,
        elevation: 0,
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
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No documents yet',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Documents sent by admin will appear here.',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
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
              return _DocCard(doc: doc);
            },
          );
        },
      ),
    );
  }
}

// ── Document card ─────────────────────────────────────────────────
class _DocCard extends StatelessWidget {
  final UserDocument doc;
  const _DocCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final color = _docColor(doc.type);
    final icon = _docIcon(doc.type);
    final date =
        '${doc.createdAt.day.toString().padLeft(2, '0')}-'
        '${doc.createdAt.month.toString().padLeft(2, '0')}-'
        '${doc.createdAt.year}';

    return AppCard(
      child: Row(
        children: [
          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppRadius.small,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),

          // Title + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: AppTextStyles.headingSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        doc.type.toUpperCase(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // View button — opens IN-APP
          GestureDetector(
            onTap: () {
              if (doc.fileUrl.isEmpty) {
                AppSnackbar.show(
                  context,
                  'Document URL is not available',
                  isError: true,
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      InAppDocViewer(url: doc.fileUrl, title: doc.title),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: AppRadius.small,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.open_in_new_rounded,
                    color: AppColors.primary,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'View',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _docIcon(String type) {
    switch (type) {
      case 'hotel':
        return Icons.hotel_rounded;
      case 'membership':
        return Icons.card_membership_rounded;
      case 'insurance':
        return Icons.health_and_safety_rounded;
      case 'swimming':
        return Icons.pool_rounded;
      case 'gym':
        return Icons.fitness_center_rounded;
      default:
        return Icons.picture_as_pdf_rounded;
    }
  }

  Color _docColor(String type) {
    switch (type) {
      case 'hotel':
        return const Color(0xFF3B82F6);
      case 'membership':
        return AppColors.primary;
      case 'insurance':
        return AppColors.accent;
      default:
        return AppColors.error;
    }
  }
}
