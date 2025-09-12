import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutAppPage extends StatefulWidget {

  const AboutAppPage({Key? key}) : super(key: key);

  @override
  _AboutAppPage createState() => _AboutAppPage();
}

class _AboutAppPage extends State<AboutAppPage> {
  String appVersion = "1.0.0";

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }



  Future<void> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion =  "${packageInfo.version} ${packageInfo.buildNumber}";

    setState(() {

    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getAppVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text("About App".tr()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text("Easy Poultry - Chicken Manager".tr(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
            Text("Version".tr()+" "+ appVersion,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
             Text(
              "app_desc".tr(),
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
             Text("Key Features:".tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
             Text("• Flock and Bird Management".tr()),
             Text("• Egg Production and Collection Tracking".tr()),
             Text("• Feed Stock and Consumption Records".tr()),
             Text("• Financial Transactions and Reports".tr()),
             Text("• Multi-user Role Management".tr()),
             Text("• Data Backup and Sync".tr()),
            const SizedBox(height: 16),
             Text("Contact Us:".tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            InkWell(
              onTap: () => _launchUrl("mailto:zaheer6110@gmail.com"),
              child: const Text("zaheer6110@gmail.com",
                  style: TextStyle(color: Colors.blue)),
            ),
            InkWell(
              onTap: () => _launchUrl("https://www.poultryhatch.com"),
              child: const Text("www.poultryhatch.com",
                  style: TextStyle(color: Colors.blue)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  _launchUrl("https://www.poultryhatch.com/p/egg-hatching-manager-privacy-policy.html"),
              child:  Text("Privacy Policy".tr(), style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, ),
            ),
          ],
        ),
      ),
    );
  }
}
