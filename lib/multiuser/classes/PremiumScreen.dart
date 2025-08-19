import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/utils.dart';
import '../model/farm_plan.dart';
import '../utils/FirebaseUtils.dart';

class PremiumScreen extends StatefulWidget {
  final bool isPaidUser;

  const PremiumScreen({Key? key, required this.isPaidUser}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  late bool isPaid;

  @override
  void initState() {
    super.initState();
    isPaid = widget.isPaidUser;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final endDate = DateFormat('MMMM dd, yyyy').format(
      DateTime(now.year, now.month + 6, now.day),
    );

    return Scaffold(
      backgroundColor: Utils.getScreenBackground(),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 10,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blue.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.egg_alt_rounded, size: 60, color: Colors.brown),
                    SizedBox(height: 16),
                    Text(
                      'Easy Poultry Manager',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[900],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Premium Subscription',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.brown[700],
                      ),
                    ),
                    Divider(height: 32, thickness: 1),
                    Text(
                      '\$28.99',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Duration: Starts Today',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Ends on: $endDate',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Add your payment or free trial logic here
                        if (!isPaid) {
                          // Sample logic

                          setState(() {
                            isPaid = true;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPaid ? Colors.green : Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 32,
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        isPaid ? 'Start Free' : 'Subscribe Now',
                        style: TextStyle(fontSize: 18,color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
