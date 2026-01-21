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
    return SafeArea(
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Container(
            width: widthScreen,
            height: heightScreen,
            color: Utils.getScreenBackground(),
            child: Column(children: [
              Utils.showBannerAd(_bannerAd, _isBannerAdReady),
              Expanded(child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 30,),
                    EasyStepper(
                      activeStep: activeStep,
                      activeStepTextColor: Colors.black87,
                      finishedStepTextColor: Colors.black87,
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
                          title: 'Language',
                        ),
                        EasyStep(
                          customStep: CircleAvatar(
                            radius: 15,
                            backgroundColor: activeStep >= 1 ? Utils.getThemeColorBlue() : Colors.grey.shade300,
                            child: Icon(Icons.business, size: 26, color: Colors.white),
                          ),
                          title: 'Farm Info',
                        ),
                        EasyStep(
                          customStep: CircleAvatar(
                            radius: 15,
                            backgroundColor: activeStep >= 2 ? Utils.getThemeColorBlue() : Colors.grey.shade300,
                            child: Icon(Icons.image, size: 26, color: Colors.white),
                          ),
                          title: 'Farm Image',
                        ),
                      ],

                      onStepReached: (index) =>
                          setState(() => activeStep = index),
                    ),
                    activeStep==0? Image.asset(activeStep==0?"assets/language_icon.png":activeStep==1?"assets/bird_icon.png":"assets/photo_icon.png", width: 120, height: 120, color: Utils.getThemeColorBlue()): activeStep >= 1? Image.asset(activeStep==1?"assets/bird_icon.png":"assets/photo_icon.png", width: 150, height: 150, color: Utils.getThemeColorBlue()): SizedBox(width: 1,),
                    Text(activeStep==0?"Language and Currency".tr():activeStep==1?"FARM_NAME".tr()+" and "+"DATE".tr():"FARM_IMAGE".tr(), style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),),
                    Visibility(
                      visible: activeStep == 0,
                      child: Center(
                        child: Container(
                          height: heightScreen,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              const SizedBox(height: 16),

                              // Select Language
                              Text("Select Language".tr(),
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                height: 60,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
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
                                    : Center(child: CircularProgressIndicator()),
                              ),

                              const SizedBox(height: 24),

                              // Currency & Unit in Equal Space
                              Row(
                                children: [
                                  // Currency
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Select Currency".tr(),
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: chooseCurrency,
                                          child: Container(
                                            height: 60,
                                            width: double.infinity, // 👈 ensures full width
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey.shade300),
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2))
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.attach_money,
                                                    color: Utils.getThemeColorBlue(), size: 22),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    selectedCurrency,
                                                    style: TextStyle(
                                                      fontSize: 18,
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

                                  const SizedBox(width: 16), // spacing between boxes

                                  // Unit
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Select Unit".tr(),
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          height: 60,
                                          width: double.infinity, // 👈 ensures full width
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade300),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2))
                                            ],
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: selectedUnit,
                                              isExpanded: true, // 👈 make dropdown fill
                                              icon: Icon(Icons.keyboard_arrow_down_rounded,
                                                  color: Colors.grey),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  selectedUnit = newValue!;
                                                });
                                              },
                                              items: ['KG', 'lbs'].map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value.tr(), style: TextStyle(fontSize: 16)),
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

                              SizedBox(height: 30,),

                              // Next button
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 5),
                                height: 60,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Utils.getThemeColorBlue(), Colors.blue], // blue gradients
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent, // removes default shadow
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => setState(() => activeStep++),
                                  child:  Text(
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
                              SizedBox(height: 10,),
                              Visibility(
                                visible: true,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "Looking for a Farm Account? ",
                                        style: TextStyle(fontSize: 12, color: Colors.black87),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          // Navigate to Join/Register Farm Screen
                                          Utils.setupCompleted();
                                          await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthGate(isStart: true)));

                                        },
                                        child: Text(
                                          " " + "Join here",
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
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: activeStep == 1,
                      child: Container(
                        height: heightScreen,
                        margin: const EdgeInsets.only(top: 30),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              "Farm Name".tr(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Farm name input with shadow
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  )
                                ],
                              ),
                              child: TextField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  hintText: 'Farm Name'.tr(),
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                                  prefixIcon: Icon(Icons.home_outlined, color: Utils.getThemeColorBlue()),
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            // Starting Date
                            Text(
                              "Starting Date".tr(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 6),

                            InkWell(
                              onTap: pickDate,
                              child: Container(
                                height: 60,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        color: Utils.getThemeColorBlue(), size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        Utils.getFormattedDate(date),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Next button
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              height: 60,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Utils.getThemeColorBlue(), Colors.blue], // blue gradients
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent, // removes default shadow
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => setState(() => activeStep++),
                                child: const Text(
                                  "Next",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10,),
                            Visibility(
                              visible: true,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Looking for a Farm Account?".tr(),
                                      style: TextStyle(fontSize: 12, color: Colors.black87),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        // Navigate to Join/Register Farm Screen
                                        Utils.setupCompleted();
                                        await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthGate(isStart: true)));

                                      },
                                      child: Text(
                                        " "+"Join here".tr(),
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
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Visibility(
                        visible: activeStep == 2? true:false,
                        child: Container(
                          height: heightScreen,
                          margin: EdgeInsets.only(top: 20),
                          padding: EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [

                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: InkWell(
                                  onTap: selectImage,
                                  child: Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Utils.getThemeColorBlue().withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Utils.getThemeColorBlue(), width: 2),
                                    ),
                                    child: Center(
                                      child: modified == 0
                                          ? Icon(Icons.image, size: 60, color: Utils.getThemeColorBlue())
                                          : Image.memory(Base64Decoder().convert(farmSetup!.image), fit: BoxFit.contain),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 30),

                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 5),
                                height: 60,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Utils.getThemeColorBlue(), Colors.lightGreen], // blue gradients
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent, // removes default shadow
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                                    Utils.showToast('SUCCESSFUL'.tr());


                                    await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));

                                  },
                                  child:  Text(
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
                              SizedBox(height: 10,),
                              Visibility(
                                visible: true,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Looking for a Farm Account?".tr(),
                                        style: TextStyle(fontSize: 12, color: Colors.black87),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          Utils.setupCompleted();
                                          await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthGate(isStart: true)));

                                        },
                                        child: Text(
                                          " "+"Join here".tr(),
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
                                ),
                              ),
                            ],
                          )
                          ,)),
                  ],
                ),
              ),)
            ],)
          ),
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
