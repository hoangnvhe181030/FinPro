import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/auth_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldDark,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _buildSection('Account', [
            _buildTile(context, Icons.person_outline, 'Edit Profile', () {}),
            _buildTile(context, Icons.lock_outline, 'Change Password', () {}),
          ]),
          const SizedBox(height: 16),
          _buildSection('Preferences', [
            _buildSwitchTile(context, Icons.notifications_outlined, 'Notifications', true, (val) {}),
            _buildTile(context, Icons.language, 'Language', () {}),
          ]),
          const SizedBox(height: 16),
          _buildSection('About', [
            _buildTile(context, Icons.info_outline, 'Version', () {}, trailing: const Text('1.0.0', style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
            _buildTile(context, Icons.description_outlined, 'Terms of Service', () {}),
            _buildTile(context, Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
          ]),
          const SizedBox(height: 32),

          // Logout
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _buildSwitchTile(BuildContext context, IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Log Out', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Log Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
