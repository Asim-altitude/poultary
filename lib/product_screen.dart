import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poultary/utils/utils.dart';
import 'dart:async';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:math';
import 'package:http/http.dart' as http;

import 'model/bird_item.dart';
import 'model/bird_product.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({Key? key}) : super(key: key);

  @override
  _ProductScreen createState() => _ProductScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _ProductScreen extends State<ProductScreen> {
  // Color themeColor = const Color.fromRGBO(0, 124, 247, 1);
  Color themeColor = Colors.red;
  double widthScreen = 0, heightScreen = 0;
  bool _isLoading = true;
  String corruptedPathPDF = "";
  static const int _initialPage = 1;
  int _actualPageNumber = _initialPage, _allPagesCount = 0;
  bool isSampleDoc = true;
  late BannerAd _bannerAd;
  double _heightBanner = 0;

  bool _isBannerAdReady = false;
  String _isAppDownloaded = '0';
  bool _showPoultryAd = false;
  Uri _urlAppLink = Uri.parse('');


  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    checkIfDownloaded();

  }



  Future<void> checkIfDownloaded() async {
    if(Utils.products.length>0){
      _isLoading = false;
      setState(() {

      });
    }
    else{
      _isLoading = true;
      setState(() {
      });
      var url = Uri.parse('https://flockhatch-default-rtdb.firebaseio.com/products.json');

      try {
        var response = await http.get(url);

        if (response.statusCode == 200) {
          // Successful GET request
          var jsonResponse = jsonDecode(response.body);
          var userId = jsonResponse['isShow'];
          userId = userId.toString();
          if(userId=='1'){
            Utils.isShowProducts = true;
            var all = jsonResponse['all'];
            for (var item in all) {
              BirdProduct bird = BirdProduct(id:  "0", name: "0", totalDays: "0", image: "0");
              try{
                bird = new BirdProduct(id: item['is'].toString(), name: item['name'].toString(), totalDays: item['link'].toString(), image: item['image'].toString());

              }catch(ex){

              }

              if(bird.id == "1"){
                Utils.products.add(bird);
              }

            }
          }
          else{
            Utils.isShowProducts = false;

          }

          _isLoading = false;
          setState(() {

          });

        } else {
          // If that call was not successful, throw an error.
          throw Exception('Failed to load data');
        }
      } catch (e) {
        // Handle any exceptions that occurred during the request.
        print('Error: $e');
      }
    }
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
      child:
      SafeArea(child: Scaffold(
        body:SafeArea(
          top: false,
          child: Container(
            width: widthScreen,
            height: heightScreen,
            color: Colors.white,
            child:Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  [

                if(!_isLoading && Utils.products.length==0)
                  Container(
                    height: Utils.HEIGHT_SCREEN-100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Container(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0,top: 10),
                        child:Align(
                          alignment: Alignment.center,
                          child:Text("Products not available.".tr(),
                            textAlign: TextAlign.center,
                            style: new TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                                fontFamily: 'PTSans'
                            ),
                          ),),),
                      Container(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0,top: 2),
                        child:Align(
                          alignment: Alignment.center,
                          child:Text("Please try again later.".tr(),
                            textAlign: TextAlign.center,
                            style: new TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey,
                                fontFamily: 'PTSans'
                            ),
                          ),),),
                    ],),
                  ),
                if(_isLoading)
                  Container(
                    height: Utils.HEIGHT_SCREEN-100,
                  child:Center(child:CircularProgressIndicator(color: Utils.getThemeColorBlue(),)),),

                if(Utils.products.length>0)
                  Container(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0,top: 10),
                    child:Align(
                      alignment: Alignment.center,
                      child:Text("Disclosure".tr(),
                        textAlign: TextAlign.center,
                        style: new TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.normal,
                            color: Colors.red,
                            fontFamily: 'PTSans'
                        ),
                      ),),),
                if(Utils.products.length>0)

                  Container(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0,top: 4,bottom: 8),
                    child:Align(
                      alignment: Alignment.center,
                      child:Text("Disclosure_Detail".tr(),
                        textAlign: TextAlign.center,
                        style: new TextStyle(
                            fontSize: 9.0,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey,
                            fontFamily: 'PTSans'
                        ),
                      ),),),
                Expanded(
                   child:GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 0.0,
                    mainAxisSpacing: 0.0,
                      childAspectRatio: ((Utils.WIDTH_SCREEN/2) / 278)
                  ),
                  itemCount: Utils.products.length,
                  itemBuilder: (context, index) {
                    return
                      getProductItem(Utils.products[index]);
                  },
                ),),

              ],
            ),),),
      ),),
    );
  }
  Widget getProductItem(BirdProduct bird){
    return
      InkWell(
        onTap: (){
          openLink(bird.totalDays);
        },
      child:Container(
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:Colors.white,
        borderRadius: BorderRadius.all(
      Radius.circular(8),

        ),
        border: Border.all(
          color: Color.fromRGBO(230, 230, 230, 1),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          Container(
            width: 150,
              height: 150,
            child: Image.network(
              bird.image,
              height: 150,
              width: 130,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 50,
            child:Align(
            alignment: Alignment.center,
            child:Text("${bird.name}",
              textAlign: TextAlign.center,
              style: new TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                  fontFamily: 'PTSans'
              ),
            ),),),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              openLink(bird.totalDays);
            },
            child: Text('View on Amazon'.tr()),
          ),
        ],
      ),
      ), );
  }
  openLink(String link) async {
    String affiliateLink = link;
    Uri affiliateUri = Uri.parse(affiliateLink);

    // Check if the Amazon app is installed
    bool isAppInstalled = await canLaunchUrl(affiliateUri);

    if (isAppInstalled) {
      // Open the link in the Amazon app
      await launchUrl(affiliateUri,mode: LaunchMode.externalApplication);
    } else {
      // If the Amazon app is not installed, open the link in the default web browser
      await launchUrl(affiliateUri,mode: LaunchMode.externalApplication);
    }
  }
}
