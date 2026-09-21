import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'transaction_provider.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String currency;
  final bool notificationsEnabled;
  final int startOfWeek; // 1 = Monday, 7 = Sunday

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.currency = 'USD',
    this.notificationsEnabled = true,
    this.startOfWeek = 1,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? currency,
    bool? notificationsEnabled,
    int? startOfWeek,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      currency: currency ?? this.currency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      startOfWeek: startOfWeek ?? this.startOfWeek,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'currency': currency,
        'notificationsEnabled': notificationsEnabled,
        'startOfWeek': startOfWeek,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere((m) => m.name == json['themeMode'], orElse: () => ThemeMode.system),
      currency: json['currency'] as String? ?? 'USD',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      startOfWeek: json['startOfWeek'] as int? ?? 1,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final Ref ref;
  SettingsNotifier(this.ref) : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final session = ref.read(sessionProvider);
    if (session.isAuthenticated && session.uid != null) {
      final remote = await ref.read(firestoreServiceProvider).loadSettings(session.uid!);
      if (remote != null) {
        state = AppSettings.fromJson(remote);
        return;
      }
    }
    final local = await ref.read(localStorageServiceProvider).loadSettings();
    if (local.isNotEmpty) state = AppSettings.fromJson(local);
  }

  Future<void> _persist() async {
    final session = ref.read(sessionProvider);
    await ref.read(localStorageServiceProvider).saveSettings(state.toJson());
    if (session.isAuthenticated && session.uid != null) {
      await ref.read(firestoreServiceProvider).saveSettings(session.uid!, state.toJson());
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _persist();
  }

  Future<void> setCurrency(String currency) async {
    state = state.copyWith(currency: currency);
    await _persist();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _persist();
  }

  Future<void> setStartOfWeek(int day) async {
    state = state.copyWith(startOfWeek: day);
    await _persist();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) => SettingsNotifier(ref));
