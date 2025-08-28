import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poultary/database/databse_helper.dart';
import 'dart:math';
import 'package:poultary/home_screen.dart';
import 'package:poultary/multiuser/classes/AdminProfile.dart';
import 'package:poultary/multiuser/classes/AuthGate.dart';

import '../../utils/session_manager.dart';
import '../../utils/utils.dart';
import '../model/user.dart';
import '../utils/FirebaseUtils.dart';

class SignupForm extends StatefulWidget {
  @override
  _SignupFormState createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final farmNameController = TextEditingController();
  final farmIdController = TextEditingController();

  bool isLoading = false;


  Future<void> generateUniqueFarmId() async {
    String email = emailController.text.trim();

    if (!Utils.isValidEmail(email)) {
      Utils.showToast("Invalid_email".tr());
      return;
    }

    setState(() => isLoading = true);

    // Use email + current time + random number, then hash it
    final random = Random();
    final input = "$email-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(999999)}";

    // SHA1 hash and take first 10 characters
    final hash = sha1.convert(utf8.encode(input)).toString().substring(0, 10).toUpperCase();

    // Add first 3 chars of email for readability
    String emailPart = email.split('@').first.toUpperCase();
    if (emailPart.length > 3) emailPart = emailPart.substring(0, 3);

    String id = "$emailPart-$hash"; // Example: "ASI-9F3A7D2B1C"

    farmIdController.text = id;

    setState(() => isLoading = false);
  }


  Future<void> handleSignup() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final farmName = farmNameController.text.trim();
    final farmId = farmIdController.text.trim();

    if ([name, email, password, farmName, farmId].any((e) => e.isEmpty)) {
      showDialog(context: context, builder: (_) => AlertDialog(
        content: Text("PROVIDE_ALL".tr()),
      ));
      return;
    }

    try {
      setState(() => isLoading = true);

      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCred.user!.uid;

      final hashedPassword = Utils().hashPassword(password);
      final MultiUser user = MultiUser(
        name: name,
        email: email,
        password: hashedPassword,
        role: 'Admin',
        image: '',
        active: true,
        farmId: farmId,
        createdAt: DateTime.now().toIso8601String(),
      );

// Save to local SQLite database
      await DatabaseHelper.insertUser(user);

      // Create farm in Firestore
      await FirebaseFirestore.instance.collection(FireBaseUtils.FARMS).doc(farmId).set({
        'adminId': uid,
        'farm_name': farmName,
        'createdAt': FieldValue.serverTimestamp(),
        'users': {
          uid: {
            'name': name,
            'email': email,
            'role': 'admin',
            'joinedAt': FieldValue.serverTimestamp(),
          }
        },
      })
      .then((_) => print('Farm created successfully'))
      .catchError((error) => print('Failed to create farm: $error'));

      // Add user profile
      await FirebaseFirestore.instance.collection('users').doc(uid).set(user.toMap())
          .then((_) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup completed successfully!'.tr())),
        );

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>  AuthGate(isStart: true)));
      })
       .catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error:".tr()+" $error")),
        );
      });
      // Optionally add default roles here

    } catch (e) {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text("Signup Failed".tr()),
        content: Text(e.toString()),
      ));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text("Create Admin Account".tr(), style: textTheme.headlineMedium),
            SizedBox(height: 16),

            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Name".tr()),
            ),
            SizedBox(height: 12),

            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email".tr()),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12),

            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password".tr()),
              obscureText: true,
            ),
            SizedBox(height: 12),

            TextField(
              controller: farmNameController,
              decoration: InputDecoration(labelText: "Farm Name".tr()),
            ),
            SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: farmIdController,
                    decoration: InputDecoration(labelText: "Farm ID".tr()),
                    readOnly: true,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: generateUniqueFarmId,
                  icon: Icon(Icons.refresh),
                  label: Text("Generate".tr()),
                )
              ],
            ),

            SizedBox(height: 24),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: handleSignup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                padding: EdgeInsets.symmetric(horizontal: 24),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                shadowColor: Colors.blue.shade100,
              ),
              child: Text(
                "Sign Up".tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}
