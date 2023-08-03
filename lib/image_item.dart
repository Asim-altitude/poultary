import 'dart:async';
import 'dart:core';



class Flock_Image{

  int? id = -1;
  int? f_id = -1;
  String image = "";


  Flock_Image(
      {
        required this.id, required this.image
      });

  Flock_Image.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    f_id = json['f_id'];
    image = json['image'];

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['image'] = this.image;
    data['f_id'] = this.f_id;

    return data;
  }
}


