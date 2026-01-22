import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poultary/database/databse_helper.dart';

import '../../add_flocks.dart';
import '../../model/flock.dart';
import '../../single_flock_screen.dart';
import '../../utils/utils.dart';
import '../utils/FirebaseUtils.dart';
import '../utils/RefreshMixin.dart';
// Import your localization and model classes accordingly

class AllFlocksScreen extends StatefulWidget {

  const AllFlocksScreen({Key? key}) : super(key: key);

  @override
  _AllFlocksScreen createState() => _AllFlocksScreen();
}
class _AllFlocksScreen extends State<AllFlocksScreen> with RefreshMixin {
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  @override
  void onRefreshEvent(String event)
  {
    try {
      if (event == FireBaseUtils.FLOCKS || event == FireBaseUtils.BIRDS)
      {
        init();
      }
    }
    catch(ex){
      print(ex);
    }
  }

  List<Flock> flocks = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    init();
    if(Utils.isShowAdd){
      _loadBannerAd();
    }

  }
  @override
  void dispose() {
    super.dispose();
    try{
      _bannerAd.dispose();
    }catch(ex){

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
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  Future<void> init() async {
    flocks = await DatabaseHelper.getFlocks();
    for(int i=0; i < flocks.length;i++)
    {
      print(flocks.elementAt(i).toJson());
    }
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryTextColor = Colors.black87;
    final shadowColor = Colors.grey.shade500;
    final lightShadowColor = Colors.white;


    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Utils.getThemeColorBlue(),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "ALL_FLOCKS".tr(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(children: [
         if(_isBannerAdReady)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                      height: 60.0,
                      width: Utils.WIDTH_SCREEN,
                      child: AdWidget(ad: _bannerAd)
                  ),
                ),
        Expanded(child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 20), // for spacing after list
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + FAB
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Stack(
                  children: [
                    if (flocks.isNotEmpty)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue, // Start color
                              Utils.getThemeColorBlue(), // End color
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () async {

                              if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_flocks")) {
                                Utils.showMissingPermissionDialog(context, "add_flocks");
                                return;
                              }

                              await Navigator.push(
                                context,
                                CupertinoPageRoute(builder: (
                                    context) => const ADDFlockScreen()),);

                              init();

                              // Refresh logic
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    "NEW_FLOCK".tr(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                  ],
                ),
              ),

              // Content
              if (flocks.isNotEmpty)
                ListView.builder(
                  itemCount: flocks.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final flock = flocks[index];
                    return GestureDetector(
                      onTap: () async {
                        Utils.selected_flock = flock;
                        await Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => const SingleFlockScreen()),);
                        // Refresh
                        init();
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: backgroundColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey,
                              offset: Offset(4, 4),
                              blurRadius: 8,
                            ),
                            BoxShadow(
                              color: lightShadowColor,
                              offset: Offset(-4, -4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              margin: EdgeInsets.all(5),
                              height: 70,
                              width: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade300,
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                flock.icon,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    flock.f_name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    flock.acqusition_type.tr(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    Utils.getFormattedDate(flock.acqusition_date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Count
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: shadowColor,
                                        offset: Offset(2, 2),
                                        blurRadius: 4,
                                      ),
                                      BoxShadow(
                                        color: lightShadowColor,
                                        offset: Offset(-2, -2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    flock.active_bird_count.toString(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "BIRDS".tr(),
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      SizedBox(height: 80),
                      Center(
                        child: Text(
                          "NO_FLOCKS".tr(),
                          style: TextStyle(fontSize: 16, color: primaryTextColor),
                        ),
                      ),
                      SizedBox(height: 20),
                      buildGradientButton(context)
                    ],
                  ),
                ),
            ],
          ),
        ),)
      ],)

    );
  }

  Widget buildGradientButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue,
              Utils.getThemeColorBlue(),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_flocks")) {
                Utils.showMissingPermissionDialog(context, "add_flocks");
                return;
              }

              await Navigator.push(
                context,
                CupertinoPageRoute(builder: (
                    context) => const ADDFlockScreen()),);

              init();
              // Refresh logic
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    "NEW_FLOCK".tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
