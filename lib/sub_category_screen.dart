import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poultary/add_eggs.dart';
import 'package:poultary/add_feeding.dart';
import 'package:poultary/inventory.dart';
import 'package:poultary/model/category_item.dart';
import 'package:poultary/model/feed_item.dart';
import 'package:poultary/model/sub_category_item.dart';
import 'package:poultary/single_flock_screen.dart';
import 'package:poultary/utils/utils.dart';

import 'add_flocks.dart';
import 'database/databse_helper.dart';
import 'model/egg_item.dart';
import 'model/flock.dart';

class SubCategoryScreen extends StatefulWidget {
  const SubCategoryScreen({Key? key}) : super(key: key);

  @override
  _SubCategoryScreen createState() => _SubCategoryScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _SubCategoryScreen extends State<SubCategoryScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }

  @override
  void initState() {
    super.initState();

    getSubCategoriesList();
  }


  List<SubItem> categoryList = [];
  void getSubCategoriesList() async {

    await DatabaseHelper.instance.database;

    categoryList = await DatabaseHelper.getSubCategoryList(Utils.selected_category);

    setState(() {

    });

  }

  int feed_total = 0;

  String applied_filter_name = Utils.selected_category_name;

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
    bottomNavigationBar: BottomAppBar(
    color: Colors.transparent,
    child: Container(
    height: 60,
    width: widthScreen,
    child: InkWell(
      onTap: () async {
        openPopup();
      },
      child: Container(
        width: widthScreen,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: const BorderRadius.all(
              Radius.circular(10.0)),
          border: Border.all(
            color:  Colors.deepPurple,
            width: 2.0,
          ),
        ),
        margin: EdgeInsets.all( 20),
        child: Text(
          "New Item",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.deepPurple,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
      ),
    ),
    ),
    elevation: 0,
    ),
      body:SafeArea(
        top: false,
          child:Container(
          width: widthScreen,
          height: heightScreen - 100,

          color: Colors.white,
            child:SingleChildScrollView(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:  [
              ClipRRect(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10),bottomRight: Radius.circular(10)),
                child: Container(
                  decoration: BoxDecoration(
                     boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple, //(x,y)
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: 60,
                        height: 60,
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
                            applied_filter_name,
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
                height: heightScreen - 220,
                width: widthScreen,
                child: ListView.builder(
                    itemCount: categoryList.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (BuildContext context, int index) {
                      return InkWell(
                        onTap: () {
                          Utils.selected_category = categoryList.elementAt(index).id!;
                          Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SingleFlockScreen()),
                        );},
                        child: Card(
                          margin: EdgeInsets.all(10),
                          color: Colors.white,
                          elevation: 3,
                          child: Container(
                            height: 70,
                            child: Row( children: [
                              Expanded(
                                child: Container(
                                  alignment: Alignment.topLeft,
                                  margin: EdgeInsets.all(10),
                                  child: Column( children: [
                                    Container(margin: EdgeInsets.all(0), child: Text(categoryList.elementAt(index).name!, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),)),
   // Container(margin: EdgeInsets.all(0), child: Text(Utils.getFormattedDate(flocks.elementAt(index).acqusition_date), style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.black),)),
                                  ],),
                                ),
                              ),

                            ]),
                          ),
                        ),
                      );

                    }),
              )

                  ]
      ),),),),),);
  }


  void openPopup() {

    final nameController = TextEditingController();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            scrollable: true,
            title: Text("New "+Utils.selected_category_name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Enter Name',
                      ),
                    ),

                    InkWell(
                      onTap: () async {
                        print(nameController.text);

                      },
                      child: Container(
                        width: widthScreen,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: const BorderRadius.all(
                              Radius.circular(10.0)),
                          border: Border.all(
                            color:  Colors.deepPurple,
                            width: 2.0,
                          ),
                        ),
                        margin: EdgeInsets.all( 20),
                        child: Text(
                          "Confirm",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          );
        });
  }
  void addNewCollection(){
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const NewFeeding()),
    );
  }
}

