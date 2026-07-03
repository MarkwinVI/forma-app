import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/dev_tools_service.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUser?.id ?? 'Not available';

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'USER ID',
                style: TextStyle(
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined,
                        size: 18, color: AppColors.textSecondary),
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
              const Divider(height: 32, color: AppColors.borderPrimary),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                const _DevToolsSection(),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentBright,
                    side: const BorderSide(color: AppColors.borderPrimary),
                  ),
                  // _AppEntry listens to auth state and swaps to the login
                  // screen once the session ends.
                  onPressed: () => AuthService().signOut(),
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

/// Debug-build only: data reset and seeding shortcuts.
class _DevToolsSection extends StatefulWidget {
  const _DevToolsSection();

  @override
  State<_DevToolsSection> createState() => _DevToolsSectionState();
}

class _DevToolsSectionState extends State<_DevToolsSection> {
  final _devToolsService = DevToolsService();

  bool _busy = false;

  Future<void> _run(
    Future<void> Function(String userId) action,
    String successMessage,
  ) async {
    final userId = AuthService().currentUser?.id;
    if (userId == null || _busy) return;

    setState(() => _busy = true);
    try {
      await action(userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dev action failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Reset to new user?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Deletes this account\'s training program, exercise progress and '
          'workout history. The account itself is kept.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.accentPrimary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _run(
      _devToolsService.resetToNewUser,
      'Account reset — Home now shows the new-user state.',
    );
  }

  Future<void> _generateWorkouts() {
    return _run(
      _devToolsService.generateSampleWorkouts,
      'Added 5 workouts across the last 30 days.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'DEVELOPER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            if (_busy) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentPrimary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _DevToolRow(
          icon: Icons.restart_alt_rounded,
          title: 'Reset to new user',
          sub: 'Wipe program, progress and workout history',
          warn: true,
          onTap: _busy ? null : _confirmReset,
        ),
        const SizedBox(height: 10),
        _DevToolRow(
          icon: Icons.auto_awesome_rounded,
          title: 'Generate 5 workouts',
          sub: 'Seed sample sessions spaced over the last 30 days',
          onTap: _busy ? null : _generateWorkouts,
        ),
      ],
    );
  }
}

class _DevToolRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final bool warn;
  final VoidCallback? onTap;

  const _DevToolRow({
    required this.icon,
    required this.title,
    required this.sub,
    this.warn = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            IconTile(icon: icon, warn: warn),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
