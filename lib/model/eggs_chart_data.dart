import 'dart:async';
import 'dart:core';



class Eggs_Chart_Item{

  String date = "";
  int? total = 0;

  Eggs_Chart_Item(
      {
        required this.date,required this.total,
      });

  Eggs_Chart_Item.fromJson(Map<String, dynamic> json) {
    date = json['collection_date'].toString();
    total = json['sum(total_eggs)'];

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['collection_date'] = this.date;
    data['sum(total_eggs)'] = this.total;


    return data;
  }

}


