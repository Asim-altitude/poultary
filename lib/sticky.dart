import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poultary/utils/utils.dart';

class SingleChildScrollViewWithStickyFirstWidget extends StatefulWidget {
  final Widget child;

  SingleChildScrollViewWithStickyFirstWidget({required this.child});

  @override
  _SingleChildScrollViewWithStickyFirstWidgetState createState() => _SingleChildScrollViewWithStickyFirstWidgetState();
}

class _SingleChildScrollViewWithStickyFirstWidgetState extends State<SingleChildScrollViewWithStickyFirstWidget> {

  late BannerAd _bannerAd;

  bool _isBannerAdReady = false;
  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    // Add any initialization logic here
  }
  @override
  void dispose() {
    try{
      _bannerAd.dispose();

    }catch(ex){
    }
    super.dispose();
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
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: widget.child,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: !Utils.isShowAdd?Container(width: Utils.WIDTH_SCREEN,height: 0,):
          Container(width: Utils.WIDTH_SCREEN,height: 60,
            color: Colors.white,
            child:_isBannerAdReady?Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 60.0 ,
                width: Utils.WIDTH_SCREEN,
                child: new AdWidget(ad: _bannerAd!),
              ),
            ):Container(),
          )
        ),
      ],
    );
  }
}