import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/home_screen.dart';
import 'package:poultary/multiuser/classes/WorkerDashboard.dart';
import 'package:poultary/multiuser/model/user.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import 'app_setup/language_setup_screen.dart';
import 'auto_add_feed_screen.dart';
import 'model/blog.dart';
import 'multiuser/classes/AuthGate.dart';

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
  //     RequestConfiguration(testDeviceIds: ['C0B856BD630A2928BC9F472E0A5C870A','C1F82EF953946E2EACA6F014AFF27318']));
  await Hive.initFlutter();
  Hive.registerAdapter(BlogAdapter());

}

Future<Widget> getInitialScreen() async {
  await DatabaseHelper.instance.database;

  bool launch = await Utils.checkAppLaunch();
  bool skipped = await SessionManager.getBool(SessionManager.skipped);
  bool loggedIn = await SessionManager.getBool(SessionManager.loggedIn);
  bool isAdmin = await SessionManager.getBool(SessionManager.isAdmin);
  MultiUser? user = await SessionManager.getUserFromPrefs();
  List<MultiUser> users = await DatabaseHelper.getAllUsers();


    if(launch) {
      return LanguageSetupScreen();
    } else if (loggedIn && isAdmin) {
      return HomeScreen();
    } else if (loggedIn && !isAdmin && user != null) {
      return WorkerDashboardScreen(
          name: user.name, email: user.email, role: user.role);
    } else if (users.length == 0) {
        return HomeScreen();
    } else {
      return AuthGate(isStart: true);
    }
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
      title: 'Easy Poultry Manager',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Utils.getThemeColorBlue()),
        useMaterial3: true,
      ),
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


