
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'birds_report_screen.dart';
import 'eggs_report_screen.dart';
import 'feed_report_screen.dart';
import 'financial_report_screen.dart';
import 'health_report_screen.dart';
import 'model/feed_item.dart';
import 'model/flock.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreen createState() => _ReportsScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _ReportsScreen extends State<ReportsScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }


  @override
  void initState() {
    super.initState();
     try
     {
       getFilters();

       getList();
     }
     catch(ex){
       print(ex);
     }
    Utils.setupAds();

  }

  int _reports_filter = 2;
  void getFilters() async {

    _reports_filter = (await SessionManager.getReportFilter())!;
    date_filter_name = filterList.elementAt(_reports_filter);

    print("SELECTED_FILTER $date_filter_name");
    print("SELECTED_FILTER_INDEX $_reports_filter");

    getData(_reports_filter);
  }

  int total_flock_birds = 0;
  int total_birds_added = 0;
  int total_birds_reduced = 0;
  int current_birds = 0;


  num gross_income = 0;
  num total_expense = 0;
  num net_income = 0;

  int vac_count = 0;
  int med_count = 0;
  int total_health_count = 0;

  int total_eggs_collected = 0;
  int total_eggs_reduced = 0;
  int total_eggs = 0;

  num total_feed_consumption = 0;


  void clearValues(){

    total_flock_birds = 0;
    total_birds_reduced = 0;
    total_birds_added = 0;
    current_birds = 0;
    total_eggs_reduced =0;
    total_eggs_collected =0;
    total_eggs =0;

    gross_income = 0;
    total_expense =0;
    net_income =0;

  }

  List<Feeding> feedings = [];

  void getAllData() async {

    print(date_filter_name);
    print("START_DATE $str_date END_DATE $end_date");
    print("REPORT_FILTER $_reports_filter");

    clearValues();

    total_flock_birds = await DatabaseHelper.getAllFlockBirdsCount(f_id, str_date, end_date);

    total_birds_added = await DatabaseHelper.getBirdsCalculations(f_id, "Addition", str_date, end_date);

    total_birds_reduced = await DatabaseHelper.getBirdsCalculations(f_id, "Reduction", str_date, end_date);

    total_birds_added = total_birds_added + total_flock_birds;
    current_birds = total_birds_added - total_birds_reduced;

    total_eggs_collected = await DatabaseHelper.getEggCalculations(f_id, 1, str_date, end_date);

    total_eggs_reduced = await DatabaseHelper.getEggCalculations(f_id, 0, str_date, end_date);

    total_eggs = total_eggs_collected - total_eggs_reduced;

    feedings = await DatabaseHelper.getTopMostUsedFeeds(f_id, str_date, end_date);

    total_feed_consumption = await DatabaseHelper.getTotalFeedConsumption(f_id, str_date, end_date);

    gross_income = await DatabaseHelper.getTransactionsTotal(f_id, "Income", str_date, end_date);
    total_expense = await DatabaseHelper.getTransactionsTotal(f_id, "Expense", str_date, end_date);

    net_income = gross_income - total_expense;

    vac_count = await DatabaseHelper.getHealthTotal(f_id, "Vaccination", str_date, end_date);
    med_count = await DatabaseHelper.getHealthTotal(f_id, "Medication", str_date, end_date);

    total_health_count = med_count + vac_count;


    gross_income = num.parse(gross_income.toStringAsFixed(2));
    total_expense = num.parse(total_expense.toStringAsFixed(2));
    net_income = num.parse(net_income.toStringAsFixed(2));
    total_feed_consumption = num.parse(total_feed_consumption.toStringAsFixed(2));

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
                        color: Utils.getThemeColorBlue(),
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
                          child: Container(
                              width: 25,
                              height: 25,
                              child: Image.asset("assets/income.png", color: Colors.white,)),
                          onTap: () {
                            // Navigator.pop(context);
                          },
                        ),
                      ),
                      Expanded(
                        child: Container(
                            margin: EdgeInsets.only(left: 5),
                            child: Text(
                              "ALL_REPORTS".tr(),
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            )),
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
                      margin: EdgeInsets.only(top: 10,left: 12,right: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(
                            Radius.circular(5.0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 2,
                            offset: Offset(0, 1), // changes position of shadow
                          ),
                        ],
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
                        openDatePicker();
                      },
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.all(
                                Radius.circular(5.0)),
                            border: Border.all(
                              color:  Utils.getThemeColorBlue(),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 2,
                                offset: Offset(0, 1), // changes position of shadow
                              ),
                            ],
                          ),
                          margin: EdgeInsets.only(right: 12,top: 15,bottom: 5),
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

              Container(
                padding: EdgeInsets.only(bottom: 30,right: 10,left: 10),
                decoration: BoxDecoration(
                  // borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  color: Colors.white,
                 /* boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 2,
                      offset: Offset(0, 1), // changes position of shadow
                    ),
                  ],*/

                ),
                child: Column(
                  children: [
                    Visibility(
                      visible: false,
                      child: InkWell(
                        onTap: () {
                          openDatePicker();
                        },
                        child: Container(
                          width: widthScreen,
                          margin: EdgeInsets.all(5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Icon(Icons.keyboard_arrow_left, color: Colors.white70,),
                              Container(
                                  margin: EdgeInsets.only(left: 5, right: 5),
                                  child:Text(date_filter_name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),)),
                              Icon(Icons.keyboard_arrow_right, color: Colors.white70,),
                            ],),
                        ),
                      ),
                    ),
                    Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                            color: Utils.getThemeColorBlue(),
                            border: Border.all(color: Colors.white38,width: 1.0)
                        ),
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.only(top: 10),
                        child: InkWell(onTap : () async{
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const FinanceReportsScreen()),
                          );
                          getData(_reports_filter);
                        },child: Column(
                          children: [

                            Row(
                              /* mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,*/
                              children: [
                                Image.asset("assets/finance_icon.png", color: Colors.white, width: 40, height: 40,),
                                Text(" "+"Financial Report".tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),),
                              ],
                            ),

                            SizedBox(height: 5,),
                            Text(net_income>=0?Utils.currency+'$net_income' : "-"+Utils.currency+"${-net_income}",style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: net_income>=0? Colors.white : Colors.red),),
                            Text("NET_INCOME".tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70),),
                            SizedBox(height: 5,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(child: getDashboardDataBox(Colors.white12, "Income".tr(), '$gross_income', Icons.arrow_upward,Colors.green)),
                                Expanded(child: getDashboardDataBox(Colors.white12, "Expense".tr(), '$total_expense', Icons.arrow_downward, Colors.pink)),

                              ],
                            ),
                          ],
                        ))),
                    Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                            //  color: Colors.white10.withAlpha(30),
                            color: Utils.getThemeColorBlue(),

                            border: Border.all(color: Colors.white38,width: 1.0)
                        ),
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.only(top: 10),
                        child: InkWell(onTap : () async{
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const BirdsReportsScreen()),
                          );
                          getData(_reports_filter);
                        },child: Column(
                          children: [

                            Row(
                              /* mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,*/
                              children: [
                                Image.asset("assets/bird_icon.png", color: Colors.white, width: 40, height: 40,),
                                Text(" "+"BIRDS_SUMMARY".tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),),
                              ],
                            ),

                        /*    SizedBox(height: 5,),
                            Text('$current_birds',style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),),
                            Text("CURRENT_BIRDS".tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70),),
                       */     SizedBox(height: 5,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [

                                Expanded(child: getCustomDataBox(Colors.white12, "TOTAL_ADDED".tr(), '$total_birds_added', '','')),
                                Expanded(child: getCustomDataBox(Colors.white12, "TOTAL_REDUCED".tr(), '$total_birds_reduced', '','')),
                                Expanded(child: getCustomDataBox(Colors.white12, "CURRENT_BIRDS".tr(), '$current_birds', '','')),

                              ],
                            ),
                          ],
                        ))),
                    Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        //  color: Colors.white10.withAlpha(30),
                            color: Utils.getThemeColorBlue(),

                            border: Border.all(color: Colors.white38,width: 1.0)
                        ),
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.only(top: 10),
                      child: InkWell(onTap : () async{
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const EggsReportsScreen()),
                      );
                      getAllData();
                    },child: Column(
                      children: [

                        Row(
                         /* mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,*/
                          children: [
                            Image.asset("assets/eggs_count.png", color: Colors.white, width: 40, height: 40,),
                            Text(" "+"EGG_COLLECTION".tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),),
                           ],
                        ),
                       
                        /*SizedBox(height: 5,),
                        Text('$total_eggs',style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),),
                        Text("Remaining Eggs".tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70),),
                        SizedBox(height: 5,),*/
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                            Expanded(child: getCustomDataBox(Colors.white12, "TOTAL_ADDED".tr(), '$total_eggs_collected', '','')),
                            Expanded(child: getCustomDataBox(Colors.white12, "TOTAL_REDUCED".tr(), '$total_eggs_reduced', '','')),
                            Expanded(child: getCustomDataBox(Colors.white12, "Remaining".tr(), '$total_eggs', '','')),

                            ],
                        ),
                      ],
                    ))),
                    Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                            //  color: Colors.white10.withAlpha(30),
                            color: Utils.getThemeColorBlue(),

                            border: Border.all(color: Colors.white38,width: 1.0)
                        ),
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.only(top: 10),
                        child: InkWell(onTap : () async{
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const FeedReportsScreen()),
                          );
                          getAllData();
                        },child: Column(
                          children: [

                            Row(
                              /* mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,*/
                              children: [
                                Image.asset("assets/feed.png", color: Colors.white, width: 40, height: 40,),
                                Text(" "+"Feeding Report".tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),),
                              ],
                            ),

                            SizedBox(height: 5,),
                            Text('$total_feed_consumption' + 'kg',style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),),
                            Text("TOTAL_CONSUMPTION".tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70),),
                            SizedBox(height: 5,),
                            Container(
                              height: feedings.length==0?10:feedings.length*45,
                              width: widthScreen,
                              child: ListView.builder(
                                  itemCount: feedings.length,
                                  scrollDirection: Axis.vertical,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemBuilder: (BuildContext context, int index) {
                                    return Container(
                                      padding: EdgeInsets.all(5),
                                      margin: EdgeInsets.only(top: 5),
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(Radius.circular(6)),
                                            color: Colors.white12,
                                          border: Border.all(color: Colors.white12,width: 1.0)
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(feedings.elementAt(index).feed_name!.tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.white),),
                                          Text(feedings.elementAt(index).quantity! +" kg",style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white),),

                                        ],),
                                    );

                                  }),
                            ),
                          ],
                        ))),
                    Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                            //  color: Colors.white10.withAlpha(30),
                            color: Utils.getThemeColorBlue(),
                            border: Border.all(color: Colors.white38,width: 1.0)
                        ),
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.only(top: 10),
                        child: InkWell(onTap : () async{
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HealthReportScreen()),
                          );
                          getAllData();
                        },child: Column(
                          children: [
                            Row(
                              /* mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,*/
                              children: [
                                Image.asset("assets/health.png", color: Colors.white, width: 40, height: 40,),
                                Text(" "+"HEALTH_SUMMARY".tr(),style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),),
                              ],
                            ),

                            /*SizedBox(height: 5,),
                            Text('$total_health_count',style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),),
                            Text("TOTAL".tr(),style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70),),
                            SizedBox(height: 5,),*/
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(child: getCustomDataBox(Colors.white12, "VACCINATIONS".tr(), '$vac_count', '','')),
                                Expanded(child: getCustomDataBox(Colors.white12, "MEDICATIONS".tr(), '$med_count', '','')),
                                Expanded(child: getCustomDataBox(Colors.white12, "TOTAL".tr(), '$total_health_count', '','')),

                              ],
                            ),
                          ],
                        ))),
                   ],
                ),
              ),



             /* Container( margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      "View Reports",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: widthScreen, height: 40,),
                    InkWell(
                        child: Container(
                          width: widthScreen - (widthScreen / 5),
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          decoration: const BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                Image( image: AssetImage(
                                    'assets/add_reduce.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),
                                Expanded(
                                  child: Text(
                                    "Stock Report",
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
                          //STOCK REPORT
                        }),

                    SizedBox(width: widthScreen, height: 10,),
                    InkWell(
                        child: Container(
                          width: widthScreen - (widthScreen / 5),
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          decoration: const BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                Image(image: AssetImage(
                                    'assets/egg.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),
                                Expanded(
                                  child: Text(
                                    "Egg Collection Report",
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

                        }),

                    SizedBox(width: widthScreen, height: 10,),
                    InkWell(
                        child: Container(
                          width: widthScreen - (widthScreen / 5),
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          decoration: const BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                Image(image: AssetImage(
                                    'assets/feed.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),
                                Expanded(
                                  child: Text(
                                    "Feeding Reports",
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

                        }),

                    SizedBox(width: widthScreen, height: 10,),
                    InkWell(
                        child: Container(
                          width: widthScreen - (widthScreen / 5),
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          decoration: const BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                Image(image: AssetImage(
                                    'assets/health.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),
                                Expanded(
                                  child: Text(
                                    "Health Reports",
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

                        }),

                    SizedBox(width: widthScreen, height: 10,),
                    InkWell(
                        child: Container(
                          width: widthScreen - (widthScreen / 5),
                          height: 60,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          decoration: const BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius:
                              BorderRadius.all(Radius.circular(10))),
                          child: Container(
                            width: 40,height: 40,
                            margin: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                Image(image: AssetImage(
                                    'assets/income.png'),
                                  fit: BoxFit.fill,
                                  color: Colors.white,
                                ),
                                Expanded(
                                  child: Text(
                                    "Financial Reports",
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

                        }),
                  ],
                ),
              ),*/
            ]
      ),),),),),);
  }


  //FILTER WORK
  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];
  void getList() async {

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: "Farm Wide".tr() ,bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1));

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
                _reports_filter = filterList.indexOf(date_filter_name);
                Utils.applied_filter = date_filter_name;
              });

              getData(_reports_filter);
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



  List<String> filterList = ['TODAY'.tr(),'YESTERDAY'.tr(),'THIS_MONTH'.tr(), 'LAST_MONTH'.tr(),'LAST3_MONTHS'.tr(), 'LAST6_MONTHS'.tr(),'THIS_YEAR'.tr(),
    'LAST_YEAR'.tr(),'ALL_TIME'.tr()];

  String date_filter_name = 'THIS_MONTH'.tr();
  String str_date = '',end_date = '';
  void getData(int filter) {
    int index = 0;

    if (filter == 0){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getAllData();

    }
    else if (filter == 1){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getAllData();

    }
    else if (filter == 2){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getAllData();
    }else if (filter == 3){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getAllData();

    }else if (filter == 4){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getAllData();
    }else if (filter == 5){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getAllData();
    }else if (filter == 6){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      getAllData();
    }else if (filter == 7){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getAllData();

    }else if (filter == 8){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());
      print(str_date+" "+end_date);

      getAllData();
    }

    getAllData();

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

  Widget getDashboardDataBox(Color color, String title, String data, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(5)),
        color: color,

      ),
      padding: EdgeInsets.all(10.0),
      margin: EdgeInsets.all(5.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row (
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              Icon(icon, color: iconColor,),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Colors.white70),)
            ],),

          Container(
              margin: EdgeInsets.only(top: 5),
              child: Text(Utils.currency+data, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),))
        ],
      ),
    );
  }


  Widget getCustomDataBox(Color color, String title, String data, String imageSource,String ext) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        color: color,
      ),
      padding: EdgeInsets.only(top: 12,bottom: 12,left: 5,right: 5),
      margin: EdgeInsets.all(6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row (
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,


            children: [

              imageSource == ''? SizedBox(width: 0,height: 0,) :  Image.asset(imageSource, width: 40, height: 40,),

              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.white70),)
            ],),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                  margin: EdgeInsets.only(top: 3),
                  child: Text(data, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),)),
              Container(
                  margin: EdgeInsets.only(top: 3),
                  child: Text(ext, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),)),
            ],
          )
        ],
      ),
    );
  }


}

