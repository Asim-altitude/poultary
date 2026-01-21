import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/category_item.dart';
import 'package:poultary/stock/screens/general_stock_screen.dart';
import 'package:poultary/stock/tools_assets/screens/tools_assets_screen.dart';
import 'package:poultary/stock/vaccine_stock_screen.dart';
import 'package:poultary/utils/utils.dart';

import '../stock/stock_screen.dart';
import '../utils/fb_analytics.dart';
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

    AnalyticsUtil.logScreenView(screenName: "main_stock_screen");
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
    return Scaffold(
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
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
            elevation: 8,
            automaticallyImplyLeading: (Utils.isMultiUSer && Utils.currentUser!.role.toLowerCase() != "admin")? true : false,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              Utils.showBannerAd(_bannerAd, _isBannerAdReady),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GeneralStockScreen()),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    // -------- ICON ----------
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        size: 32,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // -------- WRAP TEXT IN EXPANDED ----------
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "General Stock".tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "Manage supplies, cartons, materials".tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // -------- ARROW ----------
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
            ),
             GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ToolsAssetsScreen()),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      // -------- ICON ----------
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 32,
                          color: Colors.blue,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // -------- WRAP TEXT IN EXPANDED ----------
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tools and Assets".tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              "Add farm tools, machinery or assets to track condition & maintenance".tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // -------- ARROW ----------
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
                padding: EdgeInsets.all(16.0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
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
  })
  {
    // Use cool theme colors
    final Color accent = Colors.blue.shade600;
    final Color accentDark = Colors.indigo.shade700;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade50,
              Colors.indigo.shade50.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.12),
              offset: const Offset(2, 4),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accentDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(2, 3),
                  )
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: accentDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }



}

