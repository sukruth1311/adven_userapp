import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user_app/themes/app_theme.dart';
import 'package:user_app/themes/app_widgets.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/firestore_service.dart';

import '../../data/models/membership_plan.dart';
import '../../data/models/membership_request.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text("User not logged in", style: AppTextStyles.bodyMedium),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Membership Plans"),
        backgroundColor: AppColors.surface,
      ),
      body: StreamBuilder<List<MembershipPlan>>(
        stream: FirestoreService.instance.streamMembershipPlans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final plans = snapshot.data ?? [];

          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.card_membership_rounded,
                    size: 56,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No plans available",
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, index) {
              final plan = plans[index];
              return _PlanCard(plan: plan, uid: uid);
            },
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatefulWidget {
  final MembershipPlan plan;
  final String uid;
  const _PlanCard({required this.plan, required this.uid});

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _loading = false;

  Future<void> _sendRequest() async {
    setState(() => _loading = true);

    try {
      final request = MembershipRequest(
        id: const Uuid().v4(),
        userId: widget.uid,
        requestedPlanId: widget.plan.id,
        status: "pending",
        createdAt: DateTime.now(),
      );
      await FirestoreService.instance.createMembershipRequest(request);
      if (mounted) {
        AppSnackbar.show(
          context,
          "Request sent successfully!",
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.plan.name, style: AppTextStyles.headingMedium),
                    const SizedBox(height: 4),
                    Text(
                      widget.plan.description,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: AppRadius.small,
                ),
                child: Text(
                  "₹ ${widget.plan.price}",
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          AppButton(
            label: "I'm Interested",
            loading: _loading,
            onTap: _sendRequest,
            icon: const Icon(
              Icons.thumb_up_outlined,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
