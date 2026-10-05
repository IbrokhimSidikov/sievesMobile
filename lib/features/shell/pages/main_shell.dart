import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';

/// Hosts the five bottom-navigation branches. Each branch keeps its own
/// navigator and state, so switching tabs never reloads a page.
///
/// Tab order: Profile (landing) · Attendance · Break records · Productivity ·
/// Others. See `AppRoutes.createRouter` for the branch definitions.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the active tab again pops that branch to its root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.background,
      // Content scrolls under the frosted bar; pages pad their scrollables
      // with MediaQuery.paddingOf(context).bottom (set by Scaffold).
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        items: [
          AppBottomNavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: l.profile,
          ),
          AppBottomNavItem(
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_today_rounded,
            label: l.attendance,
          ),
          AppBottomNavItem(
            icon: Icons.coffee_outlined,
            selectedIcon: Icons.coffee_rounded,
            label: l.breakRecords,
          ),
          AppBottomNavItem(
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights_rounded,
            label: l.productivity,
          ),
          AppBottomNavItem(
            icon: Icons.grid_view_outlined,
            selectedIcon: Icons.grid_view_rounded,
            label: l.others,
          ),
        ],
      ),
    );
  }
}
