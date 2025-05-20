import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
    Item(image: 'assets/eggs_tray.png', title: 'Production Report'.tr(), subtitle: 'View report of Production'.tr()),
    Item(image: 'assets/finance_icon.png', title: 'Financial Report'.tr(), subtitle: 'View report of Income and Expense'.tr()),
    Item(image: 'assets/bird_icon.png', title: 'BIRDS'.tr()+' '+ 'REPORT'.tr(), subtitle: 'View report of birds additions and reductions'.tr()),
    Item(image: 'assets/eggs_count.png', title: 'EGG'.tr()+" "+ "REPORT".tr(), subtitle: 'View report of egg collection and reduction'.tr()),
    Item(image: 'assets/feed.png', title: 'Feed'.tr()+' '+ 'REPORT'.tr(), subtitle: 'View report of Feed Consumption'.tr()),
    Item(image: 'assets/health.png', title: 'Health'.tr()+" "+'REPORT'.tr(), subtitle: 'View report of Health Events'.tr()),
  ];

  List<CustomCategory> categories = [];
  late BannerAd _bannerAd;
  double _heightBanner = 0;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCategories();
    if(Utils.isShowAdd){
      _loadBannerAd();
    }
  }
  _loadBannerAd(){
    // TODO: Initialize _bannerAd
    _bannerAd = BannerAd(
      adUnitId: Utils.bannerAdUnitId,

      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _heightBanner = 60;
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          _heightBanner = 0;
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  void dispose() {
    try{
      _bannerAd.dispose();
    }catch(ex){

    }
    super.dispose();
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
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
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
          Utils.showBannerAd(_bannerAd, _isBannerAdReady),

          // ListView inside Expanded

          Expanded(child:
          Container(
            color: Colors.grey[100],

            child: GridView.builder(
              padding: EdgeInsets.all(10),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two items per row
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1, // Adjust height/width ratio
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  margin: EdgeInsets.symmetric(vertical: 0),
                  child:
                  InkWell(
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
                 child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade300, width: 1),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                   padding: const EdgeInsets.all(12),

                   child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                      ClipRRect(
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
                      SizedBox(height: 7,),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Utils.getThemeColorBlue(),
                        ),
                      ),
                        SizedBox(height: 1,),

                        Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],),


                  ),),
                );
              },
            ),
          ),),
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
