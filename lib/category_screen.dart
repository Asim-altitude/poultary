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
import 'package:poultary/single_flock_screen.dart';
import 'package:poultary/sub_category_screen.dart';
import 'package:poultary/utils/utils.dart';

import 'add_flocks.dart';
import 'database/databse_helper.dart';
import 'model/egg_item.dart';
import 'model/flock.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  _CategoryScreen createState() => _CategoryScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _CategoryScreen extends State<CategoryScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }

  @override
  void initState() {
    super.initState();

    getCategoriesList();
  }


  List<CategoryItem> categoryList = [];
  void getCategoriesList() async {

    await DatabaseHelper.instance.database;

    categoryList = await DatabaseHelper.getCategoryItem();


    setState(() {

    });

  }

  int feed_total = 0;

  String applied_filter_name = "All Categories";

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
                          Utils.selected_category_name = categoryList.elementAt(index).name!;
                          Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SubCategoryScreen()),
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



  void addNewCollection(){
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const NewFeeding()),
    );
  }
}

