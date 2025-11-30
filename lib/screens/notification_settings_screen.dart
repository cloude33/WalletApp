import 'package:flutter/material.dart';
import '../models/notification_preferences.dart';
import '../services/notification_preferences_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationPreferencesService _prefsService =
      NotificationPreferencesService();

  NotificationPreferences? _preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _prefsService.getPreferences();
    setState(() {
      _preferences = prefs;
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    if (_preferences != null) {
      await _prefsService.savePreferences(_preferences!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayarlar kaydedildi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreferences,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBudgetAlertsSection(),
          const SizedBox(height: 24),
          _buildDailySummarySection(),
          const SizedBox(height: 24),
          _buildWeeklySummarySection(),
          const SizedBox(height: 24),
          _buildBillRemindersSection(),
          const SizedBox(height: 24),
          _buildInstallmentRemindersSection(),
        ],
      ),
    );
  }

  Widget _buildBudgetAlertsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bütçe Uyarıları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Bütçe uyarılarını etkinleştir'),
              value: _preferences!.budgetAlertsEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    budgetAlertsEnabled: value,
                  );
                });
              },
            ),
            if (_preferences!.budgetAlertsEnabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Uyarı eşiği'),
                subtitle: Text('%${_preferences!.budgetAlertThreshold}'),
                trailing: SizedBox(
                  width: 200,
                  child: Slider(
                    value: _preferences!.budgetAlertThreshold.toDouble(),
                    min: 50,
                    max: 100,
                    divisions: 10,
                    label: '%${_preferences!.budgetAlertThreshold}',
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences!.copyWith(
                          budgetAlertThreshold: value.toInt(),
                        );
                      });
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Günlük Özet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Günlük özet bildirimi'),
              value: _preferences!.dailySummaryEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    dailySummaryEnabled: value,
                  );
                });
              },
            ),
            if (_preferences!.dailySummaryEnabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Bildirim saati'),
                subtitle: Text(
                  '${_preferences!.dailySummaryTime.hour.toString().padLeft(2, '0')}:'
                  '${_preferences!.dailySummaryTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _preferences!.dailySummaryTime,
                  );
                  if (time != null) {
                    setState(() {
                      _preferences = _preferences!.copyWith(
                        dailySummaryTime: time,
                      );
                    });
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Haftalık Özet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Haftalık özet bildirimi'),
              subtitle: const Text('Her Pazartesi'),
              value: _preferences!.weeklySummaryEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    weeklySummaryEnabled: value,
                  );
                });
              },
            ),
            if (_preferences!.weeklySummaryEnabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Bildirim saati'),
                subtitle: Text(
                  '${_preferences!.weeklySummaryTime.hour.toString().padLeft(2, '0')}:'
                  '${_preferences!.weeklySummaryTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _preferences!.weeklySummaryTime,
                  );
                  if (time != null) {
                    setState(() {
                      _preferences = _preferences!.copyWith(
                        weeklySummaryTime: time,
                      );
                    });
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBillRemindersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fatura Hatırlatıcıları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Fatura hatırlatıcıları'),
              value: _preferences!.billRemindersEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    billRemindersEnabled: value,
                  );
                });
              },
            ),
            if (_preferences!.billRemindersEnabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Kaç gün önce hatırlat'),
                subtitle: Text('${_preferences!.billReminderDays} gün önce'),
                trailing: SizedBox(
                  width: 200,
                  child: Slider(
                    value: _preferences!.billReminderDays.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    label: '${_preferences!.billReminderDays} gün',
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences!.copyWith(
                          billReminderDays: value.toInt(),
                        );
                      });
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentRemindersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Taksit Hatırlatıcıları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Taksit hatırlatıcıları'),
              value: _preferences!.installmentRemindersEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    installmentRemindersEnabled: value,
                  );
                });
              },
            ),
            if (_preferences!.installmentRemindersEnabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Kaç gün önce hatırlat'),
                subtitle: Text('${_preferences!.installmentReminderDays} gün önce'),
                trailing: SizedBox(
                  width: 200,
                  child: Slider(
                    value: _preferences!.installmentReminderDays.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${_preferences!.installmentReminderDays} gün',
                    onChanged: (value) {
                      setState(() {
                        _preferences = _preferences!.copyWith(
                          installmentReminderDays: value.toInt(),
                        );
                      });
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
