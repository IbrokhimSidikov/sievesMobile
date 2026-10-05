import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/api/api_service.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/theme/app_tokens.dart';
import '../cubit/career_cubit.dart';
import '../models/career_roadmap.dart';
import '../widgets/career_hero_header.dart';
import '../widgets/career_milestone_card.dart';
import '../widgets/career_roadmap_list.dart';
import '../widgets/career_state_views.dart';

/// Career roadmap of the logged-in employee: from the day they were hired to
/// today, with promotions, contract renewals, trainings and anniversaries.
class CareerPage extends StatelessWidget {
  const CareerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CareerCubit(ApiService(AuthManager().authService))..load(),
      child: const _CareerView(),
    );
  }
}

class _CareerView extends StatelessWidget {
  const _CareerView();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // White status bar icons over the indigo header in both modes.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: t.background,
        body: BlocBuilder<CareerCubit, CareerState>(
          builder: (context, state) {
            final cubit = context.read<CareerCubit>();
            final timeline = state.timeline;
            final profile = timeline?.profile;
            final next = profile == null ? null : nextMilestone(profile);
            final roadmap = timeline == null
                ? const <RoadmapItem>[]
                : buildRoadmap(timeline);
            final bottomInset = MediaQuery.of(context).padding.bottom;

            return RefreshIndicator(
              color: t.primary,
              backgroundColor: t.surface,
              edgeOffset: MediaQuery.of(context).padding.top,
              onRefresh: cubit.load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: CareerHeroHeader(timeline: timeline),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      20.w,
                      24.h,
                      20.w,
                      24.h + bottomInset,
                    ),
                    sliver: switch (state.status) {
                      CareerStatus.loading => const SliverToBoxAdapter(
                        child: CareerSkeleton(),
                      ),
                      CareerStatus.failure => SliverToBoxAdapter(
                        child: CareerMessageView(
                          icon: Icons.error_outline_rounded,
                          iconColor: t.error,
                          title: l.careerLoadError,
                          message: l.careerLoadErrorHint,
                          actionLabel: l.retry,
                          onAction: cubit.load,
                        ),
                      ),
                      CareerStatus.success when profile == null =>
                        SliverToBoxAdapter(
                          child: CareerMessageView(
                            icon: Icons.route_rounded,
                            iconColor: t.textTertiary,
                            title: l.careerEmpty,
                            message: l.careerEmptyHint,
                          ),
                        ),
                      CareerStatus.success => SliverMainAxisGroup(
                        slivers: [
                          if (next != null) ...[
                            SliverToBoxAdapter(
                              child: CareerMilestoneCard(milestone: next),
                            ),
                            SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                          ],
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.route_rounded,
                                    size: 20.sp,
                                    color: t.primary,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    l.careerRoadmap,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                      color: t.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          CareerRoadmapSliver(items: roadmap),
                        ],
                      ),
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
