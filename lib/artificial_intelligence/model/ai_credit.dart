
class AICredit {
  final int userId;
  int totalCredits;
  DateTime lastUpdated;

  AICredit({
    required this.userId,
    required this.totalCredits,
    required this.lastUpdated,
  });

  factory AICredit.fromMap(Map<String, dynamic> map) {
    return AICredit(
      userId: map['user_id'],
      totalCredits: map['total_credits'],
      lastUpdated: DateTime.parse(map['last_updated']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'total_credits': totalCredits,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}