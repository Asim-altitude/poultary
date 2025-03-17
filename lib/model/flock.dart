import 'dart:async';
import 'dart:core';



class Flock{

  int f_id = -1;
  String f_name = "";
  int? bird_count;
  int active = 1;
  int? active_bird_count;
  int? flock_new;
  String purpose = "";
  String icon = "";
  String acqusition_type = "";
  String acqusition_date = "";
  String notes = "";

  Flock({
        required this.f_id, required this.f_name,required this.bird_count, required this.active_bird_count,required this.purpose
        ,required this.acqusition_type,required this.flock_new,required this.acqusition_date,required this.notes,required this.icon, required this.active
      });

  Flock.fromJson(Map<String, dynamic> json) {
    f_id = json['f_id'];
    active = json['active'];
    f_name = json['f_name'].toString();
    purpose = json['purpose'].toString();
    bird_count = json['bird_count'];
    active_bird_count = json['active_bird_count'];
    acqusition_date = json['acqusition_date'].toString();
    notes = json['notes'].toString();
    icon = json['icon'].toString();
    flock_new = json['flock_new'];
    acqusition_type = json['acqusition_type'].toString();


  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['f_name'] = this.f_name;
    data['purpose'] = this.purpose;
    data['acqusition_date'] = this.acqusition_date;
    data['acqusition_type'] = this.acqusition_type;
    data['notes'] = this.notes;
    data['icon'] = this.icon;
    data['active'] = this.active;
    data['flock_new'] = this.flock_new;
    data['active_bird_count'] = this.active_bird_count;
    data['bird_count'] = this.bird_count;

    return data;
  }

  // CopyWith Method (For Easy Updates)
  Flock copyWith({
    int? fId,
    String? fName,
    int? birdCount,
    int? active,
    int? activeBirdCount,
    int? flockNew,
    String? purpose,
    String? icon,
    String? acquisitionType,
    String? acquisitionDate,
    String? notes,
  }) {
    return Flock(
      f_id: fId ?? this.f_id,
      f_name: fName ?? this.f_name,
      bird_count: birdCount ?? this.bird_count,
      active: active ?? this.active,
      active_bird_count: active_bird_count ?? this.active_bird_count,
      flock_new: flockNew ?? this.flock_new,
      purpose: purpose ?? this.purpose,
      icon: icon ?? this.icon,
      acqusition_type: acquisitionType ?? this.acqusition_type,
      acqusition_date: acquisitionDate ?? this.acqusition_date,
      notes: notes ?? this.notes,
    );
  }
}


