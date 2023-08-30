import 'dart:async';
import 'dart:core';



class Bird{

  int? id = -1;
  String image = "";
  String name = "";

  Bird(
      {
        required this.id,required this.name, required this.image
      });

  Bird.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    image = json['image'].toString();
    name = json['name'].toString();

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['image'] = this.image;
    data['name'] = this.name;


    return data;
  }
}


