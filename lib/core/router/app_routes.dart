
import 'package:go_router/go_router.dart';
import 'package:sieves_mob/features/home/pages/home.dart';

import '../../features/attendance/pages/attendance.dart';
import '../../features/break-records/pages/break_records.dart';
import '../../features/history/pages/history.dart';
import '../../features/login/pages/login.dart';
import '../../features/notification/pages/notification.dart';
import '../../features/onboard/pages/onboard.dart';
import '../../features/profile/pages/profile.dart';

class AppRoutes {

  static const String onboard = '/onboard';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String attendance = '/attendance';
  static const String breakRecords = '/breakRecords';
  static const String history = '/history';
  static const String notification = '/notification';

  static final GoRouter router = GoRouter(
      initialLocation: onboard,
      routes: [
          GoRoute(
              path: '/onboard',
              name: onboard,
              builder: (context, state) => const Onboard()
          ),
        GoRoute(
          path: '/login',
          name: login,
          builder: (context, state) => const Login()
        ),
        GoRoute(
            path: '/home',
            name: home,
            builder: (context, state) => const Home()
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
          path: '/history',
          name: history,
          builder: (context, state) => const History()
        ),
        GoRoute(
          path: '/notification',
          name: notification,
          builder: (context, state) => const NotificationsPage()
        )
      ]);
}