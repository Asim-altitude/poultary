
import 'dart:async';

class RefreshEventBus {
  static final RefreshEventBus _instance = RefreshEventBus._internal();

  factory RefreshEventBus() => _instance;
  RefreshEventBus._internal();

  final StreamController<String> _refreshController = StreamController<String>.broadcast();

  Stream<String> get stream => _refreshController.stream;

  void emit(String eventKey) {
    _refreshController.add(eventKey);
  }

  void dispose() {
    _refreshController.close();
  }
}
