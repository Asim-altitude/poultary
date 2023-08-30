import 'dart:async';
import 'dart:core';



class FarmSetup{

  int? id = -1;
  int? modified = 0;
  String image = "";
  String name = "";
  String location = "";
  String date = "";
  String currency = "";

  FarmSetup(
      {
        required this.id,required this.name,required this.currency,required this.location,required this.date, required this.image
      });

  FarmSetup.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    image = json['image'].toString();
    name = json['name'].toString();
    date = json['date'].toString();
    modified = json['modified'];
    currency = json['currency'];
    location = json['location'].toString();

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['image'] = this.image;
    data['name'] = this.name;
    data['date'] = this.date;
    data['currency'] = this.currency;
    data['location'] = this.location;
    data['modified'] = this.modified;


    return data;
  }
}


