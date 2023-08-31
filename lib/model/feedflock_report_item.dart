import 'dart:async';
import 'dart:core';



class FeedFlock_Report_Item{

  String f_name = "";
  int? consumption = 0;


  FeedFlock_Report_Item(
      {
        required this.f_name,required this.consumption,
      });

  FeedFlock_Report_Item.fromJson(Map<String, dynamic> json) {
    f_name = json['f_name'].toString();
    consumption = json['sum(quantity)'];

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['f_name'] = this.f_name;
    data['consumption'] = this.consumption;


    return data;
  }

  String getIndex(int index) {
    switch (index) {
      case 0:
        return f_name;
       case 1:
        return consumption.toString();



    }
    return '';
  }
}


