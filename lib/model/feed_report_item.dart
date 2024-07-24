import 'dart:async';
import 'dart:core';



class Feed_Report_Item{

  String feed_name = "";
  String f_name = "";
  num? consumption = 0;


  Feed_Report_Item(
      {
        required this.feed_name,required this.consumption,
      });

  Feed_Report_Item.fromJson(Map<String, dynamic> json) {
    feed_name = json['feed_name'].toString();
    f_name = json['f_name'].toString();
    consumption = json['sum(quantity)'];

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['feed_name'] = this.feed_name;
    data['f_name'] = this.f_name;
    data['consumption'] = this.consumption;


    return data;
  }

  String getIndex(int index) {
    switch (index) {
      case 0:
        return feed_name;
      case 1:
        return consumption.toString();
      case 2:
        return f_name;


    }
    return '';
  }
}


