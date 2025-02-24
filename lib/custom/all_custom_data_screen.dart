import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/model/custom_category.dart';
import '../database/databse_helper.dart';
import '../model/custom_category_data.dart';
import '../model/flock.dart';
import '../utils/utils.dart';
import 'add_custom_data.dart';

class CategoryDataListScreen extends StatefulWidget {

  CustomCategory? customCategory;
  CategoryDataListScreen({Key? key, required this.customCategory}) : super(key: key);

  @override
  _CustomCategoryListScreenState createState() => _CustomCategoryListScreenState();
}

class _CustomCategoryListScreenState extends State<CategoryDataListScreen> {
  late Future<List<CustomCategoryData>> _customCategories;
  int? selectedFlock;
  String? selectedType;
  List<String> categoryTypes = [];

  bool isEdit = false;
  @override
  void initState() {
    super.initState();

    if(widget.customCategory!= null){
      isEdit = true;
      selectedType = widget.customCategory!.cat_type;
    }

    _fetchData();
  }

  List<Flock> flocks = [];
  List<String> _purposeList = [];
  String _purposeselectedValue = "";
  Future<void> _fetchData() async {

    categoryTypes = (await DatabaseHelper.getUniqueCategoryTypes())!;
    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr(),bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1, flock_new: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
    }
    _purposeselectedValue = Utils.selected_flock!.f_name;
    selectedFlock = getFlockID();

    setState(() {
      _customCategories = DatabaseHelper.getCustomCategoriesData(selectedFlock,str_date,end_date, selectedType, sortSelected);
    });

  }


  Future<void> getCategoryDataList() async {

    setState(() {
      _customCategories = DatabaseHelper.getCustomCategoriesData(selectedFlock,str_date,end_date, selectedType, sortSelected);

    });
  }

  int getFlockID() {

    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue == flocks.elementAt(i).f_name){
        selectedFlock = flocks.elementAt(i).f_id;
        break;
      }
    }

    return selectedFlock!;
  }

  Future<void> _addNewCategory(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewCustomData(customCategoryData: null, customCategory: widget.customCategory!,)),);

    getCategoryDataList();

  }

  Future<void> _editCategory(BuildContext context,int index) async {
    List<CustomCategoryData> categories = await _customCategories;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewCustomData(customCategoryData: categories[index], customCategory: widget.customCategory!,)),
    );

    getCategoryDataList();

  }

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  Widget build(BuildContext context) {
    double safeAreaHeight =  MediaQuery.of(context).padding.top;
    double safeAreaHeightBottom =  MediaQuery.of(context).padding.bottom;
    widthScreen =
        MediaQuery.of(context).size.width; // because of default padding
    heightScreen = MediaQuery.of(context).size.height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery.of(context).size.height - (safeAreaHeight+safeAreaHeightBottom);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
                          widget.customCategory!.name,
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

                          getCategoryDataList();
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
                    margin: EdgeInsets.only(top: 10,left: 10,right: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(
                          Radius.circular(10.0)),
                      border: Border.all(
                        color:  Utils.getThemeColorBlue(),
                        width: 1.0,
                      ),
                    ),
                    child: getDropDownList(),
                  ),
                ),
                InkWell(
                    onTap: () {
                      openDatePicker(context);
                    },
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.all(
                              Radius.circular(10.0)),
                          border: Border.all(
                            color:  Utils.getThemeColorBlue(),
                            width: 1.0,
                          ),
                        ),
                        margin: EdgeInsets.only(right: 10,top: 15,bottom: 5),
                        padding: EdgeInsets.only(left: 5,right: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(date_filter_name, style: TextStyle(fontSize: 14),),
                            Icon(Icons.arrow_drop_down, color: Utils.getThemeColorBlue(),),
                          ],
                        ),
                      ),
                    )),
              ],
            ),

            Expanded(
              child: FutureBuilder<List<CustomCategoryData>>(
                future: _customCategories,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No data available"));
                  }
        
                  final data = snapshot.data!;
        
                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
        
                      return Card(
                        margin: EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 3,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              /// **Title & Menu (Aligned in Same Row)**
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  /// **Title (Bold & Larger)**
                                  Expanded(
                                    child: Text(
                                      item.fName,
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  /// **Menu Icon**
                                  GestureDetector(
                                    onTapDown: (TapDownDetails details) async {
                                      showMemberMenu(details.globalPosition);
                                    },
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.shade200,
                                      ),
                                      child: Image.asset('assets/options.png', fit: BoxFit.contain),
                                    ),
                                  ),
                                ],
                              ),

                              /// **Divider for separation**
                              Divider(thickness: 1, color: Colors.grey.shade300),

                              SizedBox(height: 6),

                              /// **Date Row**
                              Row(
                                children: [
                                  Icon(Icons.calendar_month, size: 18, color: Colors.blueGrey),
                                  SizedBox(width: 6),
                                  Text(
                                    Utils.getFormattedDate(item.date),
                                    style: TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                ],
                              ),

                              SizedBox(height: 6),

                              /// **Quantity Row**
                              Row(
                                children: [
                                  Icon(Icons.production_quantity_limits_outlined, size: 18, color: Colors.green),
                                  SizedBox(width: 6),
                                  Text(
                                    "${item.quantity} ${item.unit.tr()}",
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                ],
                              ),

                              SizedBox(height: 6),

                              /// **Notes Row**
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.notes, size: 18, color: Colors.orangeAccent),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.note.isNotEmpty ? item.note : "NO_NOTES".tr(),
                                      style: TextStyle(fontSize: 14, color: Colors.black87),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );

                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewCategory(context),
        child: Icon(Icons.add),
      ),
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

            getCategoryDataList();
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
            "DELETE_RECORD".tr(),
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
        if(value == 2)
        {
          _editCategory(context, selected_index!);
        }
        else if(value == 1){
          showAlertDialog(context);
        }else {
          print(value);
        }
      }
    });
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
        print('DELETED');
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


  DateTimeRange? selectedDateRange;

  Future<void> _selectDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
    }
  }

  List<String> filterList = ['TODAY'.tr(),'YESTERDAY'.tr(),'THIS_MONTH'.tr(), 'LAST_MONTH'.tr(),'LAST3_MONTHS'.tr(), 'LAST6_MONTHS'.tr(),'THIS_YEAR'.tr(),
    'LAST_YEAR'.tr(),'ALL_TIME'.tr()];

  String date_filter_name = 'THIS_MONTH'.tr();
  String pdf_formatted_date_filter = 'THIS_MONTH'.tr();
  String str_date='',end_date='';
  void getData(String filter, BuildContext context){
    int index = 0;

    if (filter == 'TODAY'.tr()){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "Today ("+str_date+")";
    }
    else if (filter == 'YESTERDAY'.tr()){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "YESTERDAY".tr() + " ("+str_date+")";

    }
    else if (filter == 'THIS_MONTH'.tr()){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "This Month ("+str_date+"-"+end_date+")";
    }else if (filter == 'LAST_MONTH'.tr()){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'LAST_MONTH'.tr()+ " ("+str_date+"-"+end_date+")";

    }else if (filter == 'LAST3_MONTHS'.tr()){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "LAST3_MONTHS".tr()+ " ("+str_date+"-"+end_date+")";
    }else if (filter == 'LAST6_MONTHS'.tr()){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "LAST6_MONTHS".tr()+" ("+str_date+"-"+end_date+")";
    }else if (filter == 'THIS_YEAR'.tr()){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = 'THIS_YEAR'.tr()+ " ("+str_date+"-"+end_date+")";
    }else if (filter == 'LAST_YEAR'.tr()){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'LAST_YEAR'.tr() +" ("+str_date+"-"+end_date+")";

    }else if (filter == 'ALL_TIME'.tr()){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = 'ALL_TIME'.tr();

    }

      getCategoryDataList();

  }


  String filter_name = "All";
  void openDatePicker(BuildContext context) {
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

              getData(date_filter_name,bcontext);
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


}
