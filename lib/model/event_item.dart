import 'dart:async';
import 'dart:core';



class MyEvent {

  int? id;
  int f_id = -1;
  String? event_name;
  String? event_detail;
  int type = 0;
  int isActive = 0;
  String? date;
  String? flock_name;


  MyEvent(this.id, this.f_id,this.flock_name,this.event_name, this.event_detail, this.type,
      this.date, this.isActive);

  MyEvent.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    f_id = json['f_id'];
    flock_name = json['flock_name'];
    event_name = json['event_name'].toString();
    event_detail = json['event_detail'].toString();
    type = json['type'];
    date = json['date'];
    isActive = json['isActive'];
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['f_id'] = this.f_id;
    data['event_name'] = this.event_name;
    data['event_detail'] = this.event_detail;
    data['type'] = this.type;
    data['date'] = this.date;
    data['isActive'] = this.isActive;
    data['flock_name'] = this.flock_name;

    return data;
  }
}


