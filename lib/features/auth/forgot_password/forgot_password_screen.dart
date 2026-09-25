import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/glass_surface.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(sessionProvider.notifier).sendPasswordReset(_email.text.trim());
      setState(() => _sent = true);
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
                      const Text('Reset Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.space(3)),
                    child: GlassSurface(
                      padding: EdgeInsets.all(AppTheme.space(2.5.round())),
                      child: _sent
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), shape: BoxShape.circle),
                                  child: const Icon(Icons.mark_email_read_outlined, size: 30, color: AppColors.gold),
                                ),
                                SizedBox(height: AppTheme.space(2)),
                                const Text('Check your inbox', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
                                SizedBox(height: AppTheme.space(1)),
                                Text(
                                  'We sent a password reset link to ${_email.text.trim()}.',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                                ),
                              ],
                            )
                          : Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Enter the email associated with your account and we\'ll send you a reset link.',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                                  ),
                                  SizedBox(height: AppTheme.space(3)),
                                  const Text('Email', style: TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w600)),
                                  SizedBox(height: AppTheme.space(1)),
                                  TextFormField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'you@example.com',
                                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                                      filled: true,
                                      fillColor: Colors.white.withValues(alpha: 0.06),
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
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Enter your email';
                                      if (!v.contains('@')) return 'Enter a valid email';
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: AppTheme.space(3)),
                                  Container(
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
                                        onTap: _loading ? null : _submit,
                                        child: Center(
                                          child: _loading
                                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.midnight))
                                              : const Text('Send Reset Link', style: TextStyle(color: AppColors.midnight, fontSize: 15.5, fontWeight: FontWeight.w800)),
                                        ),
                                      ),
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
}
