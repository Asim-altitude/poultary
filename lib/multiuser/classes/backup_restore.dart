import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/home_screen.dart';
import 'package:poultary/multiuser/classes/WorkerDashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/databse_helper.dart';
import '../../utils/session_manager.dart';
import '../../utils/utils.dart';
import '../model/user.dart';
import '../utils/FirebaseUtils.dart';
import 'package:http/http.dart' as http;

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
    setState(() {

    });

    print("BACKUP_URL $latestBackupUrl");
    final uri = Uri.parse(latestBackupUrl);
    final client = http.Client();
    final request = http.Request('GET', uri);
    final response = await client.send(request);

    if (response.statusCode != 200) {
      print("Failed to download DB file");
    }

    File abcd = await DatabaseHelper.instance.dBToCopy();

    // Prepare file path
    String recoveryPath =
        "${abcd.absolute.path}/assets/poultary.db";

    final file = File(recoveryPath);
    final sink = file.openWrite();

    final contentLength = response.contentLength ?? 0;
    int bytesReceived = 0;

    // Listen to stream and write to file while updating progress
    await response.stream.listen(
          (chunk) {
        bytesReceived += chunk.length;
        sink.add(chunk);
        if (contentLength > 0) {
          downloadProgress.value = bytesReceived / contentLength;
        }
      },
      onDone: () async {
        await sink.close();

        // 🔑 Reset database connection
        await DatabaseHelper.instance.database; // forces re-open

        await SessionManager.setBoolValue('db_initialized_${user!.farmId}', true);
        downloadProgress.value = 1.0;
        print("Database download complete.");
        downloadingDB = false;
        Utils.showToast("RESTORE_SUCCESSFUL".tr());


        if(widget.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        }
        else{
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => WorkerDashboardScreen(name: widget.user.name, email: widget.user.email, role: widget.user.role)),
          );
        }


      },
      onError: (e) {
        sink.close();
        Utils.showToast("BACKUP_FAILED".tr());

        isRestoring = false;
        isErrorOccured = true;
        setState(() {

        });
        throw Exception("Download failed: $e");
      },
      cancelOnError: true,
    );

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

        if(!isBackupFound){
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        } else
        {

          handleRestore();

        }
        setState(() {

        });
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
              SizedBox(height: 20),
              Text(
                'Restoring...'.tr(),
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ) : isErrorOccured?   Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
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
                child: Row(
                  children: [
                    Icon(Icons.restore, color: Colors.red, size: 30,),
                    Text(
                      'Try Again'.tr(),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ) : SizedBox.shrink(),
        ),
      ),
    );
  }


}
