import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:easy_localization/easy_localization.dart';

class NetworkSnackNotifier {
  static final NetworkSnackNotifier _instance = NetworkSnackNotifier._internal();
  factory NetworkSnackNotifier() => _instance;
  NetworkSnackNotifier._internal();

  OverlayEntry? _overlayEntry;
  late StreamSubscription _connectivitySubscription;

  void initialize(BuildContext context) {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);

      if (!hasConnection) {
        final hasAccess = await InternetConnectionChecker().hasConnection;
        if (!hasAccess) {
          _showOverlay(context);
        } else {
          _removeOverlay();
        }
      } else {
        _removeOverlay();
      }
    });
  }

  void dispose() {
    _connectivitySubscription.cancel();
    _removeOverlay();
  }

  void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'no_internet_message'.tr(), // Make sure to add this key in your localization
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    InkWell(
                        onTap: () {
                          _removeOverlay();
                        },
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: Text("Close".tr(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
