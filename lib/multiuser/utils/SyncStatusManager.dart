import 'package:flutter/material.dart';

class SyncStatusWidget extends StatelessWidget {
  final bool isSyncing;
  final int completed;
  final int total;

  const SyncStatusWidget({
    Key? key,
    required this.isSyncing,
    required this.completed,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isSyncing) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          Expanded(
            child: Text(
              "Syncing data... $completed/$total",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
