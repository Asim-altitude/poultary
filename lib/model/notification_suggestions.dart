class SuggestedNotification {
  final String title;
  final String description;
  final int triggerDay; // age in days
  final String birdType;
  final String category;
  final bool isDefault;

  SuggestedNotification({
    required this.title,
    required this.description,
    required this.triggerDay,
    required this.birdType,
    required this.category,
    this.isDefault = true,
  });
}
