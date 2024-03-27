import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poultary/inventory.dart';
import 'package:poultary/model/flock_image.dart';
import 'package:poultary/transactions_screen.dart';
import 'package:poultary/utils/utils.dart';

import 'add_flocks.dart';
import 'add_reduce_flock.dart';
import 'daily_feed.dart';
import 'database/databse_helper.dart';
import 'egg_collection.dart';
import 'medication_vaccination.dart';
import 'model/flock.dart';
import 'model/used_item.dart';

class SingleFlockScreen extends StatefulWidget {
  const SingleFlockScreen({Key? key}) : super(key: key);

  @override
  _SingleFlockScreen createState() => _SingleFlockScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _SingleFlockScreen extends State<SingleFlockScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();


  }

  List<Flock_Image> images = [];
  List<Uint8List> byteimages = [];
  List<BirdUsage> birdUsageList = [];
  void getImages() async {

   await DatabaseHelper.instance.database;

   images = await DatabaseHelper.getFlockImage(Utils.selected_flock!.f_id);

   print(images);

   for(int i=0;i<images.length;i++){
     Uint8List bytesImage = const Base64Decoder().convert(images.elementAt(i).image);
     byteimages.add(bytesImage);
     print(images.elementAt(i).image);
   }

   birdUsageList = await DatabaseHelper.getBirdUSage(Utils.selected_flock!.f_id);

   if (byteimages.length > 0) {
     imagesAdded = true;
     setState(() {

     });
   }

  }

  bool imagesAdded = false;

  @override
  void initState() {
    super.initState();
    getImages();
    Utils.setupAds();

  }


  @override
  Widget build(BuildContext context) {

    double safeAreaHeight =  MediaQuery.of(context).padding.top;
    double safeAreaHeightBottom =  MediaQuery.of(context).padding.bottom;
    widthScreen =
        MediaQuery.of(context).size.width; // because of default padding
    heightScreen = MediaQuery.of(context).size.height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery.of(context).size.height - (safeAreaHeight+safeAreaHeightBottom);
      child:

    return SafeArea(child: Scaffold(
      body:SafeArea(
        top: false,

          child:Container(
          width: widthScreen,
          height: heightScreen,
            color: Colors.white,
            child: SingleChildScrollView(

            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:  [
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
                            "FLOCK_DETAILS".tr(),
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
                height: 170,
                color: Colors.white,
                child: Row( children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Container( child: Text(Utils.selected_flock!.f_name, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 17, color: Utils.getThemeColorBlue(),),)),
                        Row(
                          children: [
                            Container( child: Text(Utils.selected_flock!.acqusition_type.tr(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black,decoration: TextDecoration.underline,),)),
                          ],
                        ),
                        Row(
                          children: [
                            Container( child: Text('ACQUIRED_ON'.tr(), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black54),)),
                            Container( child: Text(Utils.getFormattedDate(Utils.selected_flock!.acqusition_date), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),)),
                          ],
                        ),
                          Row(
                            children: [
                              Container( child: Text('PURPOSE1'.tr(), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black54),)),
                              Container( child: Text(Utils.selected_flock!.purpose, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),)),
                            ],
                          ),

                      ],),
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        height: 120, width: 120,
                        child: Image.asset(Utils.selected_flock!.icon, fit: BoxFit.contain,),),
                      Container(
                        margin: EdgeInsets.only(right: 10),
                        child: Row(
                          children: [
                            Container( margin: EdgeInsets.only(right: 3), child: Text(Utils.selected_flock!.active_bird_count.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 20, color: Utils.getThemeColorBlue()),)),
                            Text("BIRDS".tr(), style: TextStyle(color: Colors.black, fontSize: 14),)
                          ],
                        ),
                      ),
                    ],
                  ),

                ]),
              ),
              birdUsageList.length > 0? Container(height: 40, width: widthScreen,
              margin: EdgeInsets.only(left: 10, right: 10),
              child: ListView.builder(
                  itemCount: birdUsageList.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      width: 160,
                      height: 35,
                      margin: EdgeInsets.all(5),
                      decoration:  BoxDecoration(
                        color: Utils.getThemeColorBlue(),
                        borderRadius:
                        BorderRadius.all(Radius.circular(20))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(birdUsageList.elementAt(index).reason, style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold,color: Colors.white),),
                        Text(birdUsageList.elementAt(index).sum, style: TextStyle(fontSize: 14,color: Colors.white),),

                      ],
                    ),);
                  }),) : SizedBox(width: 0, height: 0,),
              !Utils.selected_flock!.notes.isEmpty? Container(
                width: widthScreen,
                  margin: EdgeInsets.only(left: 20,right: 10),
                  child: Text(
                    "FLOCK_DESC".tr(),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  )) : SizedBox(width: 0,height: 0,),
              !Utils.selected_flock!.notes.isEmpty?Container(
                  margin: EdgeInsets.only(left: 20,right: 10),
                  child: Text(Utils.selected_flock!.notes, style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),)): SizedBox(width: 0,height: 0,),
              imagesAdded? Container(
                height: 80,
                width: widthScreen ,
                margin: EdgeInsets.only(left: 10,right: 10),
                child: ListView.builder(
                    itemCount: byteimages!.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        margin: EdgeInsets.all(10),
                        height: 80, width: 80,
                        child: Image.memory(byteimages.elementAt(index), fit: BoxFit.fill,),
                      );
                    }),
              ): SizedBox(height: 0,width: 0,),


              Container(margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    /*Text(
                      "Manage Flock",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),*/

                    SizedBox(width: widthScreen, height: 10,),
                    InkWell(
                        child: Container(
                          width: widthScreen ,
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          decoration:  BoxDecoration(
                              color: Utils.getThemeColorBlue(),
                              borderRadius:
                              BorderRadius.all(Radius.circular(8))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                              Container(
                              width: 36,
                              height: 36,
                              child:
                                Image(image: AssetImage(
                                    'assets/add_reduce.png'),
                                  fit: BoxFit.scaleDown,
                                  color: Colors.white,

                                ),),
                                Expanded(
                                  child: Text(
                                    "ADD_REDUCE_BIRDS".tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          moveToAddReduceFlock();
                        }),

                    SizedBox(width: widthScreen, height: 10,),
                    InkWell(
                        child: Container(
                          width: widthScreen ,
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          decoration:  BoxDecoration(
                              color: Utils.getThemeColorBlue(),
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                height: 36,
                                child:Image(image: AssetImage(
                                    'assets/egg.png'),
                                  fit: BoxFit.scaleDown,
                                  color: Colors.white,
                                ),),
                                Expanded(
                                  child: Text(
                                    "EGG_COLLECTION".tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const EggCollectionScreen()),
                          );
                        }),

                    SizedBox(width: widthScreen, height: 10,),
                    InkWell(
                        child: Container(
                          width: widthScreen ,
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          decoration:  BoxDecoration(
                              color: Utils.getThemeColorBlue(),
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 8),
                            child: Row(
                              children: [
                              Container(
                              width: 36,
                              height: 36,
                              child:
                                Image(image: AssetImage(
                                    'assets/feed.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),),
                                Expanded(
                                  child: Text(
                                    "DAILY_FEEDING".tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DailyFeedScreen()),
                          );
                        }),


                    SizedBox(width: widthScreen, height: 10,),
                    InkWell(
                        child: Container(
                          width: widthScreen ,
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          decoration:  BoxDecoration(
                              color: Utils.getThemeColorBlue(),
                              borderRadius:
                              BorderRadius.all(Radius.circular(8))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                              Container(
                              width: 36,
                              height: 36,
                              child:
                                Image(image: AssetImage(
                                    'assets/health.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),),
                                Expanded(
                                  child: Text(
                                    "BIRDS_HEALTH".tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MedicationVaccinationScreen()),
                          );
                        }),

                    SizedBox(width: widthScreen, height: 10,),
                    InkWell(
                        child: Container(
                          width: widthScreen ,
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          decoration:  BoxDecoration(
                              color: Utils.getThemeColorBlue(),
                              borderRadius:
                              BorderRadius.all(Radius.circular(8))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                height: 36,
                                child:Image(image: AssetImage(
                                    'assets/income.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),),
                                Expanded(
                                  child: Text(
                                    "INCOME_EXPENSE".tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const TransactionsScreen()),
                          );
                        }),
                  ],
                ),
              ),


                   /* Text(
              "Main Menu",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24,
                  color: Utils.getThemeColorBlue(),
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold
              ),
            ),
                    SizedBox(width: widthScreen, height: 50,),
                    InkWell(
                        child: Container(
                          width: widthScreen - (widthScreen / 4),
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(left: 20, right: 20),
                          decoration: const BoxDecoration(
                              color: Utils.getThemeColorBlue(),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 30),
                            child: Row(
                              children: [
                                Image(image: AssetImage(
                                    'assets/image.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),
                                Expanded(
                                  child: Text(
                                    "Inventory",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Inventory()),
                          );
                        }),
                    SizedBox(width: widthScreen,height: 20),
                    InkWell(
                  child: Container(
                    width: widthScreen - (widthScreen / 4),
                    height: 60,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(left: 20, right: 20),
                    decoration: const BoxDecoration(
                        color: Utils.getThemeColorBlue(),
                        borderRadius:
                        BorderRadius.all(Radius.circular(10))),
                    child: Container(
                      width: 40,height: 40,
                      margin: EdgeInsets.only(left: 30),
                      child: Row(
                        children: [
                          Image(image: AssetImage(
                              'assets/image.png'),
                            fit: BoxFit.fill,
                            color: Colors.white,
                          ),
                          Expanded(
                            child: Text(
                              "Profit/Loss",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    *//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiRepeatScreen()),
                    );*//*
                  }),
                    SizedBox(width: widthScreen,height: 20),
                    InkWell(
                  child: Container(
                    width: widthScreen - (widthScreen / 4),
                    height: 60,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(left: 20, right: 20),
                    decoration: const BoxDecoration(
                        color: Utils.getThemeColorBlue(),
                        borderRadius:
                        BorderRadius.all(Radius.circular(10))),
                    child: Container(
                      width: 40,height: 40,
                      margin: EdgeInsets.only(left: 30),
                      child: Row(
                        children: [
                          Image(image: AssetImage(
                              'assets/image.png'),
                            fit: BoxFit.fill,
                            color: Colors.white,
                          ),
                          Expanded(
                            child: Text(
                              "Medication",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    *//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiScreen()),
                    );*//*
                  }),
              SizedBox(width: widthScreen,height: 20),
              InkWell(
                  child: Container(
                    width: widthScreen - (widthScreen / 4),
                    height: 60,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(left: 20, right: 20),
                    decoration: const BoxDecoration(
                        color: Utils.getThemeColorBlue(),
                        borderRadius:
                        BorderRadius.all(Radius.circular(10))),
                    child: Container(
                      width: 40,height: 40,
                      margin: EdgeInsets.only(left: 30),
                      child: Row(
                        children: [
                          Image(image: AssetImage(
                              'assets/image.png'),
                            fit: BoxFit.fill,
                            color: Colors.white,
                          ),
                          Expanded(
                            child: Text(
                              "Feeding",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    *//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiTemplateScreen()),
                    );*//*
                  }),
              SizedBox(width: widthScreen,height: 20),
              InkWell(
                  child: Container(
                    width: widthScreen - (widthScreen / 4),
                    height: 60,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(left: 20, right: 20),
                    decoration: const BoxDecoration(
                        color: Utils.getThemeColorBlue(),
                        borderRadius:
                        BorderRadius.all(Radius.circular(10))),
                    child: Container(
                      width: 40,height: 40,
                      margin: EdgeInsets.only(left: 30),
                      child: Row(
                        children: [
                          Image(image: AssetImage(
                              'assets/image.png'),
                            fit: BoxFit.fill,
                            color: Colors.white,
                          ),
                          Expanded(
                            child: Text(
                              "Form Setup",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    *//*Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmojiTemplateScreen()),
                    );*//*
                  }),*/
                  ]
      ),),),),),);
  }

  Future<void> moveToAddReduceFlock() async{
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddReduceFlockScreen()),
    );

    Utils.selected_flock = await DatabaseHelper.findFlock(Utils.selected_flock!.f_id);
    setState(() {

    });
  }

}

