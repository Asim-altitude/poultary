import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
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
import 'farm_welcome_screen.dart';

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

    if (loginMode == 'admin')
    {
      if (email.isEmpty || password.isEmpty) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Missing Information".tr()),
            content: Text("Please enter both email and password.".tr()),
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
            MultiUser multiUser = MultiUser(name: data!['name'], email: data['email'], password: data['password'], role: data['role'], farmId: data['farm_id'], createdAt: data['created_at'], image: data['image'] ?? '');
            SessionManager.saveUserToPrefs(multiUser);
            Utils.currentUser = multiUser;
            await SessionManager.setBoolValue(SessionManager.loggedIn, true);
            await SessionManager.setBoolValue(SessionManager.isAdmin, true);
            Utils.isMultiUSer = true;

            bool initialized = await SessionManager.getBool('db_initialized_${multiUser.farmId}') ?? false;

            if(initialized) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => FarmWelcomeScreen(multiUser: Utils.currentUser!, isStart: true,)),
              );
            }
            else{
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => FarmWelcomeScreen(multiUser: Utils.currentUser!, isStart: true,)),
              );
              /*Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => BackupFoundScreen(isAdmin:  true, user: multiUser,)),
              );*/
            }


          } else {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Access Denied".tr()),
                content: Text("Not an admin account.".tr()),
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
            title: Text("Login Error".tr()),
            content: Text(message.tr()),
          ),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
    else
    {
      // MEMBER login
      if (email.isEmpty || farmID.isEmpty || password.isEmpty) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Missing Info".tr()),
            content: Text("Please enter both email and farm ID.".tr()),
          ),
        );
        return;
      }

      try
      {
        setState(() => isLoading = true);

        // 1. Try to sign in using Firebase Auth
        UserCredential cred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

       // final uid = cred.user!.uid;

        // Query firestore for user with matching email and farmID
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .where('farm_id', isEqualTo: farmID)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();

          MultiUser multiUser = MultiUser(name: data['name'], email: data['email'], password: data['password'], role: data['role'], farmId: data['farm_id'], createdAt: data['created_at'], image: data['image'] ?? '');
          SessionManager.saveUserToPrefs(multiUser);
          await SessionManager.setBoolValue(SessionManager.loggedIn, true);
          await SessionManager.setBoolValue(SessionManager.isAdmin, false);
          Utils.isMultiUSer = true;
          // Optional: Store user data locally
          Utils.currentUser = multiUser;
          bool initialized = await SessionManager.getBool('db_initialized_${multiUser.farmId}') ?? false;

          if(initialized) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => FarmWelcomeScreen(multiUser: Utils.currentUser!, isStart: true,)),
            );

          }
          else{
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => FarmWelcomeScreen(multiUser: Utils.currentUser!, isStart: true,)),
            );
           /* Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => BackupFoundScreen(isAdmin: false, user: multiUser,)),
            );*/
          }

        } else {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Login Failed".tr()),
              content: Text("User not found with provided email and farm ID.".tr()),
            ),
          );
        }
      } catch (e) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Login Error".tr()),
            content: Text(e.toString()),
          ),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  bool _obscureText = true;
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
                  child: Text('admin'.tr()),
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
                  child: Text('Member'.tr()),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Dynamic Fields
          if (!isAdmin)
            TextField(
              controller: farmIdController,
              decoration: InputDecoration(labelText: 'Farm ID'.tr()),
            ),
          TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'Email'.tr()),
          ),

            /*TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),*/
          TextField(
            controller: passwordController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              labelText: 'Password'.tr(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 5,),
          InkWell(
            onTap: () {
              showForgotPasswordDialog(context);
            },
            child: Container(
              alignment: Alignment.topRight,
              child: Row(
                children: [
                  Spacer(),
                  Text('Forgot Password?', style: TextStyle(color: Colors.blue, fontSize: 14),)
                ],
              ),
            ),
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
              "Login".tr(),
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


  Future<void> showForgotPasswordDialog(BuildContext context) async {
    final TextEditingController emailController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('forgot_password'.tr()), // e.g. "Forgot Password?"
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'forgot_password_instruction'.tr(),
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'email'.tr(),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('enter_email_warning'.tr())),
                  );
                  return;
                }
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('password_reset_sent'.tr())),
                  );
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${'error'.tr()}: ${e.message}')),
                  );
                }
              },
              child: Text('send'.tr()),
            ),
          ],
        );
      },
    );
  }

}
