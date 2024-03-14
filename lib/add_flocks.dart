import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/bird_item.dart';
import 'model/flock.dart';
import 'model/flock_image.dart';

class ADDFlockScreen extends StatefulWidget {
  const ADDFlockScreen({Key? key}) : super(key: key);

  @override
  _ADDFlockScreen createState() => _ADDFlockScreen();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _ADDFlockScreen extends State<ADDFlockScreen>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();
  }

  String _purposeselectedValue = "";
  String _acqusitionselectedValue = "";

  List<String> _purposeList = [
    '--Select Purpose--',
    'Egg',
    'Meat',
    'Egg and Meat',
    'Other',
  ];

  List<String> acqusitionList = [
    '--Acqusition Type--',
    'Purchased',
    'Hatched on Farm',
    'Gift',
    'Other',
  ];

  List<Bird> birds = [];

  int chosen_index = 0;

  @override
  void initState() {
    super.initState();

    _purposeselectedValue = _purposeList[0];
    _acqusitionselectedValue = acqusitionList[0];

    getBirds();
    Utils.showInterstitial();
    Utils.setupAds();

  }

  void getBirds() async{
    await DatabaseHelper.instance.database;
    birds = await DatabaseHelper.getBirds();
    for (int i = 0; i< birds.length;i++){
      print(birds.elementAt(i).name);
      print(birds.elementAt(i).image);
      print(birds.elementAt(i).id);
    }

    birds.add(Bird(id: 100, image: "assets/other.jpg", name: 'Other'));

    setState(() {

    });

  }

  Flock? currentFlock = null;

  bool _validate = false;

  String date = "Choose Date";
  final nameController = TextEditingController();
  final birdcountController = TextEditingController();
  final notesController = TextEditingController();

  bool imagesAdded = false;


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
                            color: Utils.getThemeColorBlue(), //(x,y)
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
                                  color: Colors.white, size: 30),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          Container(
                              margin: EdgeInsets.only(left: 10),
                              child: Text(
                                "New Flock",
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
                      margin: EdgeInsets.only(left: 10,top: 16,bottom: 8),
                      child: Text(
                        "Select Birds Type",
                        textAlign: TextAlign.start,
                        style: TextStyle(
                            color: Utils.getThemeColorBlue(),
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      )),
                  Container(
                    height: 186,
                    width: widthScreen,
                    margin: EdgeInsets.only(left: 15),
                    child: ListView.builder(
                        itemCount: birds.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (BuildContext context, int index) {
                          return  index == chosen_index? InkWell(
                            onTap: () {
                              chosen_index = index;
                              setState(() {

                              });
                            },
                            child: Container(
                              margin: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(10.0)),
                                border: Border.all(
                                  color:  Utils.getThemeColorBlue(),
                                  width: 3.0,
                                ),
                              ),
                              child: Column( children: [
                               Container(


                                margin: EdgeInsets.all(10),
                                height: 100, width: 100,
                                child: Image.asset(birds.elementAt(index).image, fit: BoxFit.contain,),
                              ),
                              Container(
                                width: 100,
                              height: 50,
                              child:Text(birds.elementAt(index).name, textAlign: TextAlign.center,style: TextStyle( fontSize: 16, color: Colors.black),),),
                              ]),
                            ),
                          ): InkWell(
                            onTap: (){
                              chosen_index = index;
                              setState(() {

                              });
                            },
                            child: Container(
                              margin: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(10.0)),
                                border: Border.all(
                                  color:  Colors.black,
                                  width: 1.0,
                                ),
                              ),
                              child: Column( children: [
                                Container(
                                    margin: EdgeInsets.all(10),
                                    height: 100, width: 100,
                                    child: Image.asset(birds.elementAt(index).image, fit: BoxFit.contain,),),

                                Container(
                                  width: 100,
                                  height: 50,
                                  child:Text(birds.elementAt(index).name, textAlign: TextAlign.center,style: TextStyle( fontSize: 16, color: Colors.black),),),                              ]),
                            ),
                          );

                        }),
                  ),
                  SizedBox(width: widthScreen, height: 20,),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: widthScreen,
                          height: 100,
                          padding: EdgeInsets.all(0),
                          margin: EdgeInsets.only(left: 20, right: 20),
                          decoration: BoxDecoration(
                              color: Colors.white60,
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            child: SizedBox(
                              width: widthScreen,
                              height: 100,
                              child: TextFormField(
                                maxLines: 1,
                                maxLength: 25,
                                controller: nameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                                  hintText: 'Flock/Batch Name',
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
                          height: 70,
                          padding: EdgeInsets.all(0),
                          margin: EdgeInsets.only(left: 20, right: 20),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            child: SizedBox(
                              width: widthScreen,
                              height: 60,
                              child: TextFormField(
                                maxLines: null,
                                expands: true,
                                controller: birdcountController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                                  hintText: 'Number of Birds',
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
                          height: 70,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.only(left: 20, right: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.all(
                                Radius.circular(10.0)),
                            border: Border.all(
                              color:  Colors.black,
                              width: 1.0,
                            ),
                          ),
                          child: getDropDownList(),
                        ),
                        SizedBox(height: 10,width: widthScreen),
                        Container(
                          width: widthScreen,
                          height: 70,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.only(left: 20, right: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.all(
                                Radius.circular(10.0)),
                            border: Border.all(
                              color:  Colors.black,
                              width: 1.0,
                            ),
                          ),
                          child: getAcqusitionDropDownList(),
                        ),


                        SizedBox(height: 10,width: widthScreen),
                        Container(
                          width: widthScreen,
                          height: 70,
                          margin: EdgeInsets.only(left: 20, right: 20),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: InkWell(
                            onTap: () {
                              pickDate();
                            },
                            child: Container(
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.only(left: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(10.0)),
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
                        Row(children: [
                          imagesAdded? Container(
                            height: 80,
                            width: widthScreen - 135,
                            margin: EdgeInsets.only(left: 15),
                            child: ListView.builder(
                                itemCount: imageFileList!.length,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (BuildContext context, int index) {
                                  return Container(
                                      margin: EdgeInsets.all(10),
                                      height: 80, width: 80,
                                      child: Image.file(File(imageFileList![index].path,), fit: BoxFit.cover,
                                      ));
                                }),
                          ) : Container( height: 80,
                              width: widthScreen - 135,margin: EdgeInsets.only(left: 15), alignment: Alignment.center, child: Text('No images added')),
                          InkWell(
                            onTap: () {
                              selectImages();
                            },
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 100,
                                height: 50,
                                margin: EdgeInsets.only(right: 15),
                                decoration: BoxDecoration(
                                    color: Utils.getThemeColorBlue(),
                                    borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                                child: Row( mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.add, color: Colors.white,),
                                  Text('Images', style: TextStyle(
                                      color: Colors.white, fontSize: 14),)
                                ],),
                              ),
                            ),
                          ),
                        ],),
                        SizedBox(height: 10,width: widthScreen),
                        Container(
                          width: widthScreen,
                          height: 120,
                          padding: EdgeInsets.all(5),
                          margin: EdgeInsets.only(left: 10, right: 10),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            child: SizedBox(
                              width: widthScreen,
                              height: 100,
                              child: TextFormField(
                                maxLines: 2,
                                controller: notesController,
                                keyboardType: TextInputType.multiline,
                                textAlign: TextAlign.start,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                                  hintText: 'Write short note',
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
                          onTap: () async {
                            bool validate = checkValidation();

                            if(validate){
                              print("Everything Okay");
                              await DatabaseHelper.instance.database;
                              int? id = await DatabaseHelper.insertFlock(Flock(f_id: 1, f_name: nameController.text, bird_count: int.parse(birdcountController.text)
                                , purpose: _purposeselectedValue, acqusition_type: _acqusitionselectedValue, acqusition_date: date, notes: notesController.text, icon: birds.elementAt(chosen_index).image, active_bird_count: int.parse(birdcountController.text), active: 1,
                              ));

                              if (base64Images.length > 0){
                                insertFlockImages(id);
                              }else{
                                Utils.showToast("New Flock Created");
                                Navigator.pop(context);
                              }

                            }else{
                              Utils.showToast("Provide all required info");
                            }
                          },
                          child: Container(
                            width: widthScreen,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Utils.getThemeColorBlue(),
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(6.0)),
                              border: Border.all(
                                color:  Utils.getThemeColorBlue(),
                                width: 2.0,
                              ),
                            ),
                            margin: EdgeInsets.all( 20),
                            child: Text(
                              "Confirm",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        )

                      ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getAcqusitionDropDownList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _acqusitionselectedValue,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _acqusitionselectedValue = newValue!;

          });
        },
        items: acqusitionList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  Widget getDropDownList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _purposeselectedValue,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _purposeselectedValue = newValue!;

          });
        },
        items: _purposeList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: new TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }



    final ImagePicker imagePicker = ImagePicker();
    List<XFile>? imageFileList = [];

    void selectImages() async {
      final List<XFile>? selectedImages = await
      imagePicker.pickMultiImage();
      if (selectedImages!.isNotEmpty) {
        imageFileList!.addAll(selectedImages);
      }
      print("Image List Length:" + imageFileList!.length.toString());

      saveImagesDB();

      imagesAdded = true;

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

  bool checkValidation() {
    bool valid = true;

    if(date.toLowerCase().contains("date")){
      valid = false;
      print("Select Date");
    }

    if(_acqusitionselectedValue.toLowerCase().contains("acqusition")){
      valid = false;
      print("Select Acqusition Type");
    }

    if(_purposeselectedValue.toLowerCase().contains("purpose")){
      valid = false;
      print("Select Purpose");
    }

    if(birdcountController.text.isEmpty){
      valid = false;
      print("Select Bird Count");
    }

    if(nameController.text.isEmpty){
      valid = false;
      print("Select Flock Name");
    }

    return valid;

  }

  List<String> base64Images = [];
  
  void saveImagesDB() async {

        base64Images.clear();

      for (int i=0;i<imageFileList!.length;i++) {
        final bytes = File(imageFileList!.elementAt(i).path).readAsBytesSync();
        String base64Image =  base64Encode(bytes);
        base64Images.add(base64Image);

        print("img_pan : $base64Image");
        
      }
  }

  void insertFlockImages(int? id) {

    if (base64Images.length > 0){

      for (int i=0;i<base64Images.length;i++){
        Flock_Image image = Flock_Image(f_id: id,image: base64Images.elementAt(i));
        DatabaseHelper.insertFlockImages(image);
      }

      print("Images Inserted");
      Utils.showToast("New Flock Created");
      Navigator.pop(context);
    }

  }



}
