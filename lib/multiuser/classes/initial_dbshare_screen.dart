import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class InitialDatabaseShareScreen extends StatefulWidget {

  const InitialDatabaseShareScreen({Key? key})
      : super(key: key);

  @override
  State<InitialDatabaseShareScreen> createState() =>
      _InitialDatabaseShareScreenState();
}

class _InitialDatabaseShareScreenState
    extends State<InitialDatabaseShareScreen> {
  bool isLoading = true;
  String statusKey = "db_share_preparing"; // key for localization

  @override
  void initState() {
    super.initState();
    _startSharing();
  }

  Future<void> _startSharing() async {
    try {
      setState(() {
        statusKey = "db_share_uploading";
        isLoading = true;
      });


      setState(() {
        isLoading = false;
        statusKey = "db_share_success";
      });

      // Wait a bit before navigating
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/home");
    } catch (e) {
      setState(() {
        isLoading = false;
        statusKey = "db_share_failed";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const CircularProgressIndicator(strokeWidth: 4)
                else if (statusKey == "db_share_success")
                  Icon(Icons.check_circle,
                      size: 120, color: Colors.greenAccent)
                else
                  Icon(Icons.error_outline,
                      size: 120, color: Colors.redAccent),

                const SizedBox(height: 30),

                Text(
                  statusKey.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                if (!isLoading && statusKey == "db_share_failed")
                  ElevatedButton.icon(
                    onPressed: _startSharing,
                    icon: const Icon(Icons.refresh),
                    label: Text("retry".tr()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
