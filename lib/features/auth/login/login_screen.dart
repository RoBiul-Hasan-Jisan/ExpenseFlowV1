import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/app_logo.dart';
import '../../../widgets/glass_surface.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(sessionProvider.notifier).signIn(email: _email.text, password: _password.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('AppException: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exploreDemo() async {
    setState(() => _loading = true);
    try {
      await ref.read(sessionProvider.notifier).enterDemoMode();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppColors.auroraGradient)),
          const Positioned.fill(child: MeshDots(color: Colors.white)),
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withValues(alpha: 0.14)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.space(3), vertical: AppTheme.space(3)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppTheme.space(2)),
                    const AppLogo(size: 58, glow: true),
                    SizedBox(height: AppTheme.space(2.5.round())),
                    Text(AppConstants.appName, style: AppTheme.amountStyle(size: 32, color: Colors.white)),
                    SizedBox(height: AppTheme.space(1)),
                    Text(AppConstants.tagline, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14.5)),
                    SizedBox(height: AppTheme.space(4)),
                    GlassSurface(
                      padding: EdgeInsets.all(AppTheme.space(2.5.round())),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Email'),
                          SizedBox(height: AppTheme.space(1)),
                          _field(
                            controller: _email,
                            hint: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter your email';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          SizedBox(height: AppTheme.space(2)),
                          _label('Password'),
                          SizedBox(height: AppTheme.space(1)),
                          _field(
                            controller: _password,
                            hint: '••••••••',
                            obscure: _obscure,
                            suffix: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: Colors.white70),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          SizedBox(height: AppTheme.space(1)),
                          _PrimaryGradientButton(loading: _loading, onTap: _submit, label: 'Sign In'),
                          SizedBox(height: AppTheme.space(1.5.round())),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _loading ? null : () => context.push('/register'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: const Text('Create Account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppTheme.space(3)),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppTheme.space(1.5.round())),
                          child: Text('OR', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
                      ],
                    ),
                    SizedBox(height: AppTheme.space(3)),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _exploreDemo,
                        icon: const Icon(Icons.explore_outlined, size: 20, color: AppColors.gold),
                        label: const Text('Explore Demo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gold,
                          side: const BorderSide(color: AppColors.gold, width: 1.25),
                        ),
                      ),
                    ),
                    SizedBox(height: AppTheme.space(1)),
                    Center(
                      child: Text('No account required', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12.5)),
                    ),
                    SizedBox(height: AppTheme.space(2)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w600));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: AppColors.expense),
        ),
      ),
    );
  }
}

/// Shared gold-to-green gradient CTA used on the dark auth screens.
class _PrimaryGradientButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  final String label;

  const _PrimaryGradientButton({required this.loading, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: AppTheme.space(7),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          onTap: loading ? null : onTap,
          child: Center(
            child: loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.midnight))
                : Text(label, style: const TextStyle(color: AppColors.midnight, fontSize: 15.5, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}
