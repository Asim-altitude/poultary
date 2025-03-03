import 'dart:async';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/pdf/pdf_screen.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'model/flock.dart';
import 'model/flock_detail.dart';
import 'model/flock_report_item.dart';

class BirdsReportsScreen extends StatefulWidget {
  const BirdsReportsScreen({Key? key}) : super(key: key);

  @override
  _BirdsReportsScreen createState() => _BirdsReportsScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _BirdsReportsScreen extends State<BirdsReportsScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }

  int _reports_filter = 2;
  void getFilters() async {

    _reports_filter = (await SessionManager.getReportFilter())!;
    date_filter_name = filterList.elementAt(_reports_filter);

    getData(date_filter_name);
  }

  @override
  void initState() {
    super.initState();
     try
     {

       date_filter_name = Utils.applied_filter;
       getFilters();
       getList();

     }
     catch(ex){
       print(ex);
     }
    Utils.setupAds();

  }

  List<Flock_Detail> list = [];
  List<String> flock_name = [];

  int egg_total = 0;
  List<FlockSummary> additionsSummary = [];
  List<ReductionByReason> reductionByReason = [];
  void getEggCollectionList() async {

    //ONCE CALLED
    await DatabaseHelper.instance.database;

    list = await DatabaseHelper.getFlockDetails();

    egg_total = list.length;

    setState(() {

    });

  }


  // Function to process reductions and return a list of ReductionByReason
  List<ReductionByReason> getReductionsByReason(List<Flock_Detail> flockDetails) {
    Map<String, int> reductionsByReason = {};

    for (var detail in flockDetails.where((f) => f.item_type == "Reduction")) {
      reductionsByReason[detail.reason] = (reductionsByReason[detail.reason] ?? 0) + detail.item_count;
    }

    return reductionsByReason.entries.map((e) => ReductionByReason(reason: e.key, totalCount: e.value)).toList();
  }

  int total_initial_flock_birds = 0;
  int total_flock_birds = 0;
  int total_birds_added = 0;
  int total_birds_reduced = 0;
  int current_birds = 0;



  void clearValues(){

    total_flock_birds = 0;
    total_birds_reduced = 0;
    total_birds_added = 0;
    current_birds = 0;
    list = [];

  }

  void getAllData() async {

    await DatabaseHelper.instance.database;

    clearValues();

    total_flock_birds = await DatabaseHelper.getAllFlockBirdsCount(f_id, str_date, end_date);

    total_birds_added = await DatabaseHelper.getBirdsCalculations(f_id, "Addition", str_date, end_date);

    total_birds_reduced = await DatabaseHelper.getBirdsCalculations(f_id, "Reduction", str_date, end_date);
    total_initial_flock_birds = await DatabaseHelper.getAllFlockInitialBirdsCount(f_id, str_date, end_date);
    print("Flock Initial Birds $total_initial_flock_birds");
    print("Flock Added Birds $total_birds_added");
    /* total_initial_flock_birds = await DatabaseHelper.getAllFlockInitialBirdsCount(f_id, str_date, end_date);

    total_flock_birds = total_flock_birds + total_birds_added;*/
    //total_birds_added = total_birds_added + total_flock_birds;
   // current_birds = total_birds_added - total_birds_reduced;
    current_birds = total_flock_birds;
    total_birds_added = total_birds_added + total_initial_flock_birds;
    print("Total Added Birds $total_birds_added");
    getFilteredBirds(str_date, end_date);

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
           color: Colors.white,
            child: SingleChildScrollViewWithStickyFirstWidget(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: 50,
                        height: 50,
                        child: InkWell(
                          child: Icon(Icons.arrow_back,
                              color: Colors.white, size: 30),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Expanded(
                        child: Container(
                            margin: EdgeInsets.only(left: 5),
                            child: Text(
                              "BIRDS".tr() +" "+"REPORT".tr(),
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            )),
                      ),
                      InkWell(
                        onTap: (){
                          Utils.setupInvoiceInitials("FLOCK_REPORT".tr(),pdf_formatted_date_filter);
                          Utils.flock_details = list;
                          prepareListData();

                          Utils.TOTAL_BIRDS_ADDED = total_birds_added.toString();
                          Utils.TOTAL_BIRDS_REDUCED = total_birds_reduced.toString();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>  PDFScreen(item: 0,)),
                          );
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          margin: EdgeInsets.only(right: 10),
                          child: Image.asset('assets/pdf_icon.png'),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              Row(
                children: [
                  /*Expanded(
                    child: Container(
                      height: 45,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(left: 10),
                      margin: EdgeInsets.only(top: 10,left: 10,right: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(
                            Radius.circular(5.0)),
                        border: Border.all(
                          color:  Utils.getThemeColorBlue(),
                          width: 1.0,
                        ),
                      ),
                      child: getDropDownList(),
                    ),
                  ),*/
                  InkWell(
                    onTap: () {
                      openDatePicker();
                    },
                    borderRadius: BorderRadius.circular(8), // Adds ripple effect with rounded edges
                    child: Container(
                      height: 45,
                      width: widthScreen - 20,
                      margin: EdgeInsets.only(right: 10,left: 10, top: 15, bottom: 10),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Utils.getThemeColorBlue().withOpacity(0.1), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Utils.getThemeColorBlue(),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, color: Utils.getThemeColorBlue(), size: 18),
                          SizedBox(width: 8),
                          Text(
                            date_filter_name.tr(),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_drop_down, color: Utils.getThemeColorBlue(), size: 20),
                        ],
                      ),
                    ),
                  )
                ],
              ),


              SizedBox(height: 10),

              _flockDateChart(),
              SizedBox(height: 10),

              Container(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.blue.shade50], // Subtle gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: Offset(0, 4), // Softer drop shadow
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔷 Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SUMMARY'.tr(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Utils.getThemeColorBlue(),
                            ),
                          ),
                          Icon(Icons.bar_chart, color: Utils.getThemeColorBlue()), // Chart icon
                        ],
                      ),
                      SizedBox(height: 12),

                      // 🐥 Total Added
                      _buildSummaryRow(
                        icon: Icons.add_circle,
                        label: 'TOTAL_ADDED'.tr(),
                        value: '$total_birds_added',
                        valueColor: Colors.green.shade700,
                      ),

                      Divider(color: Colors.grey[300], thickness: 0.8),

                      // ❌ Total Reduced
                      _buildSummaryRow(
                        icon: Icons.remove_circle,
                        label: 'TOTAL_REDUCED'.tr(),
                        value: '-$total_birds_reduced',
                        valueColor: Colors.red.shade700,
                      ),

                      Divider(color: Colors.grey[300], thickness: 0.8),

                      // 🏠 Current Birds (Highlighted)
                      _buildSummaryRow(
                        icon: Icons.pets,
                        label: 'CURRENT_BIRDS'.tr(),
                        value: '$current_birds',
                        valueColor: Colors.black,
                        isBold: true,
                        fontSize: 18,
                      ),

                      SizedBox(height: 15),

                      // 📊 Birds Added Per Flock Title
                      Text(
                        'By Flock'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Utils.getThemeColorBlue(),
                        ),
                      ),
                      SizedBox(height: 8),

                      // 🐥 Birds Added Per Flock List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: additionsSummary.length,
                        separatorBuilder: (context, index) => Divider(color: Colors.grey[300], thickness: 0.8),
                        itemBuilder: (context, index) {
                          FlockSummary summary = additionsSummary[index];

                          // Calculate percentage change
                          int netChange = summary.totalAdded - summary.totalReduced;
                          double percentageChange = summary.totalAdded > 0
                              ? (netChange / summary.totalAdded) * 100
                              : 0;

                          // Determine color based on net change
                          Color changeColor = netChange >= 0 ? Colors.green.shade700 : Colors.red.shade700;
                          String changeSymbol = netChange >= 0 ? '+' : ''; // Add "+" only for positive values

                          return ListTile(
                            leading: Icon(
                              netChange >= 0 ? Icons.trending_up : Icons.trending_down,
                              color: changeColor,
                              size: 28,
                            ),
                            title: Text(
                              summary.flockName,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  'Added'.tr()+': ${summary.totalAdded}  ',
                                  style: TextStyle(fontSize: 14, color: Colors.green.shade700),
                                ),
                                Text(
                                  'Reduced'.tr()+': ${summary.totalReduced}',
                                  style: TextStyle(fontSize: 14, color: Colors.red.shade700),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$changeSymbol${netChange}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: changeColor),
                                ),
                                Text(
                                  '(${percentageChange.toStringAsFixed(1)}%)',
                                  style: TextStyle(fontSize: 12, color: changeColor),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            'Reduction By Reason'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Utils.getThemeColorBlue(),
                            ),
                          ),
                          SizedBox(height: 8),

                          // Using `map()` inside Column with SingleChildScrollView
                          SingleChildScrollView(
                            child: Column(
                              children: reductionByReason.map((reduction) {
                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 4,
                                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.redAccent,
                                      child: Icon(Icons.trending_down, color: Colors.white),
                                    ),
                                    title: Text(
                                      reduction.reason.tr(),
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      "TOTAL".tr()+" ${reduction.totalCount}",
                                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      )


                    ],
                  ),
                ),
              ),


            ]
      ),),),),),);
  }

  /// 📌 **Reusable Summary Row**
  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    bool isBold = false,
    double fontSize = 16,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: valueColor, size: 22), // Icon for visual clarity
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void getFilteredBirds(String st,String end) async {

    await DatabaseHelper.instance.database;

    list = await DatabaseHelper.getFilteredFlockDetails(f_id,"All",st,end);
    try {
      List<Flock_Detail> additions = list.where((e) => e.item_type == "Addition").toList();
      List<Flock_Detail> reductions = list.where((e) => e.item_type == "Reduction").toList();

      // Group birds added by flock name
      Map<String, List<Flock_Detail>> additionsByFlock = groupBy(additions, (e) => e.f_name);
      Map<String, List<Flock_Detail>> reductionsByFlock = groupBy(reductions, (e) => e.f_name);

      // Merge additions and reductions into a single summary list
      Set<String> allFlockNames = {...additionsByFlock.keys, ...reductionsByFlock.keys};

      additionsSummary = allFlockNames.map((flockName) {
        int totalAdded = additionsByFlock[flockName]?.fold(0, (sum, e) => sum! + e.item_count) ?? 0;
        int totalReduced = reductionsByFlock[flockName]?.fold(0, (sum, e) => sum! + e.item_count) ?? 0;

        return FlockSummary(
          flockName: flockName,
          totalAdded: totalAdded,
          totalReduced: totalReduced, // Add this to FlockSummary model
        );
      }).toList();

      reductionByReason = getReductionsByReason(list);
      print("REDUCTION_LIST ${reductionByReason.length}");
      Utils.reductionByReason = reductionByReason;
    } catch (ex) {
      print(ex);
    }

    setState(() {

    });

  }

  //FILTER WORK
  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];
  void getList() async {

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr() ,bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1, flock_new: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
    }

    _purposeselectedValue = _purposeList[0];

    setState(() {

    });

  }

  int isCollection = 1;
  int selected = 1;
  int f_id = -1;


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
            getFlockID();
            getAllData();

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


  void openDatePicker() {
    showDialog(
        context: context,
        builder: (BuildContext bcontext) {
          return AlertDialog(
            title: Text('DATE_FILTER'.tr()),
            content: setupAlertDialoadContainer(bcontext,widthScreen - 40, widthScreen),
          );
        });
  }


  Widget setupAlertDialoadContainer(BuildContext bcontext,double width, double height) {

    return Container(
      height: filterList.length * 55, // Change as per your requirement
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

              Navigator.pop(bcontext);
              getData(date_filter_name);

            },
            child: ListTile(
              title: Text(filterList.elementAt(index).tr()),
            ),
          );
        },
      ),
    );
  }



  List<String> filterList = ['TODAY','YESTERDAY','THIS_MONTH', 'LAST_MONTH','LAST3_MONTHS', 'LAST6_MONTHS','THIS_YEAR',
    'LAST_YEAR','ALL_TIME','DATE_RANGE'];

  String date_filter_name = 'THIS_MONTH';
  String pdf_formatted_date_filter = 'THIS_MONTH';
  String str_date='',end_date='';
  void getData(String filter){
    int index = 0;

    if (filter == 'TODAY'){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = 'TODAY'.tr()+" ("+Utils.getFormattedDate(str_date)+")";

      getAllData();
    }
    else if (filter == 'YESTERDAY'){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "YESTERDAY".tr() + " ("+Utils.getFormattedDate(str_date)+")";
      getAllData();
    }
    else if (filter == 'THIS_MONTH'){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'THIS_MONTH'.tr()+" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'LAST_MONTH'){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'LAST_MONTH'.tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'LAST3_MONTHS'){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "LAST3_MONTHS".tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'LAST6_MONTHS'){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "LAST6_MONTHS".tr()+" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'THIS_YEAR'){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = 'THIS_YEAR'.tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'LAST_YEAR'){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'LAST_YEAR'.tr() +" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'ALL_TIME'){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'ALL_TIME';
      getAllData();
    }else if (filter == 'DATE_RANGE'){
     _pickDateRange();
    }


  }

  DateTimeRange? selectedDateRange;
  Future<void> _pickDateRange() async {
    DateTime now = DateTime.now();
    DateTime firstDate = DateTime(now.year - 5); // Allows past 5 years
    DateTime lastDate = DateTime(now.year + 5); // Allows future 5 years

    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: selectedDateRange ?? DateTimeRange(start: now, end: now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            hintColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Colors.blue),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      var inputFormat = DateFormat('yyyy-MM-dd');
      selectedDateRange = pickedRange;

      str_date = inputFormat.format(pickedRange.start);
      end_date = inputFormat.format(pickedRange.end);
      date_filter_name = Utils.getFormattedDate(str_date) +" | "+Utils.getFormattedDate(end_date);
      print(str_date+" "+end_date);
      getAllData();

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

  void prepareListData() async{


    List<Flock_Report_Item> list = [];
    int? added = 0,reduced = 0,init_flock_birds = 0,active_birds = 0,total_added =0,total_reduced=0;


    if(f_id == -1) {
      for (int i = 0; i < flocks.length; i++) {
        if (flocks
            .elementAt(i)
            .f_id != -1) {
          init_flock_birds = await DatabaseHelper.getAllFlockInitialBirdsCount(flocks
              .elementAt(i)
              .f_id, str_date, end_date);

          added = await DatabaseHelper.getBirdsCalculations(flocks
              .elementAt(i)
              .f_id, "Addition", str_date, end_date);

          reduced = await DatabaseHelper.getBirdsCalculations(flocks
              .elementAt(i)
              .f_id, "Reduction", str_date, end_date);

          list.add(Flock_Report_Item(f_name: flocks
              .elementAt(i)
              .f_name,
              date: flocks
                  .elementAt(i)
                  .acqusition_date,
              active_bird_count: flocks
                  .elementAt(i)
                  .active_bird_count,
              addition: (added + init_flock_birds),
              reduction: reduced));

           total_added = total_added! + init_flock_birds + added;
           total_reduced = total_reduced! + reduced;
          active_birds = active_birds! + flocks
              .elementAt(i)
              .active_bird_count!;
        }
      }
    }else{
      init_flock_birds = await DatabaseHelper.getAllFlockInitialBirdsCount(f_id, str_date, end_date);

      added = await DatabaseHelper.getBirdsCalculations(f_id, "Addition", str_date, end_date);

      reduced = await DatabaseHelper.getBirdsCalculations(f_id, "Reduction", str_date, end_date);

      Flock? f = await getSelectedFlock();

      list.add(Flock_Report_Item(f_name: f!.f_name,
          date: f
              .acqusition_date,
          active_bird_count: f
              .active_bird_count,
          addition: (added + init_flock_birds),
          reduction: reduced));

       total_added = total_added + init_flock_birds + added;
        total_reduced = total_reduced + reduced;
      active_birds = f
          .active_bird_count!;
    }
    Utils.TOTAL_ACTIVE_BIRDS = active_birds.toString();
    Utils.TOTAL_BIRDS_ADDED = total_added.toString();
    Utils.TOTAL_BIRDS_REDUCED = total_reduced.toString();
    Utils.flock_report_list = list;
   // Utils.INVOICE_DATE = Utils.getFormattedDate(str_date) + " - " + Utils.getFormattedDate(end_date);

  }

  Future<Flock?> getSelectedFlock() async {

    Flock? flock = null;

    for(int i=0;i<flocks.length;i++)
    {
      if(f_id == flocks.elementAt(i).f_id)
      {
        flock = flocks.elementAt(i);
        break;
      }
    }

    return flock;

  }

  /// 📊 **Chart 1: Grouped by Flock Name**
  Widget _flockNameChart() {
    final Map<String, int> flockSummary = {};
    for (var flock in list) {
      flockSummary.update(flock.f_name, (value) => value + flock.item_count, ifAbsent: () => flock.item_count);
    }

    final List<_ChartData> chartData = flockSummary.entries
        .map((entry) => _ChartData(entry.key, entry.value))
        .toList();

    return _buildChart(
      title: 'Flock Distribution',
      xAxisLabel: 'Flock Name',
      data: chartData,
      colorGradient: [Colors.blue.shade400, Colors.blue.shade700],
    );
  }

  /// 📊 **Chart 2: Grouped by Acquisition Date**
  Widget _flockDateChart() {
    final Map<String, num> additionSummary = {};
    final Map<String, num> reductionSummary = {};

// 🟢 Process Additions
    for (var flock in list) {
      if (flock.item_type == "Addition") {
        additionSummary.update(
          Utils.getFormattedDate(flock.acqusition_date),
              (value) => value + (flock.item_count ?? 0),
          ifAbsent: () => (flock.item_count ?? 0),
        );
      }
    }

// 🔴 Process Reductions
    for (var flock in list) {
      if (flock.item_type == "Reduction") {
        reductionSummary.update(
          Utils.getFormattedDate(flock.acqusition_date),
              (value) => value + (flock.item_count ?? 0),
          ifAbsent: () => (flock.item_count ?? 0),
        );
      }
    }

    // 🔄 Merge Data
    final List<_ChartData> additionData = additionSummary.entries
        .map((entry) => _ChartData(entry.key, entry.value))
        .toList();

    final List<_ChartData> reductionData = reductionSummary.entries
        .map((entry) => _ChartData(entry.key, entry.value))
        .toList();

    return _buildGroupedChart(
      title: 'Acqusition & Reduction Trends'.tr(),
      xAxisLabel: 'DATE'.tr(),
      additionData: additionData,
      reductionData: reductionData,
      additionColor: [Colors.green.shade400, Colors.green.shade700],
      reductionColor: [Colors.red.shade400, Colors.red.shade700],
    );
  }

  Widget _buildGroupedChart({
    required String title,
    required String xAxisLabel,
    required List<_ChartData> additionData,
    required List<_ChartData> reductionData,
    required List<Color> additionColor,
    required List<Color> reductionColor,
  }) {
    return SfCartesianChart(
      title: ChartTitle(text: title),
      legend: Legend(isVisible: true),
      primaryXAxis: CategoryAxis(
        title: AxisTitle(text: xAxisLabel),
        labelRotation: -45, // Rotate labels if they overlap
      ),
      primaryYAxis: NumericAxis(title: AxisTitle(text: 'Count')),

      // 🟢 Enable Chart Interaction
      tooltipBehavior: TooltipBehavior(enable: true, header: '', canShowMarker: false),
      selectionType: SelectionType.point,  // Allow selection
      selectionGesture: ActivationMode.singleTap, // Tap to select

      series: <CartesianSeries<_ChartData, String>>[
        // 🟢 Additions Series with Tap & Tooltip
        ColumnSeries<_ChartData, String>(
          name: 'Addition'.tr(),
          dataSource: additionData,
          xValueMapper: (data, _) => data.label,
          yValueMapper: (data, _) => data.value,
          color: additionColor.first,
          enableTooltip: true,

          // 🖱️ Enable selection
          isVisibleInLegend: true,
          onPointTap: (ChartPointDetails details) {
            print("🟢 Addition Clicked: ${additionData[details.pointIndex!].label}, Value: ${additionData[details.pointIndex!].value}");
          },
        ),

        // 🔴 Reductions Series with Tap & Tooltip
        ColumnSeries<_ChartData, String>(
          name: 'REDUCTION'.tr(),
          dataSource: reductionData,
          xValueMapper: (data, _) => data.label,
          yValueMapper: (data, _) => data.value,
          color: reductionColor.first,
          enableTooltip: true,

          // 🖱️ Enable selection
          isVisibleInLegend: true,
          onPointTap: (ChartPointDetails details) {
            print("🔴 Reduction Clicked: ${reductionData[details.pointIndex!].label}, Value: ${reductionData[details.pointIndex!].value}");
          },
        ),
      ],
    );
  }



  /// 📊 **Reusable Chart Builder**
  Widget _buildChart({
    required String title,
    required String xAxisLabel,
    required List<_ChartData> data,
    required List<Color> colorGradient,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 10,right: 10,top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          SfCartesianChart(
            plotAreaBorderWidth: 0,
            legend: Legend(isVisible: true, position: LegendPosition.bottom),
            tooltipBehavior: TooltipBehavior(enable: true),
            primaryXAxis: CategoryAxis(
              title: AxisTitle(text: xAxisLabel),
              labelRotation: 45, // Rotate labels for better readability
            ),
            primaryYAxis: NumericAxis(
              title: AxisTitle(text: 'Total Count'),
              minimum: 0,
            ),
            series: <CartesianSeries>[
              ColumnSeries<_ChartData, String>(
                name: 'Birds Addition',
                dataSource: data,
                xValueMapper: (_ChartData data, _) => data.label,
                yValueMapper: (_ChartData data, _) => data.value,
                dataLabelSettings: DataLabelSettings(isVisible: true),
                borderRadius: BorderRadius.circular(8), // Rounded corners
                gradient: LinearGradient(
                  colors: colorGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 📌 Helper Model for Chart Data
class _ChartData {
  final String label;
  final num value;

  _ChartData(this.label, this.value);
}

class FlockSummary {
  String flockName;
  int totalAdded;
  int totalReduced;

  FlockSummary({required this.flockName, required this.totalAdded, required this.totalReduced});
}

class ReductionByReason {
  String reason;
  int totalCount;

  ReductionByReason({required this.reason, required this.totalCount});
}


