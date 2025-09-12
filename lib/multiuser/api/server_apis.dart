import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:poultary/multiuser/model/user.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/utils/session_manager.dart';

import '../../database/databse_helper.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../../utils/utils.dart';

ValueNotifier<double> uploadProgress = ValueNotifier(0.0);

class FlockImageUploader {
  final String uploadUrl = 'https://photogallerytv.com/Api/upload_flock_images.php';
  final String uploadProfilePicUrl = 'https://photogallerytv.com/Api/upload_profile_picture.php';

  int uploadedBytes = 0;

  Future<List<String>> uploadFlockImages({
    required String farmId,
    required List<String> base64Images,
  }) async
  {
    final response = await http.post(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'farm_id': farmId,
        'images': base64Images,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'success') {
        return List<String>.from(json['urls']);
      } else {
        throw Exception('Upload failed: ${json['message'] ?? 'Unknown error'}');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }


  Future<String> uploadProfilePicture({
    required String userId,
    required String base64Image,
  }) async {
    final response = await http.post(
      Uri.parse(uploadProfilePicUrl), // your profile upload PHP API endpoint
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'image': base64Image,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'success') {
        return json['url']; // return the uploaded image URL
      } else {
        throw Exception('Upload failed: ${json['message'] ?? 'Unknown error'}');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }


  Future<void> uploadDatabaseFile(String farmId) async {
    File dbFile = await DatabaseHelper.getFilePathDB();
    final fileLength = await dbFile.length();
    final uri = Uri.parse("https://photogallerytv.com/Api/upload_db.php");

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Content-Type': 'multipart/form-data',
    });
    request.fields['farm_id'] = farmId;

    final stream = http.ByteStream(dbFile.openRead().transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          uploadedBytes += data.length;
          uploadProgress.value = uploadedBytes / fileLength;
          sink.add(data);
        },
      ),
    ));

    var multipartFile = http.MultipartFile(
      'db_file',
      stream,
      fileLength,
      filename: path.basename(dbFile.path),
    );

    request.files.add(multipartFile);

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        MultiUser? multiUser = await SessionManager.getUserFromPrefs();
        final responseBody = await response.stream.bytesToString();
        final json = jsonDecode(responseBody);
        if (json['status'] == 'success') {

          final dbUrl = json['url'];
          print("Upload successful. DB URL: ${json['url']}");
          /// ✅ Save to Firestore
          await FirebaseFirestore.instance.collection(FireBaseUtils.DB_BACKUP).doc(farmId).set({
            'last_backup_url': dbUrl,
            'timestamp': FieldValue.serverTimestamp(),
            'uploaded_by': multiUser!.email,
          });

          print("Backup info saved to Firestore!");
          Utils.showToast("✅ Backup Updated Successfully".tr());
          Utils.shouldBackup = false;
          await SessionManager.saveBackupTimestamp();
        } else {
          print("BACKUP FAILED $json");
          Utils.showToast("❌ Could not Backup".tr());

          throw Exception("Server error: ${json['message']}");
        }
      } else {
        Utils.showToast("❌ Could not Backup".tr());
      throw Exception("HTTP ${response.statusCode}: Upload failed");
      }
    } catch (e) {
      print("Upload error: $e");
      rethrow;
    }
  }

  Future<String?> downloadImageAsBase64(String imageUrl) async {
    try {
      print("DOWNLOADING "+imageUrl);
      final response = await http.get(Uri.parse(Utils.ProxyAPI+imageUrl));
      if (response.statusCode == 200) {
        print("DONE");
        final bytes = response.bodyBytes;
        return base64Encode(bytes);
      } else {
        print('❌ Failed to download image: $imageUrl');
        print('FAILED');
        return null;
      }
    } catch (e) {
      print('❌ Error downloading image: $e');
      print('FAILED ${e.toString()}');
      return null;
    }
  }
  
  // Optional: Use image picker to test
  Future<List<File>> pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 60); // compress
    if (pickedFiles == null) return [];
    return pickedFiles.map((x) => File(x.path)).toList();
  }
}
