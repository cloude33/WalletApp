import 'package:flutter/material.dart';
import '../models/currency.dart';
import '../models/user.dart';
import '../services/data_service.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  final DataService _dataService = DataService();
  User? _currentUser;
  String _selectedCurrencyCode = 'TRY';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _dataService.getCurrentUser();
    setState(() {
      _currentUser = user;
      _selectedCurrencyCode = user?.currencyCode ?? 'TRY';
      _loading = false;
    });
  }

  Future<void> _saveCurrency(Currency currency) async {
    if (_currentUser == null) return;

    final updatedUser = User(
      id: _currentUser!.id,
      name: _currentUser!.name,
      email: _currentUser!.email,
      avatar: _currentUser!.avatar,
      currencyCode: currency.code,
      currencySymbol: currency.symbol,
    );

    await _dataService.saveUser(updatedUser);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Para birimi ${currency.name} olarak güncellendi'),
          backgroundColor: const Color(0xFF34C759),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCurrencyList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Para Birimi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCurrencyList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: availableCurrencies.length,
      itemBuilder: (context, index) {
        final currency = availableCurrencies[index];
        final isSelected = currency.code == _selectedCurrencyCode;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF5E5CE6) : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF5E5CE6).withValues(alpha: 0.1)
                    : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  currency.symbol,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? const Color(0xFF5E5CE6)
                        : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
            title: Text(
              currency.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              currency.code,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
            trailing: isSelected
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF5E5CE6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                : null,
            onTap: () => _saveCurrency(currency),
          ),
        );
      },
    );
  }
}
