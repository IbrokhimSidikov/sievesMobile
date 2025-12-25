import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/providers/locale_provider.dart';
import 'core/l10n/app_localizations_delegate.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/router/app_routes.dart';
import 'core/services/auth/auth_cubit.dart';
import 'core/services/auth/auth_manager.dart';
import 'core/services/auth/auth_state.dart';
import 'core/services/version/version_service.dart';
import 'core/services/theme/theme_cubit.dart';
import 'core/services/notification/notification_service.dart';
import 'core/widgets/force_update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📩 [FOREGROUND] Notification received');
    print('🔔 Title: ${message.notification?.title}');
    print('📝 Body: ${message.notification?.body}');
    print('📦 Data: ${message.data}');
  });
  // 🔔 iOS foreground notification presentation
  await FirebaseMessaging.instance
      .setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // Initialize notification service in background (don't await)
  print('🚀 Starting app - notification service will initialize in background');
  NotificationService().initialize().then((_) {
    print('✅ Notification service initialized');
    NotificationService().testNotificationSetup();
  }).catchError((e) {
    print('⚠️ Notification service initialization failed: $e');
  });

  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final VersionService _versionService;
  bool _isInitialized = false;
  final _navigatorKey = GlobalKey<NavigatorState>();
  final localeProvider = LocaleProvider();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize locale provider first
    await localeProvider.initialize();
    // Then initialize version service
    await _initializeVersionService();
  }

  Future<void> _initializeVersionService() async {
    try {
      // Initialize Remote Config
      final remoteConfig = FirebaseRemoteConfig.instance;
      _versionService = VersionService(remoteConfig);
      await _versionService.initialize();

      setState(() {
        _isInitialized = true;
      });

      // Check for updates after app loads
      _checkForUpdates();
    } catch (e) {
      print('Error initializing version service: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _checkForUpdates() async {
    // Wait a bit to ensure the app UI is fully loaded
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final updateStatus = await _versionService.checkForUpdate();

      print('🔍 Update check result:');
      print('  Current version: ${updateStatus.currentVersion}');
      print('  Minimum required: ${updateStatus.minimumRequiredVersion}');
      print('  Latest version: ${updateStatus.latestVersion}');
      print('  Update required: ${updateStatus.isUpdateRequired}');
      print('  Update available: ${updateStatus.isUpdateAvailable}');

      // Show update dialog if needed
      if (updateStatus.isUpdateRequired || updateStatus.isUpdateAvailable) {
        final context = _navigatorKey.currentContext;
        if (context != null && mounted) {
          showDialog(
            context: context,
            barrierDismissible: !updateStatus.isUpdateRequired,
            builder: (context) => ForceUpdateDialog(
              updateStatus: updateStatus,
            ),
          );
        } else {
          print('⚠️ Navigator context not available yet, retrying...');
          await Future.delayed(const Duration(milliseconds: 500));
          _checkForUpdates();
        }
      }
    } catch (e) {
      print('❌ Error checking for updates: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading...'),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        // Provide LocaleProvider for language switching
        ChangeNotifierProvider.value(value: localeProvider),
        // Provide AuthCubit to the entire app
        BlocProvider(create: (context) => AuthCubit(AuthManager())),
        // Provide ThemeCubit for theme switching
        BlocProvider(create: (context) => ThemeCubit()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(393, 852),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              return BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  return MaterialApp.router(
                    title: 'Sieves Mobile App',
                    debugShowCheckedModeBanner: false,
                    // Localization configuration
                    locale: localeProvider.locale,
                    supportedLocales: const [
                      Locale('en', ''),
                      Locale('uz', ''),
                      Locale('ru', ''),
                    ],
                    localizationsDelegates: const [
                      AppLocalizationsDelegate(),
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    theme: AppTheme.lightTheme.copyWith(
                      textTheme: GoogleFonts.nunitoTextTheme(
                        Theme.of(context).textTheme,
                      ),
                    ),
                    darkTheme: AppTheme.darkTheme.copyWith(
                        textTheme: GoogleFonts.nunitoTextTheme(
                            Theme.of(context).textTheme,
                        )),
                    themeMode: themeMode,
                    routerConfig: AppRoutes.router,
                    scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
                builder: (builderContext, routerChild) {
                  return Navigator(
                    key: _navigatorKey,
                    onPopPage: (route, result) => route.didPop(result),
                    pages: [
                      MaterialPage(
                        child: BlocListener<AuthCubit, AuthState>(
                          // Global listener for auth state changes
                          listener: (context, state) {
                            print('');
                            print('🌍 [GLOBAL BlocListener] Auth state changed: ${state.runtimeType}');
                            
                            if (state is AuthError) {
                              print('❌ [GLOBAL BlocListener] Showing error message: ${state.message}');
                              // Show error message (e.g., session expired)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(state.message),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            } else if (state is AuthUnauthenticated) {
                              // Session expired or user logged out - navigate to login
                              print('🔐 [GLOBAL BlocListener] AuthUnauthenticated detected');
                              print('🚀 [GLOBAL BlocListener] Navigating to /onboard...');
                              AppRoutes.router.go('/onboard');
                              print('✅ [GLOBAL BlocListener] Navigation initiated');
                            }
                            print('');
                          },
                          child: routerChild ?? const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  );
                },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}