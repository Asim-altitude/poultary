import 'dart:async';
import 'dart:core';



class Egg_Report_Item{

  String f_name = "";
  int? collected = 0;
  int? reduced = 0;
  int? reserve = 0;
  int? good_eggs = 0;
  int bad_eggs = 0;

  Egg_Report_Item(
      {
        required this.f_name,required this.collected,required this.reduced,required this.reserve,
      });

  Egg_Report_Item.fromJson(Map<String, dynamic> json) {
    f_name = json['f_name'].toString();
    collected = json['collected'];
    reduced = json['reduced'];
    reserve = json['reserve'];

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['f_name'] = this.f_name;
    data['collected'] = this.collected;
    data['reduced'] = this.reduced;
    data['reserve'] = this.reserve;

    return data;
  }

  String getIndex(int index) {
    switch (index) {
      case 0:
        return f_name;
      case 1:
        return collected.toString();
      case 2:
        return reduced.toString();
      case 3:
        return reserve.toString();

    }
    return '';
  }
}


