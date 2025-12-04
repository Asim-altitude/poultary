import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/home_screen.dart';
import 'package:poultary/multiuser/classes/WorkerDashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auto_add_feed_screen.dart';
import '../../database/databse_helper.dart';
import '../../utils/session_manager.dart';
import '../../utils/utils.dart';
import '../model/user.dart';
import '../utils/FirebaseUtils.dart';
import 'package:http/http.dart' as http;

import 'initial_dbshare_screen.dart';

class BackupFoundScreen extends StatefulWidget {

  final bool isAdmin;
  final MultiUser user;

  const BackupFoundScreen({ Key? key, required this.isAdmin, required this.user}) : super(key: key);

  @override
  State<BackupFoundScreen> createState() => _BackupFoundScreenState();

}

class _BackupFoundScreenState extends State<BackupFoundScreen> {

  bool isLooking = false;
  bool isBackupFound = false;
  bool isRestoring = false;
  bool isErrorOccured = false;
  bool downloadingDB = false;

  String latestBackupUrl = "";


  ValueNotifier<double> downloadProgress = ValueNotifier(0.0);

  Future<void> handleRestore() async {
    isRestoring = true;
    isBackupFound = false;
    isLooking = false;
    setState(() {});

    print("BACKUP_URL $latestBackupUrl");
    final uri = Uri.parse(latestBackupUrl);

    final client = http.Client();
    final request = http.Request('GET', uri);

    try {
      final response = await client.send(request).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception("❌ Failed to download DB file, status: ${response.statusCode}");
      }

      File abcd = await DatabaseHelper.instance.dBToCopy();
      String recoveryPath = "${abcd.absolute.path}/assets/poultary.db";

      final file = File(recoveryPath);
      final sink = file.openWrite();

      final contentLength = response.contentLength ?? 0;
      int bytesReceived = 0;

      await response.stream.listen(
            (chunk) {
          bytesReceived += chunk.length;
          sink.add(chunk);

          if (contentLength > 0) {
            // 🔄 update notifier for progress bar
            downloadProgress.value = bytesReceived / contentLength;
          }
        },
        onDone: () async {
          await sink.close();
          await DatabaseHelper.instance.database; // reopen DB
          await SessionManager.setBoolValue('db_initialized_${user!.farmId}', true);

          downloadProgress.value = 1.0;
          print("✅ Database download complete.");
          downloadingDB = false;
          Utils.showToast("RESTORE_SUCCESSFUL".tr());
          SharedPreferences prefs = await SharedPreferences.getInstance();
          bool isAutoFeedEnabled = prefs.getBool('isAutoFeedEnabled') ?? false;

          if (widget.isAdmin) {
            if(isAutoFeedEnabled){
              Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) =>
                    AutoFeedSyncScreen(),)
                , (route) => false,);
            }else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
              );
            }
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => WorkerDashboardScreen(
                  name: widget.user.name,
                  email: widget.user.email,
                  role: widget.user.role,
                ),
              ),
            );
          }
        },
        onError: (e) async {
          await sink.close();
          Utils.showToast("BACKUP_FAILED".tr());
          isRestoring = false;
          isErrorOccured = true;
          setState(() {});
          print("❌ Download failed: $e");
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("❌ Restore exception: $e");
      Utils.showToast("BACKUP_FAILED".tr());
      isRestoring = false;
      isErrorOccured = true;
      setState(() {});
    }
  }

  MultiUser? user = null;
  Future<void> checkMultiUSer() async {
    try {
      if (Utils.isMultiUSer) {

        user = await SessionManager.getUserFromPrefs();

        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool initialized = prefs.getBool('db_initialized_${user!.farmId}') ?? false;

        if (initialized) {
          print("Database already initialized for farm ${user!.farmId}");
          return;
        }

         latestBackupUrl = await getLatestBackupUrlFromFirestore(user!.farmId);
        if (latestBackupUrl != null && latestBackupUrl != '') {
          isLooking = false;
          isBackupFound = true;
        } else {
          isLooking = false;
          isBackupFound = false;
        }
        setState(() {

        });
        if(!isBackupFound){
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        } else
        {

          handleRestore();

        }

      }
    }
    catch(ex){
      print(ex);
    }
  }

  Future<String> getLatestBackupUrlFromFirestore(String farmId) async {
    final doc = await FirebaseFirestore.instance.collection(FireBaseUtils.DB_BACKUP).doc(farmId).get();
    return doc.data()?['last_backup_url'] ?? '';
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkMultiUSer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: isLooking
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Looking for backup...'.tr(),
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          )
              : isBackupFound? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.backup, size: 80, color: Colors.blueAccent),
              SizedBox(height: 20),
              Text(
                'Backup Found'.tr(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'We found a backup for your farm data.\nWould you like to restore it?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => HomeScreen()),
                        ); // cancel
                      },
                      child: Text('CANCEL'.tr()),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: handleRestore,
                      child: Text('Restore'.tr(), style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ) : isRestoring?
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              Container(
                margin: EdgeInsets.only(left: 20, right: 20),
                child: ValueListenableBuilder<double>(
                  valueListenable: downloadProgress,
                  builder: (context, value, _) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${(value * 100).toStringAsFixed(0)}%"),
                        LinearProgressIndicator(
                          value: value, // between 0.0 and 1.0
                          minHeight: 8,
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Restoring...'.tr(),
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ) : isErrorOccured?   Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Text(
                'Error Occured. Try Again.'.tr(),
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              InkWell(
                onTap: () {
                  isLooking = true;
                  isErrorOccured = false;
                  isBackupFound = false;
                  isRestoring = false;
                  setState(() {

                  });
                  checkMultiUSer();
                },
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // keep row tight
                    children: [
                      Icon(Icons.restore, color: Colors.red, size: 30),
                      SizedBox(width: 6),
                      Text(
                        'Try Again'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

              ),
            ],
          ) : SizedBox.shrink(),
        ),
      ),
    );
  }


}
