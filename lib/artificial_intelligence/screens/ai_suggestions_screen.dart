
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:poultary/artificial_intelligence/screens/ai_credits_screen.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/utils/utils.dart';

import '../model/ai_response.dart';
import 'ai_ask_screen.dart';

import 'package:easy_localization/easy_localization.dart';

import 'ai_response_advance_display.dart';
import 'ai_response_screen.dart';

class AISuggestionsScreen extends StatefulWidget {
  @override
  _AISuggestionsScreenState createState() => _AISuggestionsScreenState();
}

class _AISuggestionsScreenState extends State<AISuggestionsScreen> {

  int credits = 0;
  List<AIResponse> responses = [];
  bool isLoading = true;

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? user;

  Future<void> _initUser() async {
    user = auth.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
      });

      signInWithGoogle();
      return;
    }

    credits = await _fetchCredits();
    Utils.ai_credits = credits;

  }

  Future<int> _fetchCredits() async {
    final user = _auth.currentUser;

    if (user == null) return 0;

    final doc = await _firestore
        .collection("ai_users")
        .doc(user.uid)
        .get();

    final docRef =
    _firestore.collection("ai_users").doc(user.uid);

    if (!doc.exists) {
      // New user → initialize credits
      await docRef.set({
        "email": user.email,
        "name": user.displayName,
        "credits": Utils.isMultiUSer? 4 : !Utils.isShowAdd? 2 : 0, // welcome credits
        "createdAt": FieldValue.serverTimestamp(),
      });

      credits = Utils.isMultiUSer? 4 : !Utils.isShowAdd? 2 : 0;
      return credits;
    }

    return doc.data()?["credits"] ?? 0;
  }

  Future<void> initData() async {
    if(!Utils.isMultiUSer) {
      await _initUser();
      await _loadData();
    }else {
      credits = await _fetchCredits();
      Utils.ai_credits = credits;
      await _loadData();
    }
  }

  @override
  void initState() {
    super.initState();
    //_loadData();
    initData();
  }

  Future<void> _loadData() async {
    int userId = 1;

    final creditData = await DatabaseHelper.getCredits(userId);
    credits = await _fetchCredits();
    Utils.ai_credits = credits;
    final aiResponses = await DatabaseHelper.getAllResponses();

    setState(() {
    //  credits = creditData?.totalCredits ?? 0;
      responses = aiResponses;
      isLoading = false;
    });
  }

  Future<void> _navigateAndRefresh(Widget screen) async {

    if(auth.currentUser == null && !Utils.isMultiUSer)
      {
        signInWithGoogle();
        return;
      }

    if(Utils.ai_credits <= 0) {
      Utils.showToast("Low Credits. Please Recharge");
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    _loadData();
  }


 /* Widget _loginScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                "Sign in to continue",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "You need to sign in to access AI analysis and credits",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 25),

              ElevatedButton(
                onPressed: () async {
                  await signInWithGoogle();
                },
                child: Text("Sign In"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInUser() async {
    // after login success
    // FirebaseAuth sign-in logic here

    User? newUser = FirebaseAuth.instance.currentUser;

    if (newUser != null) {
      user = newUser;
      await _fetchCredits();
    }

    setState(() {});
  }
*/
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ["email"],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signInWithGoogle() async {
    try {
      // 1. Google account
      final GoogleSignInAccount? googleUser =
      await _googleSignIn.signIn();

      if (googleUser == null) return; // user cancelled

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // 2. Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Firebase sign-in
      UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        await _createOrGetUser(user);
      }

      Utils.showToast(
        "Signed in as ${user?.displayName ?? ""}",
      );

      credits = await _fetchCredits();
      Utils.ai_credits = credits;
      setState(() {});
    } catch (error) {
      print("Google Sign-In Error: $error");
      Utils.showToast(
        "Google Sign-In Error: $error",
      );
    }
  }

  Future<void> _createOrGetUser(User user) async {
    final docRef =
    _firestore.collection("ai_users").doc(user.uid);

    final doc = await docRef.get();

    if (!doc.exists) {
      // New user → initialize credits
      await docRef.set({
        "email": user.email,
        "name": user.displayName,
        "credits": Utils.isShowAdd? 1 : Utils.isMultiUSer? 5 : 3, // welcome credits
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light, // 👈 IMPORTANT
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Text(
          "AI Suggestions".tr()
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                await _navigateAndRefresh(CreditScreen());
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.blue],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.4),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Text("🪙", style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Text(
                      "${Utils.ai_credits}",
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8F9FF),
              Color(0xFFEFF1FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : responses.isEmpty
              ? _emptyState()
              : RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: EdgeInsets.only(top: 10, bottom: 80),
              itemCount: responses.length,
              itemBuilder: (context, index) {
                return _suggestionCard(responses[index]);
              },
            ),
          ),
        ),
      ),

      floatingActionButton: responses.isEmpty? null : _fabButton(),
    );
  }

  Widget _fabButton() {
    return FloatingActionButton.extended(
      onPressed: () async {
        await _navigateAndRefresh(AskAIScreen());
      },
      backgroundColor: Colors.blue,
      elevation: 6,
      icon: Icon(Icons.auto_awesome, color: Colors.white,),
      label: Text("Ask AI".tr(), style: TextStyle(color: Colors.white),),
    );
  }

  Widget _suggestionCard(AIResponse response) {
    Color color = _getCategoryColor(response.category);

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AIHealthResultScreen(aiResponse: response.response,)),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.85),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ICON WITH BACKGROUND
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIcon(response.category), color: color),
            ),

            SizedBox(width: 12),

            // CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    response.title.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),

                  Text(
                    "ai_suggestions.birds_weeks".tr(args: [
                      "${response.birdCount ?? '-'}",
                      "${response.ageWeeks ?? '-'}"
                    ]),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    response.response,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[800]),
                  ),

                  SizedBox(height: 10),

                  Row(
                    children: [
                      _chip("${response.creditsUsed} 🪙", color),
                      SizedBox(width: 8),
                      _chip(
                        DateFormat('dd MMM').format(response.createdAt),
                        Colors.grey,
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getIcon(String category) { switch (category) { case 'feed': return Icons.restaurant; case 'health': return Icons.health_and_safety; case 'financial': return Icons.attach_money; default: return Icons.smart_toy; } }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'feed':
        return Colors.green;
      case 'health':
        return Colors.red;
      case 'financial':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 60, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text(
            "ai_suggestions.empty".tr(),
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if(Utils.ai_credits > 0)
              await _navigateAndRefresh(AskAIScreen());
            },
            child: Text("ai_suggestions.new_button".tr()),
          )
        ],
      ),
    );
  }
}