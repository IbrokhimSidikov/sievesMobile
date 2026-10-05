import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../models/career_roadmap.dart';

/// `12 Mar 2024` in the app's language.
String formatCareerDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).languageCode;
  return DateFormat('d MMM yyyy', locale).format(date);
}

/// Tenure between two dates as `1 yr 4 mo`, or `12 d` in the first month.
String formatTenure(AppLocalizations l, DateTime from, DateTime to) {
  final months = monthsBetween(from, to);
  if (months == 0) {
    final days = to.difference(from).inDays.clamp(0, 31);
    return l.careerDaysShort.replaceAll('{n}', '$days');
  }
  final years = months ~/ 12;
  final rest = months % 12;
  return [
    if (years > 0) l.careerYearsShort.replaceAll('{n}', '$years'),
    if (rest > 0) l.careerMonthsShort.replaceAll('{n}', '$rest'),
  ].join(' ');
}

/// "1 month with the team", "2 years with the team", ...
String formatMilestone(AppLocalizations l, int months) {
  if (months == 1) return l.careerOneMonthWithTeam;
  if (months == 12) return l.careerOneYearWithTeam;
  if (months % 12 == 0) {
    return l.careerYearsWithTeam.replaceAll('{n}', '${months ~/ 12}');
  }
  return l.careerMonthsWithTeam.replaceAll('{n}', '$months');
}

/// Color, icon and title of each roadmap node.
class RoadmapStyle {
  final Color color;
  final IconData icon;
  final String title;

  /// Major nodes get a larger ringed dot on the rail.
  final bool major;

  const RoadmapStyle(this.color, this.icon, this.title, {this.major = false});

  static RoadmapStyle of(BuildContext context, RoadmapItem item) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return switch (item.kind) {
      RoadmapKind.hire => RoadmapStyle(
        t.success,
        Icons.rocket_launch_rounded,
        l.careerJoined,
        major: true,
      ),
      RoadmapKind.promotion => RoadmapStyle(
        t.warning,
        Icons.trending_up_rounded,
        l.careerPromoted,
        major: true,
      ),
      RoadmapKind.renewal => RoadmapStyle(
        t.primary,
        Icons.autorenew_rounded,
        l.careerRenewed,
      ),
      RoadmapKind.stepChanged => RoadmapStyle(
        t.textSecondary,
        Icons.swap_vert_rounded,
        l.careerStepChanged,
      ),
      RoadmapKind.training => RoadmapStyle(
        t.info,
        Icons.school_rounded,
        l.careerTraining,
      ),
      RoadmapKind.milestone => RoadmapStyle(
        t.primary,
        Icons.emoji_events_rounded,
        formatMilestone(l, item.milestoneMonths ?? 0),
      ),
      RoadmapKind.exit => RoadmapStyle(
        t.error,
        Icons.logout_rounded,
        l.careerExit,
        major: true,
      ),
      RoadmapKind.today => RoadmapStyle(
        t.primary,
        Icons.flag_rounded,
        l.careerToday,
        major: true,
      ),
    };
  }
}
