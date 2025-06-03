import 'package:flutter/material.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/utils/session_manager.dart';
import '../../home_screen.dart';
import '../model/user.dart';
import 'LoginForm.dart';
import 'SignupForm.dart'; // Make sure you have this screen

class AuthGate extends StatefulWidget {
  bool isStart;

  AuthGate({required this.isStart});

  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {

  bool isLogin = true;
  List<MultiUser> users = [];

  @override
  void initState() {
    // TODO: implement initState
    init();
  }

  Future<void> init() async {

    await DatabaseHelper.createUsersTableIfNotExists();
    users = await DatabaseHelper.getAllUsers();

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Stack(
        children: [
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: () {
                SessionManager.setBoolValue(SessionManager.skipped, true);
                if(widget.isStart) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen()),
                  );
                }
                else{
                  Navigator.pop(context);
                }
              },
              child: users == null? Text(
                "Skip",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ) : SizedBox(width: 1,),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                 // Icon(Icons., size: 72, color: Colors.blue.shade700),
                  Image.asset('assets/bird_icon.png', color: Colors.blue.shade700, width: 90, height: 90,),
                  SizedBox(height: 10),
                  Text(
                    "Easy Poultry Manager",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    isLogin
                        ? "Welcome back! Please login to continue."
                        : "Create your farm and get started.",
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),

                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        )
                      ],
                    ),
                    child: isLogin
                        ? LoginForm(
                      buttonStyle: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )

                        : SignupForm(),
                  ),

                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      setState(() => isLogin = !isLogin);
                    },
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.black87),
                        children: [
                          TextSpan(
                            text: isLogin
                                ? "Don't have an account? "
                                : "Already have an account? ",
                          ),
                          TextSpan(
                            text: isLogin ? "Sign Up" : "Login",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> checkSkipped() async {
    bool skipped = await SessionManager.getBool(SessionManager.skipped);
    if (skipped) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }
}
