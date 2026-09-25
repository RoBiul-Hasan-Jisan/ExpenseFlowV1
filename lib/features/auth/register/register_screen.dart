import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/app_logo.dart';
import '../../../widgets/glass_surface.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(sessionProvider.notifier).register(name: _name.text.trim(), email: _email.text.trim(), password: _password.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Check your email to verify your address.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('AppException: ', ''))));
      }
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
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(AppTheme.space(1), AppTheme.space(1), AppTheme.space(2), 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                      const AppLogo(size: 28, rounded: true),
                      SizedBox(width: AppTheme.space(1)),
                      const Text('Create Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(AppTheme.space(3), AppTheme.space(2), AppTheme.space(3), AppTheme.space(3)),
                    child: Form(
                      key: _formKey,
                      child: GlassSurface(
                        padding: EdgeInsets.all(AppTheme.space(2.5.round())),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Full Name'),
                            SizedBox(height: AppTheme.space(1)),
                            _field(controller: _name, hint: 'Jane Doe', validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null),
                            SizedBox(height: AppTheme.space(2)),
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
                              hint: 'At least 6 characters',
                              obscure: _obscure,
                              suffix: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: Colors.white70),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                            ),
                            SizedBox(height: AppTheme.space(2)),
                            _label('Confirm Password'),
                            SizedBox(height: AppTheme.space(1)),
                            _field(
                              controller: _confirm,
                              hint: 'Re-enter your password',
                              obscure: _obscure,
                              validator: (v) => (v != _password.text) ? 'Passwords do not match' : null,
                            ),
                            SizedBox(height: AppTheme.space(3)),
                            _GradientButton(loading: _loading, onTap: _submit, label: 'Create Account'),
                            SizedBox(height: AppTheme.space(1.5.round())),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).maybePop(),
                                style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                                child: const Text('Already have an account? Sign in'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  final String label;

  const _GradientButton({required this.loading, required this.onTap, required this.label});

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
