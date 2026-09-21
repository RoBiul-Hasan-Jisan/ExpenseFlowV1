import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.all(AppTheme.space(2)),
        children: [
          Text('Appearance', style: theme.textTheme.titleSmall),
          SizedBox(height: AppTheme.space(1)),
          Card(
            child: Column(children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: settings.themeMode,
                onChanged: (v) => notifier.setThemeMode(v!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: settings.themeMode,
                onChanged: (v) => notifier.setThemeMode(v!),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                value: ThemeMode.system,
                groupValue: settings.themeMode,
                onChanged: (v) => notifier.setThemeMode(v!),
              ),
            ]),
          ),
          SizedBox(height: AppTheme.space(2.5.round())),
          Text('Currency', style: theme.textTheme.titleSmall),
          SizedBox(height: AppTheme.space(1)),
          Card(
            child: Column(
              children: [
                for (final c in AppConstants.supportedCurrencies)
                  RadioListTile<String>(
                    title: Text(c),
                    value: c,
                    groupValue: settings.currency,
                    onChanged: (v) => notifier.setCurrency(v!),
                  ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.space(2.5.round())),
          Text('Notifications', style: theme.textTheme.titleSmall),
          SizedBox(height: AppTheme.space(1)),
          Card(
            child: SwitchListTile(
              title: const Text('Budget & bill reminders'),
              subtitle: const Text('Alerts for budget limits and upcoming recurring payments'),
              value: settings.notificationsEnabled,
              onChanged: (v) => notifier.setNotificationsEnabled(v),
            ),
          ),
          SizedBox(height: AppTheme.space(2.5.round())),
          Text('Week starts on', style: theme.textTheme.titleSmall),
          SizedBox(height: AppTheme.space(1)),
          Card(
            child: Row(children: [
              Expanded(
                child: RadioListTile<int>(title: const Text('Monday'), value: 1, groupValue: settings.startOfWeek, onChanged: (v) => notifier.setStartOfWeek(v!)),
              ),
              Expanded(
                child: RadioListTile<int>(title: const Text('Sunday'), value: 7, groupValue: settings.startOfWeek, onChanged: (v) => notifier.setStartOfWeek(v!)),
              ),
            ]),
          ),
          SizedBox(height: AppTheme.space(4)),
        ],
      ),
    );
  }
}
