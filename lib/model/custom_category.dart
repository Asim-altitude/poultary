import 'package:flutter/cupertino.dart';

class CustomCategory {
   int? id;
   String name;
   String itemtype;
   String cat_type;
   String unit;
   int enabled;
   IconData icon;
   String cIcon = "";

  CustomCategory({
    this.id,
    required this.name,
    required this.itemtype,
    required this.cat_type,
    required this.unit,
    required this.enabled,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'itemtype': itemtype,
      'cat_type': cat_type,
      'unit': unit,
      'enabled': enabled,
      'icon': icon.codePoint, // Save icon as an integer
    };
  }

  factory CustomCategory.fromMap(Map<String, dynamic> map) {
    return CustomCategory(
      id: map['id'],
      name: map['name'],
      itemtype: map['itemtype'],
      unit: map['unit'],
      cat_type: map['cat_type'],
      enabled: map['enabled'],
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
    );
  }
}