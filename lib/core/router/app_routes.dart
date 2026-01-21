import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sieves_mob/features/home/pages/home.dart';

import '../../features/attendance/pages/attendance.dart';
import '../../features/break-records/pages/break_records.dart';
import '../../features/break/pages/break_page.dart';
import '../../features/checklist/pages/checklist.dart';
import '../../features/history/pages/history.dart';
// import '../../features/login/pages/login.dart';
import '../../features/lms/pages/lms_page.dart';
import '../../features/productivity-timer/pages/productivity_timer.dart';
import '../../features/lms/pages/course_viewer_page.dart';
import '../../features/lms/pages/test_detail_page.dart';
import '../../features/lms/pages/test_taking_page.dart';
import '../../features/lms/pages/test_result_page.dart';
import '../../features/lms/pages/test_history_page.dart';
import '../../features/lms/models/test.dart';
import '../../features/lms/models/test_answer.dart';
import '../../features/lms/models/test_with_sessions.dart';
import '../../features/notification/pages/notifications_new.dart';
import '../../features/onboard/pages/onboard.dart';
import '../../features/profile/pages/profile.dart';
import '../../features/face-verification/pages/face_verification_page.dart';
import '../../features/wallet/pages/wallet_page.dart';
import '../../features/calendar/pages/calendar_page.dart';
import '../services/auth/auth_manager.dart';

class AppRoutes {

  static const String onboard = '/onboard';
  // static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String attendance = '/attendance';
  static const String breakRecords = '/breakRecords';
  static const String breakOrder = '/breakOrder';
  static const String history = '/history';
  static const String productivityTimer = '/productivityTimer';
  static const String checklist = '/checklist';
  static const String notificationNew = '/notificationNew';
  static const String lmsPage = '/lmsPage';
  static const String courseViewer = '/courseViewer';
  static const String testDetail = '/testDetail';
  static const String testTaking = '/testTaking';
  static const String testResult = '/testResult';
  static const String testHistory = '/testHistory';
  static const String faceVerification = '/faceVerification';
  static const String wallet = '/wallet';
  static const String calendar = '/calendar';

  static GoRouter createRouter(String initialLocation, {GlobalKey<NavigatorState>? navigatorKey}) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/onboard',
          name: onboard,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const Onboard(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        // GoRoute(
        //   path: '/login',
        //   name: login,
        //   builder: (context, state) => const Login()
        // ),
        GoRoute(
          path: '/home',
          name: home,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const Home(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/profile',
          name: profile,
          builder: (context, state) => const Profile()
        ),
        GoRoute(
            path: '/attendance',
            name: attendance,
            builder: (context, state) => const Attendance()
        ),
        GoRoute(
            path: '/breakRecords',
            name: breakRecords,
            builder: (context, state) => const BreakRecords()
        ),
        GoRoute(
            path: '/breakOrder',
            name: breakOrder,
            builder: (context, state) => const BreakPage()
        ),
        GoRoute(
          path: '/history',
          name: history,
          builder: (context, state) => const History()
        ),
        GoRoute(
          path: '/productivityTimer',
          name: productivityTimer,
          redirect: (context, state) {
            final authManager = AuthManager();
            if (!authManager.hasStopwatchAccess) {
              return '/home';
            }
            return null;
          },
          builder: (context, state) => const ProductivityTimer()
        ),
        GoRoute(
          path: '/checklist',
          name: checklist,
          builder: (context, state) => const Checklist()
        ),
        
        GoRoute(
          path: '/notificationNew',
          name: notificationNew,
          builder: (context, state) => const NotificationsPage()
        ),

        GoRoute(
          path: '/lmsPage',
          name: lmsPage,
          builder: (context, state) => const LmsPage()
        ),

        GoRoute(
          path: '/testHistory',
          name: testHistory,
          builder: (context, state) => const TestHistoryPage()
        ),

        GoRoute(
          path: '/courseViewer',
          name: courseViewer,
          builder: (context, state) {
            final test = state.extra as Test;
            return CourseViewerPage(test: test);
          }
        ),

        GoRoute(
          path: '/testDetail',
          name: testDetail,
          builder: (context, state) {
            final testWithSessions = state.extra as TestWithSessions;
            return TestDetailPage(testWithSessions: testWithSessions);
          }
        ),

        GoRoute(
          path: '/testTaking',
          name: testTaking,
          builder: (context, state) {
            final test = state.extra as Test;
            return TestTakingPage(test: test);
          }
        ),

        GoRoute(
          path: '/testResult',
          name: testResult,
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>;
            return TestResultPage(
              test: data['test'] as Test,
              score: data['score'] as int?,
              answers: data['answers'] as Map<String, TestAnswer>,
              timeTaken: data['timeTaken'] as int,
              sessionId: data['sessionId'] as int?,
              sessionData: data['sessionData'] as Map<String, dynamic>?,
            );
          }
        ),

        GoRoute(
          path: '/faceVerification',
          name: faceVerification,
          builder: (context, state) => const FaceVerificationPage()
        ),

        GoRoute(
          path: '/wallet',
          name: wallet,
          builder: (context, state) => const WalletPage()
        ),

        GoRoute(
          path: '/calendar',
          name: calendar,
          builder: (context, state) => const CalendarPage()
        ),
      ]);
  }
}