

import 'dart:convert';
import 'dart:typed_data';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poultary/model/flock_image.dart';

import '../database/databse_helper.dart';
import '../utils/utils.dart';

class CarouselDemo extends StatefulWidget {

  CarouselDemo({Key? key,}) : super(key: key);

  @override
  _CarouselDemo createState() => _CarouselDemo();
}

class _CarouselDemo extends State<CarouselDemo> {

  List<Uint8List> byteimages = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getImages();
  }

  bool imagesAdded = false;
  List<Flock_Image> images = [];
  void getImages() async {

    await DatabaseHelper.instance.database;

    images = await DatabaseHelper.getFlockImage(Utils.selected_flock!.f_id);

    print(images);

    for(int i=0;i<images.length;i++){
      Uint8List bytesImage = const Base64Decoder().convert(images.elementAt(i).image);
      byteimages.add(bytesImage);
      print("IMAGES ${images.elementAt(i).image}" );
    }

    if (byteimages.length > 0) {
      imagesAdded = true;
      setState(() {

      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(iconTheme: IconThemeData(
        color: Colors.white, //change your color here
      ),title: Text('Flock Images', style: TextStyle( color: Colors.white),), backgroundColor: Utils.getThemeColorBlue(),),
      body: Builder(
        builder: (context) {
          final double height = MediaQuery.of(context).size.height;
          return CarouselSlider(
            options: CarouselOptions(
              height: height,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              autoPlay: true,
            ),
            items: byteimages
                .map((item) => Container(
              child: Center(
                  child: Image.memory(item, fit: BoxFit.fill,),),
            )).toList(),
          );
        },
      ),
    );
  }
}

class DemoItem extends StatelessWidget {
  final String title;
  final String route;
  DemoItem(this.title, this.route);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }
}
