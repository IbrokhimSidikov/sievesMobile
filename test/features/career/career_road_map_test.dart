import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sieves_mob/core/l10n/app_localizations_delegate.dart';
import 'package:sieves_mob/core/theme/app_tokens.dart';
import 'package:sieves_mob/features/career/models/career_roadmap.dart';
import 'package:sieves_mob/features/career/models/career_timeline_model.dart';
import 'package:sieves_mob/features/career/widgets/career_road_map.dart';

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  final now = DateTime.now();
  final hire = addMonths(DateTime(now.year, now.month, now.day), -26);
  final items = buildRoadmap(
    CareerTimeline.fromJson({
      'employee': {'employeeName': 'Ali', 'hireDate': _iso(hire)},
      'events': [
        {'date': _iso(hire), 'type': 'hire', 'salaryStructureName': 'Kassir 1'},
        {
          'date': _iso(addMonths(hire, 8)),
          'type': 'contract',
          'change': 'promotion',
          'salaryStructureName': 'Kassir 2 — a long salary step name',
        },
        {
          'date': _iso(addMonths(hire, 20)),
          'type': 'contract',
          'change': 'renewal',
          'salaryStructureName': 'Kassir 2',
        },
      ],
    }),
  );

  for (final (name, tokens, locale) in [
    ('light / en', AppTokens.light, const Locale('en')),
    ('dark / ru', AppTokens.dark, const Locale('ru')),
    ('dark / uz', AppTokens.dark, const Locale('uz')),
  ]) {
    testWidgets('renders without overflow ($name)', (tester) async {
      tester.view.physicalSize = const Size(393 * 3, 852 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 852),
          minTextAdapt: true,
          builder: (_, __) => MaterialApp(
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('uz'), Locale('ru')],
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(extensions: [tokens]),
            home: Scaffold(
              backgroundColor: tokens.background,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: CareerRoadMap(items: items),
              ),
            ),
          ),
        ),
      );
      // Let the road finish drawing; the today pulse repeats forever.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(tester.takeException(), isNull);
      // hire, 1/3/6 months, promotion, 1 year, renewal, 2 years, today,
      // and two upcoming anniversaries.
      expect(items.length, 11);
    });
  }
}
