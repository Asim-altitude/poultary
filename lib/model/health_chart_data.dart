import 'dart:async';
import 'dart:core';



class Health_Chart_Item{

  String date = "";
  int? total = 0;

  Health_Chart_Item(
      {
        required this.date,required this.total,
      });

  Health_Chart_Item.fromJson(Map<String, dynamic> json) {
    date = json['date'].toString();
    total = json['count(id)'];

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['count(id)'] = this.total;


    return data;
  }

}


