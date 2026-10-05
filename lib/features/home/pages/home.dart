import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/navigation/app_modules.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/services/theme/theme_cubit.dart';
import '../../trainings/pages/trainings_modal.dart';

/// "Others" tab: the bento grid of every module that is not a tab of its own
/// and not listed under Productivity (see `AppModules`).
///
/// Also hosts the language and theme switches and the trainings shortcut.
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthManager _authManager = AuthManager();

  List<AppModule> get modules => AppModules.inGroup(
        ModuleGroup.others,
        AppLocalizations.of(context),
        _authManager,
      );

  void _navigateToModule(AppModule module) => context.push(module.route);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          l.others,
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          // Language dropdown
          Padding(
            padding: EdgeInsets.only(right: 8.sp),
            child: _buildLanguageDropdown(theme),
          ),
          // Theme toggle switch
          Padding(
            padding: EdgeInsets.only(right: 8.sp),
            child: GestureDetector(
              onTap: () {
                context.read<ThemeCubit>().toggleTheme();
              },
              child: Container(
                width: 56.w,
                height: 28.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  gradient: LinearGradient(
                    colors: theme.brightness == Brightness.dark
                        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                        : [Colors.grey.shade300, Colors.grey.shade400],
                  ),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: theme.brightness == Brightness.dark
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 24.w,
                        height: 24.h,
                        margin: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          theme.brightness == Brightness.dark
                              ? Icons.nightlight_round
                              : Icons.wb_sunny_rounded,
                          size: 14.sp,
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF6366F1)
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Trainings shortcut
          Padding(
            padding: EdgeInsets.only(right: 12.sp),
            child: IconButton(
              onPressed: () => showTrainingsModal(context),
              tooltip: l.learning,
              icon: Icon(
                Icons.school_rounded,
                size: 26.sp,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20.sp,
              8.sp,
              20.sp,
              24.sp + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverToBoxAdapter(child: _buildBentoGrid(theme)),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(ThemeData theme) {
    final mods = modules;
    if (mods.isEmpty) return const SizedBox.shrink();

    final gap = 12.sp;

    // Helper to safely get module at index
    AppModule? at(int i) => i < mods.length ? mods[i] : null;

    // Build rows progressively consuming the modules list
    final rows = <Widget>[];
    int i = 0;

    // ── Row 1: large (2/3) + two smalls stacked (1/3) ──
    if (i < mods.length) {
      final a = at(i++);
      final b = at(i++);
      final c = at(i++);
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (a != null)
                Expanded(
                  flex: 2,
                  child: _BentoCard(
                    module: a,
                    onTap: () => _navigateToModule(a),
                    size: _BentoSize.large,
                  ),
                ),
              if (b != null || c != null) SizedBox(width: gap),
              if (b != null || c != null)
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      if (b != null)
                        Expanded(
                          child: _BentoCard(
                            module: b,
                            onTap: () => _navigateToModule(b),
                            size: _BentoSize.small,
                          ),
                        ),
                      if (b != null && c != null) SizedBox(height: gap),
                      if (c != null)
                        Expanded(
                          child: _BentoCard(
                            module: c,
                            onTap: () => _navigateToModule(c),
                            size: _BentoSize.small,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
      rows.add(SizedBox(height: gap));
    }

    // ── Row 2: two medium equal cards ──
    if (i < mods.length) {
      final a = at(i++);
      final b = at(i++);
      rows.add(
        Row(
          children: [
            if (a != null)
              Expanded(
                child: _BentoCard(
                  module: a,
                  onTap: () => _navigateToModule(a),
                  size: _BentoSize.medium,
                ),
              ),
            if (a != null && b != null) SizedBox(width: gap),
            if (b != null)
              Expanded(
                child: _BentoCard(
                  module: b,
                  onTap: () => _navigateToModule(b),
                  size: _BentoSize.medium,
                ),
              ),
          ],
        ),
      );
      rows.add(SizedBox(height: gap));
    }

    // ── Row 3: small (1/3) + large (2/3) — mirrored ──
    if (i < mods.length) {
      final a = at(i++);
      final b = at(i++);
      final c = at(i++);
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (a != null || b != null)
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      if (a != null)
                        Expanded(
                          child: _BentoCard(
                            module: a,
                            onTap: () => _navigateToModule(a),
                            size: _BentoSize.small,
                          ),
                        ),
                      if (a != null && b != null) SizedBox(height: gap),
                      if (b != null)
                        Expanded(
                          child: _BentoCard(
                            module: b,
                            onTap: () => _navigateToModule(b),
                            size: _BentoSize.small,
                          ),
                        ),
                    ],
                  ),
                ),
              if (c != null) SizedBox(width: gap),
              if (c != null)
                Expanded(
                  flex: 2,
                  child: _BentoCard(
                    module: c,
                    onTap: () => _navigateToModule(c),
                    size: _BentoSize.large,
                  ),
                ),
            ],
          ),
        ),
      );
      rows.add(SizedBox(height: gap));
    }

    // ── Remaining: full-width wide cards ──
    while (i < mods.length) {
      final a = at(i++);
      final b = at(i++);
      if (a != null || b != null) {
        rows.add(
          Row(
            children: [
              if (a != null)
                Expanded(
                  child: _BentoCard(
                    module: a,
                    onTap: () => _navigateToModule(a),
                    size: _BentoSize.wide,
                  ),
                ),
              if (a != null && b != null) SizedBox(width: gap),
              if (b != null)
                Expanded(
                  child: _BentoCard(
                    module: b,
                    onTap: () => _navigateToModule(b),
                    size: _BentoSize.wide,
                  ),
                ),
            ],
          ),
        );
        rows.add(SizedBox(height: gap));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildLanguageDropdown(ThemeData theme) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;

    // Language map with flags
    final languages = {
      'en': {'name': 'EN', 'flag': '🇬🇧'},
      'uz': {'name': 'UZ', 'flag': '🇺🇿'},
      'ru': {'name': 'RU', 'flag': '🇷🇺'},
    };

    return Container(
      height: 28.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark
              ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
              : [Colors.grey.shade300, Colors.grey.shade400],
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLocale,
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF6366F1)
                : Colors.grey.shade700,
            size: 18.sp,
          ),
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          dropdownColor: theme.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          items: languages.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.value['flag']!, style: TextStyle(fontSize: 14.sp)),
                  SizedBox(width: 6.w),
                  Text(
                    entry.value['name']!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              localeProvider.setLocale(Locale(newValue));
            }
          },
          selectedItemBuilder: (BuildContext context) {
            return languages.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.value['flag']!, style: TextStyle(fontSize: 14.sp)),
                  SizedBox(width: 4.w),
                  Text(
                    entry.value['name']!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey.shade800,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }
}

// Bento card size variants
enum _BentoSize { large, medium, small, wide }

// ────────────────────────────────────────────
//  Bento Card
// ────────────────────────────────────────────
class _BentoCard extends StatefulWidget {
  final AppModule module;
  final VoidCallback onTap;
  final _BentoSize size;

  const _BentoCard({
    required this.module,
    required this.onTap,
    required this.size,
  });

  @override
  State<_BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<_BentoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Height per size variant
  double get _height {
    switch (widget.size) {
      case _BentoSize.large:
        return 180.sp;
      case _BentoSize.medium:
        return 130.sp;
      case _BentoSize.small:
        return 84.sp;
      case _BentoSize.wide:
        return 110.sp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.module.accent.resolve(context);
    final isLarge = widget.size == _BentoSize.large;
    final isSmall = widget.size == _BentoSize.small;

    return Semantics(
      button: true,
      label: widget.module.title,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          Future.delayed(const Duration(milliseconds: 100), widget.onTap);
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            height: _height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22.r),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2F2F2F), const Color(0xFF1A1A1A)]
                    : [color.withOpacity(0.18), color.withOpacity(0.10)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFFFCB74).withOpacity(0.55)
                    : color.withOpacity(0.18),
                width: isDark ? 1.6 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? const Color(0xFFFFCB74).withOpacity(0.10)
                      : color.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.40 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22.r),
              child: Stack(
                children: [
                  // ── Background decorative circles ──
                  Positioned(
                    top: -28.sp,
                    right: -28.sp,
                    child: Container(
                      width: isLarge ? 110.sp : 70.sp,
                      height: isLarge ? 110.sp : 70.sp,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFFFFCB74).withOpacity(0.08)
                            : color.withOpacity(0.07),
                      ),
                    ),
                  ),
                  if (!isSmall)
                    Positioned(
                      bottom: -20.sp,
                      left: -20.sp,
                      child: Container(
                        width: isLarge ? 80.sp : 50.sp,
                        height: isLarge ? 80.sp : 50.sp,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFFF6F6F6).withOpacity(0.04)
                              : color.withOpacity(0.05),
                        ),
                      ),
                    ),

                  // ── Content ──
                  Padding(
                    padding: EdgeInsets.all(isSmall ? 10.sp : 16.sp),
                    child: isSmall
                        ? _buildSmallContent(isDark, color)
                        : _buildFullContent(isDark, color, isLarge),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Small card: icon + title side by side
  Widget _buildSmallContent(bool isDark, Color color) {
    final iconColor = isDark ? const Color(0xFFF6F6F6) : _darken(color, 0.25);
    final textColor = isDark ? const Color(0xFFF6F6F6) : _darken(color, 0.30);
    return Row(
      children: [
        Container(
          width: 34.sp,
          height: 34.sp,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: isDark
                ? Colors.white.withOpacity(0.14)
                : color.withOpacity(0.14),
          ),
          child: Icon(widget.module.icon, size: 18.sp, color: iconColor),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            widget.module.title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.25,
              letterSpacing: -0.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Large / medium / wide card: full layout with icon top, title bottom
  Widget _buildFullContent(bool isDark, Color color, bool isLarge) {
    final iconColor = isDark ? const Color(0xFFF6F6F6) : _darken(color, 0.25);
    final titleColor = isDark ? const Color(0xFFF6F6F6) : _darken(color, 0.35);
    final subtitleColor = isDark
        ? const Color(0xFFF6F6F6).withOpacity(0.60)
        : _darken(color, 0.20).withOpacity(0.75);
    final subtitle = widget.module.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Icon box
        Container(
          width: isLarge ? 52.sp : 44.sp,
          height: isLarge ? 52.sp : 44.sp,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isLarge ? 16.r : 13.r),
            color: isDark
                ? const Color(0xFFFFCB74).withOpacity(0.15)
                : color.withOpacity(0.14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFFFCB74).withOpacity(0.35)
                  : color.withOpacity(0.22),
              width: 0.8,
            ),
          ),
          child: Icon(
            widget.module.icon,
            size: isLarge ? 26.sp : 22.sp,
            color: iconColor,
          ),
        ),
        // Title + subtitle
        Flexible(
          child: Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.module.title,
                  style: TextStyle(
                    fontSize: isLarge ? 18.sp : 14.sp,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isLarge && subtitle != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
