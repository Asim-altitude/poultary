class UpdateDeduplicator {
  // Singleton setup
  static final UpdateDeduplicator _instance = UpdateDeduplicator._internal();
  factory UpdateDeduplicator() => _instance;
  UpdateDeduplicator._internal();
  // Map: collectionKey → docId → lastModified
  final Map<String, Map<String, DateTime>> _handledUpdates = {};

  /// Returns true if the update should be processed
  bool shouldProcessUpdate(String key, String docId, DateTime lastModified) {
    final collectionMap = _handledUpdates.putIfAbsent(key, () => {});
    final previous = collectionMap[docId];

    if (previous == null || lastModified.isAfter(previous)) {
      collectionMap[docId] = lastModified;
      print("PROCESS DATA");
      return true;
    }

    print("DUPLICATE DATA OLD $previous NEW $lastModified");
    return false; // duplicate or stale
  }
}
