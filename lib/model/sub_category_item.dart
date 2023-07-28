import 'dart:async';
import 'dart:core';



class SubItem{

  int? id;
  int? c_id;
  String? name;


  SubItem(
      {
        required this.c_id,this.id, required this.name
      });

  SubItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    c_id = json['c_id'];
    name = json['name'].toString();
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['c_id'] = this.c_id;
    data['name'] = this.name;

    return data;
  }
}


