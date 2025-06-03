import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poultary/database/databse_helper.dart';
import 'dart:math';
import 'package:poultary/home_screen.dart';
import 'package:poultary/multiuser/classes/AdminProfile.dart';

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

  // Generate random farm ID and ensure uniqueness
  Future<void> generateUniqueFarmId() async {
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String id;
    bool exists = true;

    setState(() => isLoading = true);

    do {
      id = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
      final doc = await FirebaseFirestore.instance.collection('farms').doc(id).get();
      exists = doc.exists;
    } while (exists);

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
        content: Text("Please fill all fields"),
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
          .then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup completed successfully!')),
        );
        List<MultiUser> users = [];
        users.add(user);
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) =>  AdminProfileScreen(users: users)));
      })
          .catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      });


      // Optionally add default roles here


    } catch (e) {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text("Signup Failed"),
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
            Text("Create Admin Account", style: textTheme.headlineMedium),
            SizedBox(height: 16),

            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Your Name"),
            ),
            SizedBox(height: 12),

            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email Address"),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12),

            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 12),

            TextField(
              controller: farmNameController,
              decoration: InputDecoration(labelText: "Farm Name"),
            ),
            SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: farmIdController,
                    decoration: InputDecoration(labelText: "Farm ID"),
                    readOnly: true,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: generateUniqueFarmId,
                  icon: Icon(Icons.refresh),
                  label: Text("Generate"),
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
                "Sign Up",
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
