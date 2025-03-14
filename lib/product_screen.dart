import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:poultary/utils/utils.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;

import 'model/bird_item.dart';
import 'model/bird_model.dart';
import 'model/blog.dart';


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
  List<Bird> allQuestions = [];
  bool _isLoading = false;
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
  int _selectedIndex = 0;
  List<Blog> blogItems = [];
  late Box<Blog> blogBox;
  late Box localBox;
  bool isLoading = false;
  ScrollController _scrollController = ScrollController();


  @override
  void dispose() {
    super.dispose();
  }


  Future<void> loadLocalPosts() async {
    blogBox = await Hive.openBox<Blog>('blogger');
    localBox = await Hive.openBox('local_data');

    setState(() {
      blogItems = blogBox.values.toList()
        ..sort((a, b) => b.id.compareTo(a.id));
    });

    fetchNewPosts();
  }

  Future<void> fetchNewPosts() async {
    String? latestStoredId = localBox.get('latest_post_ids');

    if(latestStoredId!=null){
      try{
        int latestStoredIdInt = int.parse(latestStoredId);
        latestStoredIdInt = latestStoredIdInt+1;
        latestStoredId = latestStoredIdInt.toString();
      }catch(ex){

      }
    }
    String url = latestStoredId == null
        ? "https://hatching-38f1b-default-rtdb.firebaseio.com/posts.json?"
        "orderBy=\"\$key\"&limitToLast=20"
        : "https://hatching-38f1b-default-rtdb.firebaseio.com/posts.json?"
        "orderBy=\"\$key\"&startAt=\"$latestStoredId\"";

    print('LATEST: ${url}');

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Map<String, dynamic> newPosts = jsonDecode(response.body);

      if (newPosts.isNotEmpty) {
        for (var entry in newPosts.entries) {
          var post = Blog(
            id: int.parse(entry.key),
            title: entry.value['title'],
            summary: entry.value['summary'],
            url: entry.value['url'],
            image: entry.value['image'],
          );
          await blogBox.put(post.id.toString(), post);
        }

        // Store the latest post ID
        String latestNewId = newPosts.keys.last;
        await localBox.put('latest_post_ids', latestNewId);

        setState(() {
          blogItems = blogBox.values.toList()
            ..sort((a, b) => b.id.toString().compareTo(a.id.toString()));
        });
      }
    }
  }
  String formatTimestamp(int timestamp) {
    try{
      DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      DateTime now = DateTime.now();
      DateTime yesterday = now.subtract(Duration(days: 1));

      if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(now)) {
        return "Today";
      } else if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(yesterday)) {
        return "Yesterday";
      } else {
        return DateFormat('d MMMM').format(date); // Example: "10 March"
      }
    }catch(ex){
      return timestamp.toString();
    }

  }
  String formatTime(int timestamp) {
    try {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateFormat('hh:mm a').format(date); // Example: "02:56 PM"
    } catch (ex) {
      return timestamp.toString();
    }
  }
  Future<void> fetchOlderPosts() async {
    if (isLoading) return;
    print("load more");
    if (blogItems.isEmpty) return;
    int oldestId = blogItems.last.id;
    String url = "https://hatching-38f1b-default-rtdb.firebaseio.com/posts.json?"
        "orderBy=\"\$key\"&endAt=\"$oldestId\"&limitToLast=20";

    print('VARVAR:$url');

    setState(() => isLoading = true);
    var response = await http.get(Uri.parse(url));
    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      Map<String, dynamic> olderPosts = jsonDecode(response.body);
      if (olderPosts.isNotEmpty) {
        olderPosts.remove(oldestId.toString());
        for (var entry in olderPosts.entries) {
          var post = Blog(
            id: int.parse(entry.key),
            title: entry.value['title'],
            summary: entry.value['summary'],
            url: entry.value['url'],
            image: entry.value['image'],
          );
          await blogBox.put(post.id.toString(), post);
        }
        setState(() {
          blogItems = blogBox.values.toList()
            ..sort((a, b) => b.id.toString().compareTo(a.id.toString()));
        });
      }
    }
  }
  @override
  void initState() {
    super.initState();
    checkIfDownloaded();
    loadLocalPosts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        fetchOlderPosts();
      }
    });

  }
  Future<void> checkIfDownloaded() async {
    if(Utils.products.length>0){

    }
    else{

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
              BirdModel bird = BirdModel(id: "0", name: "0", totalDays: "0", image: "0");
              try{
                bird = new BirdModel(id: item['is'].toString(), name: item['name'].toString(), totalDays: item['link'].toString(), image: item['image'].toString());

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children:  [
                SizedBox(height: 16,),
                ToggleSwitch(
                  minWidth: 140.0,
                  initialLabelIndex: _selectedIndex,
                  cornerRadius: 20.0,
                  activeFgColor: Colors.white,
                  inactiveBgColor: Colors.grey,
                  inactiveFgColor: Colors.white,
                  totalSwitches: 2,
                  labels: ['Poultry'.tr(),"Products".tr()],
                  icons: [Icons.egg_outlined,MdiIcons.bird, Icons.shopping_cart],
                  activeBgColors: [[Colors.pink],[Colors.pink],[Utils.getThemeColorBlue()]],
                  onToggle: (index) {
                    setState(() {
                      _selectedIndex = index!;
                    });
                  },
                ),
                if(_selectedIndex==0)
                  SizedBox(height: 10,),
                if(_selectedIndex==0)
                  Expanded(
                    child: blogItems.isEmpty
                        ? Center(child: CircularProgressIndicator())
                        : ListView.builder(
                      itemCount: blogItems.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == blogItems.length) {
                          return Center(child: CircularProgressIndicator());
                        }
                        Blog blog = blogItems[index];
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                spreadRadius: 2,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: (){
                              openLink(blog.url);
                            },

                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    blog.image.replaceAll("s72", "s500"),
                                    width: Utils.WIDTH_SCREEN,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(height: 6),

                                Container(
                                  padding: EdgeInsets.only(left: 12,right: 12,top: 6,bottom: 6),
                                  child:Text(
                                    blog.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatTime(blog.id),
                                      style: TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                    SizedBox(width: 4,),
                                    Text(
                                      formatTimestamp(blog.id),
                                      style: TextStyle(fontSize: 14, color: Colors.pink),
                                    ),
                                    SizedBox(width: 2,),
                                    Icon(Icons.public,color: Colors.pink,size: 14,),
                                    SizedBox(width: 10,),

                                  ],),
                                SizedBox(height: 6),

                                // Text(
                                //   blog.summary,
                                //   style: TextStyle(
                                //     fontSize: 14,
                                //     color: Colors.grey[700],
                                //   ),
                                //   maxLines: 3,
                                //   overflow: TextOverflow.ellipsis,
                                // ),

                                // Expanded(
                                //   child: Padding(
                                //     padding: EdgeInsets.all(12),
                                //     child: Column(
                                //       crossAxisAlignment: CrossAxisAlignment.start,
                                //       children: [
                                //
                                //       ],
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        );

                      },
                      controller: _scrollController
                        ..addListener(() {
                          if (!isLoading && blogItems.length > 20) {
                            // fetchOlderPosts();
                          }
                        }),
                    ),
                  ),
                if(!_isLoading && Utils.products.length==0 && _selectedIndex ==1)
                  Container(
                    height: Utils.HEIGHT_SCREEN-180,
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
                    height: Utils.HEIGHT_SCREEN-160,
                    child:Center(child:CircularProgressIndicator(color: Utils.getThemeColorBlue(),)),),

                if(Utils.products.length>0 && _selectedIndex == 1)
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
                if(Utils.products.length>0 && _selectedIndex == 1)

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
                if(_selectedIndex==1)
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
  Widget getProductItem(BirdModel bird){
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
