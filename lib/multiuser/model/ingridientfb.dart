
import '../../model/feed_ingridient.dart';

class IngredientFB {
  final String sync_id;
  final double qty;
  FeedIngredient? ingredient; // optional detailed data

  IngredientFB(this.sync_id, this.qty, {this.ingredient});

  /// 🔼 Convert to Firebase JSON
  Map<String, dynamic> toJson() {
    return {
      'sync_id': sync_id,
      'qty': qty,
      if (ingredient != null) 'ingredient': ingredient!.toLocalFBJson(),
    };
  }

  /// 🔽 Construct from Firebase JSON
  factory IngredientFB.fromJson(Map<String, dynamic> json) {
    return IngredientFB(
      json['sync_id'] ?? '',
      (json['qty'] as num).toDouble(),
      ingredient: json['ingredient'] != null
          ? FeedIngredient.fromJson(json['ingredient'])
          : null,
    );
  }

  /// 💾 For local storage if needed
  Map<String, dynamic> toLocalFBJson() {
    return {
      'sync_id': sync_id,
      'qty': qty,
      if (ingredient != null) 'ingredient': ingredient!.toLocalFBJson(),
    };
  }

  /// 🔽 From local JSON
  factory IngredientFB.fromLocalJson(Map<String, dynamic> json) {
    return IngredientFB(
      json['sync_id'] ?? '',
      (json['qty'] as num).toDouble(),
      ingredient: json['ingredient'] != null
          ? FeedIngredient.fromMap(json['ingredient'])
          : null,
    );
  }
}
