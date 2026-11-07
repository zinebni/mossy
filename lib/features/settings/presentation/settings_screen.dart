import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mossy_card.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = authState.user;
    final currentLocale = ref.watch(localeProvider);
    final languageName = currentLocale.languageCode == 'fr' ? 'Français' : 'English';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkGreen),
          onPressed: () => context.pop(),
        ),
        title: Text('Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (authState.isDemoMode)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.butterYellow.withAlpha(50), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.butterYellow.withAlpha(120))),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.darkGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Running in Demo Mode. Configure Supabase credentials to enable real accounts.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.darkGreen))),
              ]),
            ),
          _sectionLabel('Profile'),
          MossyCard(
            child: Column(children: [
              _ListTile(icon: Icons.person_outline_rounded, title: profile?.username ?? 'Explorer', subtitle: 'Tap to edit username'),
              _Divider(),
              _ListTile(icon: Icons.emoji_events_outlined, title: 'Level ${profile?.explorerLevel ?? 1}', subtitle: '${profile?.totalPoints ?? 0} total points'),
            ]),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Preferences'),
          MossyCard(
            child: Column(children: [
              _SwitchTile(icon: Icons.notifications_outlined, title: 'Notifications', value: _notificationsEnabled, onChanged: (v) => setState(() => _notificationsEnabled = v)),
              _Divider(),
              _ListTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: languageName,
                trailing: DropdownButton<String>(
                  value: languageName,
                  underline: const SizedBox(),
                  style: const TextStyle(color: AppColors.sageGreen, fontWeight: FontWeight.w600),
                  items: ['English', 'Français'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(localeProvider.notifier).setLocale(v == 'Français' ? 'fr' : 'en');
                    }
                  },
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          _sectionLabel('About'),
          MossyCard(
            child: Column(children: [
              _ListTile(icon: Icons.info_outline_rounded, title: 'Version', subtitle: '1.0.0'),
              _Divider(),
              _ListTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () {}),
              _Divider(),
              _ListTile(icon: Icons.map_outlined, title: 'Discovery Map', onTap: () => context.go('/map')),
            ]),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Account'),
          MossyCard(
            child: Column(children: [
              _ListTile(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                titleColor: AppColors.error,
                onTap: () => _confirmSignOut(context, ref),
              ),
              if (!authState.isDemoMode) ...[
                _Divider(),
                _ListTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete Account',
                  titleColor: AppColors.error,
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 20),
          MossyCard(
            child: _ListTile(
              icon: Icons.refresh_rounded,
              title: 'Reset Onboarding',
              subtitle: 'See the intro again',
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('onboarding_completed', false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Onboarding reset!')));
                }
              },
            ),
          ),
          const SizedBox(height: 40),
          Center(child: Text('Mossy — Look closer. Discover more.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText, fontStyle: FontStyle.italic))),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedText, letterSpacing: 0.5)),
  );

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) context.go('/onboarding');
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account'),
        content: const Text('To delete your account, please contact support or use the Supabase dashboard. This action is irreversible.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _ListTile({required this.icon, required this.title, this.subtitle, this.titleColor, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(children: [
          Icon(icon, color: titleColor ?? AppColors.sageGreen, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: titleColor ?? AppColors.darkGreen)),
            if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
          ])),
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText) : const SizedBox()),
        ]),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(children: [
        Icon(icon, color: AppColors.sageGreen, size: 22),
        const SizedBox(width: 14),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.darkGreen))),
        Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.sageGreen),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(height: 1, color: AppColors.border, indent: 36, endIndent: 0);
}
