import 'dart:async';
import 'dart:core';



class CategoryItem{

  int? id;
  String? name;

  CategoryItem({
        required this.id, required this.name
  });

  CategoryItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'].toString();
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;

    return data;
  }
}


