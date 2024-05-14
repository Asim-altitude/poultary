import 'dart:async';
import 'dart:core';



class Finance_Chart_Item{

  String date = "";
  String type = "";
  int? amount = 0;

  Finance_Chart_Item(
      {
        required this.date,required this.type,required this.amount,
      });

  Finance_Chart_Item.fromJson(Map<String, dynamic> json) {
    date = json['date'].toString();
    type = json['type'].toString();
    amount = json['sum(amount)'];

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['type'] = this.type;
    data['sum(amount)'] = this.amount;


    return data;
  }

}


