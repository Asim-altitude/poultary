import 'dart:async';
import 'dart:core';



class BirdUsage{

  String reason = "";
  String sum = "";

  BirdUsage.fromJson(Map<String, dynamic> json) {

    reason = json['reason'].toString();
    sum = json['sum(item_count)'].toString();

  }

}


