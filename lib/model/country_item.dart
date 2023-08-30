import 'dart:async';
import 'dart:core';



class CountryItem{

  String country_name = "";
  String currency = "";

  CountryItem(
      {
        required this.currency, required this.country_name
      });

  CountryItem.fromJson(Map<String, dynamic> json) {

    currency = json['currency'].toString();
    country_name = json['country_name'].toString();

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['country_name'] = this.country_name;
    data['currency'] = this.currency;

    return data;
  }
}


