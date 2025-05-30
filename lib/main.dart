import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:poultary/utils/utils.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import 'app_setup/language_setup_screen.dart';
import 'auto_add_feed_screen.dart';
import 'model/blog.dart';

bool direction = true;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(EasyLocalization(
          supportedLocales: [Locale('en'), Locale('ar'),Locale('de'),Locale('ru'),Locale('fa'),Locale('it'),Locale('ja'),Locale('ko'),Locale('pt'),Locale('tr'),Locale('fr'),Locale('id'),Locale('hi'),Locale('es'),Locale('zh'),Locale('uk'),Locale('pl'),Locale('bn'),Locale('te'),Locale('ta'),Locale('el')],
          path: 'assets/translations', // <-- change the path of the translation files
          fallbackLocale: Locale('en'),
      child: MyApp()),);
  launch = await Utils.checkAppLaunch();
  requestGDPR();

  direction = await Utils.getDirection();
  await MobileAds.instance.initialize();
  Utils.direction = await Utils.getDirection();
  // MobileAds.instance.updateRequestConfiguration(
  //     RequestConfiguration(testDeviceIds: ['C0B856BD630A2928BC9F472E0A5C870A','C1F82EF953946E2EACA6F014AFF27318']));
  await Hive.initFlutter();
  Hive.registerAdapter(BlogAdapter());

}

 bool launch = true;
 void checkFirstAppLaunch() async{
   launch = await Utils.checkAppLaunch();
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return

      MaterialApp(
      title: 'Easy Poultry Manager',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Utils.getThemeColorBlue()),
        useMaterial3: true,
      ),

      home: Directionality(
          textDirection: direction? ui.TextDirection.ltr: ui.TextDirection.ltr,
          child: launch? LanguageSetupScreen() : AutoFeedSyncScreen()),
    );
  }
}


