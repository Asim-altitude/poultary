import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poultary/home_screen.dart';
import 'package:poultary/multiuser/classes/WorkerDashboard.dart';
import 'package:poultary/multiuser/model/user.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/utils.dart';
import 'backup_restore.dart';

class LoginForm extends StatefulWidget {
  final ButtonStyle? buttonStyle;

  const LoginForm({Key? key, this.buttonStyle}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController(); // for admin only
  final farmIdController = TextEditingController(); // for member only

  bool isLoading = false;
  String loginMode = 'admin'; // 'admin' or 'member'

  void handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final farmID = farmIdController.text.trim();

    if (loginMode == 'admin') {
      if (email.isEmpty || password.isEmpty) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Missing Information"),
            content: Text("Please enter both email and password."),
          ),
        );
        return;
      }

      try {
        setState(() => isLoading = true);

        final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password);

        if (userCred.user != null) {
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCred.user!.uid)
              .get();

          if (snapshot.exists && snapshot.data()?['role'] == 'Admin') {
            final data = snapshot.data();
            MultiUser multiUser = MultiUser(name: data!['name'], email: data!['email'], password: "password", role: data!['role'], farmId: data!['farm_id'], createdAt: data!['created_at']);
            SessionManager.saveUserToPrefs(multiUser);
            await SessionManager.setBoolValue(SessionManager.loggedIn, true);
            await SessionManager.setBoolValue(SessionManager.isAdmin, true);
            Utils.isMultiUSer = true;

            bool initialized = await SessionManager.getBool('db_initialized_${multiUser.farmId}') ?? false;

            if(initialized) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
              );
            }
            else{
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => BackupFoundScreen(isAdmin:  true, user: multiUser,)),
              );
            }


          } else {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Access Denied"),
                content: Text("Not an admin account."),
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = "Login failed. Please try again.";
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          message = "Invalid email or password.";
        }
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Login Error"),
            content: Text(message),
          ),
        );
      } finally {
        setState(() => isLoading = false);
      }
    } else {
      // MEMBER login
      if (email.isEmpty || farmID.isEmpty) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Missing Info"),
            content: Text("Please enter both email and farm ID."),
          ),
        );
        return;
      }

      try {
        setState(() => isLoading = true);
        // Query firestore for user with matching email and farmID
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .where('farm_id', isEqualTo: farmID)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          MultiUser multiUser = MultiUser(name: data!['name'], email: data!['email'], password: "password", role: data!['role'], farmId: data!['farm_id'], createdAt: data!['created_at']);
          SessionManager.saveUserToPrefs(multiUser);
          await SessionManager.setBoolValue(SessionManager.loggedIn, true);
          await SessionManager.setBoolValue(SessionManager.isAdmin, false);
          Utils.isMultiUSer = true;
          // Optional: Store user data locally

          bool initialized = await SessionManager.getBool('db_initialized_${multiUser.farmId}') ?? false;

          if(initialized) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => WorkerDashboardScreen(name: data['name'], email: data['email'], role: data['role'])),
            );

          }
          else{
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => BackupFoundScreen(isAdmin: false, user: multiUser,)),
            );
          }

        } else {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Login Failed"),
              content: Text("User not found with provided email and farm ID."),
            ),
          );
        }
      } catch (e) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Login Error"),
            content: Text(e.toString()),
          ),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = loginMode == 'admin';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Toggle Tabs
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => loginMode = 'admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAdmin ? Colors.blue.shade700 : Colors.grey.shade300,
                    foregroundColor: isAdmin ? Colors.white : Colors.black87,
                  ),
                  child: Text('Admin'),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => loginMode = 'member'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isAdmin ? Colors.blue.shade700 : Colors.grey.shade300,
                    foregroundColor: !isAdmin ? Colors.white : Colors.black87,
                  ),
                  child: Text('Member'),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Dynamic Fields
          if (!isAdmin)
            TextField(
              controller: farmIdController,
              decoration: InputDecoration(labelText: 'Farm ID'),
            ),
          TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          if (isAdmin)
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          SizedBox(height: 16),

          ElevatedButton(
            onPressed: isLoading ? null : handleLogin,
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
            child: isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
              "Login",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          )
        ],
      ),
    );
  }
}
