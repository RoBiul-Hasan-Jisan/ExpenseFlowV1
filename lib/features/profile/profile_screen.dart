import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/export_service.dart';
import '../../providers/transaction_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final theme = Theme.of(context);
    final user = session.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppTheme.space(2),
          AppTheme.space(2),
          AppTheme.space(2),
          AppTheme.space(2) + MediaQuery.of(context).padding.bottom + 100,
        ),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
                SizedBox(height: AppTheme.space(1.5.round())),
                Text(user?.name ?? 'Guest', style: theme.textTheme.titleLarge),
                Text(user?.email ?? '', style: theme.textTheme.bodySmall),
                if (session.isDemo)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Demo Account', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning)),
                  ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.space(3)),
          if (session.isDemo) ...[
            _SectionCard(children: [
              ElevatedButton(onPressed: () => context.push('/register'), child: const Text('Create Account')),
              SizedBox(height: AppTheme.space(1)),
              OutlinedButton(onPressed: () => context.push('/login'), child: const Text('Sign In')),
            ]),
            SizedBox(height: AppTheme.space(3)),
          ],
          _SectionLabel('Preferences'),
          _SectionCard(children: [
            _NavRow(icon: Icons.tune_rounded, label: 'Currency & Settings', onTap: () => context.push('/settings')),
            _NavRow(icon: Icons.event_repeat_rounded, label: 'Recurring Payments', onTap: () => context.push('/recurring')),
            _NavRow(icon: Icons.calendar_month_rounded, label: 'Financial Calendar', onTap: () => context.push('/calendar')),
            _NavRow(icon: Icons.summarize_outlined, label: 'Reports', onTap: () => context.push('/reports'), showDivider: false),
          ]),
          SizedBox(height: AppTheme.space(2.5.round())),
          _SectionLabel('Data'),
          _SectionCard(children: [
            _NavRow(
              icon: Icons.download_outlined,
              label: 'Export Data (CSV)',
              onTap: () => _exportData(context, ref),
            ),
            if (session.isDemo)
              _NavRow(
                icon: Icons.restart_alt_rounded,
                label: 'Clear Demo Data',
                destructive: true,
                onTap: () => _confirmClearDemo(context, ref),
                showDivider: false,
              ),
          ]),
          SizedBox(height: AppTheme.space(2.5.round())),
          _SectionLabel('Security'),
          _SectionCard(children: [
            if (!session.isDemo) _NavRow(icon: Icons.lock_reset_rounded, label: 'Change Password', onTap: () => context.push('/forgot-password')),
            _NavRow(
              icon: Icons.logout_rounded,
              label: session.isDemo ? 'Exit Demo Mode' : 'Logout',
              destructive: true,
              onTap: () => ref.read(sessionProvider.notifier).signOut(),
              showDivider: false,
            ),
          ]),
          SizedBox(height: AppTheme.space(4)),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final txns = ref.read(transactionsProvider).maybeWhen(data: (t) => t, orElse: () => <TransactionModel>[]);
    final categories = ref.read(categoriesProvider).maybeWhen(data: (c) => c, orElse: () => <CategoryModel>[]);
    try {
      final file = await ExportService().exportTransactionsCsv(txns.cast(), categories.cast());
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to ${file.path.split('/').last}')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _confirmClearDemo(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear demo data?'),
        content: const Text('This resets all demo transactions, budgets, and recurring items back to sample data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sessionProvider.notifier).resetDemoData();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: AppTheme.space(1), bottom: AppTheme.space(1)),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: EdgeInsets.all(AppTheme.space(1)), child: Column(children: children)));
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final bool showDivider;

  const _NavRow({required this.icon, required this.label, required this.onTap, this.destructive = false, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.expense : null;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color),
          title: Text(label, style: TextStyle(color: color)),
          trailing: const Icon(Icons.chevron_right_rounded, size: 18),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 56),
      ],
    );
  }
}