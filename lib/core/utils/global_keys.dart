import 'package:flutter/widgets.dart';

/// Root navigator key shared between [MaterialApp.router] (via GoRouter) and
/// services that live outside the widget tree (e.g. the notification service)
/// so they can present global overlays such as the announcement pop-up.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
