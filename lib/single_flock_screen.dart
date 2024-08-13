import 'dart:async';
import 'dart:convert';
import 'package:avatar_view/avatar_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poultary/app_intro/image_slider.dart';
import 'package:poultary/model/flock_image.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/transactions_screen.dart';
import 'package:poultary/utils/utils.dart';
import 'add_reduce_flock.dart';
import 'daily_feed.dart';
import 'database/databse_helper.dart';
import 'egg_collection.dart';
import 'medication_vaccination.dart';
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

  void getUsage() async{
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
                      InkWell(onTap: (){
                        showAlertDialog(context,Utils.selected_flock!.f_name);
                      },child:Align(alignment:Alignment.topRight,child: Container(margin:EdgeInsets.only(right: 10),child: Image.asset("assets/edit.png", width: 30, height: 30,color: Colors.white,),)),),

                    ],
                  ),
                ),
              ),

               Container(child: Text(Utils.selected_flock!.f_name, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white,),)),
              Container(
                margin: EdgeInsets.only(left: 15, top: 5),
                child: Row(children: [
                  Image.asset(Utils.selected_flock!.icon.replaceAll("jpeg", "png"), width: 125, height: 125,),
                  /*AvatarView(
                    radius: 65,
                    borderColor: Utils.getThemeColorBlue(),
                    avatarType: AvatarType.RECTANGLE,
                    backgroundColor: Colors.grey.withAlpha(50),
                    imagePath:
                    Utils.selected_flock!.icon,
                    placeHolder: Container(
                      child: Icon(Icons.ac_unit, size: 50,),
                    ),
                    errorWidget: Container(
                      child: Icon(Icons.error, size: 50,),
                    ),
                  ),*/
                  Container(
                    margin: EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 15),
                          child: Row(
                            children: [
                              Container( margin: EdgeInsets.only(right: 3), child: Text(Utils.selected_flock!.active_bird_count.toString(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),)),
                              Text("BIRDS".tr(), style: TextStyle(color: Colors.white70, fontSize: 16),)
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container( child: Text('PURPOSE1'.tr()+": ", style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.white70),)),
                            Container( child: Text(Utils.selected_flock!.purpose, style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),)),
                          ],
                        ),
                        Row(
                          children: [
                            Container( child: Text('ACQUSITION'.tr()+": ", style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.white70),)),
                            Container( child: Text(Utils.selected_flock!.acqusition_type.tr(), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white,decoration: TextDecoration.underline,),)),
                          ],
                        ),
                        Row(
                          children: [
                            //Icon(Icons.calendar_month, size: 25, color: Colors.white70,),
                            Container( child: Text('DATE'.tr()+": ", style: TextStyle( fontWeight: FontWeight.normal, fontSize: 12, color: Colors.white70),)),
                            Container( child: Text(Utils.getFormattedDate(Utils.selected_flock!.acqusition_date), style: TextStyle( fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),)),
                          ],
                        ),

                    ],),
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
                      height: 55,
                      padding: EdgeInsets.all(5),
                      margin: EdgeInsets.all(5),
                      decoration:  BoxDecoration(
                        color: Colors.white12,
                        borderRadius:
                        BorderRadius.all(Radius.circular(10))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(birdUsageList.elementAt(index).reason, style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold,color: Colors.white),),
                        SizedBox(width: 10,),
                        Text(birdUsageList.elementAt(index).sum, style: TextStyle(fontSize: 14,color: Colors.white),),

                      ],
                    ),);
                  }),) : SizedBox(width: 0, height: 0,),

              !Utils.selected_flock!.notes.isEmpty? Container(
                  margin: EdgeInsets.only(left: 20,right: 10),
                  child: Text(Utils.selected_flock!.notes, style: TextStyle( fontWeight: FontWeight.normal, fontSize: 14, color: Colors.white),)): SizedBox(width: 0,height: 0,),
              imagesAdded? Container(
                height: 80,
                width: widthScreen ,
                margin: EdgeInsets.only(left: 10,right: 10),
                child: ListView.builder(
                    itemCount: byteimages.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) {
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CarouselDemo()),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.all(10),
                          height: 80, width: 80,
                          child:  Image.memory(byteimages.elementAt(index), fit: BoxFit.fill,),
                        ),
                      );
                    }),
              ): SizedBox(height: 0,width: 0,),

              Container(
                height: heightScreen,
                margin: EdgeInsets.only(top: 30),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  color: Utils.getScreenBackground(),

                ),
                child: Column(
                  children: [
                    Text(
                      "Manage_Flock_1".tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Utils.getThemeColorBlue(),
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: widthScreen, height: 10,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                      Expanded(
                        child: InkWell(
                            child: Container(
                              margin: EdgeInsets.all(10),
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
                            margin: EdgeInsets.all(10),
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
                                margin:   EdgeInsets.all(10),
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
                                margin:  EdgeInsets.all(10),
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
                                   margin: EdgeInsets.only(left: 10),
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
                    SizedBox(width: widthScreen, height: 10,),
                    InkWell(
                        child: Container(
                          width: widthScreen ,
                          height: 60,
                          margin: EdgeInsets.all(10),
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
  }


}

