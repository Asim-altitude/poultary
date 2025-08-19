import 'package:flutter/material.dart';
import 'package:poultary/app_setup/language_setup_screen.dart';
import 'package:poultary/multiuser/classes/AuthGate.dart';
import 'package:poultary/utils/session_manager.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                "🐔 Easy Poultry Manager",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF37474F),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Select your preferred mode of use:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF607D8B),
                ),
              ),
              const Spacer(),
              _buildAccountOption(
                context,
                title: "Farm Account",
                description: "Multi-user, online, with roles. Requires a paid plan.",
                icon: Icons.home_work_outlined,
                color: Colors.blue.shade700,
                onPressed: () async {
                  await SessionManager.setupComplete();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>  AuthGate(isStart: true)),
                  );
                },
              ),
              const SizedBox(height: 24),

              _buildAccountOption(
                context,
                title: "Individual Account",
                description: "Use offline on a single device.",
                icon: Icons.person_outline,
                color: Colors.green.shade600,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LanguageSetupScreen()),
                  );
                },
              ),

              const Spacer(),
              const Text(
                "You can change account type later from settings.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountOption(
      BuildContext context, {
        required String title,
        required String description,
        required IconData icon,
        required Color color,
        required VoidCallback onPressed,
      }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        shadowColor: color.withOpacity(0.3),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(icon, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
