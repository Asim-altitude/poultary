
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poultary/add_feeding.dart';
import 'package:poultary/model/category_item.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/sub_category_screen.dart';
import 'package:poultary/utils/utils.dart';
import 'database/databse_helper.dart';

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
    Utils.setupAds();

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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10.0), // Round bottom-left corner
            bottomRight: Radius.circular(10.0), // Round bottom-right corner
          ),
          child: AppBar(
            title: Text(
              applied_filter_name.tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.blue, // Customize the color
            elevation: 8, // Gives it a more elevated appearance
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context); // Navigates back
              },
            ),
          ),
        ),
      ),

      body:SafeArea(
        top: false,
          child:Container(
          width: widthScreen,
          height: heightScreen,
            color: Utils.getScreenBackground(),
            child:SingleChildScrollViewWithStickyFirstWidget(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:  [
              Utils.getDistanceBar(),


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
                            height: 60,
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

                                        Icon(Icons.keyboard_arrow_right,color: Utils.getThemeColorBlue(),size: 20,),
                                        SizedBox(width: 6,),
                                        Text(categoryList.elementAt(index).name!.tr(),style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Utils.getThemeColorBlue()),),
                                      ],
                                    )),

                              ],),),
                        ),
                      );
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
                                    Container(margin: EdgeInsets.all(0), child: Text(categoryList.elementAt(index).name!, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 18, color: Utils.getThemeColorBlue()),)),
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
      ),),),),);
  }



  void addNewCollection(){
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => NewFeeding()),
    );
  }
}

