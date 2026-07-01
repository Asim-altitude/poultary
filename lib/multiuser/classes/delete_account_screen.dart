import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:poultary/utils/utils.dart';

import 'AuthGate.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _confirmController = TextEditingController();

  bool _isDeleting = false;
  bool get _canDelete => _confirmController.text.trim().toUpperCase() == "DELETE";

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage("No logged-in user found.".tr());
      return;
    }

    final confirmed = await _showFinalConfirmation();
    if (!confirmed) return;

    setState(() => _isDeleting = true);

    try {
      final uid = user.uid;

      await _deleteUserCloudData(uid);

      await user.delete();

      await Utils.logoutUser();

      if (!mounted) return;

      _showDeletedSuccessDialog();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AuthGate(isStart: true)),
            (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'requires-recent-login') {
        _showMessage(
          "For security, please log out and sign in again, then try deleting your account.".tr(),
        );
      } else {
        _showMessage(e.message ?? "Unable to delete account.".tr());
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage("Something went wrong. Please try again.".tr());
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _deleteUserCloudData(String uid) async {
    final firestore = FirebaseFirestore.instance;

    // Delete user profile document
    await firestore.collection('users').doc(uid).delete().catchError((_) {});

    // Example: delete farms owned by this user
    // Change collection/field names according to your database.
    final farms = await firestore
        .collection('users')
        .where('farm_id', isEqualTo: Utils.currentUser!.farmId)
        .get();

    for (final farm in farms.docs) {
      await farm.reference.delete();
    }



  }

  Future<bool> _showFinalConfirmation() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title:  Text("Delete Account".tr()+"?"),
          content:  Text(
            "This will permanently delete your account and cloud data. This action cannot be undone.".tr(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:  Text("Cancel".tr()),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child:  Text("Delete Permanently".tr()),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  void _showDeletedSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title:  Text("Account Deleted".tr()),
          content:  Text(
            "Your account has been deleted successfully.".tr(),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();

                // Change this route to your login/onboarding screen
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                      (route) => false,
                );
              },
              child:  Text("OK".tr()),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        title:  Text("Delete Account".tr()),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 18),
                     Text(
                      "Delete your account".tr(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user?.email ?? "Your current account".tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _InfoTile(
                      icon: Icons.warning_amber_rounded,
                      title: "Permanent action",
                      description:
                      "Your account will be permanently deleted and cannot be restored.",
                    ),
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.cloud_off_rounded,
                      title: "Cloud data removal",
                      description:
                      "Cloud profile and synced farm data linked to this account will be removed.",
                    ),
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.phone_android_rounded,
                      title: "Local device data",
                      description:
                      "Offline data stored on this device may remain unless you clear app data or uninstall the app.",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.red.withOpacity(0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      "Type DELETE to confirm".tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: "DELETE".tr(),
                        filled: true,
                        fillColor: const Color(0xffF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                    _canDelete ? Colors.red : Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: !_canDelete || _isDeleting ? null : _deleteAccount,
                  icon: _isDeleting
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.delete_outline_rounded),
                  label: Text(
                    _isDeleting ? "Deleting...".tr() : "Delete Account".tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _isDeleting ? null : () => Navigator.pop(context),
                child:  Text("Cancel".tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.red, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description.tr(),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}