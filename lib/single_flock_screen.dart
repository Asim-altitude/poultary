import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:poultary/app_intro/image_slider.dart';
import 'package:poultary/model/flock_detail.dart';
import 'package:poultary/model/flock_image.dart';
import 'package:poultary/model/weight_record.dart';
import 'package:poultary/multiuser/utils/SyncManager.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/suggested_notifcations.dart';
import 'package:poultary/transactions_screen.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:poultary/weight_record_screen.dart';
import 'add_birds.dart';
import 'add_reduce_flock.dart';
import 'custom/all_custom_data_screen.dart';
import 'custom/custom_flock_category.dart';
import 'daily_feed.dart';
import 'database/databse_helper.dart';
import 'egg_collection.dart';
import 'flock_notifications_screen.dart';
import 'medication_vaccination.dart';
import 'model/custom_category.dart';
import 'model/flock.dart';
import 'model/schedule_notification.dart';
import 'model/used_item.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'multiuser/api/server_apis.dart';
import 'multiuser/model/birds_modification.dart';
import 'multiuser/model/user.dart';
import 'multiuser/utils/FirebaseUtils.dart';
import 'multiuser/utils/RefreshMixin.dart';
import 'multiuser/utils/SyncStatus.dart';

class SingleFlockScreen extends StatefulWidget {
  const SingleFlockScreen({Key? key}) : super(key: key);

  @override
  _SingleFlockScreen createState() => _SingleFlockScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _SingleFlockScreen extends State<SingleFlockScreen> with SingleTickerProviderStateMixin, RefreshMixin{

  @override
  void onRefreshEvent(String event) async {
    try {
      if (event == FireBaseUtils.FLOCKS) {
        Flock? flock = await DatabaseHelper.getSingleFlock(Utils.selected_flock!.f_id);
        if(flock == null){
          Utils.showToast("Flock is Deleted".tr());
          Navigator.pop(context);
        }else{
          Utils.selected_flock = flock;
          setState(() {

          });
        }
      }
    }
    catch(ex){
      print(ex);
    }
  }
  double widthScreen = 0;
  double heightScreen = 0;
  bool ageInWeeks = false;
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

   byteimages.clear();
   for(int i=0;i<images.length;i++) {
     Uint8List bytesImage = const Base64Decoder().convert(images.elementAt(i).image);
     byteimages.add(bytesImage);
     print("IMAGE_ID "+images.elementAt(i).id.toString());
   }

   if (byteimages.length > 0) {
     imagesAdded = true;
     setState(() {

     });
   }

  }


  Future<void> _showFlockBatchesBottomSheet(BuildContext context) async {
    List<Flock_Detail> additionList =
    await DatabaseHelper.getFlockDetailsByFlock(Utils.selected_flock!.f_id);

    print("${additionList.length} ADDED FOUND");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 🔹 Quick Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    icon: const Icon(Icons.change_circle_outlined, color: Colors.white),
                    label: Text("Modify Birds".tr(),
                        style: const TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.pop(context);
                      // 👉 Navigate or show your add birds logic here
                      moveToAddReduceFlock();
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Empty state
                if (additionList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        "No batches found for this flock.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 400,
                    child: ListView.builder(
                      itemCount: additionList.length,
                      itemBuilder: (context, index) {
                        final detail = additionList[index];
                        final recordDate =
                        DateTime.tryParse(detail.acqusition_date);
                        final ageDays = recordDate != null
                            ? DateTime.now().difference(recordDate).inDays
                            : 0;
                        final ageText = recordDate == null
                            ? "Unknown"
                            : (ageDays < 30
                            ? "$ageDays days"
                            : "${(ageDays / 30).floor()} months ${ageDays % 30} days");

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Icon(
                                    Icons.group_work,
                                    size: 28,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        "Birds".tr() +
                                            ":" +
                                            " ${detail.item_count}",
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: detail.item_type
                                                .toLowerCase() ==
                                                "addition"
                                                ? Colors.green
                                                : Colors.red),
                                      ),
                                      Text(
                                        detail.item_type.toLowerCase() ==
                                            "addition"
                                            ? "Added".tr() +
                                            " " +
                                            "ON".tr() +
                                            ":" +
                                            " ${Utils.getFormattedDate(detail.acqusition_date)}"
                                            : "Reduced".tr() +
                                            " " +
                                            "ON".tr() +
                                            ":" +
                                            " ${Utils.getFormattedDate(detail.acqusition_date)}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        Utils.getAnimalAgeWeeks(
                                            detail.acqusition_date) +
                                            " ",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }



  Future<List<Flock_Image>> getSavedImages() async {

    await DatabaseHelper.instance.database;

    List<Flock_Image> fimages = await DatabaseHelper.getFlockImage(Utils.selected_flock!.f_id);

    return fimages;
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

  int mortalityCount = 0,cullingCount = 0;

  List<CustomCategory> categories = [];
  List<CustomCategory> defaultcategories = [];
  Future<void> getAllCategories() async {

    mortalityCount = await DatabaseHelper.getFlockMortalityCount(Utils.selected_flock!.f_id);
    cullingCount = await DatabaseHelper.getFlockCullingCount(Utils.selected_flock!.f_id);
    weightRecord = await DatabaseHelper.getLatestWeightRecord(Utils.selected_flock!.f_id);

    defaultcategories = Utils.getDefaultFlockCatgories();


    try{
      categories = (await DatabaseHelper.getCustomCategories())!;
      await DatabaseHelper.createCategoriesDataTable();

      defaultcategories.addAll(categories);

      await DatabaseHelper.instance.addSyncColumnsToTable("CustomCategoryData");
      await DatabaseHelper.instance.assignSyncIds("CustomCategoryData");

    }catch(ex){

    }


    setState(() {});
  }

  void addEggColorColumn() async {
    DatabaseHelper.instance.database;
    await DatabaseHelper.addEggColorColumn();
    print("DONE");
  }

  WeightRecord? weightRecord;

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
      appBar: AppBar(
        backgroundColor: Utils.getThemeColorBlue(), // Customize the color
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Navigates back
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.orangeAccent,),
            tooltip: 'Notification',
            onPressed: () async {
              // Handle search action
              List<ScheduledNotification> notifications = await DatabaseHelper.getScheduledNotificationsByFlockId(Utils.selected_flock!.f_id);
              if(notifications.length > 0){
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlockNotificationScreen(allNotifications: notifications,),
                  ),
                );
              }else{
                print(Utils.selected_flock!.icon.split(".")[0].replaceAll("assets/", ""));
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SuggestedNotificationScreen(birdType: Utils.selected_flock!.icon.split(".")[0].replaceAll("assets/", ""), flockId: Utils.selected_flock!.f_id, flockAgeInDays: Utils.getAgeIndays(Utils.selected_flock!.acqusition_date),),
                  ),
                );
              }
            },
          ),
          GestureDetector(
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
        ],
      ),
      body: SafeArea(
         child:Container(
          width: widthScreen,
          height: heightScreen,
            color: Utils.getThemeColorBlue(), // Customize the color
            child: SingleChildScrollViewWithStickyFirstWidget(
            child: Column(
             children:  [
              Utils.getDistanceBar(),

              /*ClipRRect(
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
                        child:  Row(
                          children: [
                            GestureDetector(
                              onTap: ()
                              async {

                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                padding: EdgeInsets.all(5),
                                child: Icon(Icons.notifications_active, color: Colors.amber,),
                              ),
                            ),
                            GestureDetector(
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),*/
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 🐦 Flock Image + Acquisition Type
                        Column(
                          children: [
                            InkWell(
                              onTap: () {
                                if(byteimages.length==0){
                                  String defaultImage = '${Utils.selected_flock!.icon.replaceAll("jpeg", "png")}';

                                  showAssetImageDialog(context, defaultImage);
                                }else {
                                  _showFullScreenImage(context, byteimages, 0);
                                }
                              },
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: buildImageGrid(byteimages),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              Utils.selected_flock!.acqusition_type.tr(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        /// 📋 Details Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// 🔢 Bird Count

                              InkWell(
                                onTap: () async {
                                  await _showFlockBatchesBottomSheet(context);
                                },
                                child: Container(
                                  padding: EdgeInsets.all(5.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        Utils.selected_flock!.active_bird_count.toString(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "BIRDS".tr(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              /// 🎯 Purpose
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.assignment, color: Colors.white70, size: 18),
                                  const SizedBox(width: 6),
                                  Text('PURPOSE1'.tr() + ": ",
                                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                  Expanded(
                                    child: Text(
                                      Utils.selected_flock!.purpose.tr(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              /// 🕒 Age
                              Row(
                                children: [
                                  const Icon(Icons.watch_later_outlined, color: Colors.white70, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Age'.tr() + ": ",
                                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                  Text(
                                    ageInWeeks? Utils.getAnimalAgeWeeks(Utils.selected_flock!.acqusition_date):Utils.getAnimalAge(Utils.selected_flock!.acqusition_date),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10,),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        ageInWeeks = !ageInWeeks;
                                      });
                                    },
                                      child: const Icon(Icons.switch_camera_outlined, color: Colors.white70, size: 22)),

                                ],
                              ),

                              const SizedBox(height: 8),

                              /// 📅 Acquisition Date
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
                                  const SizedBox(width: 6),
                                  Text('DATE'.tr() + ": ",
                                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                  Text(
                                    Utils.getFormattedDate(Utils.selected_flock!.acqusition_date),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    Center(
                      child: InkWell(
                        onTap: () async{
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WeightRecordScreen(
                                flockId: Utils.selected_flock!.f_id,
                                birdsCount: Utils.selected_flock!.active_bird_count!,
                              ),
                            ),
                          );

                          refreshData();
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          color: Colors.white12,
                          elevation: 2,
                          margin: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.monitor_weight, color: Colors.white70),
                                SizedBox(width: 8),
                                Text(
                                  'AVG Weight'.tr() + ": ",
                                  style: TextStyle(fontSize: 14, color: Colors.white70),
                                ),
                                Text(
                                  weightRecord != null
                                      ? "${weightRecord!.averageWeight} ${Utils.selected_unit.tr()}"
                                      : 'No Records'.tr(),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                                    SizedBox(width: 8),
                                    Text(
                                      "MORTALITY".tr()+"/"+ "CULLING".tr(),
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.red),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _showAddMortalityDialog(context); // Modified dialog to choose between Mortality / Culling
                                  },
                                  child: Icon(Icons.add_circle_outline, color: Utils.getThemeColorBlue(), size: 30),
                                ),
                              ],
                            ),

                            SizedBox(height: 5),

                            // Mortality Row
                            GestureDetector(
                              onTap: () {
                                _showMortalityRecordsDialog(context, 'MORTALITY');
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "MORTALITY".tr(),
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        mortalityCount > 0 ? "$mortalityCount ${'BIRDS'.tr()}" : "No Records".tr(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: mortalityCount > 0 ? Colors.black : Colors.grey,
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios_rounded, size: 20, color: Colors.grey,),
                                    ],
                                  ),

                                ],
                              ),
                            ),

                            SizedBox(height: 5),

                            // Culling Row
                            GestureDetector(
                              onTap: () {
                                _showMortalityRecordsDialog(context, 'CULLING');

                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "CULLING".tr(),
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        cullingCount > 0 ? "$cullingCount ${'BIRDS'.tr()}" : "No Records".tr(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: cullingCount > 0 ? Colors.black : Colors.grey,
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios_rounded, size: 20, color: Colors.grey,),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    /*/// **Images List**
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
                        ),),*/
                  ],
                ),
              ),
              Container(
                height: heightScreen,
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
                   GridView.builder(
                     shrinkWrap: true, // ✅ important!
                     physics: NeverScrollableScrollPhysics(),
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

                                if(Utils.isMultiUSer && !Utils.hasFeaturePermission("view_birds"))
                                {
                                  Utils.showMissingPermissionDialog(context, "view_birds");
                                  return;
                                }

                                print("Birds Modification");
                                moveToAddReduceFlock();
                              } else if (index == 1) {
                                if(Utils.isMultiUSer && !Utils.hasFeaturePermission("view_eggs"))
                                {
                                  Utils.showMissingPermissionDialog(context, "view_eggs");
                                  return;
                                }

                                print("Egg Collection");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const EggCollectionScreen()),
                                );
                              } else if (index == 2) {

                                if(Utils.isMultiUSer && !Utils.hasFeaturePermission("view_feed"))
                                {
                                  Utils.showMissingPermissionDialog(context, "view_feed");
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const DailyFeedScreen()),
                                );
                              } else if (index == 3) {
                                if(Utils.isMultiUSer && !Utils.hasFeaturePermission("view_health"))
                                {
                                  Utils.showMissingPermissionDialog(context, "view_health");
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const MedicationVaccinationScreen()),
                                );
                              } else if (index == 4) {

                                if(Utils.isMultiUSer && !Utils.hasFeaturePermission("view_transaction"))
                                {
                                  Utils.showMissingPermissionDialog(context, "view_transaction");
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const TransactionsScreen()),
                                );
                              } else {
                                if(Utils.isMultiUSer && !Utils.hasFeaturePermission("view_custom_category"))
                                {
                                  Utils.showMissingPermissionDialog(context, "view_custom_category");
                                  return;
                                }

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
      ),),),),);
  }


  void showAssetImageDialog(BuildContext context, String image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Your asset image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    image, // put your asset path here
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _showFullScreenImage(BuildContext context, List<Uint8List> byteimages, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.all(0),
          child: Stack(
            children: [
              PhotoViewGallery.builder(
                itemCount: byteimages.length,
                pageController: PageController(initialPage: initialIndex),
                builder: (context, index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: MemoryImage(byteimages[index]),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  );
                },
                scrollPhysics: BouncingScrollPhysics(),
                backgroundDecoration: BoxDecoration(color: Colors.black),
              ),

              // Close Button
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildImageGrid(List<Uint8List> images) {
    String defaultImage = '${Utils.selected_flock!.icon.replaceAll("jpeg", "png")}';

    if (images.isEmpty) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(defaultImage, fit: BoxFit.contain, width: 120, height: 120),
        ),
      );
    }

    return Stack(
      children: [
        // First image as background
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            images.elementAt(0),
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),

        // Gradient overlay for better readability
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.0),
              ],
            ),
          ),
        ),

        // "+X more" text with center alignment
        if (images.length > 1)
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "+${images.length - 1} "+"more".tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget ImageWidget(Uint8List image, String defaultImage, {double height = 100, double width = double.infinity}) {
    return Container(
      margin: EdgeInsets.all(4),
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: image == "image"
              ? Image.asset(defaultImage, width: 120, height: 120,) as ImageProvider
              : MemoryImage(image),
          fit: BoxFit.cover,
        ),
      ),
    );
  }


  Future<void> moveToAddReduceFlock() async{
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddReduceFlockScreen()),
    );

    refreshData();
  }


  void refreshData() async {
    Utils.selected_flock = await DatabaseHelper.findFlock(Utils.selected_flock!.f_id);
    mortalityCount = await DatabaseHelper.getFlockMortalityCount(Utils.selected_flock!.f_id);
    cullingCount = await DatabaseHelper.getFlockCullingCount(Utils.selected_flock!.f_id);
    weightRecord = await DatabaseHelper.getLatestWeightRecord(Utils.selected_flock!.f_id);

    setState(() {

    });
  }

  List<String> flock_urls = [];
  Future<void> getFlockImagesFirestore(Flock flock, String farmId) async {
    final query = FirebaseFirestore.instance
        .collection(FireBaseUtils.FLOCK_IMAGES)
        .where('farm_id', isEqualTo: farmId)
        .where('f_sync_id', isEqualTo: flock.sync_id); // Use correct field name

    final snapshot = await query.get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final List<dynamic>? imageUrls = data['image_urls'];

      if (imageUrls != null && imageUrls.isNotEmpty) {
        flock_urls = imageUrls.cast<String>();
        print("🖼️ Flock Image URLs: $flock_urls");

        // TODO: Save URLs to SQLite or use them as needed
      } else {
        print("⚠️ No images found for flock: ${data['f_sync_id']}");
      }
    }

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

          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("delete_flocks"))
          {
            Utils.showMissingPermissionDialog(context, "delete_flocks");
            return;
          }

         showDeleteConfirmation(context);
        }
        else if(value == 2)
        {

          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("edit_flocks"))
            {
              Utils.showMissingPermissionDialog(context, "edit_flocks");

              return;
            }

         // showAlertDialog(context, Utils.selected_flock!.f_name);
          showEditFlockDialog(context, flock: Utils.selected_flock!, onSave: (flock) async {
            Utils.selected_flock = flock;
            await DatabaseHelper.updateFlockInfo(flock);

            await insertFlockImages(Utils.selected_flock!.f_id, Utils.selected_flock!.sync_id);
            Utils.selected_flock = await DatabaseHelper.getSingleFlock(Utils.selected_flock!.f_id!);
            getImages();
            // UPDATE ON SERVER
            if(Utils.isMultiUSer && Utils.hasFeaturePermission("edit_flocks")) {
              SyncManager().addModifiedId(flock.f_id.toString());
              flock.sync_status = SyncStatus.UPDATED;
              flock.modified_by = Utils.currentUser!.email;
              flock.last_modified = Utils.getTimeStamp();
              flock.farm_id = Utils.currentUser!.farmId;

              await FireBaseUtils.updateFlock(flock);
            }
            setState(() {

            });

            Navigator.pop(context);
          });

          if(Utils.isMultiUSer && Utils.hasFeaturePermission("edit_flocks")){
            getFlockImagesFirestore(Utils.selected_flock!, Utils.currentUser!.farmId);
          }else{

          }


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
        Utils.showToast("DONE");
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


  void _showAddMortalityDialog(BuildContext context) {
    final _countController = TextEditingController();
    final _noteController = TextEditingController();
    DateTime? selectedDate = DateTime.now();
    String selectedType = "MORTALITY"; // Default option

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Center(
                child: Text(
                  "Add".tr()+" ${selectedType.tr()}".tr(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 24),

              // Mortality or Culling selection
              Text(
                "Type".tr(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ["MORTALITY", "CULLING"].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.tr()),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedType = value!;
                },
              ),
              SizedBox(height: 20),

              // Count Field
              Text(
                "Enter Count".tr(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: "Enter Count".tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Date Picker
              Text(
                "Choose date".tr(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    selectedDate = pickedDate;
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedDate == null
                        ? "Choose date".tr()
                        : DateFormat('yyyy-MM-dd').format(selectedDate!),
                    style: TextStyle(fontSize: 16, color: selectedDate == null ? Colors.grey : Colors.black),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Note Field
              Text(
                "Notes".tr(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Notes".tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Save Button
              ElevatedButton.icon(
                onPressed: () async {
                  if (_countController.text.isEmpty || selectedDate == null) {
                    Utils.showToast("Please enter count and select date".tr());
                    return;
                  }
                  int count = int.tryParse(_countController.text) ?? 0;
                  String note = _noteController.text.trim();

                  if (count > 0 && count <= Utils.selected_flock!.active_bird_count!) {
                    int active_birds = Utils.selected_flock!.active_bird_count!;
                    active_birds = active_birds - count;
                    print(active_birds);

                    DatabaseHelper.updateFlockBirds(
                        active_birds, Utils.selected_flock!.f_id);


                    Flock_Detail reductionObject = Flock_Detail(
                      f_id: Utils.selected_flock!.f_id,
                      f_name: Utils.selected_flock!.f_name,
                      item_type: "Reduction",
                      item_count: count,
                      acqusition_type: selectedType, // "MORTALITY" or "CULLING"
                      acqusition_date: DateFormat('yyyy-MM-dd').format(selectedDate!),
                      reason: selectedType,
                      short_note: note,
                      transaction_id: '-1',
                      sync_id: Utils.getUniueId(),
                      sync_status: SyncStatus.SYNCED,
                      last_modified: Utils.getTimeStamp(),
                      modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                      farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
                      f_sync_id: Utils.selected_flock!.sync_id
                    );

                    DatabaseHelper.insertFlockDetail(reductionObject);

                    if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_birds")){
                      BirdsModification birdsModify = BirdsModification(flockDetail: reductionObject);
                      birdsModify.farm_id = Utils.currentUser!.farmId;
                      birdsModify.modified_by = Utils.currentUser!.email;

                      await FireBaseUtils.uploadBirdsDetails(birdsModify);

                      // UPDATE FLOCK
                      Flock? flock = Utils.selected_flock;
                      flock!.active_bird_count = active_birds;
                      flock.farm_id = Utils.currentUser!.farmId;
                      flock.last_modified = Utils.getTimeStamp();
                      flock.modified_by = Utils.currentUser!.email;
                      await FireBaseUtils.updateFlock(flock);

                    }

                    refreshData();
                    Navigator.pop(context);
                  } else {
                    Utils.showToast("Invalid ${selectedType.toLowerCase()} count");
                  }
                },
                icon: Icon(Icons.save, color: Colors.white),
                label: Text("SAVE".tr(), style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Utils.getThemeColorBlue(),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showMortalityRecordsDialog(BuildContext context, String reason) async {
    List<Flock_Detail> mortalityList = await DatabaseHelper.getMortalityRecords(Utils.selected_flock!.f_id,reason);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row with Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${reason.tr()}"+ "Records".tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 10),

              // Mortality List or Empty Message
              mortalityList.isEmpty
                  ? Expanded(
                child: Center(
                  child: Text(
                    "No Mortality Records Found".tr(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              )
                  : Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: mortalityList.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final mortality = mortalityList[index];
                    return Card(
                      color: Colors.grey[100],
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${"Count".tr()}: ${mortality.item_count}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "${"Date".tr()}: ${mortality.acqusition_date}",
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  if (mortality.short_note != null && mortality.short_note!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Text(
                                        "${"Note".tr()}: ${mortality.short_note}",
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => NewBirdsCollection(
                                              isCollection: false, flock_detail: mortality)),
                                    );
                                    refreshData();
                                    Navigator.pop(context);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    bool confirm = await showConfirmationDialog(context, "Delete this record?".tr());
                                    if (confirm) {
                                      int birds_to_del = mortality.item_count;
                                      int active_count = Utils.selected_flock!.active_bird_count!;
                                      active_count = active_count + birds_to_del;
                                      await DatabaseHelper.deleteItemWithFlockID("Flock_Detail", mortality.f_detail_id!);
                                      await DatabaseHelper.updateFlockBirds(active_count, Utils.selected_flock!.f_id);

                                      Utils.showToast("Deleted successfully");
                                      refreshData();
                                      Navigator.pop(context);
                                       // Refresh after delete
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  static Future<bool> showConfirmationDialog(BuildContext context, String message) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirmation".tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel".tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete".tr(), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
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

        if(Utils.isMultiUSer) {
          Utils.selected_flock!.sync_status = SyncStatus.DELETED;

          bool deleted = await FireBaseUtils.updateFlock(Utils.selected_flock!);
          if (deleted) {
            await DatabaseHelper.deleteFlockAndRelatedInfo(
                Utils.selected_flock!.f_id);
            Utils.selected_flock = null;
            Utils.showToast("RECORD_DELETED".tr());
            Navigator.pop(context);
            Navigator.pop(context);
          }else{
            Utils.showToast("Error_Deleting".tr());

          }
        }else{
          await DatabaseHelper.deleteFlockAndRelatedInfo(
              Utils.selected_flock!.f_id);
          Utils.selected_flock = null;
          Utils.showToast("RECORD_DELETED".tr());
          Navigator.pop(context);
          Navigator.pop(context);
        }
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

    if(Utils.isMultiUSer && Utils.hasFeaturePermission("delete_custom_category")){
      defaultcategories[index].sync_status = SyncStatus.DELETED;
      defaultcategories[index].last_modified = Utils.getTimeStamp();
      defaultcategories[index].modified_by = Utils.currentUser!.email;
      await FireBaseUtils.updateCustomCategory(defaultcategories[index]);
    }

    setState(() {
      defaultcategories.removeAt(index);
    });
  }

  Future<void> _toggleCategoryStatus(int index) async {
    defaultcategories[index].enabled = defaultcategories[index].enabled == 1? 0:1;
    await DatabaseHelper.updateCategory(defaultcategories[index]);

    if(Utils.isMultiUSer && Utils.hasFeaturePermission("edit_custom_category")){
      defaultcategories[index].sync_status = SyncStatus.UPDATED;
      defaultcategories[index].last_modified = Utils.getTimeStamp();
      defaultcategories[index].modified_by = Utils.currentUser!.email;
      await FireBaseUtils.updateCustomCategory(defaultcategories[index]);
    }

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
    TextEditingController dateController = TextEditingController(text: flock.acqusition_date.isNotEmpty ? flock.acqusition_date : "");

    List<String> _purposeList = ['EGG', 'MEAT', 'EGG_MEAT', 'OTHER'];
    List<String> _acquisitionList = ['PURCHASED', 'HATCHED', 'GIFT', 'OTHER'];

    String selectedAcquisition = flock.acqusition_type;
    String selectedPurpose = flock.purpose;

    base64Images.clear();
    imageFileList.clear();

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
              final List<XFile>? selectedImages = await _picker.pickMultiImage();

              if (selectedImages != null && selectedImages.isNotEmpty) {
                int remainingSlots = 5 - (byteimages.length + imageFileList.length);


                final imagesToAdd = selectedImages.take(remainingSlots).toList();
                imageFileList.addAll(imagesToAdd);

                print("Image List Length: ${imageFileList.length}");

                saveImagesDB();
                imagesAdded = true;

                setState(() {});
              }

            }

            void _removeImage(int index) {
              setState(() {
                imageFileList.removeAt(index);
                base64Images.removeAt(index);
              });

            }

            void _removeImageExisting(int index) async{
              print("DELETING "+images[index].id!.toString());
             int result =  await DatabaseHelper.deleteItem("Flock_Image", images[index].id!);
              if(flock_urls.length > 0){
                flock_urls.removeAt(index);
              }
             print("DELETED "+result.toString());
              setState(() {
                byteimages.removeAt(index);
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
                            flock = flock.copyWith(acqusition_date: formattedDate);
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
                            flock = flock.copyWith(acqusition_type: newValue);
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
                    (imageFileList.length + byteimages.length) < 5 ? SizedBox(
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

                    ) : SizedBox(width: 1,),

                    (imageFileList.length + byteimages.length) < 5 ? Text('Add 1-5 images', style: TextStyle(color: Colors.grey, ),) : SizedBox(width: 1,),

                    SizedBox(height: 12),

                    if (byteimages.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, // Two images per row
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 1,
                        ),
                        itemCount: byteimages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(byteimages[index], width: 80, height: 80,fit: BoxFit.cover,)
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImageExisting(index),
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
                                  File(imageFileList[index].path),
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
                              f_name: nameController.text,
                              notes: descController.text,
                            );
                          });
                          onSave(flock);
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


  Future<List<String>> getBase64Images(List<Flock_Image> images) async {

  List<String> oldImagesBase64 = [];

  for(int i=0;i<images.length;i++){
  oldImagesBase64.add(images.elementAt(i).image);
  }

  return oldImagesBase64;
  }

  List<XFile> imageFileList = [];
  void saveImagesDB() async {

    base64Images.clear();

    File file;
    for (int i=0;i<imageFileList.length;i++) {

      file = await Utils.convertToJPGFileIfRequiredWithCompression(File(imageFileList.elementAt(i).path));
      final bytes = File(file.path).readAsBytesSync();
      String base64Image =  base64Encode(bytes);
      base64Images.add(base64Image);

      print("img_pan : $base64Image");

    }
  }



  bool saving_images = false;
  List<String> base64Images = [];
  Future<void> insertFlockImages(int f_id, String? id) async {

    if(Utils.isMultiUSer){
      try {

        setState(() {
          saving_images = true;
        });
        List<Flock_Image> photos = await getSavedImages();
        List<String> oldPhoto = await getBase64Images(photos);

        MultiUser? user = await SessionManager.getUserFromPrefs();
        List<String> imageUrls = await FlockImageUploader().uploadFlockImages(
            farmId: user!.farmId, base64Images: base64Images);


        if(flock_urls.length == 0){
          List<String> imUrls = await FlockImageUploader().uploadFlockImages(
              farmId: user.farmId, base64Images: oldPhoto);
          imageUrls.addAll(imUrls);
        }else {
          imageUrls.addAll(flock_urls);
        }

        final firestore = FirebaseFirestore.instance;
        //final timestamp = FieldValue.serverTimestamp(); VALID ONLY FOR CREATION

        final imagesCollection = firestore
            .collection(FireBaseUtils.FLOCK_IMAGES)
            .doc("${user.farmId}_$id");

        //UPDATE URLS
       await FireBaseUtils.saveFlockImagesToFirestore(farmId: user.farmId, flockId: Utils.selected_flock!.sync_id!, imageUrls: imageUrls, uploadedBy: user.email);


        setState(() {
          saving_images = false;
        });

        if (base64Images.length > 0) {
          for (int i = 0; i < base64Images.length; i++) {
            Flock_Image image = Flock_Image(
              f_id: f_id, image: base64Images.elementAt(i),
              sync_id: Utils.getUniueId(),
              sync_status: SyncStatus.SYNCED,
              last_modified: Utils.getTimeStamp(),
              modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
              farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
            );
            DatabaseHelper.insertFlockImages(image);
          }

          print("Images Inserted");

        }

      }
      catch(ex){
        setState(() {
          saving_images = false;
        });
        Utils.showToast(ex.toString());
        print(ex);
      }
    } else {
      if (base64Images.length > 0) {
        for (int i = 0; i < base64Images.length; i++) {
          Flock_Image image = Flock_Image(
              f_id: f_id, image: base64Images.elementAt(i),
              sync_id: Utils.getUniueId(),
              sync_status: SyncStatus.SYNCED,
              last_modified: Utils.getTimeStamp(),
              modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
              farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : ''
          );

          DatabaseHelper.insertFlockImages(image);
        }

        print("Images Inserted");

      }
    }

  }


}

