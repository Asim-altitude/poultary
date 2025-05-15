import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/birds_report_screen.dart';
import 'package:poultary/eggs_report_screen.dart';
import 'package:poultary/feed_report_screen.dart';
import 'package:poultary/financial_report_screen.dart';
import 'package:poultary/production_report.dart';
import 'package:poultary/utils/utils.dart';

import 'custom_category_report.dart';
import 'database/databse_helper.dart';
import 'health_report_screen.dart';
import 'model/custom_category.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({Key? key}) : super(key: key);

  @override
  _ReportListScreen createState() => _ReportListScreen();
}

class _ReportListScreen extends State<ReportListScreen> {
  final List<Item> items = [
    Item(image: 'assets/eggs_tray.png', title: 'Production Report'.tr(), subtitle: 'View report of Production and Cost'.tr()),
    Item(image: 'assets/finance_icon.png', title: 'Financial Report'.tr(), subtitle: 'View report of Income and Expense'.tr()),
    Item(image: 'assets/bird_icon.png', title: 'BIRDS'.tr()+' '+ 'REPORT'.tr(), subtitle: 'View report of birds additions and reductions'.tr()),
    Item(image: 'assets/eggs_count.png', title: 'EGG'.tr()+" "+ "REPORT".tr(), subtitle: 'View report of egg collection and reduction'.tr()),
    Item(image: 'assets/feed.png', title: 'Feed'.tr()+' '+ 'REPORT'.tr(), subtitle: 'View report of Feed Consumption'.tr()),
    Item(image: 'assets/health.png', title: 'Health'.tr()+" "+'REPORT'.tr(), subtitle: 'View report of Health Events'.tr()),
  ];

  List<CustomCategory> categories = [];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCategories();
  }

  Future<void> getCategories() async {
    categories = (await DatabaseHelper.getCustomCategories())!;

    for(int i=0;i<categories.length;i++){
      Item item = Item(image: "", title: categories.elementAt(i).name, subtitle: "View report of "+categories.elementAt(i).cat_type);
      item.icon = categories.elementAt(i).icon;
      items.add(item);
    }
   setState(() {

   });

  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      body: Column(
        children: [
          // Top Gradient Header
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
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(left: 12),
                      child: Center(
                        child: Text(
                          "All Reports".tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ListView inside Expanded
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.image != ""
                          ? Image.asset(
                        item.image,
                        width: 45,
                        height: 45,
                        fit: BoxFit.cover,
                        color: Utils.getThemeColorBlue(),
                      )
                          : Icon(
                        item.icon,
                        size: 45,
                        color: Utils.getThemeColorBlue(),
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Utils.getThemeColorBlue(),
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[700]),
                    onTap: () async {
                      if (index == 0) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>  ProductionReportScreen()),
                        );
                      } else if (index == 1) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FinanceReportsScreen()),
                        );
                      } else if (index == 2) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BirdsReportsScreen()),
                        );
                      } else if (index == 3) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EggsReportsScreen()),
                        );
                      } else if (index == 4) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FeedReportsScreen()),
                        );
                      } else if (index == 5) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HealthReportScreen()),
                        );
                      } else {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryChartScreen(
                              customCategory: categories[index - 6],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}

class Item {
  final String image;
  final String title;
  final String subtitle;
  IconData? icon;

  Item({required this.image, required this.title, required this.subtitle});
}
