import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/category_item.dart';
import 'package:poultary/stock/vaccine_stock_screen.dart';
import 'package:poultary/utils/utils.dart';

import '../stock/stock_screen.dart';
import 'egg_stock_screen.dart';
import 'medicine_stock_screen.dart';

class ManageInventoryScreen extends StatefulWidget {
  @override
  _ManageInventoryScreenState createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen> {
  BannerAd? _bannerAd;
  double _heightBanner = 0;
  bool _isBannerAdReady = false;
  @override
  void initState() {
    super.initState();
    // Initialize any necessary data or perform setup tasks here
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

    _bannerAd?.load();
  }

  @override
  void dispose() {
    try{
      _bannerAd?.dispose();
    }catch(ex){

    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(0.0),
              bottomRight: Radius.circular(0.0),
            ),
            child: AppBar(
              title: Text(
                "Manage Inventory".tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              backgroundColor: Utils.getThemeColorBlue(),
              elevation: 8,
              automaticallyImplyLeading: false,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Utils.showBannerAd(_bannerAd, _isBannerAdReady),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                  children: [
                    _buildInventoryItem(
                      icon: Icons.fastfood,
                      title: "Feed Stock".tr(),
                      description: "Manage available feed quantity and types".tr(),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => FeedStockScreen()),
                        );
                      },
                    ),
                    _buildInventoryItem(
                      icon: Icons.egg,
                      title: "Egg Stock".tr(),
                      description: "Manage collected eggs and storage".tr(),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EggStockScreen()),
                        );
                      },
                    ),
                    _buildInventoryItem(
                      icon: Icons.medical_services,
                      title: "Medicine Stock".tr(),
                      description: "Track medicines and expiration dates".tr(),
                      onTap: () async {
                        CategoryItem item = CategoryItem(id: null, name: "Medicine");
                        int? medicineCategoryID = await DatabaseHelper.addCategoryIfNotExists(item);
      
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MedicineStockScreen(id: medicineCategoryID!),
                          ),
                        );
                      },
                    ),
                    _buildInventoryItem(
                      icon: Icons.vaccines,
                      title: "Vaccine Stock".tr(),
                      description: "Manage vaccination schedules and stock".tr(),
                      onTap: () async {
                        CategoryItem item = CategoryItem(id: null, name: "Vaccine");
                        int? vaccineCategoryID = await DatabaseHelper.addCategoryIfNotExists(item);
      
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VaccineStockScreen(id: vaccineCategoryID!),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      
      ),
    );
  }

  Widget _buildInventoryItem({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    Color color= Colors.orange.shade500;
    Color colorBG=  Colors.orange.shade900;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.025),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorBG, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              offset: Offset(0, 4),
              blurRadius: 6,
            )
          ],
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorBG, size: 40),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorBG,
              ),
            ),
            SizedBox(height: 2),
            Expanded(
              child: Text(
                description,
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }


}

