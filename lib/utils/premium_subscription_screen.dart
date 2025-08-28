import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool isPremiumSelected = false;

  final features = [
    {"title": "Remove All Ads", "ads": true, "premium": true},
    {"title": "Advanced Reports", "ads": false, "premium": true},
    {"title": "Multi-User Support", "ads": false, "premium": true},
    {"title": "Priority Support", "ads": false, "premium": true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // HEADER SECTION (Compact, Gradient)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Upgrade Your Experience",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Choose the plan that fits you best",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // TOGGLE SWITCH FOR OPTIONS
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _buildToggleOption("Ads Removal", !isPremiumSelected),
                  _buildToggleOption("Premium", isPremiumSelected),
                ],
              ),
            ),

            SizedBox(height: 20),

            // FEATURE LIST
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final f = features[index];
                  bool included = isPremiumSelected
                      ? f["premium"] as bool
                      : f["ads"] as bool;

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: ListTile(
                      leading: Icon(
                        included ? Icons.check_circle : Icons.cancel,
                        color: included ? Colors.green : Colors.redAccent,
                      ),
                      title: Text(
                        f["title"] as String,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),

            // PURCHASE BUTTON
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.deepPurple,
                ),
                onPressed: () {},
                child: Text(
                  isPremiumSelected
                      ? "Subscribe Premium • \$28.99 / 6 Months"
                      : "Remove Ads • \$4.99 (One Time)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isPremiumSelected = text == "Premium";
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected
                ? [
              BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2))
            ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
