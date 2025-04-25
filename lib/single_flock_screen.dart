import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:poultary/app_intro/image_slider.dart';
import 'package:poultary/model/flock_image.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/transactions_screen.dart';
import 'package:poultary/utils/utils.dart';
import 'add_reduce_flock.dart';
import 'custom/all_custom_data_screen.dart';
import 'custom/custom_flock_category.dart';
import 'daily_feed.dart';
import 'database/databse_helper.dart';
import 'egg_collection.dart';
import 'medication_vaccination.dart';
import 'model/custom_category.dart';
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

  String date = "Choose date";
  void getUsage() async {
    birdUsageList = await DatabaseHelper.getBirdUSage(Utils.selected_flock!.f_id);

    print("BIRD USAGES ${birdUsageList.length}");

    setState(() {

    });
  }

  List<Flock_Image> images = [];
  List<Uint8List> byteimages = [];
  List<BirdUsage> birdUsageList = [];
  void getImages() async {

   await DatabaseHelper.instance.database;


   images = await DatabaseHelper.getFlockImage(Utils.selected_flock!.f_id);

   date = Utils.selected_flock!.acqusition_date;

   print(images);

   for(int i=0;i<images.length;i++){
     Uint8List bytesImage = const Base64Decoder().convert(images.elementAt(i).image);
     byteimages.add(bytesImage);
     print(images.elementAt(i).image);
   }

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
    getUsage();
    addEggColorColumn();
    getAllCategories();
    Utils.setupAds();

  }

  int mortalityCount = 0;

  List<CustomCategory> categories = [];
  List<CustomCategory> defaultcategories = [];
  Future<void> getAllCategories() async {

    mortalityCount = await DatabaseHelper.getFlockMortalityCount(Utils.selected_flock!.f_id);
    defaultcategories = Utils.getDefaultFlockCatgories();

    categories = (await DatabaseHelper.getCustomCategories())!;
    await DatabaseHelper.createCategoriesDataTable();

    defaultcategories.addAll(categories);

    setState(() {});
  }

  void addEggColorColumn() async{
    DatabaseHelper.instance.database;
    await DatabaseHelper.addEggColorColumn();
    print("DONE");
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
            color: Utils.getThemeColorBlue(),
            child: SingleChildScrollViewWithStickyFirstWidget(

            child: Column(
             children:  [
              Utils.getDistanceBar(),

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: 45,
                        height: 45,
                        child: InkWell(
                          child: Icon(Icons.arrow_back,
                              color: Colors.white, size: 30),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child:  GestureDetector(
                          onTapDown: (TapDownDetails details) {
                            showMemberMenu(details.globalPosition);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            padding: EdgeInsets.all(5),
                            child: Image.asset('assets/menu_dots.png', color: Colors.white,),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// **Flock Name (Title)**
                    Center(
                      child: Text(
                        Utils.selected_flock!.f_name,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),

                    SizedBox(height: 8),

                    /// **Flock Details Row**
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        /// **Flock Icon**
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white10, // Subtle background
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.all(10),
                              child: Image.asset(
                                Utils.selected_flock!.icon.replaceAll("jpeg", "png"),
                                width: 90, height: 90,
                              ),
                            ),
                            Text(
                              Utils.selected_flock!.acqusition_type.tr(),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white,),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),

                        SizedBox(width: 10),

                        /// **Bird Count & Additional Details**
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// **Bird Count**
                              Row(
                                children: [
                                   Text(
                                    Utils.selected_flock!.active_bird_count.toString(),
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  SizedBox(width: 5),
                                  Text("BIRDS".tr(), style: TextStyle(color: Colors.white70, fontSize: 16)),
                                ],
                              ),

                              SizedBox(height: 8),

                              /// **Purpose**
                              Row(
                                children: [
                                  Icon(Icons.assignment, color: Colors.white70, size: 18),
                                  SizedBox(width: 5),
                                  Text('PURPOSE1'.tr() + ": ", style: TextStyle(fontSize: 12, color: Colors.white70)),
                                  Expanded(
                                    child: Text(
                                      Utils.selected_flock!.purpose.tr(),
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                      overflow: TextOverflow.ellipsis, // Prevents overflow issues
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 5),


                              Row(
                                children: [
                                  Icon(Icons.watch_later_outlined, color: Colors.white70, size: 18),
                                  SizedBox(width: 5),
                                  Text('Age'.tr() + ": ", style: TextStyle(fontSize: 12, color: Colors.white70)),
                                  Text(
                                    Utils.getAnimalAge(Utils.selected_flock!.acqusition_date),
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),


                              /// **Acquisition Date**
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.white70, size: 18),
                                  SizedBox(width: 5),
                                  Text('DATE'.tr() + ": ", style: TextStyle(fontSize: 12, color: Colors.white70)),
                                  Text(
                                    Utils.getFormattedDate(Utils.selected_flock!.acqusition_date),
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10,),
                    /// **Notes Section**
                    if (Utils.selected_flock!.notes.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.only(left: 5, right: 5),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          Utils.selected_flock!.notes,
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ),

                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Utils.getScreenBackground(),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                                SizedBox(width: 5,),
                                Text("MORTALITY".tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red)),
                              ],
                            ),

                            Row(
                              children: [
                                SizedBox(height: 4),
                                Text("$mortalityCount "+"BIRDS".tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                    /// **Images List**
                    if (imagesAdded)
                      Container(
                        height: 80,
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 10),
                        child: ListView.builder(
                          itemCount: byteimages.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (BuildContext context, int index) {
                            return Stack(
                              children: [
                                // Image Container
                                InkWell(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => CarouselDemo()));
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: MemoryImage(byteimages[index]),
                                        fit: BoxFit.cover,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        )
                                      ],
                                    ),
                                  ),
                                ),

                                // Delete Button (Positioned on top-right)
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        byteimages.removeAt(index);
                                      });
                                      DatabaseHelper.deleteItem("Flock_Image", images.elementAt(index).id!);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),),
                  ],
                ),
              ),
              Container(
                height: heightScreen,
                margin: EdgeInsets.only(top: 20),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  color: Utils.getScreenBackground(),

                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 5),
                          alignment: Alignment.center,
                          child: Text(
                            "Manage_Flock_1".tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Utils.getThemeColorBlue(),
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            await DatabaseHelper.createCustomCategoriesTableIfNotExists();

                            await Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (context) =>  CustomCategoryScreen(customCategory: null,)),
                            );

                            getAllCategories();

                          },
                          child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                  width: 50,
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.all(7),
                                  margin: EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 2,
                                        offset: Offset(0, 1), // changes position of shadow
                                      ),
                                    ],
                                    color: Utils.getThemeColorBlue(),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10.0)),
                                    border: Border.all(
                                      color:  Utils.getThemeColorBlue(),
                                      width: 2.0,
                                    ),
                                  ),child: Text("+", style: TextStyle( fontWeight: FontWeight.normal, fontSize: 20, color: Colors.white),))),
                        ),
                      ],
                    ),

                    SizedBox(width: widthScreen, height: 20,),
                  /*  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                      Expanded(
                        child: InkWell(
                            child: Container(
                              margin: EdgeInsets.only(left: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                color: Utils.getThemeColorBlue(),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 2,
                                    offset: Offset(0, 1), // changes position of shadow
                                  ),
                                ],
                              ),
                              child: Container(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      child:
                                      Image(image: AssetImage(
                                          'assets/birds.png'),
                                        fit: BoxFit.scaleDown,
                                        color: Colors.white,

                                      ),),
                                    Text(
                                      "ADD_REDUCE_BIRDS".tr(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            onTap: () {
                              moveToAddReduceFlock();
                            }),
                      ),
                      Expanded(
                        child: InkWell(
                          child: Container(
                            margin: EdgeInsets.only(right: 10, left: 5),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              color: Utils.getThemeColorBlue(),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 2,
                                  offset: Offset(0, 1), // changes position of shadow
                                ),
                              ],

                            ),
                            child: Container(
                              child: Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    child:Image(image: AssetImage(
                                        'assets/egg.png'),
                                      fit: BoxFit.scaleDown,
                                      color: Colors.white,
                                    ),),
                                  Text(
                                    "EGG_COLLECTION".tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold
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
                          }),),
                    ],),
                    SizedBox(width: widthScreen, height: 10,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: InkWell(
                              child: Container(
                                margin:  EdgeInsets.only(left: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                  color: Utils.getThemeColorBlue(),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 2,
                                      offset: Offset(0, 1), // changes position of shadow
                                    ),
                                  ],

                                ),
                                child: Container(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        child:
                                        Image(image: AssetImage(
                                            'assets/feed.png'),
                                          fit: BoxFit.fill,
                                          color: Colors.white,
                                        ),),
                                      Text(
                                        "DAILY_FEEDING".tr(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.bold
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
                        ),
                        Expanded(
                          child: InkWell(
                              child: Container(
                                margin:  EdgeInsets.only(left: 5,right: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                  color: Utils.getThemeColorBlue(),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 2,
                                      offset: Offset(0, 1), // changes position of shadow
                                    ),
                                  ],

                                ),
                                child: Container(
                                   margin: EdgeInsets.only(left: 5),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 80,height: 80,
                                        child:
                                        Image(image: AssetImage(
                                            'assets/health.png'),
                                          fit: BoxFit.fill,
                                          color: Colors.white,
                                        ),),
                                      Text(
                                        "BIRDS_HEALTH".tr(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.bold
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
                              }),),
                      ],),
                    SizedBox(width: widthScreen, height: 5,),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                              child: Container(
                                height: 60,
                                margin: EdgeInsets.only(top: 10, left: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                  color: Utils.getThemeColorBlue(),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 2,
                                      offset: Offset(0, 1), // changes position of shadow
                                    ),
                                  ],

                                ),
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
                              onTap: () async{
                               await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const TransactionsScreen()),
                                );

                                Utils.selected_flock = await DatabaseHelper.findFlock(Utils.selected_flock!.f_id);

                              }),
                        ),

                        Expanded(
                          child: InkWell(
                              child: Container(
                                height: 60,
                                margin: EdgeInsets.only(top: 10,right: 10, left: 5),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                  color: Utils.getThemeColorBlue(),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 2,
                                      offset: Offset(0, 1), // changes position of shadow
                                    ),
                                  ],

                                ),
                                child: Container(
                                  width: 40,height: 40,
                                  margin: EdgeInsets.only(left: 5),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        child:Image(image: AssetImage(
                                            'assets/more.png'),
                                          fit: BoxFit.fill,
                                          color: Colors.white,
                                        ),),
                                      Expanded(
                                        child: Text(
                                          "More Items".tr(),
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
                              onTap: () async{

                                await DatabaseHelper.createCustomCategoriesTableIfNotExists();
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AllCategoryScreen()),);

                              }),
                        ),
                      ],
                    ),*/
                    Container(
                      height: widthScreen,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 5.0,
                          mainAxisSpacing: 5.0,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: defaultcategories.length,
                        itemBuilder: (context, index) {
                          final category = defaultcategories[index];
                          return InkWell(
                            onTap: () {
                              if (index == 0) {
                                print("Birds Modification");
                                moveToAddReduceFlock();
                              } else if (index == 1) {
                                print("Egg Collection");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const EggCollectionScreen()),
                                );
                              } else if (index == 2) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const DailyFeedScreen()),
                                );
                              } else if (index == 3) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const MedicationVaccinationScreen()),
                                );
                              } else if (index == 4) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const TransactionsScreen()),
                                );
                              } else {
                                _showOptions(index);
                              }
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              color: category.enabled == 1 ? Colors.white : Colors.grey[300],
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    index <= 4
                                        ? Container(
                                      width: 35,
                                      height: 35,
                                      child: Image(
                                        image: AssetImage(category.cIcon),
                                        fit: BoxFit.fill,
                                        color: Utils.getThemeColorBlue(),
                                      ),
                                    )
                                        : Icon(category.icon, size: 35, color: Utils.getThemeColorBlue()),
                                    SizedBox(height: 5),
                                    Text(
                                      category.name.tr(),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    /*Text(
                                      '${category.cat_type}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),*/
                                    Text('${category.itemtype.tr()}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 10, color: category.itemtype == "Collection" ? Colors.green : category.itemtype == "Default"?Colors.grey:Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )



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
    mortalityCount = await DatabaseHelper.getFlockMortalityCount(Utils.selected_flock!.f_id);
    setState(() {

    });
  }


  void showMemberMenu(Offset offset) async {
    double left = offset.dx;
    double top = offset.dy;
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, 0, 0),

      items: [
        PopupMenuItem(
          value: 2,
          child: Text(
            "EDIT".tr(),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ), PopupMenuItem(
          value: 1,
          child: Text(
            "DELETE".tr(),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ),

      ],
      elevation: 8.0,
    ).then((value) async {
      if (value != null) {
        if(value == 1){
         showDeleteConfirmation(context);
        }
        else if(value == 2)
        {
         // showAlertDialog(context, Utils.selected_flock!.f_name);
          showEditFlockDialog(context, flock: Utils.selected_flock!, onSave: (flock){
            Utils.selected_flock = flock;
            DatabaseHelper.updateFlockInfo(flock);
            insertFlockImages(Utils.selected_flock!.f_id);
            Utils.showToast("SUCCESSFUL".tr());
            setState(() {

            });
          });
        }else
        {
          print(value);
        }
      }
    });
  }


  final nameController = TextEditingController();
  showAlertDialog(BuildContext context,String name) {

    nameController.text = name;
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("CANCEL".tr()),
      onPressed:  () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text("DONE".tr()),
      onPressed:  () async {
        Utils.selected_flock!.f_name = nameController.text;
        await DatabaseHelper.updateFlockName(nameController.text, Utils.selected_flock!.f_id);
        Utils.showToast("DONE".tr());
        Navigator.pop(context);
        setState(() {

        });
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("EDIT".tr()),
      content: Container(
        padding: EdgeInsets.all(10),
        child: TextFormField(
          maxLines: null,
          controller: nameController,
          textInputAction: TextInputAction.next,
          decoration:  InputDecoration(
            fillColor: Colors.white.withAlpha(70),
            border: OutlineInputBorder(
                borderRadius:
                BorderRadius.all(Radius.circular(20))),
            hintText: 'FLOCK_NAME'.tr(),
            hintStyle: TextStyle(
                color: Colors.grey, fontSize: 16),
            labelStyle: TextStyle(
                color: Colors.black, fontSize: 16),
          ),
        ),
      ), /*Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            child: TextFormField(
              maxLines: null,
              controller: nameController,
              textInputAction: TextInputAction.next,
              decoration:  InputDecoration(
                fillColor: Colors.white.withAlpha(70),
                border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.all(Radius.circular(20))),
                hintText: 'FLOCK_NAME'.tr(),
                hintStyle: TextStyle(
                    color: Colors.grey, fontSize: 16),
                labelStyle: TextStyle(
                    color: Colors.black, fontSize: 16),
              ),
            ),
          ),
         *//* Container(
            width: widthScreen,
            height: 60,
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.only(left: 10, right: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(70),
              borderRadius: const BorderRadius.all(
                  Radius.circular(20.0)),
              border: Border.all(
                color:  Colors.grey,
                width: 1.0,
              ),
            ),
            child: getAcqusitionDropDownList(),
          ),
          Container(
            width: widthScreen,
            height: 60,
            margin: EdgeInsets.only(left: 10, right: 10,top: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(70),
              borderRadius: const BorderRadius.all(
                  Radius.circular(20.0)),
              border: Border.all(
                color:  Colors.grey,
                width: 1.0,
              ),
            ),
            child: InkWell(
              onTap: () {
                pickDate();
              },
              child: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: 10),

                child: Text(Utils.getFormattedDate(date), style: TextStyle(
                    color: Colors.black, fontSize: 16),),
              ),
            ),
          ),*//*
        ],
      ),*/
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void pickDate() async{

    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1950),
        //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime.now());

    if (pickedDate != null)
    {
      String formattedDate =
      DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        date = formattedDate;
      });
    } else {}

  }


  List<String> acqusitionList = [
    'PURCHASED'.tr(),
    'HATCHED'.tr(),
    'GIFT'.tr(),
    'OTHER'.tr(),
  ];
  String _acqusitionselectedValue = 'PURCHASED'.tr();
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

  showDeleteConfirmation(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("CANCEL".tr()),
      onPressed:  () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text("DONE".tr()),
      onPressed:  () async {

        await DatabaseHelper.deleteFlockAndRelatedInfo(Utils.selected_flock!.f_id);
        Utils.selected_flock = null;
        Utils.showToast("RECORD_DELETED".tr());
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("CONFIRMATION".tr()),
      content: Container(
        padding: EdgeInsets.all(10),
        child: Text('RU_SURE'.tr())
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );

  void deleteRecords(List feedings) {

  }

 }


  void _showOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.remove_red_eye_outlined, size: 30,),
              title: Text('View Category Data'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: defaultcategories.elementAt(index).enabled==0? Colors.grey:Colors.black),),
              onTap: () async {
                if(defaultcategories.elementAt(index).enabled==1) {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>
                        CategoryDataListScreen(
                          customCategory: defaultcategories.elementAt(index),)),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('EDIT'.tr(), style: TextStyle(color: defaultcategories.elementAt(index).enabled==0? Colors.grey:Colors.black),),
              onTap: () {
                if(defaultcategories.elementAt(index).enabled==1) {
                  Navigator.pop(context);
                  _editCategory(index);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('DELETE'.tr(), style: TextStyle(color: defaultcategories.elementAt(index).enabled==0? Colors.grey:Colors.black),),
              onTap: () {
                if(defaultcategories.elementAt(index).enabled==1) {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(context, index);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.block),
              title: Text(defaultcategories[index].enabled == 1 ? 'Disable'.tr() : 'Enable'.tr()),
              onTap: () {
                Navigator.pop(context);
                _toggleCategoryStatus(index);
              },
            ),
          ],
        );
      },
    );
  }

  void _editCategory(int index) {
    // Implement edit functionality
    _createCategory(defaultcategories[index]);
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context,int index) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("CONFIRMATION".tr()),
          content: Text(
            "RU_SURE".tr(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: Text("CANCEL".tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: Text("DELETE".tr(), style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      _deleteCategory(index);
    }
  }


  Future<void> _deleteCategory(int index) async {
    await DatabaseHelper.deleteCategoryData(defaultcategories.elementAt(index).id!);
    await DatabaseHelper.deleteCategory(defaultcategories.elementAt(index).id!);

    setState(() {
      defaultcategories.removeAt(index);
    });
  }

  Future<void> _toggleCategoryStatus(int index) async {
    defaultcategories[index].enabled = defaultcategories[index].enabled == 1? 0:1;
    await DatabaseHelper.updateCategory(defaultcategories[index]);
    setState(() {

    });

  }

  Future<void> _createCategory(CustomCategory? item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomCategoryScreen(customCategory: item,)),
    );
    getAllCategories();
  }


  void showEditFlockDialog(BuildContext context, {
    required Flock flock,
    required Function(Flock) onSave,
  }) {
    TextEditingController nameController = TextEditingController(text: flock.f_name);
    TextEditingController descController = TextEditingController(text: flock.notes);

    TextEditingController dateController = TextEditingController(
        text: flock.acqusition_date.isNotEmpty ? flock.acqusition_date : ""
    );

    List<String> _purposeList = ['EGG', 'MEAT', 'EGG_MEAT', 'OTHER'];
    List<String> _acquisitionList = ['PURCHASED', 'HATCHED', 'GIFT', 'OTHER'];

    String selectedAcquisition = flock.acqusition_type;
    String selectedPurpose = flock.purpose;


    final ImagePicker _picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _pickImages() async {
              final List<XFile>? pickedFiles = await _picker.pickMultiImage();
              if (pickedFiles != null && pickedFiles.isNotEmpty) {
                setState(() {
                  imageFileList.addAll(pickedFiles.map((file) => file.path));
                });

                saveImagesDB();
              }
            }

            void _removeImage(int index) {
              setState(() {
                imageFileList.removeAt(index);
                base64Images.removeAt(index);
              });

            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Button to Pick Images


                    // Flock Name
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Flock Name".tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Acquisition Date Picker
                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "DATE".tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: flock.acqusition_date.isNotEmpty
                              ? DateFormat('yyyy-MM-dd').parse(flock.acqusition_date)
                              : DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                          setState(() {
                            dateController.text = formattedDate;
                            flock = flock.copyWith(acquisitionDate: formattedDate);
                          });
                        }
                      },
                    ),
                    SizedBox(height: 12),

                    // Acquisition Type Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedAcquisition,
                      decoration: InputDecoration(
                        labelText: "ACQUSITION".tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                      items: _acquisitionList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.tr(), style: TextStyle(fontSize: 16)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            flock = flock.copyWith(acquisitionType: newValue);
                          });
                        }
                      },
                    ),
                    SizedBox(height: 12),

                    // Purpose Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedPurpose,
                      decoration: InputDecoration(
                        labelText: "PURPOSE1".tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                      items: _purposeList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.tr(), style: TextStyle(fontSize: 16)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            flock = flock.copyWith(purpose: newValue);
                          });
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "DESCRIPTION_1".tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: _pickImages,
                        child: Text("+"+"IMAGES".tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Display Selected Images in Grid
                    if (imageFileList.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, // Two images per row
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: imageFileList.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(imageFileList[index]),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red.withOpacity(0.8),
                                    ),
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                    SizedBox(height: 12),
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            flock = flock.copyWith(
                              fName: nameController.text,
                              notes: descController.text,
                            );
                          });
                          onSave(flock);
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Update".tr(),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Utils.getThemeColorBlue(),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<String> imageFileList = [];
  void saveImagesDB() async {

    base64Images.clear();

    File file;
    for (int i=0;i<imageFileList.length;i++) {

      file = await Utils.convertToJPGFileIfRequiredWithCompression(File(imageFileList.elementAt(i)));
      final bytes = File(file.path).readAsBytesSync();
      String base64Image =  base64Encode(bytes);
      base64Images.add(base64Image);

      print("img_pan : $base64Image");

    }
  }
  List<String> base64Images = [];
  void insertFlockImages(int? id) {

    if (base64Images.length > 0){

      for (int i=0;i<base64Images.length;i++){
        Flock_Image image = Flock_Image(f_id: id,image: base64Images.elementAt(i));
        DatabaseHelper.insertFlockImages(image);
      }

      print("Images Inserted");
      Utils.showToast("FLOCK_CREATED".tr());
      Navigator.pop(context);
    }

  }


}

