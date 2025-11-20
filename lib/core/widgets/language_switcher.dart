import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/locale_provider.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cxRoyalBlue.withOpacity(0.1),
                      AppColors.cxEmeraldGreen.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: AppColors.cxRoyalBlue,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Language',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Language options
          Row(
            children: [
              _buildLanguageOption(
                context: context,
                languageCode: 'en',
                languageName: 'English',
                flag: '🇬🇧',
                isSelected: currentLocale == 'en',
                onTap: () => localeProvider.setLocale(const Locale('en')),
              ),
              SizedBox(width: 12.w),
              _buildLanguageOption(
                context: context,
                languageCode: 'uz',
                languageName: 'O\'zbek',
                flag: '🇺🇿',
                isSelected: currentLocale == 'uz',
                onTap: () => localeProvider.setLocale(const Locale('uz')),
              ),
              SizedBox(width: 12.w),
              _buildLanguageOption(
                context: context,
                languageCode: 'ru',
                languageName: 'Русский',
                flag: '🇷🇺',
                isSelected: currentLocale == 'ru',
                onTap: () => localeProvider.setLocale(const Locale('ru')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String languageCode,
    required String languageName,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.cx43C19F,
                      AppColors.cx4AC1A7,
                    ],
                  )
                : null,
            color: isSelected ? null : Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.cx43C19F
                  : Theme.of(context).dividerColor.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.cx43C19F.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                flag,
                style: TextStyle(fontSize: 24.sp),
              ),
              SizedBox(height: 6.h),
              Text(
                languageName,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
