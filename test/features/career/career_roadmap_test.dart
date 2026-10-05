import 'package:flutter_test/flutter_test.dart';
import 'package:sieves_mob/features/career/models/career_roadmap.dart';
import 'package:sieves_mob/features/career/models/career_timeline_model.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  group('addMonths', () {
    test('clamps to the last day of a shorter month', () {
      expect(addMonths(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
      expect(addMonths(DateTime(2023, 1, 31), 1), DateTime(2023, 2, 28));
    });

    test('rolls over the year', () {
      expect(addMonths(DateTime(2024, 11, 15), 3), DateTime(2025, 2, 15));
    });
  });

  test('monthsBetween counts only completed months', () {
    expect(monthsBetween(DateTime(2024, 1, 15), DateTime(2024, 2, 14)), 0);
    expect(monthsBetween(DateTime(2024, 1, 15), DateTime(2024, 2, 15)), 1);
    expect(monthsBetween(DateTime(2023, 6, 1), DateTime(2025, 1, 1)), 19);
  });

  group('buildRoadmap', () {
    final hire = addMonths(_today(), -14);
    final timeline = CareerTimeline.fromJson({
      'employee': {
        'employeeName': 'Ali Valiyev',
        'hireDate': _iso(hire),
        'isActive': true,
        'contractCount': 2,
        'trainingCount': 1,
      },
      'events': [
        {'date': _iso(hire), 'type': 'hire', 'salaryStructureName': 'L1'},
        {
          'date': _iso(addMonths(hire, 2)),
          'type': 'training',
          'trainingTheme': 'Hygiene',
        },
        {
          'date': _iso(addMonths(hire, 7)),
          'type': 'contract',
          'change': 'promotion',
          'salaryStructureName': 'L2',
        },
      ],
    });

    test(
      'skips trainings, interleaves milestones, then today and upcoming',
      () {
        final kinds = buildRoadmap(timeline).map((i) => i.kind).toList();
        expect(kinds, [
          RoadmapKind.hire, // hire
          RoadmapKind.milestone, // 1 month
          RoadmapKind.milestone, // 3 months
          RoadmapKind.milestone, // 6 months
          RoadmapKind.promotion, // month 7
          RoadmapKind.milestone, // 1 year
          RoadmapKind.today,
          RoadmapKind.upcoming, // 2 years
          RoadmapKind.upcoming, // 3 years
        ]);
      },
    );

    test('today node carries the day number', () {
      final today = buildRoadmap(
        timeline,
      ).firstWhere((i) => i.kind == RoadmapKind.today);
      expect(today.dayNumber, _today().difference(hire).inDays + 1);
    });

    test('upcoming stops carry months and days left', () {
      final upcoming = buildRoadmap(timeline).where((i) => i.isUpcoming);
      expect(upcoming.map((i) => i.milestoneMonths), [24, 36]);
      expect(
        upcoming.first.daysLeft,
        addMonths(hire, 24).difference(_today()).inDays,
      );
    });

    test('days per salary step, current step still counting', () {
      final roadmap = buildRoadmap(timeline);
      final hireStop = roadmap.firstWhere((i) => i.kind == RoadmapKind.hire);
      final promo = roadmap.firstWhere((i) => i.kind == RoadmapKind.promotion);
      expect(hireStop.daysInStep, addMonths(hire, 7).difference(hire).inDays);
      expect(hireStop.isCurrentStep, isFalse);
      expect(promo.daysInStep, _today().difference(addMonths(hire, 7)).inDays);
      expect(promo.isCurrentStep, isTrue);
      expect(currentStepDays(roadmap), promo.daysInStep);
      // Milestones and today carry no step duration.
      expect(
        roadmap
            .where((i) => i.kind == RoadmapKind.milestone)
            .every((i) => i.daysInStep == null),
        isTrue,
      );
    });

    test('counts promotions', () {
      expect(timeline.promotionCount, 1);
    });

    test('next milestone is 2 years, partly done', () {
      final next = nextMilestone(timeline.profile!)!;
      expect(next.months, 24);
      expect(next.date, addMonths(hire, 24));
      expect(next.progress, greaterThan(0));
      expect(next.progress, lessThan(1));
    });
  });

  test('former employee: no today node, no next milestone', () {
    final hire = DateTime(2022, 3, 10);
    final timeline = CareerTimeline.fromJson({
      'employee': {
        'employeeName': 'X',
        'hireDate': _iso(hire),
        'exitDate': '2022-09-01',
        'isActive': false,
      },
      'events': [
        {'date': _iso(hire), 'type': 'hire'},
        {'date': '2022-09-01', 'type': 'exit'},
      ],
    });
    final kinds = buildRoadmap(timeline).map((i) => i.kind).toList();
    expect(kinds.last, RoadmapKind.exit);
    expect(kinds, isNot(contains(RoadmapKind.today)));
    // 1, 3 months passed before the exit; 6 months (10 Sep) did not.
    expect(kinds.where((k) => k == RoadmapKind.milestone).length, 2);
    expect(nextMilestone(timeline.profile!), isNull);
    // Last step ends at the exit date and is not "current".
    final hireStop = buildRoadmap(timeline).first;
    expect(hireStop.daysInStep, DateTime(2022, 9, 1).difference(hire).inDays);
    expect(hireStop.isCurrentStep, isFalse);
    expect(currentStepDays(buildRoadmap(timeline)), isNull);
  });

  test('renewal on the same step does not restart the count', () {
    final hire = addMonths(_today(), -10);
    final roadmap = buildRoadmap(
      CareerTimeline.fromJson({
        'employee': {'employeeName': 'X', 'hireDate': _iso(hire)},
        'events': [
          {'date': _iso(hire), 'type': 'hire', 'salaryStructureName': 'L1'},
          {
            'date': _iso(addMonths(hire, 5)),
            'type': 'contract',
            'change': 'renewal',
            'salaryStructureName': 'L1',
          },
        ],
      }),
    );
    final hireStop = roadmap.firstWhere((i) => i.kind == RoadmapKind.hire);
    final renewal = roadmap.firstWhere((i) => i.kind == RoadmapKind.renewal);
    expect(hireStop.daysInStep, _today().difference(hire).inDays);
    expect(hireStop.isCurrentStep, isTrue);
    expect(renewal.daysInStep, isNull);
  });

  test('no contract yet: empty roadmap', () {
    final timeline = CareerTimeline.fromJson({'employee': null, 'events': []});
    expect(timeline.profile, isNull);
    expect(buildRoadmap(timeline), isEmpty);
  });
}
