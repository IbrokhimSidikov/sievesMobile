import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../router/app_routes.dart';
import '../services/auth/auth_manager.dart';
import '../theme/app_accents.dart';

/// Which bottom-navigation hub a module is listed under.
///
/// Profile, Attendance and Break records are tabs of their own and are not
/// part of this catalog.
enum ModuleGroup {
  /// The "Productivity" tab.
  productivity,

  /// The "Others" tab: every module that is not a tab and not productivity.
  others,
}

/// One entry in a hub page. Pure data: hubs decide how to render it.
@immutable
class AppModule {
  const AppModule({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accent,
    required this.route,
    required this.group,
  });

  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final AppAccent accent;
  final String route;
  final ModuleGroup group;
}

/// The single catalog of hub modules.
///
/// To move a module between the Productivity and Others tabs, change its
/// [AppModule.group] here. Order in the list is display order.
abstract class AppModules {
  static List<AppModule> all(AppLocalizations l, AuthManager auth) => [
        // ── Productivity ────────────────────────────────────────────
        if (auth.hasStopwatchAccess)
          AppModule(
            id: 'productivityTimer',
            title: l.productivityTimerCard,
            subtitle: l.productivityTimerCardSubtitle,
            icon: Icons.timer_rounded,
            accent: AppAccents.slate,
            route: AppRoutes.productivityTimer,
            group: ModuleGroup.productivity,
          ),
        if (auth.hasStopwatchAccess)
          AppModule(
            id: 'matrixQualification',
            title: l.matrixQualification,
            subtitle: l.matrixQualificationSubtitle,
            icon: Icons.grid_view_rounded,
            accent: AppAccents.purple,
            route: AppRoutes.matrixQualificationPage,
            group: ModuleGroup.productivity,
          ),
        if (auth.hasStopwatchAccess)
          AppModule(
            id: 'introTrainings',
            title: l.introEmployeeListTitle,
            subtitle: l.introEmployeeListSubtitle,
            icon: Icons.groups_rounded,
            accent: AppAccents.violet,
            route: AppRoutes.introEmployeeList,
            group: ModuleGroup.productivity,
          ),
        if (auth.hasStopwatchAccess)
          AppModule(
            id: 'tasks',
            title: l.tasks,
            subtitle: l.tasksSubtitle,
            icon: Icons.task_alt_rounded,
            accent: AppAccents.slate,
            route: AppRoutes.taskManagement,
            group: ModuleGroup.productivity,
          ),
        AppModule(
          id: 'checklist',
          title: l.checklist,
          subtitle: l.checklistSubtitle,
          icon: Icons.checklist_rounded,
          accent: AppAccents.slate,
          route: AppRoutes.checklist,
          group: ModuleGroup.productivity,
        ),

        // ── Others ──────────────────────────────────────────────────
        // Break order and Face ID first for the staff who have them: these
        // are used several times a day, so they take the large tiles.
        if (auth.hasBreakAccess)
          AppModule(
            id: 'breakOrder',
            title: l.breakOrder,
            subtitle: l.breakOrderSubtitle,
            icon: Icons.restaurant_menu_rounded,
            accent: AppAccents.orange,
            route: AppRoutes.breakOrder,
            group: ModuleGroup.others,
          ),
        if (auth.hasBreakAccess)
          AppModule(
            id: 'faceVerification',
            title: l.faceVerification,
            subtitle: l.faceIdSubtitle,
            icon: Icons.face_rounded,
            accent: AppAccents.teal,
            route: AppRoutes.faceVerification,
            group: ModuleGroup.others,
          ),
        AppModule(
          id: 'learning',
          title: l.learning,
          subtitle: l.learningSubtitle,
          icon: Icons.school_rounded,
          accent: AppAccents.violet,
          route: AppRoutes.lmsPage,
          group: ModuleGroup.others,
        ),
        AppModule(
          id: 'hr',
          title: l.hr,
          subtitle: l.hrSubtitle,
          icon: Icons.menu_book_rounded,
          accent: AppAccents.indigo,
          route: AppRoutes.hrPage,
          group: ModuleGroup.others,
        ),
        AppModule(
          id: 'history',
          title: l.history,
          subtitle: l.historySubtitle,
          icon: Icons.history_rounded,
          accent: AppAccents.blue,
          route: AppRoutes.history,
          group: ModuleGroup.others,
        ),
        AppModule(
          id: 'career',
          title: l.careerTitle,
          subtitle: l.careerSubtitle,
          icon: Icons.stairs_rounded,
          accent: AppAccents.violet,
          route: AppRoutes.careerpage,
          group: ModuleGroup.others,
        ),
        AppModule(
          id: 'wallet',
          title: l.lWallet,
          subtitle: l.lWalletSubtitle,
          icon: Icons.account_balance_wallet_rounded,
          accent: AppAccents.green,
          route: AppRoutes.wallet,
          group: ModuleGroup.others,
        ),
        AppModule(
          id: 'qualification',
          title: l.qualificationDisplayPage,
          icon: Icons.verified_user_rounded,
          accent: AppAccents.purple,
          route: AppRoutes.qualificationDisplayPage,
          group: ModuleGroup.others,
        ),
        AppModule(
          id: 'feedback',
          title: l.feedback,
          subtitle: l.feedbackSubtitle,
          icon: Icons.feedback_rounded,
          accent: AppAccents.indigo,
          route: AppRoutes.feedbackForm,
          group: ModuleGroup.others,
        ),
        if (auth.hasCancelAccess)
          AppModule(
            id: 'orderCancel',
            title: 'Otmen chek',
            icon: Icons.cancel_rounded,
            accent: AppAccents.red,
            route: AppRoutes.orderCancel,
            group: ModuleGroup.others,
          ),
      ];

  static List<AppModule> inGroup(
    ModuleGroup group,
    AppLocalizations l,
    AuthManager auth,
  ) =>
      all(l, auth).where((m) => m.group == group).toList(growable: false);
}
