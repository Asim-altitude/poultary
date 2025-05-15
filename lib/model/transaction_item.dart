import 'dart:core';

class TransactionItem {

  int? id = -1;
  int? f_id = -1;
  String date = "";
  String f_name = "";
  String sale_item = "";
  String expense_item = "";
  String type = "";
  String amount = "";
  String payment_method = "";
  String payment_status = "";
  String sold_purchased_from = "";
  String short_note = "";
  String how_many = "";
  String extra_cost = "";
  String extra_cost_details = "";
  String flock_update_id = "";

  TransactionItem(
      {
        required this.f_id, required this.date,required this.f_name, required this.sale_item,
        required this.expense_item, required this.type, required this.amount
     , required this.payment_method, required this.payment_status, required this.sold_purchased_from
        , required this.short_note, required this.how_many, required this.extra_cost,
        required this.extra_cost_details,required this.flock_update_id
      });

  TransactionItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    f_id = json['f_id'];
    date = json['date'];
    f_name = json['f_name'];
    sale_item = json['sale_item'];
    expense_item = json['expense_item'];
    type = json['type'];
    amount = json['amount'];
    sold_purchased_from = json['sold_purchased_from'];
    short_note = json['short_note'];
    how_many = json['how_many'];
    extra_cost = json['extra_cost'];
    flock_update_id = json['flock_update_id'] ?? "-1";
    extra_cost_details = json['extra_cost_details'].toString();
    payment_status = json['payment_status'].toString();
    payment_method = json['payment_method'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    data['f_id'] = this.f_id;
    data['date'] = this.date;
    data['f_name'] = this.f_name;
    data['sale_item'] = this.sale_item;
    data['expense_item'] = this.expense_item;
    data['type'] = this.type;
    data['amount'] = this.amount;
    data['sold_purchased_from'] = this.sold_purchased_from;
    data['short_note'] = this.short_note;
    data['how_many'] = this.how_many;
    data['flock_update_id'] = this.flock_update_id;
    data['extra_cost'] = this.extra_cost;
    data['extra_cost_details'] = this.extra_cost_details;
    data['payment_status'] = this.payment_status;
    data['payment_method'] = this.payment_method;


    return data;
  }
}


