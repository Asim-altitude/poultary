import 'dart:async';
import 'dart:core';



class Flock_Detail{

  int f_id = -1;
  int? f_detail_id;
  int item_count = 0;
  String item_type = "";
  String f_name = "";
  String acqusition_type = "";
  String acqusition_date = "";
  String short_note = "";
  String reason = "";
  String transaction_id = "";

  Flock_Detail(
      {
        required this.f_id, required this.f_name, required this.item_type,required this.item_count
        ,required this.acqusition_type,required this.acqusition_date,required this.reason,required this.short_note,
        required this.transaction_id
      });

  Flock_Detail.fromJson(Map<String, dynamic> json) {
    f_id = json['f_id'];
    f_detail_id = json['f_detail_id'];
    item_type = json['item_type'].toString();
    f_name = json['f_name'].toString();
    item_count = json['item_count'];
    acqusition_date = json['acqusition_date'].toString();
    short_note = json['short_note'].toString();
    reason = json['reason'].toString();
    transaction_id = json['transaction_id'] ?? "-1";
    acqusition_type = json['acqusition_type'].toString();

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    data["f_id"] = this.f_id;
    data['item_type'] = this.item_type;
    data['f_name'] = this.f_name;
    data['reason'] = this.reason;
    data['acqusition_date'] = this.acqusition_date;
    data['acqusition_type'] = this.acqusition_type;
    data['short_note'] = this.short_note;
    data['item_count'] = this.item_count;
    data['transaction_id'] = this.transaction_id;

    return data;
  }
}


