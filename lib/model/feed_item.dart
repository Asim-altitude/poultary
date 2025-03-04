import 'dart:core';

class Feeding{

  int? id;
  int? f_id;
  String? date;
  String f_name = "";
  String? feed_name;
  String? short_note;
  String? quantity;

  Feeding(
      {
        required this.f_id,this.id, required this.feed_name, required this.f_name, required this.quantity, required this.date,required this.short_note
      });

  Feeding.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    f_id = json['f_id'];
    f_name = json['f_name'];
    feed_name = json['feed_name'].toString();
    quantity = json['quantity'].toString();
    date = json['feeding_date'].toString();
    short_note = json['short_note'].toString();
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['f_id'] = this.f_id;
    data['f_name'] = this.f_name;
    data['feed_name'] = this.feed_name;
    data['quantity'] = this.quantity;
    data['feeding_date'] = this.date;
    data['short_note'] = this.short_note;

    return data;
  }
}


