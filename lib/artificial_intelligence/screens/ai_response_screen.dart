import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class AIResponseScreen extends StatelessWidget {
  final String response;

  const AIResponseScreen({
    Key? key,
    required this.response,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        title: Text("AI Insights", style: TextStyle(color: Colors.white),),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.blueAccent],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: _responseCard(context),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Top AI Header
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.blueAccent],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.white, size: 40),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Smart AI Analysis Result",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  // 📊 Response Card
  Widget _responseCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.indigo),
              SizedBox(width: 8),
              Text(
                "AI Response",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),

          SizedBox(height: 16),

          // Response Text
          SelectableText(
            response,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 20),

          Divider(),

          SizedBox(height: 10),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.copy),
                  label: Text("Copy"),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: response));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Copied to clipboard")),
                    );
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.share, color: Colors.white,),
                  label: Text("Share", style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    Share.share(response);
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}