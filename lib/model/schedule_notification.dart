import 'package:poultary/model/recurrence_type.dart';

class ScheduledNotification {
  int id;
  final String birdType;
  final int flockId;
  final String title;
  final String description;
  final DateTime scheduledAt;
  final RecurrenceType recurrence;

  ScheduledNotification({
    required this.id,
    required this.birdType,
    required this.flockId,
    required this.title,
    required this.description,
    required this.scheduledAt,
    required this.recurrence,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bird_type': birdType,
      'flock_id': flockId,
      'title': title,
      'description': description,
      'scheduled_at': scheduledAt.toIso8601String(),
      'recurrence': recurrence.name,
    };
  }

  static ScheduledNotification fromMap(Map<String, dynamic> map) {
    return ScheduledNotification(
      id: map['id'],
      birdType: map['bird_type'],
      flockId: map['flock_id'],
      title: map['title'],
      description: map['description'],
      scheduledAt: DateTime.parse(map['scheduled_at']),
      recurrence: RecurrenceType.values.firstWhere((e) => e.name == map['recurrence']),
    );
  }


}

