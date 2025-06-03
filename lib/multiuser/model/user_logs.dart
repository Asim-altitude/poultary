import 'package:cloud_firestore/cloud_firestore.dart';

class UserLog {
  final String farmId;
  final String email;
  final DateTime lastSigned;
  final String dataChanges;

  UserLog({
    required this.farmId,
    required this.email,
    required this.lastSigned,
    required this.dataChanges,
  });

  factory UserLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserLog(
      farmId: data['farm_id'],
      email: data['email'],
      lastSigned: (data['last_signed'] as Timestamp).toDate(),
      dataChanges: data['data_changes'],
    );
  }
}
