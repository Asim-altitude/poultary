import 'dart:math' as math;

/// Math utility functions for the insights engine
class InsightsMathUtils {
  InsightsMathUtils._();

  /// Calculate mean of a list of doubles
  static double mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Calculate median of a list of doubles
  static double median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  /// Calculate standard deviation
  static double stdDev(List<double> values) {
    if (values.length < 2) return 0;
    final avg = mean(values);
    final variance =
        values.map((v) => math.pow(v - avg, 2).toDouble()).reduce((a, b) => a + b) /
            (values.length - 1);
    return math.sqrt(variance);
  }

  /// Calculate coefficient of variation (stdDev / mean) as percentage
  /// Higher = more volatile/inconsistent
  static double coefficientOfVariation(List<double> values) {
    final avg = mean(values);
    if (avg == 0) return 0;
    return (stdDev(values) / avg) * 100;
  }

  /// Consistency score (100 = perfectly consistent, 0 = very volatile)
  static double consistencyScore(List<double> values) {
    final cv = coefficientOfVariation(values);
    return (100 - cv.clamp(0, 100)).clamp(0, 100).toDouble();
  }

  /// Linear regression slope (positive = increasing trend)
  /// Returns slope per unit index
  static double linearSlope(List<double> values) {
    final n = values.length;
    if (n < 2) return 0;

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumX2 += i * i.toDouble();
    }

    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) return 0;
    return (n * sumXY - sumX * sumY) / denominator;
  }

  /// Returns the trend direction based on slope relative to mean
  /// threshold = minimum % change per period to count as a trend
  static TrendClassification classifyTrend(
    List<double> values, {
    double strongThreshold = 0.10, // 10% change = strong
    double weakThreshold = 0.03,   // 3% change = minor
  }) {
    if (values.length < 5) {
      return TrendClassification(
        slopePercent: 0,
        isStrong: false,
        isImproving: false,
        isStable: true,
        insufficient: true,
      );
    }

    final avg = mean(values);
    if (avg == 0) {
      return TrendClassification(
        slopePercent: 0,
        isStrong: false,
        isImproving: false,
        isStable: true,
        insufficient: false,
      );
    }

    final slope = linearSlope(values);
    final slopePercent = (slope / avg); // fraction change per step

    final isStrong = slopePercent.abs() >= strongThreshold;
    final isMinor = slopePercent.abs() >= weakThreshold;

    return TrendClassification(
      slopePercent: slopePercent,
      isStrong: isStrong,
      isImproving: slopePercent > 0,
      isStable: !isMinor,
      insufficient: false,
    );
  }

  /// Percent change from old to new value
  static double percentChange(double oldValue, double newValue) {
    if (oldValue == 0) return 0;
    return ((newValue - oldValue) / oldValue) * 100;
  }

  /// Split list into two halves and compare means
  static double halfPeriodChange(List<double> values) {
    if (values.length < 4) return 0;
    final mid = values.length ~/ 2;
    final first = values.sublist(0, mid);
    final second = values.sublist(mid);
    final firstMean = mean(first);
    return percentChange(firstMean, mean(second));
  }

  /// Calculate 7-day moving averages
  static List<double> movingAverage(List<double> values, int window) {
    if (values.length < window) return values;
    final result = <double>[];
    for (int i = window - 1; i < values.length; i++) {
      final slice = values.sublist(i - window + 1, i + 1);
      result.add(mean(slice));
    }
    return result;
  }

  /// Detect outliers using IQR method
  /// Returns indices of outliers
  static List<int> detectOutliers(List<double> values, {double iqrMultiplier = 1.5}) {
    if (values.length < 4) return [];
    final sorted = List<double>.from(values)..sort();
    final q1 = sorted[sorted.length ~/ 4];
    final q3 = sorted[(sorted.length * 3) ~/ 4];
    final iqr = q3 - q1;
    final lower = q1 - iqrMultiplier * iqr;
    final upper = q3 + iqrMultiplier * iqr;

    final outliers = <int>[];
    for (int i = 0; i < values.length; i++) {
      if (values[i] < lower || values[i] > upper) {
        outliers.add(i);
      }
    }
    return outliers;
  }

  /// Simple exponential smoothing forecast
  /// alpha = smoothing factor (0.1 = heavy smoothing, 0.9 = light)
  static List<double> forecast(
    List<double> values,
    int periods, {
    double alpha = 0.3,
  }) {
    if (values.isEmpty) return [];
    double smoothed = values.first;
    for (final v in values) {
      smoothed = alpha * v + (1 - alpha) * smoothed;
    }
    return List.filled(periods, smoothed);
  }

  /// Safe division
  static double safeDivide(double numerator, double denominator) {
    if (denominator == 0) return 0;
    return numerator / denominator;
  }

  /// Clamp a score between 0 and 100
  static double clampScore(double value) => value.clamp(0, 100);

  /// Format a number to N decimal places
  static String format(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }

  /// Calculate percentage score for a trend direction (for overall score)
  static double trendToScore(double percentChange) {
    if (percentChange >= 15) return 100;
    if (percentChange >= 8) return 85;
    if (percentChange >= 3) return 70;
    if (percentChange >= -3) return 55;
    if (percentChange >= -8) return 40;
    if (percentChange >= -15) return 25;
    return 10;
  }
}

/// Result of trend classification
class TrendClassification {
  final double slopePercent;
  final bool isStrong;
  final bool isImproving;
  final bool isStable;
  final bool insufficient;

  const TrendClassification({
    required this.slopePercent,
    required this.isStrong,
    required this.isImproving,
    required this.isStable,
    required this.insufficient,
  });

  double get percentChangePerStep => slopePercent * 100;
}
