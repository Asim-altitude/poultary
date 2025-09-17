import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/home_screen.dart';
import 'package:poultary/multiuser/classes/WorkerDashboard.dart';
import 'package:poultary/multiuser/model/user.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'app_setup/language_setup_screen.dart';
import 'auto_add_feed_screen.dart';
import 'model/blog.dart';
import 'multiuser/classes/AuthGate.dart';
import 'multiuser/classes/farm_welcome_screen.dart';
import 'multiuser/classes/welcome_screen.dart';

bool direction = true;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(); // This is important!

  runApp(EasyLocalization(
          supportedLocales: [Locale('en'), Locale('ar'),Locale('de'),Locale('ru'),Locale('fa'),Locale('it'),Locale('ja'),Locale('ko'),Locale('pt'),Locale('tr'),Locale('fr'),Locale('id'),Locale('hi'),Locale('es'),Locale('zh'),Locale('uk'),Locale('pl'),Locale('bn'),Locale('te'),Locale('ta'),Locale('el')],
          path: 'assets/translations', // <-- change the path of the translation files
          fallbackLocale: Locale('en'),
      child: MyApp()),);
  requestGDPR();

  direction = await Utils.getDirection();
  await MobileAds.instance.initialize();
  Utils.direction = await Utils.getDirection();
  // MobileAds.instance.updateRequestConfiguration(
  //     RequestConfiguration(testDeviceIds: ['C0B856BD630A2928BC9F472E0A5C870A','C1F82EF953946E2EACA6F014AFF27318','6A26B5F47A581E9DF187B0FAE54A685E']));
  await Hive.initFlutter();
  Hive.registerAdapter(BlogAdapter());

/*  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.blue, // Your desired color
      statusBarIconBrightness: Brightness.light, // light icons (for dark background)
    ),
  );*/

  final themeColor = Colors.blue;
  final isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;


}

Future<Widget> getInitialScreen() async {
  await DatabaseHelper.instance.database;
  SharedPreferences prefs = await SharedPreferences.getInstance();


  bool initialSetupDone = await Utils.checkAppLaunch();
  bool skipped = true; //await SessionManager.getBool(SessionManager.skipped);
  bool loggedIn = await SessionManager.getBool(SessionManager.loggedIn);
  bool loggedOut = await SessionManager.getBool(SessionManager.loggedOut);

  bool isAdmin = await SessionManager.getBool(SessionManager.isAdmin);
  MultiUser? user = await SessionManager.getUserFromPrefs();
  List<MultiUser> users = await DatabaseHelper.getAllUsers();
  bool isAutoFeedEnabled = prefs.getBool('isAutoFeedEnabled') ?? false;
  Utils.currentUser = user;

  try {
    _configEasyLoading();
  }
  catch (ex) {
    print(ex);
  }

  /*if(launch){
    return LanguageSetupScreen();
  } else if (isAutoFeedEnabled){
    return AutoFeedSyncScreen();
  }else {
    return HomeScreen();
  }*/

  /*if(launch) {
      return LanguageSetupScreen();
    } else if (loggedIn) {
      return FarmWelcomeScreen(multiUser: Utils.currentUser!, isStart: true,);
    } else if (isAutoFeedEnabled) {
        return AutoFeedSyncScreen();
    } else if (users.length == 0 && skipped && !isAutoFeedEnabled) {
      return HomeScreen();
    } else {
      return AuthGate(isStart: true);
    }*/

  // 1. If user has NOT done initial setup → Show SetupScreen
  if (initialSetupDone) {
    return LanguageSetupScreen();
  }

  // 2. If user is logged in → Show UserFarmScreen
  if (loggedIn) {
    return FarmWelcomeScreen(multiUser: Utils.currentUser!, isStart: true);
  }

  // 3. If user is logged out AND initial setup is done → Show LoginScreen
  if (loggedOut) {
    return AuthGate(isStart: true);
  }

  // 4. If initial setup is done, user is neither logged in nor logged out, BUT auto feed is enabled → Show AutoFeed
  if (isAutoFeedEnabled) {
    return AutoFeedSyncScreen();
  }

  // 5. Default → HomeScreen
  return HomeScreen();
}


void _configEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 1500)
    ..indicatorType = EasyLoadingIndicatorType.wave // Smooth animation
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 50.0
    ..radius = 12.0
    ..progressColor = Colors.white
    ..backgroundColor = const Color(0xFF222831) // Deep charcoal
    ..indicatorColor = const Color(0xFF00ADB5) // Neon teal
    ..textColor = Colors.white
    ..maskColor = Colors.black.withOpacity(0.4)
    ..userInteractions = false
    ..dismissOnTap = false;
}

void requestGDPR(){

  final params = ConsentRequestParameters();
  ConsentInformation.instance.requestConsentInfoUpdate(
    params,
        () async {
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        loadForm();
      }
    },
        (FormError error) {
      // Handle the error
    },
  );
}
void loadForm() {
  ConsentForm.loadConsentForm(
        (ConsentForm consentForm) async {
      var status = await ConsentInformation.instance.getConsentStatus();
      print('ConsentStatus:${status}');
      if (status == ConsentStatus.required) {
        consentForm.show(
              (FormError? formError) {
            // Handle dismissal by reloading form
            loadForm();
          },
        );
      }
    },
        (formError) {
      // Handle the error
    },
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: EasyLoading.init(),
      title: 'Easy Poultry Manager',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Utils.getThemeColorBlue(),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // darkTheme: ThemeData(
      //   fontFamily: 'Roboto',
      //   colorScheme: ColorScheme.fromSeed(
      //     seedColor: Utils.getThemeColorBlue(),
      //     brightness: Brightness.dark,
      //   ),
      //   useMaterial3: true,
      // ),
      themeMode: ThemeMode.system, //
      home: Directionality(
        textDirection: direction ? ui.TextDirection.ltr : ui.TextDirection.rtl,
        child: FutureBuilder<Widget>(
          future: getInitialScreen(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            } else if (snapshot.hasError) {
              return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
            } else {
              return snapshot.data!;
            }
          },
        ),
      ),
    );
  }
}


