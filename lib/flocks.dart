import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poultary/add_flocks.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/flock.dart';

class FlockScreen extends StatefulWidget {
  const FlockScreen({Key? key}) : super(key: key);

  @override
  _FlockScreen createState() => _FlockScreen();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _FlockScreen extends State<FlockScreen>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;
  
  List<Flock> flocks = [];
  
  bool no_flock = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();


    
    getList();
    
  }

  void getList() async {

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();
    
    if(flocks.length == 0)
      {
        no_flock = true;
        print('No Flocks');
      }


    setState(() {
      
    });

  }

  String inputText = "Text";
  String outputFont = "Roboto-Regular";
  String outText = "";

  bool _validate = false;

  final inputtextController = TextEditingController();
  final inputcountController = TextEditingController();
  final outputController = TextEditingController();

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
          child: SingleChildScrollView(
            child: Container(
              width: widthScreen,
              height: heightScreen,
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: 60,
                        height: 60,
                        child: InkWell(
                          child: Icon(Icons.arrow_back,
                              color: Colors.black, size: 30),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Expanded(
                          child: Container(
                              margin: EdgeInsets.only(left: 10),
                              child: Text(
                                "All Flocks",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ))),
                    ],
                  ),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                      Container(
                        height: heightScreen - 150,
                        child: ListView.builder(
                        itemCount: flocks.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Card(
                              child: getFlock(index)
                          );}),
                      ),
                        InkWell(
                            child: Container(

                              width: widthScreen ,
                              height: 60,
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(left: 20, right: 20),
                              decoration: const BoxDecoration(
                                  color: Colors.deepPurple,
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
                                        "New Flock",
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
                          builder: (context) => const ADDFlockScreen()),
                    );
                            }),
                        SizedBox(height: 10,width: widthScreen),
                      ]),


                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  getFlock(int index) {

    return Column( children: [
      Container(
          width: widthScreen,
          margin: EdgeInsets.all(10),
          child: Text(flocks.elementAt(index).f_name, style: TextStyle( fontSize: 22, color: Colors.deepPurple, fontWeight: FontWeight.bold),)),
      Row(
            children: [
      Text("Current Birds", style: TextStyle( fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal),),
              Text(flocks.elementAt(index).bird_count.toString(), style: TextStyle( fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),),
            ],
          )
    ] ,);
  }
}


