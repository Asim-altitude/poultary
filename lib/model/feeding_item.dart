import 'dart:async';
import 'dart:core';



class Feeding{

  int id = -1;
  int f_id = -1;
  String image = "";
  String feed_name = "";
  int? quantity;
  String? feeding_date;
  String? short_note;


  Feeding(
      {
        required this.f_id, required this.id, required this.image, required this.feed_name,required this.feeding_date
        ,required this.short_note,required this.quantity
      });

  Feeding.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    f_id = json['f_id'];
    quantity = json['quantity'];
    image = json['image'].toString();
    feed_name = json['feed_name'].toString();
    feeding_date = json['feeding_date'].toString();
    short_note = json['short_note'].toString();

  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['f_id'] = this.f_id;
    data['image'] = this.image;
    data['quantity'] = this.quantity;
    data['feed_name'] = this.feed_name;
    data['feeding_date'] = this.feeding_date;
    data['short_note'] = this.short_note;


    return data;
  }
}


