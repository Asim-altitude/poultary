import 'dart:async';
import 'dart:core';



class Health_Report_Item{

  String f_name = "";
  String medicine_name = "";
  String disease_name = '';
  String birds = '';
  String date = '';

  Health_Report_Item(
      {
        required this.f_name,required this.date, required this.medicine_name,required this.disease_name,required this.birds
      });

  Health_Report_Item.fromJson(Map<String, dynamic> json) {
    f_name = json['f_name'];
    medicine_name = json['medicine_name'];
    disease_name = json['disease_name'];
    birds = json['birds'];
    date = json['date'];

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['f_name'] = this.f_name;
    data['medicine_name'] = this.medicine_name;
    data['disease_name'] = this.disease_name;
    data['birds'] = this.birds;
    data['date'] = this.date;

    return data;
  }

  String getIndex(int index) {
    switch (index) {
      case 0:
        return medicine_name;
      case 1:
        return disease_name;
      case 2:
        return f_name;
      case 3:
        return date;
      case 4:
        return birds;
    }
    return '';
  }
}


