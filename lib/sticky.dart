import 'package:flutter/material.dart';
import 'package:poultary/utils/utils.dart';

class SingleChildScrollViewWithStickyFirstWidget extends StatelessWidget {
  final Widget child;

  SingleChildScrollViewWithStickyFirstWidget({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: child,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Utils.getAdBar(),
        ),
      ],
    );
  }
}