import 'dart:async';
import 'dart:core';



class Flock_Image{

  int? f_id = -1;
  String image = "";

  Flock_Image(
      {
        required this.f_id, required this.image
      });

  Flock_Image.fromJson(Map<String, dynamic> json) {
    f_id = json['f_id'];
    image = json['image'].toString();

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['f_id'] = this.f_id;
    data['image'] = this.image;


    return data;
  }
}


