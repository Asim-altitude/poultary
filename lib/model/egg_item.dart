import 'dart:async';
import 'dart:core';



class Eggs{

  int? id;
  int f_id = -1;
  String? image;
  String? f_name;
  int good_eggs = 0;
  int bad_eggs = 0;
  int total_eggs = 0;
  String? date;
  String? short_note;


  Eggs(
      {
        required this.f_id,required this.f_name, this.id, required this.image, required this.good_eggs,required this.bad_eggs
        , required this.total_eggs, required this.date,required this.short_note
      });

  Eggs.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    f_id = json['f_id'];
    image = json['image'].toString();
    f_name = json['f_name'].toString();
    good_eggs = json['good_eggs'];
    bad_eggs = json['spoilt_eggs'];
    total_eggs = json['total_eggs'];
    date = json['collection_date'].toString();
    short_note = json['short_note'].toString();

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['f_id'] = this.f_id;
    data['image'] = this.image;
    data['f_name'] = this.f_name;
    data['good_eggs'] = this.good_eggs;
    data['spoilt_eggs'] = this.bad_eggs;
    data['short_note'] = this.short_note;
    data['total_eggs'] = this.total_eggs;
    data['collection_date'] = this.date;


    return data;
  }
}


