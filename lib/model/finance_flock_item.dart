import 'dart:async';
import 'dart:core';


class FinanceFlockItem{

  int? id = -1;
  int active_birds = 0;
  int selected_birds = 1;
  String name = "";
  bool isActive = false;

  FinanceFlockItem(
      {
        required this.id,required this.name, required this.active_birds,
        required this.selected_birds,required this.isActive
      });

  FinanceFlockItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    active_birds = json['active_birds'];
    selected_birds = json['selected_birds'];
    isActive = json['isActive'];
    name = json['name'].toString();

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['active_birds'] = this.active_birds;
    data['selected_birds'] = this.selected_birds;
    data['name'] = this.name;
    data['isActive'] = this.isActive;


    return data;
  }
}


