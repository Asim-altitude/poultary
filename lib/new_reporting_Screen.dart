import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poultary/birds_report_screen.dart';
import 'package:poultary/eggs_report_screen.dart';
import 'package:poultary/feed_report_screen.dart';
import 'package:poultary/financial_report_screen.dart';
import 'package:poultary/flock_weight_report.dart';
import 'package:poultary/performance_report_screen.dart';
import 'package:poultary/production_report.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/ui/ai_insights_widget.dart';
import 'package:poultary/utils/utils.dart';


import 'advance_insights_engine/ui/usage_example.dart';
import 'custom_category_report.dart';
import 'database/databse_helper.dart';
import 'health_report_screen.dart';
import 'model/custom_category.dart';

class ReportListScreen extends StatefulWidget {
  bool showBack;
  ReportListScreen({Key? key, required this.showBack}) : super(key: key);

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
    Item(image: 'assets/weight_icon.png', title: 'Weight Report'.tr(), subtitle: 'View report of Flock Weight Change'.tr()),

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

    AnalyticsUtil.logScreenView(screenName: "all_report_screen");
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
      appBar: AppBar(
        title: Text(
          "All Reports".tr(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        elevation: 8,
        automaticallyImplyLeading: ((Utils.isMultiUSer && Utils.currentUser!.role.toLowerCase() != "admin") || widget.showBack)? true : false,
      ),
      body: Column(
        children: [

           if(_isBannerAdReady)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                      height: 60.0,
                      width: Utils.WIDTH_SCREEN,
                      child: AdWidget(ad: _bannerAd)
                  ),
                ),

          // ListView inside Expanded

          Container(
            margin: EdgeInsets.all(10.0),
            child: PerformanceReportCard(onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  PerformanceReportScreen()),
              );
            },),
          ),
          Expanded(child:
          Container(
            color: Colors.grey[100],

            child: GridView.builder(
              padding: EdgeInsets.all(10),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two items per row
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
                childAspectRatio: 1.1, // Adjust height/width ratio
              ),
              itemBuilder: (context, index) {
                final item = items[index];
               return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      if (index == 0) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProductionReportScreen()),
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
                      } else if (index == 6) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WeightReportScreen()),
                        );
                      } else {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryChartScreen(
                              customCategory: categories[index - 7],
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4F46E5), // Indigo
                            Color(0xFF06B6D4), // Cyan
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), // reduced height
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: item.image != ""
                                ? Image.asset(
                              item.image,
                              width: 26,
                              height: 26,
                              fit: BoxFit.contain,
                              color: Colors.white,
                            )
                                : Icon(
                              item.icon,
                              size: 26,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Title
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 3),

                          // Subtitle
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
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
