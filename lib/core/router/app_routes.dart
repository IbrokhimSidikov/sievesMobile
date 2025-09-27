
import 'package:go_router/go_router.dart';
import 'package:sieves_mob/features/home/pages/home.dart';

import '../../features/attendance/pages/attendance.dart';
import '../../features/login/pages/login.dart';
import '../../features/onboard/pages/onboard.dart';
import '../../features/profile/pages/profile.dart';

class AppRoutes {

  static const String onboard = '/onboard';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String attendance = '/attendance';

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
      ]);
}