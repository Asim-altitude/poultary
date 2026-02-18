import 'dart:convert';
import 'dart:io';

import 'package:currency_picker/currency_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:language_picker/language_picker_dropdown.dart';
import 'package:language_picker/languages.dart';
import 'package:poultary/add_flocks.dart';
import 'package:poultary/home_screen.dart';
import 'package:poultary/multiuser/classes/AuthGate.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/utils.dart';

import '../database/databse_helper.dart';
import '../model/farm_item.dart';
import '../utils/session_manager.dart';


class LanguageSetupScreen extends StatefulWidget {
  const LanguageSetupScreen({Key? key}) : super(key: key);

  @override
  _LanguageSetupScreen createState() => _LanguageSetupScreen();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _LanguageSetupScreen extends State<LanguageSetupScreen>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  final supportedLanguages = [
    Languages.english,
    Languages.arabic,
    Languages.russian,
    Languages.persian,
    Languages.german,
    Languages.japanese,
    Languages.korean,
    Languages.portuguese,
    Languages.turkish,
    Languages.french,
    Languages.indonesian,
    Languages.hindi,
    Languages.spanish,
    Languages.chineseSimplified,
    Languages.ukrainian,
    Languages.polish,
    Languages.bengali,
    Languages.telugu,
    Languages.tamil,
    Languages.greek

  ];
  String selectedUnit = 'KG';
  String selectedCurrency = "\$";
  late Language _selectedCupertinoLanguage;
  bool isGetLanguage = false;
  getLanguage() async {
    _selectedCupertinoLanguage = await Utils.getSelectedLanguage();

    setState(() {
      isGetLanguage = true;

    });

  }

  getDate() async{
   DateTime dateTime = DateTime.now();

    date = DateFormat('yyyy-MM-dd').format(dateTime);

    setState(() {

    });

  }


  Widget _buildDropdownItem(Language language) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 8.0,
        ),
        if(language.isoCode !="pt" && language.isoCode !="zh_Hans")
          Text("${language.name} (${language.isoCode})",
            style: new TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'PTSans'),
          ),
        if(language.isoCode =="pt")
          Text("${'Portuguese'} (${language.isoCode})",
            style: new TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'PTSans'),
          ),
        if(language.isoCode =="zh_Hans")
          Text("${'Chinese'} (zh)",
            style: new TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'PTSans'),
          ),
      ],
    );
  }

  @override
  void dispose() {
    try{
      _bannerAd.dispose();
    }catch(ex){

    }
    super.dispose();
  }

  String date = "Choose date";
  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = 'Poultry Farm'.tr();
    getDate();
    getLanguage();
    getInfo();

    if(Utils.isShowAdd){
      _loadBannerAd();
    }

  }
  _loadBannerAd(){
    // TODO: Initialize _bannerAd
    _bannerAd = BannerAd(
      adUnitId: Utils.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }
  int activeStep = 0;
  int activeStep2 = 0;
  int reachedStep = 0;
  int upperBound = 5;
  double progress = 0.2;
  Set<int> reachedSteps = <int>{0, 2, 4, 5};
 /* final dashImages = [
    'assets/1.png',
    'assets/2.png',
    'assets/3.png',
    'assets/4.png',
    'assets/5.png',
  ];*/

  void increaseProgress() {
    if (progress < 1) {
      setState(() => progress += 0.2);
    } else {
      setState(() => progress = 0);
    }
  }
  bool _isPreparing = false;


  Widget _buildStepper() {
    return  Container(
      color: Utils.getThemeColorBlue(),
      child: EasyStepper(
        activeStep: activeStep,
        activeStepTextColor: Colors.white,
        finishedStepTextColor: Colors.white54,
        internalPadding: 30,
        showLoadingAnimation: false,
        stepRadius: 18,
        showStepBorder: false,
        steps: [
          EasyStep(
            customStep: CircleAvatar(
              radius: 15, // Increase size
              backgroundColor: activeStep >= 0 ? Utils.getThemeColorBlue() : Colors.grey.shade300,
              child: Icon(Icons.language, size: 26, color: Colors.white),
            ),
            title: 'LANGUAGE'.tr(),
          ),
          EasyStep(
            customStep: CircleAvatar(
              radius: 15,
              backgroundColor: activeStep >= 1 ? Utils.getThemeColorBlue() : Colors.grey.shade300,
              child: Icon(Icons.business, size: 26, color: Colors.white),
            ),
            title: 'Farm Name'.tr(),
          ),
          EasyStep(
            customStep: CircleAvatar(
              radius: 15,
              backgroundColor: activeStep >= 2 ? Utils.getThemeColorBlue() : Colors.grey.shade300,
              child: Icon(Icons.image, size: 26, color: Colors.white),
            ),
            title: 'Farm Logo'.tr(),
          ),
          EasyStep(
            customStep: CircleAvatar(
              radius: 15,
              backgroundColor: activeStep >= 3
                  ? Utils.getThemeColorBlue()
                  : Colors.grey.shade300,
              child: Icon(Icons.group_work, size: 26, color: Colors.white),
            ),
            title: 'Flock'.tr(),
          ),

        ],

        onStepReached: (index) =>
            setState(() => activeStep = index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double safeAreaHeight = MediaQuery.of(context).padding.top;
    double safeAreaHeightBottom = MediaQuery.of(context).padding.bottom;
    widthScreen =
        MediaQuery.of(context).size.width; // because of default padding
    heightScreen = MediaQuery.of(context).size.height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery.of(context).size.height -
        (safeAreaHeight + safeAreaHeightBottom);
    child:
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: AppBar(
          backgroundColor: Utils.getThemeColorBlue(),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Utils.getThemeColorBlue()),
            onPressed: () {
              if (activeStep > 0) {
                setState(() => activeStep--);
              } else {
                Navigator.pop(context);
              }
            },
          ),

          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(30),
            child: _buildStepper(),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Container(
          width: widthScreen,
          height: heightScreen,
          color: Utils.getScreenBackground(),
          child: Column(children: [
            /* if(_isBannerAdReady)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                    height: 60.0,
                    width: Utils.WIDTH_SCREEN,
                    child: AdWidget(ad: _bannerAd)
                ),
              ),*/
            Expanded(child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Utils.getThemeColorBlue().withOpacity(0.06),
                      Colors.white,
                    ],
                  ),
                ),
                child: Column(
                  children: [

                   SizedBox(height: 20,),
                   /* activeStep==0? Image.asset(activeStep==0?"assets/language_icon.png":activeStep==1?"assets/farm_logo.png": "assets/farm_icon.png", width: 120, height: 120, color: Utils.getThemeColorBlue()): activeStep >= 1? Image.asset(activeStep==1?"assets/farm_logo.png": activeStep==2?"assets/photo_icon.png":"assets/farm_icon.png", width: 150, height: 150, color: Utils.getThemeColorBlue()): SizedBox(width: 1,),
                  *///  Text(activeStep==0?"Language and Currency".tr():activeStep==1?"FARM_NAME".tr()+" and "+"DATE".tr():activeStep==2?"FARM_IMAGE".tr() : "", style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),),
                    Visibility(
                      visible: activeStep == 0,
                      child: Container(
                        height: heightScreen,
                        width: double.infinity,

                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [


                            // Hero icon with glow
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Utils.getThemeColorBlue().withOpacity(0.25),
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  "assets/language_icon.png",
                                  width: 75,
                                  height: 75,
                                  color: Utils.getThemeColorBlue(),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Center(
                              child: Text(
                                "Language and Currency".tr(),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Utils.getThemeColorBlue(),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),

                            const SizedBox(height: 4),

                            Center(
                              child: Text(
                                "Choose your preferred language, currency and unit to personalize your experience."
                                    .tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  height: 1.6,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Select Language
                            Text(
                              "Select Language".tr(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 6),

                            Container(
                              height: 60,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Utils.getThemeColorBlue().withOpacity(0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: isGetLanguage
                                  ? LanguagePickerDropdown(
                                initialValue: _selectedCupertinoLanguage,
                                itemBuilder: _buildDropdownItem,
                                languages: supportedLanguages,
                                onValuePicked: (Language language) {
                                  _selectedCupertinoLanguage = language;
                                  Utils.setSelectedLanguage(
                                      _selectedCupertinoLanguage, context);
                                },
                              )
                                  : const Center(child: CircularProgressIndicator()),
                            ),

                            const SizedBox(height: 15),

                            // Currency & Unit
                            Row(
                              children: [
                                // Currency
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Select Currency".tr(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: chooseCurrency,
                                        child: Container(
                                          height: 60,
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color:
                                              Utils.getThemeColorBlue().withOpacity(0.3),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 8,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.attach_money_rounded,
                                                color: Utils.getThemeColorBlue(),
                                                size: 22,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  selectedCurrency,
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.bold,
                                                    color: Utils.getThemeColorBlue(),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Unit
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Select Unit".tr(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 60,
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color:
                                            Utils.getThemeColorBlue().withOpacity(0.3),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: selectedUnit,
                                            isExpanded: true,
                                            icon: Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: Colors.grey.shade600,
                                            ),
                                            onChanged: (String? newValue) {
                                              setState(() => selectedUnit = newValue!);
                                            },
                                            items: ['KG', 'lbs'].map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(
                                                  value.tr(),
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 25),

                            // Next button
                            Container(
                              height: 60,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: LinearGradient(
                                  colors: [
                                    Utils.getThemeColorBlue(),
                                    Colors.blueAccent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    Utils.getThemeColorBlue().withOpacity(0.45),
                                    blurRadius: 14,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () => setState(() => activeStep++),
                                child: Text(
                                  "Next".tr(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Join farm
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Looking for a Farm Account?".tr(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    Utils.setupCompleted();
                                    await Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => AuthGate(isStart: true)),
                                    );
                                  },
                                  child: Text(
                                    "  " + "Join here".tr(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Utils.getThemeColorBlue(),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Visibility(
                      visible: activeStep == 1,
                      child: Container(
                        height: heightScreen,

                        padding: const EdgeInsets.symmetric(horizontal: 20,),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🌾 Header
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Utils.getThemeColorBlue().withOpacity(0.25),
                                          blurRadius: 18,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      "assets/farm_logo.png",
                                      width: 75,
                                      height: 75,
                                      color: Utils.getThemeColorBlue(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "${"FARM_NAME".tr()} & ${"DATE".tr()}",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Utils.getThemeColorBlue(),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Choose Farm Name and Starting date to personalize your experience.".tr(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 🏠 Farm Name
                            Text(
                              "Farm Name".tr(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),

                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: nameController,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: "Enter your farm name".tr(),
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  border: InputBorder.none,
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  prefixIcon: Icon(
                                    Icons.agriculture_outlined,
                                    color: Utils.getThemeColorBlue(),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            // 📅 Starting Date
                            Text(
                              "Starting Date".tr(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),

                            InkWell(
                              onTap: pickDate,
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                height: 60,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month_outlined,
                                      color: Utils.getThemeColorBlue(),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        Utils.getFormattedDate(date),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    Icon(Icons.keyboard_arrow_down_rounded,
                                        color: Colors.grey.shade500),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // 🚀 Next Button
                            Container(
                              height: 58,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Utils.getThemeColorBlue(),
                                    Colors.blueAccent,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () => setState(() => activeStep++),
                                child: Text(
                                  "Next".tr(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 🔗 Join Farm
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Looking for a Farm Account?".tr(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    Utils.setupCompleted();
                                    await Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AuthGate(isStart: true),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "  ${"Join here".tr()}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Utils.getThemeColorBlue(),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    Visibility(
                      visible: activeStep == 2,
                      child: Container(
                        height: heightScreen,
                        width: double.infinity,

                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            // Hero icon with glow
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Utils.getThemeColorBlue().withOpacity(0.25),
                                    blurRadius: 18,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                "assets/photo_icon.png",
                                width: 75,
                                height: 75,
                                color: Utils.getThemeColorBlue(),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Text(
                              "FARM_IMAGE".tr(),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Utils.getThemeColorBlue(),
                                letterSpacing: 0.4,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Add a photo of your farm. This helps personalize your account and makes it easier to recognize."
                                  .tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.6,
                              ),
                            ),

                            const SizedBox(height: 15),

                            // Upload Card
                            InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: selectImage,
                              child: Container(
                                height: 170,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Utils.getThemeColorBlue().withOpacity(0.4),
                                    width: 1.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: modified == 0
                                      ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 48,
                                        color: Utils.getThemeColorBlue(),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Tap to upload image".tr(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Utils.getThemeColorBlue(),
                                        ),
                                      ),
                                    ],
                                  )
                                      : ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.memory(
                                      Base64Decoder().convert(farmSetup!.image),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 36),

                            // DONE button
                            Container(
                              height: 60,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: LinearGradient(
                                  colors: [
                                    Utils.getThemeColorBlue(),
                                    Colors.lightGreen,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Utils.getThemeColorBlue().withOpacity(0.4),
                                    blurRadius: 14,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () async {
                                  await DatabaseHelper.instance.database;

                                  if (nameController.text.isNotEmpty) {
                                    farmSetup!.name = nameController.text;
                                  }

                                  SessionManager.setUnit(selectedUnit);
                                  farmSetup!.date = date;
                                  farmSetup!.modified = 1;
                                  DatabaseHelper.updateFarmSetup(farmSetup);

                                  Utils.setupCompleted();
                                  setState(() => activeStep = 3);
                                },
                                child: Text(
                                  "DONE".tr(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Join farm
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Looking for a Farm Account?".tr(),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    Utils.setupCompleted();
                                    await Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => AuthGate(isStart: true)),
                                    );
                                  },
                                  child: Text(
                                    "  " + "Join here".tr(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Utils.getThemeColorBlue(),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    Visibility(
                      visible: activeStep == 3,
                      child: Container(
                        height: heightScreen,
                        width: double.infinity,

                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            // Logo with soft glow
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Utils.getThemeColorBlue().withOpacity(0.25),
                                    blurRadius: 18,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                "assets/poultry_display_logo.png",
                                width: 90,
                                height: 90,
                              ),
                            ),

                            const SizedBox(height: 20),

                            Text(
                              "Add Your First Flock".tr(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Utils.getThemeColorBlue(),
                                letterSpacing: 0.4,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "Track birds, eggs, feed and performance from day one.\\nYou can skip this step and add flocks later anytime."
                                  .tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: Colors.grey.shade700,
                                height: 1.6,
                              ),
                            ),

                            const SizedBox(height: 36),

                            // Modern Glass Card CTA
                            InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: _isPreparing
                                  ? null
                                  : () async {
                                setState(() => _isPreparing = true);

                                await DatabaseHelper.instance.database;
                                await Utils.generateDatabaseTables();

                                try {
                                  List<String> tables = Utils.getTAllables();
                                  for (final table in tables) {
                                    await DatabaseHelper.instance.addSyncColumnsToTable(table);
                                    await DatabaseHelper.instance.assignSyncIds(table);
                                  }
                                  await SessionManager.setBoolValue(
                                      SessionManager.table_created, true);
                                } catch (ex) {
                                  debugPrint(ex.toString());
                                }

                                if (!mounted) return;

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ADDFlockScreen(isStart: true),
                                  ),
                                );
                              },

                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  gradient: LinearGradient(
                                    colors: [
                                      Utils.getThemeColorBlue(),
                                      Utils.getThemeColorBlue().withOpacity(0.85),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Utils.getThemeColorBlue().withOpacity(0.45),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // ICON / LOADER
                                    Container(
                                      height: 52,
                                      width: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.18),
                                      ),
                                      child: _isPreparing
                                          ? const Padding(
                                        padding: EdgeInsets.all(14),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                          : const Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),

                                    const SizedBox(width: 18),

                                    // TEXT
                                    Expanded(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 250),
                                        child: _isPreparing
                                            ? Column(
                                          key: const ValueKey("loading"),
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Getting Ready…".tr(),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Please wait while we prepare things."
                                                  .tr(),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white.withOpacity(0.85),
                                              ),
                                            ),
                                          ],
                                        )
                                            : Column(
                                          key: const ValueKey("normal"),
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Add New Flock".tr(),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Layers, Broilers, Breeders, Ducks…".tr(),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white.withOpacity(0.85),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // ARROW (hide during loading)
                                    AnimatedOpacity(
                                      opacity: _isPreparing ? 0 : 1,
                                      duration: const Duration(milliseconds: 200),
                                      child: const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Secondary Action (Skip)
                            GestureDetector(
                              onTap: () async {
                                await Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => HomeScreen()),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.watch_later_outlined,
                                      size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Skip for now".tr(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),


                  ],
                ),
              ),
            ),)
          ],)
        ),
      ),
    );
  }

  FarmSetup? farmSetup = null;
  int modified = 0;
  void getInfo() async {
    print('OKOKOK');

    await DatabaseHelper.instance.database;
    List<FarmSetup> list = await DatabaseHelper.getFarmInfo();
    print('OKOKOK1');

    farmSetup = list.elementAt(0);
    print(list.length);

    if(farmSetup!.image.toLowerCase().contains("asset")){
      modified = 0;
    }else{
      modified = 1;
    }
    setState(() {

    });

  }

  final ImagePicker imagePicker = ImagePicker();
  List<XFile>? imageFileList = [];

  void selectImage() async {
    final XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);
    cropImage(image);
  }

  void cropImage(XFile? imageFile) async {
    CroppedFile? croppedFile = await ImageCropper()
        .cropImage(
      sourcePath: imageFile!.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Cropper',
        ),

      ],
    );

    final bytes = File(croppedFile!.path).readAsBytesSync();
    String base64Image =  base64Encode(bytes);

    farmSetup!.image = base64Image;
    modified = 1;
    setState((){});
  }

  void pickDate() async{

    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1950),
        //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime.now());

    if (pickedDate != null) {
      print(
          pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
      String formattedDate =
      DateFormat('yyyy-MM-dd').format(pickedDate);
      print(
          formattedDate); //formatted date output using intl package =>  2021-03-16
      setState(() {
        date =
            formattedDate; //set output date to TextField value.
      });
    } else {}
  }

  void chooseCurrency() {
    showCurrencyPicker(
      context: context,
      showFlag: true,
      showCurrencyName: true,
      showCurrencyCode: true,
      onSelect: (Currency currency) {
        selectedCurrency = currency.symbol;
        DatabaseHelper.updateCurrency(selectedCurrency);
        Utils.currency = selectedCurrency;
        setState(() {

        });
        Utils.showToast("SUCCESSFUL".tr());
      },
    );
  }

}

class _InputCard extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;

  const _InputCard({
    required this.icon,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          prefixIcon: Icon(icon, color: Utils.getThemeColorBlue()),
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String date;
  final VoidCallback onTap;

  const _DateCard({
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                color: Utils.getThemeColorBlue()),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                Utils.getFormattedDate(date),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
