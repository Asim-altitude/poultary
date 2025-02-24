import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/add_birds.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:poultary/view_transaction.dart';
import 'database/databse_helper.dart';
import 'model/flock.dart';
import 'model/flock_detail.dart';

class AddReduceFlockScreen extends StatefulWidget {

  AddReduceFlockScreen({Key? key}) : super(key: key);

  @override
  _AddReduceFlockScreen createState() => _AddReduceFlockScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _AddReduceFlockScreen extends State<AddReduceFlockScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;


  @override
  void dispose() {
    super.dispose();

  }

  int _other_filter = 2;
  void getFilters() async {

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr(),bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1, flock_new: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
    }
    _purposeselectedValue = Utils.selected_flock!.f_name;
    f_id = getFlockID();
    _other_filter = (await SessionManager.getOtherFilter())!;
    date_filter_name = filterList.elementAt(_other_filter);

    addNewColumn();

    getData(date_filter_name);

   }

   void addNewColumn() async{
    try{
      int c = await DatabaseHelper.addColumnInFlockDetail();
      print("Column Info $c");
    }catch(ex){
      print(ex);
    }

    try{
      int c = await DatabaseHelper.addColumnInFTransactions();
      print("Column Info $c");
    }catch(ex){
      print(ex);
    }

    try{
      int? c = await DatabaseHelper.updateLinkedFlocketailNullValue();
      print("Flock Details Update Info $c");

      int? t = await DatabaseHelper.updateLinkedTransactionNullValue();
      print("Transactions Update Info $t");
    }catch(ex){
      print(ex);
    }
   }

  @override
  void initState() {
    super.initState();

    getFilters();

    Utils.setupAds();

  }

  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];

  int selected = 1;
  int f_id = -1;

  bool no_colection = true;
  List<Flock_Detail> list = [];
  List<String> flock_name = [];

  void getEggCollectionList() async {

    await DatabaseHelper.instance.database;

    list = await DatabaseHelper.getFlockDetails();
    egg_total = list.length;

    setState(() {

    });

  }

  int egg_total = 0;

  String applied_filter_name = "All Additions/Reductions";

  @override
  Widget build(BuildContext context) {

    double safeAreaHeight =  MediaQuery.of(context).padding.top;
    double safeAreaHeightBottom =  MediaQuery.of(context).padding.bottom;
    widthScreen =
        MediaQuery.of(context).size.width; // because of default padding
    heightScreen = MediaQuery.of(context).size.height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery.of(context).size.height - (safeAreaHeight+safeAreaHeightBottom);

    return SafeArea(child: Scaffold(
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Container(
          height: 65,
          width: widthScreen,
          child: Row(
            children: [
              /// Add Birds Button
              Expanded(
                child: InkWell(
                  onTap: () => addNewCollection(),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: 55,
                    margin: EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade700, Colors.green.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline_sharp, color: Colors.white, size: 28),
                        SizedBox(width: 6),
                        Text(
                          'ADD_BIRDS'.tr(),
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// Reduce Birds Button
              Expanded(
                child: InkWell(
                  onTap: () => reduceCollection(),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: 55,
                    margin: EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade700, Colors.red.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_circle_outline, color: Colors.white, size: 28),
                        SizedBox(width: 6),
                        Text(
                          'REDUCE_BIRDS'.tr(),
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        elevation: 0,
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

              ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Utils.getThemeColorBlue().withOpacity(0.9), Utils.getThemeColorBlue()],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      /// Back Button
                      InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        ),
                      ),

                      /// Title
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(left: 12),
                          child: Text(
                            applied_filter_name.tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      /// Sort Button
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          openSortDialog(context, (selectedSort) {
                            setState(() {
                              sortOption = selectedSort == "date_desc" ? "Date (New)" : "Date (Old)";
                              sortSelected = selectedSort == "date_desc" ? "DESC" : "ASC";
                            });

                            getFilteredTransactions(str_date, end_date);
                          });
                        },
                        child: Container(
                          height: 45,
                          width: 130,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  sortOption.tr(),
                                  style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.sort, color: Colors.white, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 45,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(left: 10),
                      margin: EdgeInsets.only(top: 10, left: 10, right: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Utils.getThemeColorBlue(),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                      child: getDropDownList(),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      openDatePicker();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Utils.getThemeColorBlue(),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                      margin: EdgeInsets.only(right: 10, top: 15, bottom: 5),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            date_filter_name,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          Icon(Icons.arrow_drop_down, color: Utils.getThemeColorBlue()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              /// Attractive Filter Buttons
              Container(
                height: 50,
                width: widthScreen,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  children: [
                    buildFilterButton('All', 1),
                    buildFilterButton('Addition', 2),
                    buildFilterButton('Reduction', 3),
                  ],
                ),
              ),

              list.length > 0 ? Container(
                height: heightScreen - 290,
                width: widthScreen,
                child: ListView.builder(
                  itemCount: list.length,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemBuilder: (BuildContext context, int index) {
                    var item = list[index];
                    bool hasTransaction = item.transaction_id != "-1";

                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// **Header: Name + Menu Icon**
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.f_name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),

                                /// **Menu Icon**
                               !hasTransaction? GestureDetector(
                                  onTapDown: (TapDownDetails details) {
                                    selected_id = item.f_detail_id;
                                    selected_index = index;
                                    showMemberMenu(details.globalPosition);
                                  },
                                  child: Icon(Icons.more_vert, color: Colors.black54),
                                ):SizedBox(height: 1,),
                              ],
                            ),
                            SizedBox(height: 10),

                            /// **Bird Count with Addition/Reduction Label**
                            Row(
                              children: [
                                Image.asset("assets/bird_icon.png", width: 30, height: 30),
                                SizedBox(width: 6),
                                Text(
                                  "${item.item_count} "+"BIRDS".tr(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: item.item_type == 'Reduction'
                                        ? Colors.red.withOpacity(0.15)
                                        : Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.item_type.tr(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: item.item_type == 'Reduction' ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),

                            /// **Date Positioned Properly Below Birds Count**
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.blueGrey),
                                SizedBox(width: 6),
                                Text(
                                  Utils.getFormattedDate(item.acqusition_date.toString()),
                                  style: TextStyle(fontSize: 14, color: Colors.black54),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),

                            /// **Reason / Acquisition Type**
                            Text(
                              item.item_type == 'Reduction' ? item.reason.toString().tr() : item.acqusition_type.toString().tr(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueAccent,
                              ),
                            ),
                            SizedBox(height: 12),

                            /// **Notes Section**
                            if (item.short_note.isNotEmpty)
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.notes, size: 18, color: Colors.black54),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.short_note,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 14, color: Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(height: 12),

                            /// **Action Button (View Details)**
                            if (hasTransaction)
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () async {
                                    selected_id = item.f_detail_id;
                                    selected_index = index;
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ViewCompleteTransaction(
                                          transaction_id: item.transaction_id,
                                          isTransaction: false,
                                        ),
                                      ),
                                    );
                                    getData(date_filter_name);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.visibility, size: 18, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text(
                                          "View Details".tr(),
                                          style: TextStyle(fontSize: 14, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
                    : Utils.getCustomEmptyMessage("assets/add_reduce_.png", "NO_BIRDS_ADD_REDUCE")


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

  /// **Filter Button Builder**
  Widget buildFilterButton(String label, int id) {
    bool isSelected = selected == id;
    return Expanded(
      child: InkWell(
        onTap: () {
          selected = id;
          filter_name = label;
          getFilteredTransactions(str_date, end_date);
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              colors: [Utils.getThemeColorBlue().withOpacity(0.9), Utils.getThemeColorBlue()],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isSelected ? Utils.getThemeColorBlue() : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: id == 1 ? Radius.circular(10) : Radius.zero,
              bottomLeft: id == 1 ? Radius.circular(10) : Radius.zero,
              topRight: id == 3 ? Radius.circular(10) : Radius.zero,
              bottomRight: id == 3 ? Radius.circular(10) : Radius.zero,
            ),
            border: Border.all(
              color: Utils.getThemeColorBlue(),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Utils.getThemeColorBlue().withOpacity(0.3),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ]
                : [],
          ),
          child: Text(
            label.tr(),
            style: TextStyle(
              color: isSelected ? Colors.white : Utils.getThemeColorBlue(),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }



  Future<void> addNewCollection() async{
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewBirdsCollection(isCollection: true,flock_detail: null)),
    );

    getData(date_filter_name);
    ;
  }

  Future<void> reduceCollection() async{
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>  NewBirdsCollection(isCollection: false,flock_detail: null)),
    );

    getData(date_filter_name);
  }


  Widget getDropDownList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _purposeselectedValue,
        elevation: 10,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _purposeselectedValue = newValue!;

            Utils.SELECTED_FLOCK = _purposeselectedValue;
            Utils.SELECTED_FLOCK_ID = getFlockID();
            getFilteredTransactions(str_date, end_date);

          });
        },
        items: _purposeList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String filter_name = "All";
  void openDatePicker() {
    showDialog(
        context: context,
        builder: (BuildContext bcontext) {
          return AlertDialog(
            title: Text("DATE_FILTER".tr()),
            content: setupAlertDialoadContainer(bcontext,widthScreen - 40, widthScreen),
          );
        });
  }
  Widget setupAlertDialoadContainer(BuildContext bcontext,double width, double height) {

    return Container(
      height: height, // Change as per your requirement
      width: width, // Change as per your requirement
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: filterList.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () {

              setState(() {
                date_filter_name = filterList.elementAt(index);
              });

              getData(date_filter_name);
              Navigator.pop(bcontext);
            },
            child: ListTile(
              title: Text(filterList.elementAt(index)),
            ),
          );
        },
      ),
    );
  }

  void getFilteredTransactions(String st,String end) async {

    await DatabaseHelper.instance.database;


    list = await DatabaseHelper.getFilteredFlockDetailsWithSort(f_id,filter_name,st,end,sortSelected);


    setState(() {

    });

  }


  List<String> filterList = ['TODAY'.tr(),'YESTERDAY'.tr(),'THIS_MONTH'.tr(), 'LAST_MONTH'.tr(),'LAST3_MONTHS'.tr(), 'LAST6_MONTHS'.tr(),'THIS_YEAR'.tr(),
    'LAST_YEAR'.tr(),'ALL_TIME'.tr()];

  String date_filter_name = 'THIS_MONTH'.tr();
  String pdf_formatted_date_filter = 'THIS_MONTH'.tr();
  String str_date='',end_date='';
  void getData(String filter){
    int index = 0;

    if (filter == 'TODAY'.tr()){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "Today ("+str_date+")";
      getFilteredTransactions(str_date,end_date);
    }
    else if (filter == 'YESTERDAY'.tr()){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "YESTERDAY".tr() + " ("+str_date+")";
      getFilteredTransactions(str_date,end_date);
    }
    else if (filter == 'THIS_MONTH'.tr()){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = "This Month ("+str_date+"-"+end_date+")";
    }else if (filter == 'LAST_MONTH'.tr()){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = 'LAST_MONTH'.tr()+ " ("+str_date+"-"+end_date+")";

    }else if (filter == 'LAST3_MONTHS'.tr()){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = "LAST3_MONTHS".tr()+ " ("+str_date+"-"+end_date+")";
    }else if (filter == 'LAST6_MONTHS'.tr()){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = "LAST6_MONTHS".tr()+" ("+str_date+"-"+end_date+")";
    }else if (filter == 'THIS_YEAR'.tr()){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);
      pdf_formatted_date_filter = 'THIS_YEAR'.tr()+ " ("+str_date+"-"+end_date+")";
    }else if (filter == 'LAST_YEAR'.tr()){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = 'LAST_YEAR'.tr() +" ("+str_date+"-"+end_date+")";

    }else if (filter == 'ALL_TIME'.tr()){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date,end_date);

      pdf_formatted_date_filter = 'ALL_TIME'.tr();
    }

  }

  int getFlockID() {

    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue == flocks.elementAt(i).f_name){
        f_id = flocks.elementAt(i).f_id;
        break;
      }
    }

    return f_id;
  }


  //RECORD DELETEION AND PDF

  int? selected_id = 0;
  int? selected_index = 0;
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
            "EDIT_RECORD".tr(),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ), PopupMenuItem(
          value: 1,
          child: Text(
            list.elementAt(selected_index!).transaction_id!= "-1" ? "VIEW_RECORD".tr() : "DELETE_RECORD".tr(),
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
        if(value == 2){
          if(list.elementAt(selected_index!).item_type == "Addition") {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      NewBirdsCollection(isCollection: true,
                          flock_detail: list.elementAt(selected_index!))),
            );

            getData(date_filter_name);

          }else{
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      NewBirdsCollection(isCollection: false,
                          flock_detail: list.elementAt(selected_index!))),
            );

            getData(date_filter_name);

          }
        }
        else if(value == 1){
          if(list.elementAt(selected_index!).transaction_id != "-1")
          {
            // View Complete Record

            print(selected_index);
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>  ViewCompleteTransaction(transaction_id: list.elementAt(selected_index!).transaction_id, isTransaction: false,)),
            );

            getData(date_filter_name);
          }
          else
          {
            showAlertDialog(context);
          }
        }else {
          print(value);
        }
      }
    });
  }

  showCautionDialog(BuildContext context) {

    // set up the buttons

    Widget continueButton = TextButton(
      child: Text("VIEW_INFO".tr()),
      onPressed:  () async {

      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("INFO".tr()),
      content: Text("MULTIPLE_OPERATIONS".tr()),
      actions: [
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


  showAlertDialog(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("CANCEL".tr()),
      onPressed:  () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text("DELETE".tr()),
      onPressed:  () async {
        if(list.elementAt(selected_index!).f_id != -1) {

          if(list.elementAt(selected_index!).transaction_id != "-1"){
            if(list.elementAt(selected_index!).transaction_id.contains(","))
            {
              /*Flock flock = await DatabaseHelper
                    .getSingleFlock(list.elementAt(selected_index!).f_id);
                int active_birds = */

            }else{

              await DatabaseHelper.deleteItem("Transactions",int.parse(list
                  .elementAt(selected_index!).transaction_id));

              int birds_to_delete = list
                  .elementAt(selected_index!)
                  .item_count;
              Flock? flock = await DatabaseHelper
                  .getSingleFlock(list
                  .elementAt(selected_index!)
                  .f_id);
              int current_birds = flock!.active_bird_count!;

              if (list
                  .elementAt(selected_index!)
                  .item_type == "Addition")
                current_birds = current_birds - birds_to_delete;
              else
                current_birds = current_birds + birds_to_delete;

              await DatabaseHelper.updateFlockBirds(
                  current_birds, list
                  .elementAt(selected_index!)
                  .f_id);
            }
          }else {
            int birds_to_delete = list
                .elementAt(selected_index!)
                .item_count;
            Flock? flock = await DatabaseHelper
                .getSingleFlock(list
                .elementAt(selected_index!)
                .f_id);
            int current_birds = flock!.active_bird_count!;

            if (list
                .elementAt(selected_index!)
                .item_type == "Addition")
              current_birds = current_birds - birds_to_delete;
            else
              current_birds = current_birds + birds_to_delete;

            await DatabaseHelper.updateFlockBirds(
                current_birds, list
                .elementAt(selected_index!)
                .f_id);
          }

        }
        DatabaseHelper.deleteItemWithFlockID("Flock_Detail", selected_id!);
        list.removeAt(selected_index!);
        Utils.showToast("RECORD_DELETED".tr());
        Navigator.pop(context);
        setState(() {

        });

      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("CONFIRMATION".tr()),
      content: Text("RU_SURE".tr()),
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

  String sortSelected = "DESC"; // Default label
  String sortOption = "Date (New)";
  void openSortDialog(BuildContext context, Function(String) onSortSelected) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Sort By".tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Divider(),
              ListTile(
                title: Text("Date (New)".tr()),
                onTap: () {
                  onSortSelected("date_desc");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text("Date (Old)".tr()),
                onTap: () {
                  onSortSelected("date_asc");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }


}

