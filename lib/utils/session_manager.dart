import 'dart:convert';
import 'package:poultary/multiuser/model/farm_plan.dart';
import 'package:poultary/multiuser/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SessionManager {
  static const String user_id = "user_id";
  static const String app_launch = "app_launch";
  static const String whats_new = "new_feature";
  static const String phone_id = "phone_id";
  static const String is_premium = "is_premium";
  static final String countryCode = "countryCode";
  static final String user = "user";
  static final String country_code_web = "country_code_web";
  static final String country_flag_web = "country_flag_web";
  static final String won_today = "won_today";
  static final String won_total = "won_total";
  static final String level = "level";
  static final String mil_win = "mil_win";
  static final String one_min_highest = "one_min_highest";
  static final String vs_computer = "vs_computer";
  static final String last_time_saved = "last_time_saved";
  static final String reward_time = "reward_time";
  static final String in_app = "in_app";
  static final String selected_language = "selected_language";
  static final String automaticOnlineBackup = "automatic_backup_drive";
  static final String dash_filter = "dash_filter";
  static final String report_filter = "report_filter";
  static final String other_filter = "other_filter";
  static final String unit_key = "unit_key";
  static final String tray_size = "tray_size";
  static final String tray_enabled = "tray_enabled";
  static final String table_created = "table_created";
  static final String skipped = "multi_skipped";
  static final String loggedIn = "loggedIn";
  static final String loggedOut = "loggedOut";
  static final String isAdmin = "isAdmin";
  static final String accessExpired = "accessExpired";
  static final String isSubscribed = "hasSubscription";
  static final String offlineConfirmation = "offlineConfirmation";


  static Future<void> clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }


  static Future<void> setValue(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value); // use key parameter
  }

  static Future<String?> getValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(key); // use key parameter
    return value;
  }


  static Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = prefs.getString('last_backup_time');
    return lastBackup != null ? DateTime.parse(lastBackup) : null;
  }

  static Future<void> saveBackupTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    await prefs.setString('last_backup_time', now);
  }

  static Future<DateTime?> getLastSyncTime(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_sync_$key');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  static Future<void> setLastSyncTime(String key, DateTime? dateTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_sync_$key', dateTime!.millisecondsSinceEpoch);
  }

  static Future<void> saveFarmPlan(FarmPlan farmPlan) async {
    final prefs = await SharedPreferences.getInstance();
    String userJson = jsonEncode(farmPlan.toJson());
    await prefs.setString('farmPlan', userJson);
  }

  static Future<FarmPlan?> getFarmPlan() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('farmPlan');
    if (userJson == null || userJson == "") return null;
    Map<String, dynamic> userMap = jsonDecode(userJson);
    return FarmPlan.fromJson(userMap);
  }

  static Future<void> saveUserToPrefs(MultiUser user) async {
    final prefs = await SharedPreferences.getInstance();
    String userJson = jsonEncode(user.toMap());
    await prefs.setString('user', userJson);
  }

  static Future<void> clearUserObject() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', "");
  }

  static Future<MultiUser?> getUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user');
    if (userJson == null || userJson == "") return null;
    Map<String, dynamic> userMap = jsonDecode(userJson);
    return MultiUser.fromMap(userMap);
  }


  static Future<void> setUnit(String countryCode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(SessionManager.unit_key, countryCode);
  }

  static Future<String> getUnit() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String unit;
    unit = pref.getString(SessionManager.unit_key) ?? "KG";
    return unit;
  }


  static Future<void> setInt(int traySize) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(SessionManager.tray_size, traySize);
  }

  static Future<int> getInt(String key) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    int count;
    count = pref.getInt(key) ?? 0;
    return count;
  }
  static Future<void> setBoolValue(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  static Future<void> setBool(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(SessionManager.tray_enabled, value);
  }

  static Future<bool> getBool(String key) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getBool(key) ?? false;

  }

  static Future<void> setUserID(int userid) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(SessionManager.user_id, userid);
  }

  static Future<int?> getUserID() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    int? user_id;
    user_id = pref.getInt(SessionManager.user_id) ?? null;
    return user_id;
  }

  static Future<bool> isShowWhatsNewDialog() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    bool app_launch;
    app_launch = pref.getBool(SessionManager.whats_new) ?? true;
    return app_launch;
  }

  static Future<bool> isAutoOnlineBackup() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    bool backup;
    backup = pref.getBool(SessionManager.automaticOnlineBackup) ?? false;
    return backup;
  }

  static setOnlineBackup(bool value) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setBool(SessionManager.automaticOnlineBackup, value);
  }

  static setWhatsNewDialog(bool value) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setBool(SessionManager.whats_new, value);
  }

  static Future<bool> getAppLaunch() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    bool app_launch;
    app_launch = pref.getBool(SessionManager.app_launch) ?? true;
    return app_launch;
  }

  static setupComplete() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setBool(SessionManager.app_launch, false);
  }

  static Future<void> setPhoneID(String phoneId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(SessionManager.phone_id, phoneId);
  }

  static Future<String?> getPhoneId() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String? phoneId;
    phoneId = pref.getString(SessionManager.phone_id);
    return phoneId;
  }
  static Future<void> setPremium(bool premiumValue) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(SessionManager.is_premium, premiumValue);
  }

  static Future<bool?> getPremium() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    bool? isPremium;
    isPremium = pref.getBool(SessionManager.is_premium);
    return isPremium;
  }

  static Future<void> setCountryCode(String countryCode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(SessionManager.countryCode, countryCode);
  }

  static Future<String> getCountryCode() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String countryCode;
    countryCode = pref.getString(SessionManager.countryCode) ?? "";
    return countryCode;
  }
  static Future<void> setWonToday(int won_today) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(SessionManager.won_today, won_today);
  }

  static Future<int> getWonToday() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    int won_today;
    won_today = pref.getInt(SessionManager.won_today) ?? 0;
    return won_today;
  }

  static Future<void> setWonTotal(int won_total) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(SessionManager.won_total, won_total);
  }

  static Future<int> getWonTotal() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    int won_total;
    won_total = pref.getInt(SessionManager.won_total) ?? 0;
    return won_total;
  }

  static Future<void> setLevel(int level) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(SessionManager.level, level);
  }

  static Future<int> getLevel() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    int level;
    level = pref.getInt(SessionManager.level) ?? 0;
    return level;
  }
  static Future<void> setMillionaireWins(int mil_win) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(SessionManager.mil_win, mil_win);
  }

  static Future<int> getMillionaireWins() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    int mil_win;
    mil_win = pref.getInt(SessionManager.mil_win) ?? 0;
    return mil_win;
  }

  static Future<void> setOneMinuteHighest(int level) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(SessionManager.one_min_highest, level);
  }

  static Future<int> getOneMinuteHighest() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    int one_min_highest;
    one_min_highest = pref.getInt(SessionManager.one_min_highest) ?? 0;
    return one_min_highest;
  }

  static Future<void> setVSComputer(int vs_computer) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(SessionManager.vs_computer, vs_computer);
  }

  static Future<int> getVSComputer() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    int vs_computer;
    vs_computer = pref.getInt(SessionManager.vs_computer) ?? 0;
    return vs_computer;
  }
  static Future<void> setLastTimeSaved(int last_time_saved) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(SessionManager.last_time_saved, last_time_saved);
  }

  static Future<int> getLasTimeSaved() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    int last_time_saved;
    last_time_saved = pref.getInt(SessionManager.last_time_saved) ?? 0;
    return last_time_saved;
  }

  static Future<void> setRewardTime(int reward_time) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(SessionManager.reward_time, reward_time);
  }

  static Future<int> getRewardTime() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    int reward_time;
    reward_time = pref.getInt(SessionManager.reward_time) ?? 0;
    return reward_time;
  }
  static Future<void> setInApp(bool in_app) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(SessionManager.in_app, in_app);
  }

  static Future<bool> getInApp() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    bool? in_app;
    in_app = pref.getBool(SessionManager.in_app) ?? false;
    return in_app;
  }
  static Future<void> setSelectedLanguage(String selectedLanguage) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(SessionManager.selected_language, selectedLanguage);
  }

  static Future<String> getSelectedLanguage() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String selectedLanguage;
    selectedLanguage = pref.getString(SessionManager.selected_language) ?? 'en';
    return selectedLanguage;
  }

  static Future<int?> getDashboardFilter() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    int? selectedLanguage;
    selectedLanguage = pref.getInt(SessionManager.dash_filter) ?? 6;
    return selectedLanguage;
  }

  static Future<int?> getReportFilter() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    int? selectedLanguage;
    selectedLanguage = pref.getInt(SessionManager.report_filter) ?? 6;
    return selectedLanguage;
  }

  static Future<int?> getOtherFilter() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    int? selectedLanguage;
    selectedLanguage = pref.getInt(SessionManager.other_filter) ?? 2;
    return selectedLanguage;
  }

  static Future<void> updateFilterValue(String key, int value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(key, value);
  }

}
