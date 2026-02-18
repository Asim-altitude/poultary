import 'enums.dart';

/// Information about the user's flock
class FlockInfo {
  /// Primary bird species
  final BirdSpecies primarySpecies;

  /// Approximate age of flock in weeks (optional)
  final int? avgAgeWeeks;

  /// Date the current flock was started (optional)
  final DateTime? flockStartDate;

  /// User's country code (e.g. 'US', 'IN', 'NG') — optional, not used for
  /// benchmarking but can be used for currency display hints
  final String? countryCode;

  /// User's currency symbol (e.g. '$', '₹', '₦', '£')
  final String currencySymbol;

  /// Whether this is an indoor or outdoor operation
  final bool? isIndoor;

  /// Approximate flock capacity (total birds the farm can hold)
  final int? farmCapacity;

  const FlockInfo({
    required this.primarySpecies,
    required this.currencySymbol,
    this.avgAgeWeeks,
    this.flockStartDate,
    this.countryCode,
    this.isIndoor,
    this.farmCapacity,
  });

  /// Computes estimated current age in weeks if startDate is provided
  int? get estimatedCurrentAgeWeeks {
    if (flockStartDate == null) return avgAgeWeeks;
    final weeks =
        DateTime.now().difference(flockStartDate!).inDays ~/ 7;
    return weeks;
  }

  Map<String, dynamic> toJson() => {
        'primarySpecies': primarySpecies.name,
        'avgAgeWeeks': avgAgeWeeks,
        'flockStartDate': flockStartDate?.toIso8601String(),
        'countryCode': countryCode,
        'currencySymbol': currencySymbol,
        'isIndoor': isIndoor,
        'farmCapacity': farmCapacity,
      };

  factory FlockInfo.fromJson(Map<String, dynamic> json) => FlockInfo(
        primarySpecies: BirdSpecies.values.firstWhere(
          (e) => e.name == json['primarySpecies'],
          orElse: () => BirdSpecies.other,
        ),
        currencySymbol: json['currencySymbol'] as String? ?? '',
        avgAgeWeeks: json['avgAgeWeeks'] as int?,
        flockStartDate: json['flockStartDate'] != null
            ? DateTime.parse(json['flockStartDate'] as String)
            : null,
        countryCode: json['countryCode'] as String?,
        isIndoor: json['isIndoor'] as bool?,
        farmCapacity: json['farmCapacity'] as int?,
      );
}
