import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:currency_picker/currency_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/bird_item.dart';
import 'model/egg_item.dart';
import 'model/farm_item.dart';
import 'model/flock.dart';
import 'model/flock_image.dart';

class FarmSetupScreen extends StatefulWidget {
  const FarmSetupScreen({Key? key}) : super(key: key);

  @override
  _FarmSetupScreen createState() => _FarmSetupScreen();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _FarmSetupScreen extends State<FarmSetupScreen>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;



  @override
  void dispose() {
    super.dispose();

  }

  String _purposeselectedValue = "";
  String _reductionReasonValue = "";


  int chosen_index = 0;

  @override
  void initState() {
    super.initState();

    getInfo();
    Utils.setupAds();

  }

  FarmSetup? farmSetup = null;
  void getInfo() async {

    await DatabaseHelper.instance.database;
    List<FarmSetup> list = await DatabaseHelper.getFarmInfo();
    farmSetup = list.elementAt(0);

    if(farmSetup!.image.toLowerCase().contains("asset")){
      modified = 0;
    }else{
      modified = 1;
    }
    locationController.text = farmSetup!.location;
    nameController.text = farmSetup!.name;
    date = farmSetup!.date;

    selectedCurrency = farmSetup!.currency;

    if(date.toLowerCase().contains("date")){
      var now = DateTime.now();
      var formatter = DateFormat('yyyy-MM-dd');
      date = formatter.format(now);
      print("Select Date");
    }

    setState(() {

    });

  }

  int modified = 0;

  String selectedCurrency = "\$";
  String date = "Choose date";
  final locationController = TextEditingController();
  final nameController = TextEditingController();


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
            child: SingleChildScrollViewWithStickyFirstWidget(
              child: Column(
                children: [
                  Utils.getDistanceBar(),
                  ClipRRect(
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0),bottomRight: Radius.circular(0)),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Utils.getThemeColorBlue()
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            alignment: Alignment.center,
                            width: 50,
                            height: 50,
                            child: InkWell(
                              child: Icon(Icons.arrow_back,
                                  color: Colors.white, size: 25),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          Container(
                              margin: EdgeInsets.only(left: 10),
                              child: Text(
                                 'FARM_SETUP'.tr(),
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              )),

                        ],
                      ),
                    ),
                  ),

                  Container(
                    margin: EdgeInsets.only(top: 80),
                    alignment: Alignment.center,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              selectImage();
                            },
                            child: Container(
                              margin: EdgeInsets.all(10),
                              child: Stack(
                                children: [
                                 Container(
                                   width: widthScreen,
                                   height: 160,
                                   child: modified==0? Image.asset('assets/farm_icon.png', fit: BoxFit.contain,)
                                       : Image.memory(Base64Decoder().convert(farmSetup!.image), fit: BoxFit.contain,),
                                 ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 30,width: widthScreen),
                          Container(
                            width: widthScreen,
                            height: 60,
                            margin: EdgeInsets.only(left: 16, right: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(70),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),
                              ),
                              child: SizedBox(
                                width: widthScreen,
                                height: 60,
                                child: TextFormField(
                                  expands: false,
                                  controller: nameController,
                                  textAlign: TextAlign.start,
                                  decoration:  InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(5))),
                                    hintText: 'Poultry Farm'.tr(),
                                    hintStyle: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                    labelStyle: TextStyle(
                                        color: Colors.black, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                         // SizedBox(height: 10,width: widthScreen),
                          Visibility(
                            visible: false,
                            child: Container(
                              width: widthScreen,
                              height: 60,
                              padding: EdgeInsets.all(0),
                              margin: EdgeInsets.only(left: 16, right: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(70),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),

                              ),
                              child: Container(
                                child: SizedBox(
                                  width: widthScreen,
                                  height: 60,
                                  child: TextFormField(

                                    controller: locationController,
                                    textAlign: TextAlign.start,
                                    decoration:  InputDecoration(
                                      border: OutlineInputBorder(
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(5))),
                                      hintText: 'LOCATION_HINT'.tr(),
                                      hintStyle: TextStyle(
                                          color: Colors.grey, fontSize: 16),
                                      labelStyle: TextStyle(
                                          color: Colors.black, fontSize: 16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10,width: widthScreen),
                          InkWell(
                            onTap: () {
                              chooseCurrency();
                            },
                            child: Container(
                              width: widthScreen,
                              height: 60,
                              padding: EdgeInsets.all(0),
                              margin: EdgeInsets.only(left: 16, right: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(70),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),

                              ),
                              child: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(5.0)),
                                  border: Border.all(
                                    color:  Colors.grey,
                                    width: 1.0,
                                  ),
                                ),
                                child: SizedBox(
                                  height: 60,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("CURRENCY".tr(), style: TextStyle(fontSize: 16,fontWeight: FontWeight.normal),),
                                      Text(selectedCurrency, style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),),

                                    ],
                                  )
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10,width: widthScreen),
                          Container(
                            width: widthScreen,
                            height: 60,
                            margin: EdgeInsets.only(left: 16, right: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(70),
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(5.0)),

                            ),
                            child: InkWell(
                              onTap: () {
                                pickDate();
                              },
                              child: Container(
                                alignment: Alignment.centerLeft,
                                padding: EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(5.0)),
                                  border: Border.all(
                                    color:  Colors.grey,
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(Utils.getFormattedDate(date), style: TextStyle(
                                    color: Colors.black, fontSize: 16),),
                              ),
                            ),
                          ),


                          SizedBox(height: 10,width: widthScreen),
                          InkWell(
                            onTap: () async {
                              bool validate = checkValidation();

                              if(validate){
                                print("Everything Okay");
                                await DatabaseHelper.instance.database;
                                if(!locationController.text.isEmpty){
                                  farmSetup!.location = locationController.text;
                                }
                                if(!nameController.text.isEmpty){
                                  farmSetup!.name = nameController.text;
                                }
                                farmSetup!.date = date;
                                farmSetup!.modified = 1;
                                DatabaseHelper.updateFarmSetup(farmSetup);

                                Utils.showToast('SUCCESSFUL'.tr());
                                Navigator.pop(context);

                              }else{
                                Utils.showToast("Provide all required info");
                              }
                            },
                            child: Container(

                              width: widthScreen,
                              height: 58,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:  Utils.getThemeColorBlue(),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),
                                border: Border.all(
                                  color:  Utils.getThemeColorBlue(),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 2,
                                    offset: Offset(0, 1), // changes position of shadow
                                  ),
                                ],
                              ),
                              margin: EdgeInsets.only( left: 16,right: 16,top: 15),
                              child: Text(
                                "SAVE".tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          )

                        ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

  bool checkValidation() {
    bool valid = true;

    if(date.toLowerCase().contains("date")){
      valid = false;
      print("Select Date");
    }

    if(nameController.text.length == 0){
      valid = false;
      print("No name");
    }



    return valid;

  }


  final ImagePicker imagePicker = ImagePicker();
  List<XFile>? imageFileList = [];

  void selectImage() async {
    final XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);
    cropImage(image);
  }

  void cropImage(XFile? imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile!.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Utils.getThemeColorBlue(),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
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

  Future<void> chooseCurrency() async {
    final allCurrencies = CurrencyService().getAll(); // Get built-in currencies
    final extraCurrencies = Utils.getMissingCurrency(); // Get missing currencies

    // Merge lists while ensuring no duplicate codes
    final Map<String, Currency> mergedMap = {
      for (var currency in allCurrencies) currency.code: currency, // Add existing currencies
      for (var currency in extraCurrencies) currency.code: currency, // Override with missing currencies
    };

    final List<Currency> mergedList = mergedMap.values.toList(); // Convert map back to list

    // 📌 Print all merged currencies
    print("✅ Merged Currency List:");
    for (var currency in mergedList) {
      print("${currency.code} - ${currency.name} (${currency.symbol})");
    }

    Currency? selected = await showCurrencyListDialog(context, mergedList);

    // Show dialog and wait for result
  //  Currency? selected = await showCurrencyListDialog(context, mergedList);

    if (selected != null) {
      print("Selected: ${selected.name} (${selected.code})");
      selectedCurrency = selected.symbol;
      DatabaseHelper.updateCurrency(selectedCurrency);
      Utils.currency = selectedCurrency;
      setState(() {}); // UI update happens after selection
      Utils.showToast("SUCCESSFUL".tr());
    }

   /* showCurrencyPicker(
      context: context,
      showFlag: true,
      showCurrencyName: true,
      showCurrencyCode: true,
      onSelect: (Currency currency) {
        print("Selected: ${currency.name} (${currency.code})");
        selectedCurrency = currency.symbol;
        DatabaseHelper.updateCurrency(selectedCurrency);
        Utils.currency = selectedCurrency;
        setState(() {});
        Utils.showToast("SUCCESSFUL".tr());
      },
      currencyFilter: mergedList.map((c) => c.code).toList(), // Ensure IRR & others are included
    );*/
  }



}




class CustomCurrencyService extends CurrencyService {
  @override
  List<Currency> getAll() {
    final allCurrencies = super.getAll();

    // Ensure IRR is not duplicated
    if (!allCurrencies.any((c) => c.code == "IRR")) {
      allCurrencies.add(Currency(
        code: "IRR",
        name: "Iranian Rial",
        symbol: "﷼",
        flag: "IR",  // Ensure this matches the internal flag system
        decimalDigits: 0,
        number: 364,
        namePlural: "Iranian Rials",
        thousandsSeparator: ",",
        decimalSeparator: ".",
        spaceBetweenAmountAndSymbol: true,
        symbolOnLeft: false,
      ));
    }

    return allCurrencies;
  }
}


Future<Currency?> showCurrencyListDialog(BuildContext context, List<Currency> currencies) async {
  return await showDialog<Currency>(
    context: context,
    builder: (BuildContext context) {
      return _CurrencyPickerDialog(currencies: currencies);
    },
  );
}

class _CurrencyPickerDialog extends StatefulWidget {
  final List<Currency> currencies;
  const _CurrencyPickerDialog({Key? key, required this.currencies}) : super(key: key);

  @override
  State<_CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<_CurrencyPickerDialog> {
  late TextEditingController _searchController;
  late List<Currency> _filteredCurrencies;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredCurrencies = widget.currencies;
  }

  void _filterCurrencies(String query) {
    setState(() {
      _filteredCurrencies = widget.currencies
          .where((currency) =>
      currency.name.toLowerCase().contains(query.toLowerCase()) ||
          currency.code.toLowerCase().contains(query.toLowerCase()) ||
          currency.symbol.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        children: [
          const Text("Select Currency"),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search currency...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: _filterCurrencies,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: _filteredCurrencies.length,
          itemBuilder: (context, index) {
            final currency = _filteredCurrencies[index];
            return ListTile(
              leading: CircleAvatar(child: Text(currency.code.substring(0, 2))),
              title: Text("${currency.name} (${currency.code})"),
              subtitle: Text(currency.symbol),
              onTap: () => Navigator.pop(context, currency),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Close"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

