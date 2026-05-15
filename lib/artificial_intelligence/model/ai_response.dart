class AIResponse {
  final int? id;
  final String flockId;
  final String category; // feed, health, financial
  final String title; // "Feed Suggestion"
  final String response;
  final int creditsUsed;
  final DateTime createdAt;

  // Optional metadata
  final int? birdCount;
  final int? ageWeeks;

  AIResponse({
    this.id,
    required this.flockId,
    required this.category,
    required this.title,
    required this.response,
    required this.creditsUsed,
    required this.createdAt,
    this.birdCount,
    this.ageWeeks,
  });

  factory AIResponse.fromMap(Map<String, dynamic> map) {
    return AIResponse(
      id: map['id'],
      flockId: map['flock_id'],
      category: map['category'],
      title: map['title'],
      response: map['response'],
      creditsUsed: map['credits_used'],
      createdAt: DateTime.parse(map['created_at']),
      birdCount: map['bird_count'],
      ageWeeks: map['age_weeks'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'flock_id': flockId,
      'category': category,
      'title': title,
      'response': response,
      'credits_used': creditsUsed,
      'created_at': createdAt.toIso8601String(),
      'bird_count': birdCount,
      'age_weeks': ageWeeks,
    };
  }
}