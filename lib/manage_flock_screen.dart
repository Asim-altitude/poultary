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
import 'model/egg_item.dart';
import 'model/flock.dart';

class ManageFlockScreen extends StatefulWidget {
  const ManageFlockScreen({Key? key}) : super(key: key);

  @override
  _ManageFlockScreen createState() => _ManageFlockScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _ManageFlockScreen extends State<ManageFlockScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }

  @override
  void initState() {
    super.initState();
    getList();
    Utils.setupAds();

  }

  bool no_flock = false;
  List<Flock> flocks = [];
  void getList() async {

    await DatabaseHelper.instance.database;
    flocks = await DatabaseHelper.getAllFlocks();

    if(flocks.length == 0)
    {
      no_flock = true;
      print('No Flocks');
    }

    setState(() {

    });

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
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          width: 50,
                          height: 50,
                          child: Icon(Icons.arrow_back,
                              color: Colors.white, size: 30),
                        ),
                      ),
                      Container(
                          child: Text(
                            'Manage Flocks',
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
              flocks.length > 0 ?Column(
                children: [
                  Container(
                      alignment:  Alignment.center,
                      margin: EdgeInsets.only(top: 20),
                      child: Text('Click any flock to Activate or Expire.',style: TextStyle( fontSize: 14,color: Colors.black, fontWeight:  FontWeight.bold),)),
                  Row(
                    children: [
                      Container(
                        width: widthScreen - 32,
                          alignment:  Alignment.center,
                          margin: EdgeInsets.only(top: 10,left: 16,right: 16),
                          child: Text(' Expired flocks will no longer appear in the app except this screen.',textAlign: TextAlign.center,style: TextStyle( fontSize: 14,color: Colors.grey),)),

                    ],
                  )
                ],
              ) : SizedBox(width: 0,height: 0,),
              SizedBox(height: 8,),
              flocks.length > 0 ? Container(
                height: heightScreen - 100,
                width: widthScreen,

                child: ListView.builder(
                    itemCount: flocks.length,
                    scrollDirection: Axis.vertical,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      return  InkWell(
                          onTap: () async{
                            flocks.elementAt(index).active = flocks.elementAt(index).active == 1 ? 0 : 1;
                            await DatabaseHelper.updateFlockStatus(flocks.elementAt(index).active,flocks.elementAt(index).f_id);
                            setState(() {

                            });
                          },
                          child:Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(3)),

                                color: Colors.white,
                                border: Border.all(color: Colors.blueAccent,width: 1.0)
                            ),
                            margin: EdgeInsets.only(left: 12,right: 12,top: 2,bottom: 8),
                            child: Container(
                              height: 150,
                              width: widthScreen,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),
                              ),
                              child: Row( children: [
                                Expanded(
                                  child: Container(

                                    margin: EdgeInsets.all(10),
                                    padding: EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container( child: Text(flocks.elementAt(index).f_name, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 18, color: Utils.getThemeColorBlue()),)),
                                        Container( child: Text(flocks.elementAt(index).acqusition_type, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),)),
                                        Container( child: Text(Utils.getFormattedDate(flocks.elementAt(index).acqusition_date), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black),)),
                                        InkWell(
                                          onTap: () async {
                                             flocks.elementAt(index).active = flocks.elementAt(index).active == 1 ? 0 : 1;
                                             await DatabaseHelper.updateFlockStatus(flocks.elementAt(index).active,flocks.elementAt(index).f_id);
                                             setState(() {

                                             });
                                          },
                                            child: Container(margin: EdgeInsets.only(top: 10), child: Text(flocks.elementAt(index).active == 1? "ACTIVE" : "EXPIRED", style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: flocks.elementAt(index).active == 1? Colors.green: Colors.red),))),

                                      ],),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      margin: EdgeInsets.all(5),
                                      height: 80, width: 80,
                                      child: Image.asset(flocks.elementAt(index).icon, fit: BoxFit.contain,),),
                                    Container(
                                      margin: EdgeInsets.only(right: 10),
                                      child: Row(
                                        children: [
                                          Container( margin: EdgeInsets.only(right: 5), child: Text(flocks.elementAt(index).active_bird_count.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 16, color: Utils.getThemeColorBlue()),)),
                                          Text("Birds", style: TextStyle(color: Colors.black, fontSize: 14),)
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                              ]),
                            ),
                          )
                      );

                    }),
              ) :
              Align(
                alignment: Alignment.center,
              child:Container(

                  alignment:  Alignment.center,
                  margin: EdgeInsets.only(top: 50,left: 16,right: 16),
                  child: Text('No Flocks Added Yet. Add new from Dashboard',textAlign: TextAlign.center,style: TextStyle( fontSize: 16,color: Colors.black,),),),),

                  ]
      ),),),),),);
  }

}

