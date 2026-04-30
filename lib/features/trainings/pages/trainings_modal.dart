import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';

void showTrainingsModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TrainingsSheet(),
  );
}

class _TrainingsSheet extends StatefulWidget {
  const _TrainingsSheet();

  @override
  State<_TrainingsSheet> createState() => _TrainingsSheetState();
}

class _TrainingsSheetState extends State<_TrainingsSheet> {
  final AuthManager _authManager = AuthManager();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _themes = [];
  Set<int> _attendedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _authManager.authService.getAccessToken();
      final employeeId = _authManager.currentEmployeeId;

      if (token == null || employeeId == null) {
        throw Exception('Not authenticated');
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final results = await Future.wait([
        http.get(
          Uri.parse('https://api.v3.sievesapp.com/training-theme'),
          headers: headers,
        ),
        http.get(
          Uri.parse(
            'https://api.v3.sievesapp.com/trained-employee/employee/$employeeId',
          ),
          headers: headers,
        ),
      ]);

      final themesResp = results[0];
      final attendedResp = results[1];

      if (themesResp.statusCode != 200) {
        throw Exception('Failed to load trainings (${themesResp.statusCode})');
      }

      final List<dynamic> themesData = json.decode(themesResp.body);
      final themes = themesData
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final Set<int> attended = {};
      if (attendedResp.statusCode == 200) {
        final List<dynamic> attendedData = json.decode(attendedResp.body);
        for (final item in attendedData) {
          final id = (item as Map)['id'];
          if (id is int) attended.add(id);
        }
      }

      // Sort: attended (completed) first, preserving original order within each group
      themes.sort((a, b) {
        final aDone = attended.contains(a['id']) ? 0 : 1;
        final bDone = attended.contains(b['id']) ? 0 : 1;
        return aDone.compareTo(bDone);
      });

      if (!mounted) return;
      setState(() {
        _themes = themes;
        _attendedIds = attended;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final completed = _attendedIds.length;
    final total = _themes.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.cx43C19F,
                            AppColors.cx43C19F.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.translate('trainings'),
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (!_isLoading && _error == null)
                            Text(
                              '$completed / $total ${l10n.translate('trainingsCompletedLabel')}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : _load,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1.h, color: theme.dividerColor.withOpacity(0.3)),
              Expanded(child: _buildBody(theme, l10n, scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    ThemeData theme,
    AppLocalizations l10n,
    ScrollController scrollController,
  ) {
    if (_isLoading) {
      return _buildShimmerList(theme, scrollController);
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48.sp,
                color: AppColors.cxCrimsonRed,
              ),
              SizedBox(height: 12.h),
              Text(
                l10n.translate('trainingsLoadError'),
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 16.h),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.translate('retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_themes.isEmpty) {
      return Center(
        child: Text(
          l10n.translate('trainingsNoData'),
          style: TextStyle(
            fontSize: 14.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: _themes.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final item = _themes[index];
        final id = item['id'] as int?;
        final name = (item['name'] as String?)?.trim() ?? '';
        final attended = id != null && _attendedIds.contains(id);
        return _TrainingTile(
          name: name,
          attended: attended,
          completedLabel: l10n.translate('trainingsCompletedBadge'),
        );
      },
    );
  }

  Widget _buildShimmerList(ThemeData theme, ScrollController scrollController) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.cxF5F7F9.withOpacity(0.06)
        : AppColors.cxSilverTint;
    final highlightColor = isDark
        ? AppColors.cxSilverTint
        : AppColors.cxF5F7F9.withOpacity(0.15);
    final blockColor = isDark ? AppColors.cxWhite : AppColors.cxBlack;

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: 7,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: blockColor.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: blockColor.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: blockColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 10.h,
                        width: 140.w,
                        decoration: BoxDecoration(
                          color: blockColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: blockColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrainingTile extends StatelessWidget {
  final String name;
  final bool attended;
  final String completedLabel;

  const _TrainingTile({
    required this.name,
    required this.attended,
    required this.completedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = attended
        ? AppColors.cxEmeraldGreen.withOpacity(0.08)
        : theme.colorScheme.onSurface.withOpacity(0.04);
    final borderColor = attended
        ? AppColors.cxEmeraldGreen.withOpacity(0.35)
        : theme.dividerColor.withOpacity(0.4);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          if (attended)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 6.h,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.cxEmeraldGreen,
                    Color(0xFF2AAE4A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cxEmeraldGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    completedLabel,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
