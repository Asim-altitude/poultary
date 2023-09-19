import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poultary/add_eggs.dart';
import 'package:poultary/add_feeding.dart';
import 'package:poultary/category_screen.dart';
import 'package:poultary/inventory.dart';
import 'package:poultary/model/category_item.dart';
import 'package:poultary/model/feed_item.dart';
import 'package:poultary/single_flock_screen.dart';
import 'package:poultary/sub_category_screen.dart';
import 'package:poultary/utils/utils.dart';

import 'add_flocks.dart';
import 'database/databse_helper.dart';
import 'farm_setup_screen.dart';
import 'manage_flock_screen.dart';
import 'model/egg_item.dart';
import 'model/flock.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreen createState() => _SettingsScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _SettingsScreen extends State<SettingsScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }

  @override
  void initState() {
    super.initState();


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
            color: Utils.getScreenBackground(),
            child:SingleChildScrollView(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:  [

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
                        width: 52,
                        height: 52,
                        child: Icon(Icons.settings,
                            color: Colors.white),
                      ),
                      Container(

                          child: Text(
                            'Settings',
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

              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FarmSetupScreen()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(3)),

                      color: Colors.white,
                      border: Border.all(color: Colors.blueAccent,width: 1.0)
                  ),
                  margin: EdgeInsets.only(left: 12,right: 12,top: 12,bottom: 8),
                  child: Container(
                    height: 50,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white, //(x,y)
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                      Align(
                          alignment: Alignment.topLeft,
                          child: Row(
                            children: [

                              Icon(Icons.settings_applications,color: Utils.getThemeColorBlue(),),
                              SizedBox(width: 4,),
                              Text('Farm Management',style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Utils.getThemeColorBlue()),),
                            ],
                          )),

                    ],),),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CategoryScreen()),

                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(3)),

                      color: Colors.white,
                      border: Border.all(color: Colors.blueAccent,width: 1.0)
                  ),
                  margin: EdgeInsets.only(left: 12,right: 12,top: 2,bottom: 8),
                  child: Container(
                    height: 50,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white, //(x,y)
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                            alignment: Alignment.topLeft,
                            child: Row(
                              children: [

                                Icon(Icons.settings_applications,color: Utils.getThemeColorBlue(),),
                                SizedBox(width: 4,),
                                Text('Category Management',style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Utils.getThemeColorBlue()),),
                              ],
                            )),

                      ],),),
                ),
              ),

              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ManageFlockScreen()),

                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(3)),

                      color: Colors.white,
                      border: Border.all(color: Colors.blueAccent,width: 1.0)
                  ),
                  margin: EdgeInsets.only(left: 12,right: 12,top: 2,bottom: 8),
                  child: Container(
                    height: 50,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white, //(x,y)
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                            alignment: Alignment.topLeft,
                            child: Row(
                              children: [

                                Icon(Icons.settings_applications,color: Utils.getThemeColorBlue(),),
                                SizedBox(width: 4,),
                                Text('Flock Management',style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Utils.getThemeColorBlue()),),
                              ],
                            )),

                      ],),),
                ),
              ),


                  ]
      ),),),),),);
  }



  void addNewCollection(){
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const NewFeeding()),
    );
  }
}

