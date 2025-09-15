import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:poultary/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportScreen extends StatelessWidget {
  final String supportEmail = "zaheer6110@gmail.com"; // Replace with your actual support email

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10.0), // Round bottom-left corner
            bottomRight: Radius.circular(10.0), // Round bottom-right corner
          ),
          child: AppBar(
            title: Text(
              "Contact & Support".tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.blue, // Customize the color
            elevation: 8, // Gives it a more elevated appearance
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context); // Navigates back
              },
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// **Email Support Card**
            _buildEmailSupportCard(),

            SizedBox(height: 16),

            /// **WhatsApp Group & Channel Support**
            _buildWhatsAppSupport(),
          ],
        ),
      ),
    );
  }

  /// **Email Support Card**
  Widget _buildEmailSupportCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// **Title & Icon**
          Row(
            children: [
              Icon(Icons.email, color: Colors.blueAccent, size: 30),
              SizedBox(width: 10),
              Text(
                "Email Support".tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          SizedBox(height: 10),

          /// **Email Address**
          Text(
            "For any queries, feel free to email us:".tr(),
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          SizedBox(height: 6),

          /// **Email**
          GestureDetector(
            onTap: () {
              // Function to open email client
              print("Email tapped");
            },
            child: Text(
              supportEmail,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  /// **WhatsApp Support - Group & Channel**
  Widget _buildWhatsAppSupport() {
    return Container(
      padding: EdgeInsets.all(5),
      child: Column(
        children: [
          /// **WhatsApp Group - Ask a Question**
          InkWell(
            onTap: () {
              _launchUrl();
            },
            child: _buildWhatsAppCard(
              title: "Ask a Question".tr(),
              subtitle: "Join our WhatsApp Group and stay connected to our support".tr(),
              icon: MdiIcons.whatsapp,
              iconColor: Colors.green, // WhatsApp color
            ),
          ),

          SizedBox(height: 12),

          /// **WhatsApp Channel - Farming Community**
          InkWell(
            onTap: () {
              _launchUrl2();
            },
            child: _buildWhatsAppCard(
              title: "Tips & Updates".tr(),
              subtitle: "Follow our WhatsApp Channel to stay updated with the latest farming tips".tr(),
              icon: MdiIcons.whatsapp,
              iconColor: Colors.blue, // WhatsApp channel color
            ),
          ),
        ],
      ),
    );
  }

  /// **Enhanced WhatsApp Card with Forward Arrow**
  Widget _buildWhatsAppCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      margin: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
        border: Border.all(color: Colors.grey.shade300), // Light border for clean look
      ),
      child: Row(
        children: [
          /// **WhatsApp Icon**
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            radius: 28,
            child: Icon(icon, color: iconColor, size: 30),
          ),
          SizedBox(width: 14),

          /// **Title & Subtitle**
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// **Title**
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 4),

                /// **Subtitle**
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          /// **Forward Arrow**
          Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  final Uri _url = Uri.parse('https://chat.whatsapp.com/DT7MfbSM53G8MYoe4ufmsU');
  final Uri _url2 = Uri.parse('https://whatsapp.com/channel/0029Vb358El3gvWaZBGYBU28');

  Future<void> _launchUrl() async {

    if (!await launchUrl(
      _url,
      mode: LaunchMode.externalApplication, // Ensures opening in the app
    )) {
      throw 'Could not launch $_url2';
    }
  }
  Future<void> _launchUrl2() async {
    if (!await launchUrl(
      _url2,
      mode: LaunchMode.externalApplication, // Ensures opening in the app
    )) {
      throw 'Could not launch $_url2';
    }
  }



}
