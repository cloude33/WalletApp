import 'package:flutter/material.dart';
import '../models/notification_preferences.dart';
import '../services/notification_preferences_service.dart';
import 'kmh_alert_settings_screen.dart';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ayarlar kaydedildi')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _savePreferences),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDailySummarySection(),
          const SizedBox(height: 24),
          _buildWeeklySummarySection(),
          const SizedBox(height: 24),
          _buildBillRemindersSection(),
          const SizedBox(height: 24),
          _buildInstallmentRemindersSection(),
          const SizedBox(height: 24),
          _buildPaymentRemindersSection(),
          const SizedBox(height: 24),
          _buildLimitAlertsSection(),
          const SizedBox(height: 24),
          _buildStatementCutNotificationsSection(),
          const SizedBox(height: 24),
          _buildInstallmentEndingNotificationsSection(),
          const SizedBox(height: 24),
          _buildKmhNotificationsSection(),
        ],
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
                subtitle: Text(
                  '${_preferences!.installmentReminderDays} gün önce',
                ),
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

  Widget _buildPaymentRemindersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kredi Kartı Ödeme Hatırlatmaları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Ödeme hatırlatmaları'),
              subtitle: const Text('Son ödeme tarihinden önce hatırlat'),
              value: _preferences!.paymentRemindersEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    paymentRemindersEnabled: value,
                  );
                });
              },
            ),
            if (_preferences!.paymentRemindersEnabled) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Hatırlatma günleri (son ödeme tarihinden önce)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              CheckboxListTile(
                title: const Text('3 gün önce'),
                value: _preferences!.paymentReminderDays.contains(3),
                onChanged: (value) {
                  setState(() {
                    final days = List<int>.from(_preferences!.paymentReminderDays);
                    if (value == true) {
                      if (!days.contains(3)) days.add(3);
                    } else {
                      days.remove(3);
                    }
                    days.sort();
                    _preferences = _preferences!.copyWith(
                      paymentReminderDays: days,
                    );
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('5 gün önce'),
                value: _preferences!.paymentReminderDays.contains(5),
                onChanged: (value) {
                  setState(() {
                    final days = List<int>.from(_preferences!.paymentReminderDays);
                    if (value == true) {
                      if (!days.contains(5)) days.add(5);
                    } else {
                      days.remove(5);
                    }
                    days.sort();
                    _preferences = _preferences!.copyWith(
                      paymentReminderDays: days,
                    );
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('7 gün önce'),
                value: _preferences!.paymentReminderDays.contains(7),
                onChanged: (value) {
                  setState(() {
                    final days = List<int>.from(_preferences!.paymentReminderDays);
                    if (value == true) {
                      if (!days.contains(7)) days.add(7);
                    } else {
                      days.remove(7);
                    }
                    days.sort();
                    _preferences = _preferences!.copyWith(
                      paymentReminderDays: days,
                    );
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLimitAlertsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Limit Uyarıları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Limit uyarıları'),
              subtitle: const Text('Kart limitine yaklaşıldığında uyar'),
              value: _preferences!.limitAlertsEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    limitAlertsEnabled: value,
                  );
                });
              },
            ),
            if (_preferences!.limitAlertsEnabled) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Uyarı eşikleri (limit kullanım oranı)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              CheckboxListTile(
                title: const Text('%80 limite ulaşıldığında'),
                value: _preferences!.limitAlertThresholds.contains(80.0),
                onChanged: (value) {
                  setState(() {
                    final thresholds = List<double>.from(_preferences!.limitAlertThresholds);
                    if (value == true) {
                      if (!thresholds.contains(80.0)) thresholds.add(80.0);
                    } else {
                      thresholds.remove(80.0);
                    }
                    thresholds.sort();
                    _preferences = _preferences!.copyWith(
                      limitAlertThresholds: thresholds,
                    );
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('%90 limite ulaşıldığında'),
                value: _preferences!.limitAlertThresholds.contains(90.0),
                onChanged: (value) {
                  setState(() {
                    final thresholds = List<double>.from(_preferences!.limitAlertThresholds);
                    if (value == true) {
                      if (!thresholds.contains(90.0)) thresholds.add(90.0);
                    } else {
                      thresholds.remove(90.0);
                    }
                    thresholds.sort();
                    _preferences = _preferences!.copyWith(
                      limitAlertThresholds: thresholds,
                    );
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('%100 limite ulaşıldığında'),
                value: _preferences!.limitAlertThresholds.contains(100.0),
                onChanged: (value) {
                  setState(() {
                    final thresholds = List<double>.from(_preferences!.limitAlertThresholds);
                    if (value == true) {
                      if (!thresholds.contains(100.0)) thresholds.add(100.0);
                    } else {
                      thresholds.remove(100.0);
                    }
                    thresholds.sort();
                    _preferences = _preferences!.copyWith(
                      limitAlertThresholds: thresholds,
                    );
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatementCutNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ekstre Kesim Bildirimleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Ekstre kesim bildirimleri'),
              subtitle: const Text('Ekstre kesildiğinde bildirim al'),
              value: _preferences!.statementCutNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    statementCutNotificationsEnabled: value,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentEndingNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Taksit Bitişi Bildirimleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Taksit bitişi bildirimleri'),
              subtitle: const Text('Taksit son ödemeye ulaştığında bildirim al'),
              value: _preferences!.installmentEndingNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    installmentEndingNotificationsEnabled: value,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKmhNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KMH Bildirimleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kredili Mevduat Hesabı (KMH) bildirimleri için ayarlar',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: const Text('Limit Uyarıları'),
              subtitle: const Text('KMH limit kullanımı uyarıları'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KmhAlertSettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.blue),
              title: const Text('Faiz Bildirimleri'),
              subtitle: const Text('Günlük faiz tahakkuku bildirimleri'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KmhAlertSettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.green),
              title: const Text('Ödeme Hatırlatıcıları'),
              subtitle: const Text('Ödeme planı hatırlatıcıları'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ödeme hatırlatıcıları ödeme planı ekranından yönetilir'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

