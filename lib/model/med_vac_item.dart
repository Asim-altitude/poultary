import 'dart:core';


class Vaccination_Medication {

  int? id;
  int? f_id;
  String disease = "";
  String medicine = "";
  String date = "";
  String quantity = "";
  String unit = "";
  String type = "";
  String f_name = "";
  String short_note = "";
  String doctor_name = "";
  int bird_count = 0;


  Vaccination_Medication({this.id,required this.f_id,required this.f_name,required this.disease,required this.medicine,
    required this.date,required this.type,required this.short_note,required this.bird_count,required this.doctor_name, required this.quantity, required this.unit});

  Vaccination_Medication.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    f_id = json["f_id"];
    f_name = json["f_name"];
    disease = json['disease'].toString();
    medicine = json['medicine'].toString();
    date = json['date'].toString();
    type = json['type'].toString();
    short_note = json['short_note'].toString();
    bird_count = json["bird_count"];
    doctor_name = json['doctor_name'];
    quantity = json['quantity'];
    unit = json['unit'];

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['f_id'] = this.f_id;
    data['disease'] = this.disease;
    data['medicine'] = this.medicine;
    data['date'] = this.date;
    data['type'] = this.type;
    data['short_note'] = this.short_note;
    data['bird_count'] = this.bird_count;
    data['doctor_name'] = this.doctor_name;
    data['f_name'] = this.f_name;
    data['quantity'] = this.quantity;
    data['unit'] = this.unit;

    return data;
  }

}


