
import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'RefreshEventBus.dart';

mixin RefreshMixin<T extends StatefulWidget> on State<T> {
  late final StreamSubscription _refreshSub;

  @override
  void initState() {
    super.initState();
    _refreshSub = RefreshEventBus().stream.listen(onRefreshEvent);
  }

  @override
  void dispose() {
    _refreshSub.cancel();
    super.dispose();
  }

  /// Override this in your widget to respond to refresh events
  void onRefreshEvent(String event) {}
}
