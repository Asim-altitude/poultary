import 'dart:async';
import 'dart:core';



class Finance_Report_Item{

  String f_name = "";
  String salePurchaseItem = "";
  String income = '';
  String expense = '';
  String date = '';

  Finance_Report_Item(
      {
        required this.f_name,required this.date, required this.salePurchaseItem,required this.income,required this.expense
      });

  Finance_Report_Item.fromJson(Map<String, dynamic> json) {
    f_name = json['f_name'].toString();
    salePurchaseItem = json['salePurchaseItem'];
    income = json['income'];
    expense = json['expense'];
    date = json['date'].toString();

  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['f_name'] = this.f_name;
    data['salePurchaseItem'] = this.salePurchaseItem;
    data['income'] = this.income;
    data['expense'] = this.expense;
    data['date'] = this.date;

    return data;
  }

  String getIndex(int index) {
    switch (index) {
      case 0:
        return salePurchaseItem;
      case 1:
        return f_name;
      case 2:
        return date;
      case 3:
        return income;
      case 4:
        return expense;
    }
    return '';
  }
}


