import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Onboarding check-list for recently hired employees.
///
/// [OnboardingChecklistIcon] is a small pulsing badge meant to sit in the
/// profile card. Tapping it opens [OnboardingChecklistSheet] — a step-by-step
/// questionnaire where the employee either confirms that each required
/// training was actually delivered, or proceeds without confirming and can
/// escalate a complaint to head administration at the end.
/// ─────────────────────────────────────────────────────────────────────────

class OnboardingChecklistIcon extends StatefulWidget {
  const OnboardingChecklistIcon({super.key});

  @override
  State<OnboardingChecklistIcon> createState() =>
      _OnboardingChecklistIconState();
}

class _OnboardingChecklistIconState extends State<OnboardingChecklistIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openChecklist() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OnboardingChecklistSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.cxWarning;

    return GestureDetector(
      onTap: _openChecklist,
      child: SizedBox(
        width: 56.w,
        height: 56.w,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final t = _pulseController.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                // Expanding, fading ring
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
                  scale: 1.0 + 0.06 * (0.5 - (t - 0.5).abs()) * 2,
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
  final IconData icon;
  final String text;

  const _ChecklistItem({required this.icon, required this.text});
}

const List<_ChecklistItem> _checklistItems = [
  _ChecklistItem(
    icon: Icons.handshake_rounded,
    text:
        'Meni Team Leader yoki Trainer kutib oldi va ish jarayoni bilan tanishtirdi.',
  ),
  _ChecklistItem(
    icon: Icons.groups_rounded,
    text: 'Meni filial jamoasi va asosiy mas’ul xodimlar bilan tanishtirishdi.',
  ),
  _ChecklistItem(
    icon: Icons.badge_rounded,
    text:
        'Menga filialdagi asosiy pozitsiyalar va ularning vazifalari tushuntirildi.',
  ),
  _ChecklistItem(
    icon: Icons.health_and_safety_rounded,
    text:
        'Menga xavfsizlik qoidalari, favqulodda holatlarda harakat qilish va mehnat xavfsizligi tushuntirildi.',
  ),
  _ChecklistItem(
    icon: Icons.clean_hands_rounded,
    text:
        'Menga gigiyena, qo‘l yuvish va oziq-ovqat xavfsizligining asosiy qoidalari tushuntirildi.',
  ),
  _ChecklistItem(
    icon: Icons.assignment_ind_rounded,
    text:
        'Menga o‘z pozitsiyam bo‘yicha asosiy vazifalar, standartlar va kimga murojaat qilishim kerakligi tushuntirildi.',
  ),
];

class OnboardingChecklistSheet extends StatefulWidget {
  const OnboardingChecklistSheet({super.key});

  @override
  State<OnboardingChecklistSheet> createState() =>
      _OnboardingChecklistSheetState();
}

class _OnboardingChecklistSheetState extends State<OnboardingChecklistSheet> {
  final PageController _pageController = PageController();

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

  void _finish() {
    // TODO: submit confirmations to the backend when the API is ready.
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cx43C19F,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        content: const Text('Check-list yakunlandi. Rahmat!'),
      ),
    );
  }

  void _contactAdministration() {
    // TODO: wire this to a real complaint / contact flow when available.
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F1F2E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.support_agent_rounded,
                color: AppColors.cxWarning,
                size: 26.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Direktorga murojaat',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Belgilangan trening(lar) o‘tkazilmagani haqidagi murojaatingiz '
            'bosh administratsiyaga yuboriladi. Davom etasizmi?',
            style: TextStyle(fontSize: 14.sp, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cxWarning,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.cxWarning,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    content: const Text(
                      'Murojaatingiz administratsiyaga yuborildi.',
                    ),
                  ),
                );
              },
              child: const Text('Yuborish'),
            ),
          ],
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
            onPressed: _finish,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cx43C19F,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 20.sp,
                  color: Colors.white,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Yakunlash',
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
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: OutlinedButton(
            onPressed: _contactAdministration,
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
    );
  }
}
