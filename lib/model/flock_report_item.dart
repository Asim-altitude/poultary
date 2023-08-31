import 'dart:async';
import 'dart:core';



class Flock_Report_Item{

  String f_name = "";
  int? active_bird_count;
  int? addition = 0;
  int? reduction = 0;
  String? date;

  Flock_Report_Item(
      {
        required this.f_name,required this.date, required this.active_bird_count,required this.addition,required this.reduction
      });

  Flock_Report_Item.fromJson(Map<String, dynamic> json) {
    f_name = json['f_name'].toString();
    active_bird_count = json['active_bird_count'];
    addition = json['addition'];
    reduction = json['reduction'];
    date = json['date'].toString();

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['f_name'] = this.f_name;
    data['active_bird_count'] = this.active_bird_count;
    data['addition'] = this.addition;
    data['reduction'] = this.reduction;
    data['date'] = this.date;

    return data;
  }

  String getIndex(int index) {
    switch (index) {
      case 0:
        return f_name;
      case 1:
        return date.toString();
      case 2:
        return addition.toString();
      case 3:
        return reduction.toString();
      case 4:
        return active_bird_count.toString();
    }
    return '';
  }
}


