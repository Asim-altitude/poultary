import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsUtil {
  // Singleton instance
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /* --------------------------------------------------------------------------
   * SCREEN TRACKING
   * -------------------------------------------------------------------------- */

  /// Call this in every screen (initState or didChangeDependencies)
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  /* --------------------------------------------------------------------------
   * USER ACTIVITY (DAU / MAU)
   * -------------------------------------------------------------------------- */

  /// Call once after login / app start
  static Future<void> setUser({
    required String userId,
    String? role, // admin / manager / worker
  }) async {
    await _analytics.setUserId(id: userId);

    if (role != null) {
      await _analytics.setUserProperty(
        name: 'role',
        value: role,
      );
    }
  }

  /* --------------------------------------------------------------------------
   * BASIC ENGAGEMENT EVENTS
   * -------------------------------------------------------------------------- */

  static Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  /// Use for important buttons
  static Future<void> logButtonClick({
    required String buttonName,
    required String screen,
  }) async {
    await _analytics.logEvent(
      name: 'button_click',
      parameters: {
        'button': buttonName,
        'screen': screen,
      },
    );
  }

  /* --------------------------------------------------------------------------
   * POULTRY APP–SPECIFIC EVENTS (VERY IMPORTANT)
   * -------------------------------------------------------------------------- */

  static Future<void> logAddFlock() async {
    await _analytics.logEvent(name: 'add_flock');
  }

  static Future<void> logAddEggEntry({
    required int eggCount,
  }) async {
    await _analytics.logEvent(
      name: 'add_egg_entry',
      parameters: {
        'eggs': eggCount,
      },
    );
  }

  static Future<void> logAddFeed({
    required double quantity,
    required String unit,
  }) async {
    await _analytics.logEvent(
      name: 'add_feed',
      parameters: {
        'qty': quantity,
        'unit': unit,
      },
    );
  }

  static Future<void> logAddBirds({
    required String quantity,
    required String event,
  }) async {
    await _analytics.logEvent(
      name: 'modify_birds',
      parameters: {
        'qty': quantity,
        'event': event,
      },
    );
  }

  static Future<void> logAddEgg({
    required String quantity,
    required String event,
  }) async {
    await _analytics.logEvent(
      name: 'add_eggs',
      parameters: {
        'qty': quantity,
        'event': event,
      },
    );
  }

  static Future<void> logAddTransaction({
    required String type, // income / expense
    required double amount,
  }) async {
    await _analytics.logEvent(
      name: 'add_transaction',
      parameters: {
        'type': type,
        'amount': amount,
      },
    );
  }

  /* --------------------------------------------------------------------------
   * FILTERS & REPORTS
   * -------------------------------------------------------------------------- */

  static Future<void> logDateFilter({
    required String range, // today, week, month, all_time
  }) async {
    await _analytics.logEvent(
      name: 'date_filter_used',
      parameters: {
        'range': range,
      },
    );
  }

  static Future<void> logReportGenerated({
    required String reportType, // eggs, finance, feed
  }) async {
    await _analytics.logEvent(
      name: 'report_generated',
      parameters: {
        'type': reportType,
      },
    );
  }

  /* --------------------------------------------------------------------------
   * ERRORS (VERY USEFUL)
   * -------------------------------------------------------------------------- */

  static Future<void> logError({
    required String message,
    String? screen,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'message': message,
        if (screen != null) 'screen': screen,
      },
    );
  }
}
