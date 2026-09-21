import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/app_logo.dart';

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
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.space(3), vertical: AppTheme.space(4)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppTheme.space(4)),
                const AppLogo(size: 56),
                SizedBox(height: AppTheme.space(2.5.round())),
                Text(AppConstants.appName, style: theme.textTheme.displayLarge),
                SizedBox(height: AppTheme.space(1)),
                Text(AppConstants.tagline, style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodySmall?.color)),
                SizedBox(height: AppTheme.space(4)),
                Text('Email', style: theme.textTheme.labelLarge),
                SizedBox(height: AppTheme.space(1)),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'you@example.com'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.space(2)),
                Text('Password', style: theme.textTheme.labelLarge),
                SizedBox(height: AppTheme.space(1)),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                ),
                SizedBox(height: AppTheme.space(1)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ),
                SizedBox(height: AppTheme.space(1)),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Sign In'),
                ),
                SizedBox(height: AppTheme.space(1.5.round())),
                OutlinedButton(
                  onPressed: _loading ? null : () => context.push('/register'),
                  child: const Text('Create Account'),
                ),
                SizedBox(height: AppTheme.space(3)),
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerTheme.color)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppTheme.space(1.5.round())),
                      child: Text('OR', style: theme.textTheme.bodySmall),
                    ),
                    Expanded(child: Divider(color: theme.dividerTheme.color)),
                  ],
                ),
                SizedBox(height: AppTheme.space(3)),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _exploreDemo,
                  icon: const Icon(Icons.explore_outlined, size: 20),
                  label: const Text('Explore Demo'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
                ),
                SizedBox(height: AppTheme.space(1)),
                Center(
                  child: Text('No account required', style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
