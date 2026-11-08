import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mossy_button.dart';
import '../../../core/widgets/mossy_card.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/mascot/mascot_expression.dart';
import '../../../shared/widgets/mascot/mossy_mascot.dart';

/// Screen managing user authentication (Sign In, Registration, Password Reset, Guest Mode).
class AuthScreen extends ConsumerStatefulWidget {
  final bool initialIsSignUp;
  final bool animateMascot;

  const AuthScreen({
    super.key,
    this.initialIsSignUp = false,
    this.animateMascot = true,
  });

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  // Text Editing Controllers
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  final _signUpUsernameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  bool _obscureSignInPassword = true;
  bool _obscureSignUpPassword = true;
  bool _obscureSignUpConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIsSignUp ? 1 : 0,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(authProvider.notifier).clearError();
        ref.read(authProvider.notifier).clearSuccess();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpUsernameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (!mounted) return;
    try {
      context.go('/home');
    } catch (_) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _handleSignIn() async {
    if (!(_signInFormKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(authProvider.notifier).signInWithEmail(
          _signInEmailController.text,
          _signInPasswordController.text,
        );

    if (success) {
      _navigateToHome();
    }
  }

  Future<void> _handleSignUp() async {
    if (!(_signUpFormKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(authProvider.notifier).signUpWithEmail(
          _signUpEmailController.text,
          _signUpPasswordController.text,
          username: _signUpUsernameController.text,
        );

    if (success) {
      _navigateToHome();
    }
  }

  Future<void> _handleContinueAsGuest() async {
    await ref.read(authProvider.notifier).continueAsGuest();
    _navigateToHome();
  }

  Future<void> _handleDemoExplore() async {
    await ref.read(authProvider.notifier).enterDemoMode();
    _navigateToHome();
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _signInEmailController.text);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.creamBackground,
        title: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: AppColors.sageGreen),
            const SizedBox(width: 8),
            Text(
              'Reset Password',
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.w700,
                color: AppColors.darkGreen,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your account email and we will send you instructions to reset your password.',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('auth_reset_email_field'),
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  label: 'Email address',
                  icon: Icons.email_outlined,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Email is required';
                  if (!val.contains('@') || !val.contains('.')) return 'Invalid email address';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          ElevatedButton(
            key: const Key('auth_send_reset_button'),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final email = emailController.text;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                await ref.read(authProvider.notifier).resetPassword(email);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.darkGreen,
                    behavior: SnackBarBehavior.floating,
                    content: Text('Reset link dispatched to $email'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Send Link', style: GoogleFonts.quicksand(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.nunito(color: AppColors.secondaryText, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.sageGreen, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.sageGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isSignUp = _tabController.index == 1;

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkGreen, size: 20),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              )
            : null,
        actions: [
          TextButton.icon(
            key: const Key('auth_guest_button'),
            onPressed: _handleContinueAsGuest,
            icon: const Icon(Icons.explore_outlined, color: AppColors.secondaryText, size: 18),
            label: Text(
              'Guest Tour',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Mossy Mascot header
                  MossyMascot(
                    expression: isSignUp ? MascotExpression.excited : MascotExpression.happy,
                    size: 96,
                    animate: widget.animateMascot,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Mossy Nature Journal',
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSignUp
                        ? 'Begin your wild exploration journey'
                        : 'Welcome back! Log in to access your discoveries',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: AppColors.secondaryText,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Tab selector (Sign In vs Create Account)
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.sageGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.secondaryText,
                      labelStyle: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(key: Key('auth_tab_sign_in'), text: 'Sign In'),
                        Tab(key: Key('auth_tab_sign_up'), text: 'Create Account'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3. Error / Success message banners
                  if (authState.errorMessage != null)
                    Container(
                      key: const Key('auth_error_banner'),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => ref.read(authProvider.notifier).clearError(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 200.ms).shake(duration: 300.ms),

                  if (authState.successMessage != null)
                    Container(
                      key: const Key('auth_success_banner'),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.sageGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.sageGreen.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppColors.darkGreen, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authState.successMessage!,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: AppColors.darkGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 200.ms),

                  // 4. Form Area inside MossyCard
                  MossyCard(
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: isSignUp
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: _buildSignInForm(authState),
                      secondChild: _buildSignUpForm(authState),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. Quick Demo account button
                  TextButton.icon(
                    key: const Key('auth_demo_button'),
                    onPressed: _handleDemoExplore,
                    icon: const Icon(Icons.eco_rounded, size: 16, color: AppColors.sageGreen),
                    label: Text(
                      'Explore with Demo Account (Fern Wanderer)',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sageGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm(AuthState authState) {
    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('auth_email_field'),
            controller: _signInEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Email address',
              icon: Icons.email_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('auth_password_field'),
            controller: _signInPasswordController,
            obscureText: _obscureSignInPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSignIn(),
            decoration: _inputDecoration(
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignInPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.secondaryText,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureSignInPassword = !_obscureSignInPassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('auth_forgot_password_button'),
              onPressed: _showForgotPasswordDialog,
              child: Text(
                'Forgot password?',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          MossyButton.primary(
            key: const Key('auth_signin_button'),
            text: 'Sign In',
            isLoading: authState.isLoading,
            isFullWidth: true,
            onPressed: authState.isLoading ? null : _handleSignIn,
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm(AuthState authState) {
    return Form(
      key: _signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('auth_username_field'),
            controller: _signUpUsernameController,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Explorer Name',
              icon: Icons.person_outline_rounded,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Name is required';
              if (value.trim().length < 2) return 'Must be at least 2 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('auth_signup_email_field'),
            controller: _signUpEmailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Email address',
              icon: Icons.email_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Email is required';
              if (!value.contains('@') || !value.contains('.')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('auth_signup_password_field'),
            controller: _signUpPasswordController,
            obscureText: _obscureSignUpPassword,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Password (min. 6 characters)',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignUpPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.secondaryText,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureSignUpPassword = !_obscureSignUpPassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const Key('auth_confirm_password_field'),
            controller: _signUpConfirmPasswordController,
            obscureText: _obscureSignUpConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSignUp(),
            decoration: _inputDecoration(
              label: 'Confirm Password',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignUpConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.secondaryText,
                  size: 20,
                ),
                onPressed: () => setState(
                    () => _obscureSignUpConfirmPassword = !_obscureSignUpConfirmPassword),
              ),
            ),
            validator: (value) {
              if (value != _signUpPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          MossyButton.primary(
            key: const Key('auth_signup_button'),
            text: 'Create Account',
            isLoading: authState.isLoading,
            isFullWidth: true,
            onPressed: authState.isLoading ? null : _handleSignUp,
          ),
        ],
      ),
    );
  }
}
