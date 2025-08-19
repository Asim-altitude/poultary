import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AccessExpiredCard extends StatelessWidget {
  final VoidCallback onUpgrade;

  const AccessExpiredCard({super.key, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red[50],
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.lock_clock, color: Colors.redAccent, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'access_expired_message'.tr(), // "Access Expired - Please Upgrade"
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[900],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('upgrade'.tr()), // "Upgrade"
            ),
          ],
        ),
      ),
    );
  }
}
