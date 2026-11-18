import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mossy_card.dart';
import '../../../l10n/app_localizations.dart';
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
    final isFr = currentLocale.languageCode == 'fr';
    final languageName = isFr ? 'Français' : 'English';
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkGreen),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text(l10n?.settings ?? 'Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
          elevation: 0,
        ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionLabel(l10n?.profile ?? 'Profile'),
          MossyCard(
            child: Column(children: [
              _ListTile(icon: Icons.person_outline_rounded, title: profile?.username ?? 'Explorer', subtitle: isFr ? 'Touchez pour modifier' : 'Tap to edit username'),
              _Divider(),
              _ListTile(icon: Icons.emoji_events_outlined, title: l10n?.explorerLevel(profile?.explorerLevel ?? 1) ?? 'Level ${profile?.explorerLevel ?? 1}', subtitle: l10n?.points(profile?.totalPoints ?? 0) ?? '${profile?.totalPoints ?? 0} total points'),
            ]),
          ),
          const SizedBox(height: 20),
          _sectionLabel(isFr ? 'Préférences' : 'Preferences'),
          MossyCard(
            child: Column(children: [
              _SwitchTile(icon: Icons.notifications_outlined, title: l10n?.notifications ?? 'Notifications', value: _notificationsEnabled, onChanged: (v) => setState(() => _notificationsEnabled = v)),
              _Divider(),
              _ListTile(
                icon: Icons.language_rounded,
                title: l10n?.language ?? 'Language',
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
          _sectionLabel(l10n?.about ?? 'About'),
          MossyCard(
            child: Column(children: [
              _ListTile(icon: Icons.info_outline_rounded, title: 'Version', subtitle: '1.0.0'),
              _Divider(),
              _ListTile(icon: Icons.privacy_tip_outlined, title: l10n?.privacy ?? 'Privacy Policy', onTap: () {}),
              _Divider(),
              _ListTile(icon: Icons.map_outlined, title: l10n?.discoveryMap ?? 'Discovery Map', onTap: () => context.push('/map')),
            ]),
          ),
          const SizedBox(height: 20),
          _sectionLabel(isFr ? 'Compte' : 'Account'),
          MossyCard(
            child: Column(children: [
              if (!authState.isAuthenticated || authState.isGuest)
                _ListTile(
                  icon: Icons.login_rounded,
                  title: isFr ? 'Connexion / Inscription' : 'Sign In / Register',
                  subtitle: isFr ? 'Synchronisez vos découvertes sur le cloud' : 'Sync discoveries across devices',
                  titleColor: AppColors.sageGreen,
                  onTap: () => context.push('/auth'),
                )
              else
                _ListTile(
                  icon: Icons.account_circle_outlined,
                  title: isFr ? 'Changer de compte' : 'Switch Account',
                  subtitle: isFr ? 'Connecté en tant que ${profile?.username ?? 'Explorer'}' : 'Currently signed in as ${profile?.username ?? 'Explorer'}',
                  onTap: () => context.push('/auth'),
                ),
              _Divider(),
              _ListTile(
                icon: Icons.logout_rounded,
                title: l10n?.signOut ?? 'Sign Out',
                titleColor: AppColors.error,
                onTap: () => _confirmSignOut(context, ref),
              ),
              if (authState.isAuthenticated && !authState.isGuest) ...[
                _Divider(),
                _ListTile(
                  icon: Icons.delete_forever_rounded,
                  title: l10n?.deleteAccount ?? 'Delete Account',
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
              title: isFr ? 'Réinitialiser l\'accueil' : 'Reset Onboarding',
              subtitle: isFr ? 'Revoir l\'introduction de l\'application' : 'See the intro again',
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('onboarding_completed', false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isFr ? 'Accueil réinitialisé !' : 'Onboarding reset!')));
                }
              },
            ),
          ),
          const SizedBox(height: 40),
          Center(child: Text('Mossy — ${l10n?.tagline ?? 'Look closer. Discover more.'}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText, fontStyle: FontStyle.italic))),
        ],
      ),
    ),
  );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedText, letterSpacing: 0.5)),
  );

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final isFr = ref.read(localeProvider).languageCode == 'fr';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n?.signOut ?? 'Sign Out'),
        content: Text(isFr ? 'Voulez-vous vraiment vous déconnecter ?' : 'Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: Text(l10n?.cancel ?? 'Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(true), child: Text(l10n?.signOut ?? 'Sign Out', style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) context.go('/auth');
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final isFr = ref.read(localeProvider).languageCode == 'fr';
    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n?.deleteAccount ?? 'Delete Account'),
        content: Text(isFr
            ? 'Pour supprimer votre compte, veuillez contacter le support ou utiliser le tableau de bord Supabase. Cette action est irréversible.'
            : 'To delete your account, please contact support or use the Supabase dashboard. This action is irreversible.'),
        actions: [TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('OK'))],
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
