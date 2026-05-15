import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:poultary/utils/utils.dart';

class CreditScreen extends StatefulWidget {

  @override
  _CreditScreen createState() => _CreditScreen();
}

class _CreditScreen extends State<CreditScreen> {
  int credits = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    init();
  }

  Future<void> init() async {
    credits = await _fetchCredits();
    Utils.ai_credits = credits;
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text("AI Credits"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10),
            _balanceCard(),
            SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Choose a Plan",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 10),

            _creditOption("10 Credits", "\$2.99"),
            _creditOption("20 Credits", "\$4.99"),
            _creditOption(
              "50 Credits",
              "\$9.99",
              highlight: true,
              badge: "BEST VALUE",
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard() {

    final user = FirebaseAuth.instance.currentUser;
    final email = Utils.isMultiUSer? Utils.currentUser!.email : user?.email ?? "Not signed in";

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF6A5AE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔐 Email Row
          InkWell(
            onTap: () {
              if(!Utils.isMultiUSer)
              showAccountSwitchSheet(context);
            },
            child: Row(
              children: [
                Icon(Icons.account_circle, color: Colors.white70, size: 22),
                SizedBox(width: 6),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 20, color: Colors.white70,)
              ],
            ),
          ),

          SizedBox(height: 16),

          /// Credits Label
          Text(
            "Available Credits",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),

          SizedBox(height: 8),

          /// Credits Value
          Text(
            "$credits",
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          /// Description
          Text(
            "Use credits to generate AI insights for your farm",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void showAccountSwitchSheet(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _accountSwitchUI(context, user),
    );
  }

  Widget _creditOption(
      String title,
      String price, {
        bool highlight = false,
        String? badge,
      })  {
    return GestureDetector(
      onTap: () async {
        // trigger purchase

        int remaining_cr = Utils.ai_credits;

        if(title.startsWith("10")){
          remaining_cr += 10;
        }else if(title.startsWith("20")){
          remaining_cr += 20;
        } else if(title.startsWith("50")){
          remaining_cr += 50;
        }

        var user = _auth.currentUser;

        final docRef =
        _firestore.collection("ai_users").doc(user!.uid);

        await docRef.update({
          "credits": remaining_cr, // welcome credits
          "createdAt": FieldValue.serverTimestamp(),
        });

        Utils.ai_credits = remaining_cr;

        setState(() {
          credits = Utils.ai_credits;

        });

      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: highlight ? Colors.green : Colors.grey.shade200,
            width: highlight ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: highlight
                    ? Colors.green.withOpacity(0.15)
                    : Colors.blue.withOpacity(0.1),
              ),
              child: Icon(
                Icons.bolt,
                color: highlight ? Colors.green : Colors.blue,
              ),
            ),

            SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge != null) ...[
                        SizedBox(width: 8),
                        Container(
                          padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ]
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Instant AI analysis for your poultry farm",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: highlight ? Colors.green : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> _fetchCredits() async {
    final user = _auth.currentUser;

    if (user == null) return 0;

    final doc = await _firestore
        .collection("ai_users")
        .doc(user.uid)
        .get();

    return doc.data()?["credits"] ?? 0;
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ["email"],
  );

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

  Widget _accountSwitchUI(BuildContext context, User? user) {
    final email = user?.email ?? "Not signed in";
    final name = user?.displayName ?? "";
    final photo = user?.photoURL;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// Drag Handle
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          SizedBox(height: 20),

          /// Title
          Text(
            "Account",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 20),

          /// Current User Card
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Color(0xFFF6F8FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [

                /// Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundImage:
                  photo != null ? NetworkImage(photo) : null,
                  child: photo == null
                      ? Icon(Icons.person, color: Colors.white)
                      : null,
                ),

                SizedBox(width: 12),

                /// Name + Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                /// Active Badge
                Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "ACTIVE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),

          SizedBox(height: 25),

          /// Switch Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: Colors.blue,
              ),
              onPressed: () async {
                await _switchAccount(context);
              },
              child: Text(
                "Switch Account",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),

          SizedBox(height: 10),

          /// Cancel
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),

          SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> _switchAccount(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // 🔴 Proper sign out from both Firebase + Google
      await FirebaseAuth.instance.signOut();
      await googleSignIn.signOut();

      // Optional: disconnect to force account chooser
      await googleSignIn.disconnect();

      // ✅ Sign in again → account picker will show
      final GoogleSignInAccount? googleUser =
      await googleSignIn.signIn();

      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      Navigator.pop(context); // close sheet

      // 🔄 Refresh UI
      // call your _loadCredits() or setState()

      credits = await _fetchCredits();

      setState(() {

      });
    } catch (e) {
      print("Switch account error: $e");
    }
  }
}