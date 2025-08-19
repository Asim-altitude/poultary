import 'package:cloud_firestore/cloud_firestore.dart';

class FarmPlan {
  final String farmId;
  final String adminEmail;
  final String planName;
  final String planType;
  final DateTime planStartDate;
  final DateTime planExpiryDate;
  final int userCapacity;

  FarmPlan({
    required this.farmId,
    required this.adminEmail,
    required this.planName,
    required this.planType,
    required this.planStartDate,
    required this.planExpiryDate,
    required this.userCapacity,
  });

  /// 🔽 Create from Firestore (Map<String, dynamic>)
  factory FarmPlan.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      } else if (value is DateTime) {
        return value;
      } else {
        throw FormatException("Invalid date format: $value");
      }
    }

    return FarmPlan(
      farmId: json['farm_id'] ?? '',
      adminEmail: json['admin_email'] ?? '',
      planType: json['plan_type'] ?? 'Free',
      planName: json['plan_name'] ?? 'Unknown Plan',
      planStartDate: parseDate(json['plan_start']),
      planExpiryDate: parseDate(json['plan_expiry']),
      userCapacity: json['user_capacity'] ?? 1,
    );
  }



  /// 🔼 Convert to Firestore (Map<String, dynamic>)
  Map<String, dynamic> toJson() {
    return {
      'farm_id': farmId,
      'admin_email': adminEmail,
      'plan_name': planName,
      'plan_type' : planType,
      'plan_start': planStartDate.toIso8601String(),
      'plan_expiry': planExpiryDate.toIso8601String(),
      'user_capacity': userCapacity,
    };
  }

  /// ✅ Check if plan is currently active
  bool get isActive => planExpiryDate.isAfter(DateTime.now());

  /// ✅ Get days left
  int get daysLeft => planExpiryDate.difference(DateTime.now()).inDays;
}
