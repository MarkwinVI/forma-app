import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../login/login_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUser?.id ?? 'Not available';

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'USER ID',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      userId,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 18, color: AppColors.textSecondary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: userId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User ID copied')),
                      );
                    },
                    tooltip: 'Copy',
                  ),
                ],
              ),
              Divider(height: 32, color: AppColors.borderPrimary),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentBright,
                    side: const BorderSide(color: AppColors.borderPrimary),
                  ),
                  onPressed: () async {
                    await AuthService().signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginView()),
                      (_) => false,
                    );
                  },
                  child: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
