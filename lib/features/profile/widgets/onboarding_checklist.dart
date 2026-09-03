import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_manager.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Onboarding check-list for recently hired employees.
///
/// [OnboardingChecklistIcon] is a small pulsing badge meant to sit in the
/// profile card. Tapping it opens [OnboardingChecklistSheet] — a step-by-step
/// questionnaire where the employee either confirms that each required
/// training was actually delivered, or proceeds without confirming and can
/// escalate a complaint to head administration at the end.
/// ─────────────────────────────────────────────────────────────────────────

/// Snapshot of the checklist state for the current employee, as reported by
/// `GET /onboarding-checklist/status`.
class OnboardingChecklistStatus {
  final int workedDays;
  final int threshold;
  final bool isDue;
  final bool submitted;
  final bool shouldPulse;

  const OnboardingChecklistStatus({
    required this.workedDays,
    required this.threshold,
    required this.isDue,
    required this.submitted,
    required this.shouldPulse,
  });

  factory OnboardingChecklistStatus.fromJson(Map<String, dynamic> json) {
    final workedDays = (json['worked_days'] as num?)?.toInt() ?? 0;
    final threshold = (json['threshold'] as num?)?.toInt() ?? 10;
    final submitted = json['submitted'] == true || json['submitted'] == 1;
    final isDue =
        json['is_due'] == true ||
        json['is_due'] == 1 ||
        workedDays >= threshold;
    final shouldPulse = json.containsKey('should_pulse')
        ? (json['should_pulse'] == true || json['should_pulse'] == 1)
        : (isDue && !submitted);
    return OnboardingChecklistStatus(
      workedDays: workedDays,
      threshold: threshold,
      isDue: isDue,
      submitted: submitted,
      shouldPulse: shouldPulse,
    );
  }
}

class OnboardingChecklistIcon extends StatefulWidget {
  const OnboardingChecklistIcon({super.key});

  @override
  State<OnboardingChecklistIcon> createState() =>
      _OnboardingChecklistIconState();
}

class _OnboardingChecklistIconState extends State<OnboardingChecklistIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final AuthManager _authManager = AuthManager();

  OnboardingChecklistStatus? _status;

  bool get _shouldPulse => _status?.shouldPulse ?? false;
  bool get _submitted => _status?.submitted ?? false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _loadStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final json = await _authManager.apiService.getOnboardingChecklistStatus();
    if (!mounted) return;
    setState(() {
      _status = json != null ? OnboardingChecklistStatus.fromJson(json) : null;
    });
    _syncPulse();
  }

  /// Runs the pulse only while the checklist is due and not yet submitted.
  void _syncPulse() {
    if (_shouldPulse) {
      if (!_pulseController.isAnimating) _pulseController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  Future<void> _openChecklist() async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OnboardingChecklistSheet(status: _status),
    );
    if (submitted == true) {
      // Optimistically stop pulsing, then re-sync with the backend.
      if (mounted && _status != null) {
        setState(() {
          _status = OnboardingChecklistStatus(
            workedDays: _status!.workedDays,
            threshold: _status!.threshold,
            isDue: _status!.isDue,
            submitted: true,
            shouldPulse: false,
          );
        });
        _syncPulse();
      }
      await _loadStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _submitted ? AppColors.cx43C19F : AppColors.cxWarning;

    return GestureDetector(
      onTap: _openChecklist,
      child: SizedBox(
        width: 56.w,
        height: 56.w,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final t = _shouldPulse ? _pulseController.value : 0.0;
            return Stack(
              alignment: Alignment.center,
              children: [
                // Expanding, fading ring (only while pulsing)
                if (_shouldPulse)
                  Container(
                    width: 40.w + (16.w * t),
                    height: 40.w + (16.w * t),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withOpacity((1 - t) * 0.5),
                        width: 2,
                      ),
                    ),
                  ),
                // Softly breathing badge
                Transform.scale(
                  scale: _shouldPulse
                      ? 1.0 + 0.06 * (0.5 - (t - 0.5).abs()) * 2
                      : 1.0,
                  child: Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withOpacity(0.25),
                          accent.withOpacity(0.12),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withOpacity(0.45),
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (_shouldPulse)
                          BoxShadow(
                            color: accent.withOpacity(0.25 * (1 - t)),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: Icon(
                      Icons.checklist_rounded,
                      color: accent,
                      size: 22.sp,
                    ),
                  ),
                ),
                // Small "done" badge once the checklist has been submitted
                if (_submitted)
                  Positioned(
                    right: 4.w,
                    bottom: 4.w,
                    child: Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                        color: AppColors.cx43C19F,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 10.sp,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One item of the check-list.
class _ChecklistItem {
  /// Stable identifier sent to the backend.
  final String key;
  final IconData icon;
  final String text;

  const _ChecklistItem({
    required this.key,
    required this.icon,
    required this.text,
  });
}

const List<_ChecklistItem> _checklistItems = [
  _ChecklistItem(
    key: 'welcome_intro',
    icon: Icons.handshake_rounded,
    text:
        'Meni Team Leader yoki Trainer kutib oldi va ish jarayoni bilan tanishtirdi.',
  ),
  _ChecklistItem(
    key: 'team_intro',
    icon: Icons.groups_rounded,
    text: 'Meni filial jamoasi va asosiy mas’ul xodimlar bilan tanishtirishdi.',
  ),
  _ChecklistItem(
    key: 'positions_explained',
    icon: Icons.badge_rounded,
    text:
        'Menga filialdagi asosiy pozitsiyalar va ularning vazifalari tushuntirildi.',
  ),
  _ChecklistItem(
    key: 'safety_rules',
    icon: Icons.health_and_safety_rounded,
    text:
        'Menga xavfsizlik qoidalari, favqulodda holatlarda harakat qilish va mehnat xavfsizligi tushuntirildi.',
  ),
  _ChecklistItem(
    key: 'hygiene_rules',
    icon: Icons.clean_hands_rounded,
    text:
        'Menga gigiyena, qo‘l yuvish va oziq-ovqat xavfsizligining asosiy qoidalari tushuntirildi.',
  ),
  _ChecklistItem(
    key: 'role_duties',
    icon: Icons.assignment_ind_rounded,
    text:
        'Menga o‘z pozitsiyam bo‘yicha asosiy vazifalar, standartlar va kimga murojaat qilishim kerakligi tushuntirildi.',
  ),
];

class OnboardingChecklistSheet extends StatefulWidget {
  final OnboardingChecklistStatus? status;

  const OnboardingChecklistSheet({super.key, this.status});

  @override
  State<OnboardingChecklistSheet> createState() =>
      _OnboardingChecklistSheetState();
}

class _OnboardingChecklistSheetState extends State<OnboardingChecklistSheet> {
  final PageController _pageController = PageController();
  final AuthManager _authManager = AuthManager();

  bool _isSubmitting = false;

  /// Head-office branch. Its employees never escalate to a branch manager.
  static const int _headOfficeBranchId = 2;

  bool get _isHeadOffice => _authManager.currentBranchId == _headOfficeBranchId;

  /// Page 0 = intro, pages 1..N = questions, page N+1 = summary.
  int _currentPage = 0;

  /// Confirmation state per check-list item.
  late final List<bool> _confirmed = List.filled(_checklistItems.length, false);

  int get _totalPages => _checklistItems.length + 2;

  bool get _isIntro => _currentPage == 0;

  bool get _isSummary => _currentPage == _totalPages - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _goToPage(_currentPage + 1);
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  List<Map<String, dynamic>> _buildPayloadItems() {
    return [
      for (int i = 0; i < _checklistItems.length; i++)
        {
          'key': _checklistItems[i].key,
          'text': _checklistItems[i].text,
          'confirmed': _confirmed[i],
        },
    ];
  }

  void _showSnack(
    String message,
    Color color, {
    IconData icon = Icons.check_rounded,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262633) : Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: color.withOpacity(0.35), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxBlack,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sends the checklist to the backend. When [notifyManager] is true the
  /// backend pushes an FCM notification with the unconfirmed items to the
  /// branch manager / director.
  Future<void> _submit({
    required bool notifyManager,
    required bool contactManager,
  }) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final result = await _authManager.apiService.submitOnboardingChecklist(
      items: _buildPayloadItems(),
      notifyManager: notifyManager,
      contactManager: contactManager,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result == null) {
      _showSnack(
        'Yuborishda xatolik yuz berdi. Iltimos, qayta urinib ko‘ring.',
        AppColors.cxCrimsonRed,
        icon: Icons.priority_high_rounded,
      );
      return;
    }

    final notified = result['notified'] == true;
    // Show the toast while the sheet context is still mounted, then close.
    if (notifyManager) {
      _showSnack(
        notified
            ? 'Murojaatingiz filial rahbariga yuborildi.'
            : 'Check-list saqlandi. Filial rahbari topilmadi, '
                  'administratsiya xabardor qilinadi.',
        AppColors.cxWarning,
        icon: notified ? Icons.send_rounded : Icons.check_rounded,
      );
    } else {
      _showSnack('Check-list yakunlandi. Rahmat!', AppColors.cx43C19F);
    }
    Navigator.of(context).pop(true);
  }

  void _finish() {
    final unconfirmed = _confirmed.where((c) => !c).length;
    if (unconfirmed == 0 || _isHeadOffice) {
      _submit(notifyManager: false, contactManager: false);
      return;
    }
    _confirmSendUnconfirmed(unconfirmed);
  }

  /// At least one item is unconfirmed: ask whether to notify the manager.
  void _confirmSendUnconfirmed(int unconfirmed) {
    _showAppleDialog(
      icon: Icons.report_problem_rounded,
      accent: AppColors.cxWarning,
      title: '$unconfirmed ta band tasdiqlanmadi',
      message:
          'Tasdiqlanmagan bandlar ro‘yxati filial menejeri / direktoriga '
          'bildirishnoma sifatida yuborilsinmi?',
      cancelLabel: 'Yubormasdan yakunlash',
      confirmLabel: 'Yuborish',
      onCancel: () => _submit(notifyManager: false, contactManager: false),
      onConfirm: () => _submit(notifyManager: true, contactManager: false),
    );
  }

  void _contactAdministration() {
    _showAppleDialog(
      icon: Icons.support_agent_rounded,
      accent: AppColors.cxWarning,
      title: 'Direktorga murojaat',
      message:
          'Check-list natijalari va tasdiqlanmagan bandlar filial '
          'menejeri / direktoriga bildirishnoma sifatida yuboriladi. '
          'Davom etasizmi?',
      cancelLabel: 'Bekor qilish',
      confirmLabel: 'Yuborish',
      onConfirm: () => _submit(notifyManager: true, contactManager: true),
    );
  }

  /// iOS-style alert: blurred backdrop, centred card, icon, bold title,
  /// muted message and a hairline-separated action row.
  Future<void> _showAppleDialog({
    required IconData icon,
    required Color accent,
    required String title,
    required String message,
    required String cancelLabel,
    required String confirmLabel,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const iosBlue = Color(0xFF0A84FF);
    final hairline = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.12);

    Widget action({
      required String label,
      required Color color,
      required FontWeight weight,
      required VoidCallback onTap,
      required BorderRadius radius,
    }) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: SizedBox(
              height: 48.h,
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: weight,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withOpacity(isDark ? 0.45 : 0.25),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, _, __) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Center(
            child: Container(
              width: 290.w,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A36).withOpacity(0.96)
                    : Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 20.h),
                      child: Column(
                        children: [
                          Container(
                            width: 56.w,
                            height: 56.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent.withOpacity(0.22),
                                  accent.withOpacity(0.08),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent.withOpacity(0.35),
                                width: 1,
                              ),
                            ),
                            child: Icon(icon, color: accent, size: 28.sp),
                          ),
                          SizedBox(height: 14.h),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.25,
                              color: isDark
                                  ? const Color(0xFFF2F2F7)
                                  : AppColors.cxBlack,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.sp,
                              height: 1.45,
                              color: isDark
                                  ? const Color(0xFFA1A1AA)
                                  : AppColors.cxBlack.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 0.6, color: hairline),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          action(
                            label: cancelLabel,
                            color: iosBlue,
                            weight: FontWeight.w400,
                            radius: BorderRadius.only(
                              bottomLeft: Radius.circular(24.r),
                            ),
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              onCancel?.call();
                            },
                          ),
                          VerticalDivider(
                            width: 0.6,
                            thickness: 0.6,
                            color: hairline,
                          ),
                          action(
                            label: confirmLabel,
                            color: accent,
                            weight: FontWeight.w700,
                            radius: BorderRadius.only(
                              bottomRight: Radius.circular(24.r),
                            ),
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              onConfirm();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1A1A24) : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          topRight: Radius.circular(28.r),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(isDark),
          _buildProgressBar(isDark),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildIntroPage(isDark),
                for (int i = 0; i < _checklistItems.length; i++)
                  _buildQuestionPage(i, isDark),
                _buildSummaryPage(isDark),
              ],
            ),
          ),
          _buildBottomBar(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 12.w, 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A2A3A), const Color(0xFF1F1F2E)]
              : [AppColors.cxWarning.withOpacity(0.12), Colors.white],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          topRight: Radius.circular(28.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cxWarning.withOpacity(0.25),
                  AppColors.cxWarning.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.cxWarning.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.checklist_rounded,
              color: AppColors.cxWarning,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yangi xodim uchun',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : AppColors.cxBlack.withOpacity(0.5),
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Kirish check-listi',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxBlack,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close_rounded,
              size: 24.sp,
              color: isDark
                  ? const Color(0xFF9CA3AF)
                  : AppColors.cxBlack.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final progress = (_currentPage) / (_totalPages - 1);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6.h,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.08)
                      : AppColors.cxPlatinumGray.withOpacity(0.6),
                  valueColor: const AlwaysStoppedAnimation(AppColors.cxWarning),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            _isIntro
                ? ''
                : _isSummary
                ? 'Yakun'
                : '$_currentPage / ${_checklistItems.length}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFF9CA3AF)
                  : AppColors.cxBlack.withOpacity(0.5),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroPage(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF252532), const Color(0xFF1F1F2E)]
                    : [
                        AppColors.cxWarning.withOpacity(0.1),
                        AppColors.cxWarning.withOpacity(0.04),
                      ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.cxWarning.withOpacity(isDark ? 0.3 : 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.waving_hand_rounded,
                  color: AppColors.cxWarning,
                  size: 44.sp,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Jamoamizga xush kelibsiz!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxBlack,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Iltimos, quyidagi bandlarni diqqat bilan o‘qing va '
                  'bajarilgan bo‘lsa belgilang. Bu ma’lumot filialingizda '
                  'kirish treninglari to‘g‘ri o‘tkazilayotganini nazorat '
                  'qilishga yordam beradi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.6,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : AppColors.cxBlack.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16.sp,
                color: isDark
                    ? const Color(0xFF6B7280)
                    : AppColors.cxBlack.withOpacity(0.4),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${_checklistItems.length} ta band · taxminan 1 daqiqa',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : AppColors.cxBlack.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(int index, bool isDark) {
    final item = _checklistItems[index];
    final confirmed = _confirmed[index];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(22.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252532) : AppColors.cxF5F7F9,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : AppColors.cxPlatinumGray.withOpacity(0.8),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cxRoyalBlue.withOpacity(0.2),
                        AppColors.cxRoyalBlue.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    item.icon,
                    color: AppColors.cxRoyalBlue,
                    size: 24.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxBlack,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Confirm tile
          GestureDetector(
            onTap: () => setState(() => _confirmed[index] = !confirmed),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: confirmed
                    ? AppColors.cx43C19F.withOpacity(isDark ? 0.15 : 0.1)
                    : (isDark ? const Color(0xFF1F1F2E) : Colors.white),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: confirmed
                      ? AppColors.cx43C19F
                      : (isDark
                            ? Colors.white.withOpacity(0.12)
                            : AppColors.cxPlatinumGray),
                  width: confirmed ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 26.w,
                    height: 26.w,
                    decoration: BoxDecoration(
                      color: confirmed
                          ? AppColors.cx43C19F
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: confirmed
                            ? AppColors.cx43C19F
                            : (isDark
                                  ? Colors.white.withOpacity(0.3)
                                  : AppColors.cxBlack.withOpacity(0.25)),
                        width: 2,
                      ),
                    ),
                    child: confirmed
                        ? Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18.sp,
                          )
                        : null,
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      'Tasdiqlayman — bu band bajarilgan',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: confirmed
                            ? AppColors.cx43C19F
                            : (isDark
                                  ? const Color(0xFF9CA3AF)
                                  : AppColors.cxBlack.withOpacity(0.6)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Agar bu band bajarilmagan bo‘lsa, belgilamasdan davom eting — '
            'yakunda administratsiyaga murojaat qilishingiz mumkin.',
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.5,
              color: isDark
                  ? const Color(0xFF6B7280)
                  : AppColors.cxBlack.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPage(bool isDark) {
    final confirmedCount = _confirmed.where((c) => c).length;
    final allConfirmed = confirmedCount == _checklistItems.length;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: allConfirmed
                    ? [
                        AppColors.cx43C19F.withOpacity(isDark ? 0.2 : 0.12),
                        AppColors.cx4AC1A7.withOpacity(isDark ? 0.1 : 0.05),
                      ]
                    : [
                        AppColors.cxWarning.withOpacity(isDark ? 0.2 : 0.12),
                        AppColors.cxWarning.withOpacity(isDark ? 0.1 : 0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: (allConfirmed ? AppColors.cx43C19F : AppColors.cxWarning)
                    .withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  allConfirmed
                      ? Icons.verified_rounded
                      : Icons.report_problem_rounded,
                  color: allConfirmed
                      ? AppColors.cx43C19F
                      : AppColors.cxWarning,
                  size: 36.sp,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allConfirmed
                            ? 'Barcha bandlar tasdiqlandi'
                            : '$confirmedCount / ${_checklistItems.length} band tasdiqlandi',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFE8E8F0)
                              : AppColors.cxBlack,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        allConfirmed
                            ? 'Kirish treninglari to‘liq o‘tkazilgan.'
                            : 'Ba’zi bandlar tasdiqlanmadi. Xohlasangiz, '
                                  'administratsiyaga murojaat qilishingiz mumkin.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          height: 1.4,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : AppColors.cxBlack.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Per-item recap
          for (int i = 0; i < _checklistItems.length; i++) ...[
            GestureDetector(
              onTap: () => _goToPage(i + 1),
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252532) : AppColors.cxF5F7F9,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      _confirmed[i]
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: _confirmed[i]
                          ? AppColors.cx43C19F
                          : (isDark
                                ? const Color(0xFF6B7280)
                                : AppColors.cxBlack.withOpacity(0.3)),
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        _checklistItems[i].text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          height: 1.4,
                          color: isDark
                              ? const Color(0xFFC4C4D0)
                              : AppColors.cxBlack.withOpacity(0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24.w,
        12.h,
        24.w,
        MediaQuery.of(context).padding.bottom + 16.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : AppColors.cxPlatinumGray.withOpacity(0.6),
            width: 1,
          ),
        ),
      ),
      child: _isSummary ? _buildSummaryActions() : _buildNextActions(isDark),
    );
  }

  Widget _buildNextActions(bool isDark) {
    return Row(
      children: [
        if (!_isIntro) ...[
          SizedBox(
            width: 52.w,
            height: 52.h,
            child: OutlinedButton(
              onPressed: _back,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : AppColors.cxPlatinumGray,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 22.sp,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : AppColors.cxBlack.withOpacity(0.6),
              ),
            ),
          ),
          SizedBox(width: 12.w),
        ],
        Expanded(
          child: SizedBox(
            height: 52.h,
            child: FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cxWarning,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isIntro ? 'Boshlash' : 'Keyingisi',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 20.sp,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _finish,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cx43C19F,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSubmitting)
                  SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20.sp,
                    color: Colors.white,
                  ),
                SizedBox(width: 8.w),
                Text(
                  _isSubmitting ? 'Yuborilmoqda…' : 'Yakunlash',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!_isHeadOffice) ...[
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : _contactAdministration,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                side: const BorderSide(color: AppColors.cxWarning, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.support_agent_rounded,
                    size: 20.sp,
                    color: AppColors.cxWarning,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Direktorga murojaat',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cxWarning,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
