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
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Utils.getAdBar(),

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
                    margin: EdgeInsets.only(top: 30),
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
                                   child: modified==0? Image.asset('assets/farm.jpg', fit: BoxFit.contain,)
                                       : Image.memory(Base64Decoder().convert(farmSetup!.image), fit: BoxFit.contain,),
                                 ),
                                 Align(
                                     alignment: Alignment.bottomRight,
                                     child: Icon(Icons.edit, color:  Utils.getThemeColorBlue(),
                                         )),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 10,width: widthScreen),
                          Container(
                            width: widthScreen,
                            height: 60,
                            padding: EdgeInsets.all(0),
                            margin: EdgeInsets.only(left: 16, right: 16),
                            decoration: BoxDecoration(
                                color: Colors.white60,
                                borderRadius:
                                BorderRadius.all(Radius.circular(5))),
                            child: Container(

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
                                    hintText: 'FARM_NAME'.tr(),
                                    hintStyle: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                    labelStyle: TextStyle(
                                        color: Colors.black, fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 10,width: widthScreen),
                          Container(
                            width: widthScreen,
                            height: 60,
                            padding: EdgeInsets.all(0),
                            margin: EdgeInsets.only(left: 16, right: 16),
                            decoration: BoxDecoration(
                                color: Colors.white60,
                                borderRadius:
                                BorderRadius.all(Radius.circular(5))),
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
                                  color: Colors.white60,
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(5))),
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
                                      Text(selectedCurrency, style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),),

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
                                color: Colors.white60,
                                borderRadius:
                                BorderRadius.all(Radius.circular(5))),
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
                                    color:  Colors.black,
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
                              ),
                              margin: EdgeInsets.only( left: 16,right: 16,top: 4),
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
    final XFile? image = await
    imagePicker.pickImage(source: ImageSource.gallery);
    final bytes = File(image!.path).readAsBytesSync();
    String base64Image =  base64Encode(bytes);
    farmSetup!.image = base64Image;
    modified = 1;
    setState((){});
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
