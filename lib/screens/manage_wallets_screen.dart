import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';
import '../services/data_service.dart';
import 'add_wallet_screen.dart';
import 'edit_wallet_screen.dart';

class ManageWalletsScreen extends StatefulWidget {
  const ManageWalletsScreen({super.key});

  @override
  State<ManageWalletsScreen> createState() => _ManageWalletsScreenState();
}

class _ManageWalletsScreenState extends State<ManageWalletsScreen> {
  final DataService _dataService = DataService();
  List<Wallet> _wallets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  // Wallet name'den kesim ve ödeme tarihi bilgilerini temizle
  String _cleanWalletName(String name) {
    String cleaned = name;
    
    // Kesim tarihi bilgisini kaldır
    if (cleaned.contains('(Kesim: ')) {
      final start = cleaned.indexOf('(Kesim: ');
      final end = cleaned.indexOf(')', start);
      if (end > start) {
        cleaned = cleaned.substring(0, start).trim() + cleaned.substring(end + 1).trim();
      }
    }
    
    // Son ödeme tarihi bilgisini kaldır
    if (cleaned.contains('(Son Ödeme: ')) {
      final start = cleaned.indexOf('(Son Ödeme: ');
      final end = cleaned.indexOf(')', start);
      if (end > start) {
        cleaned = cleaned.substring(0, start).trim() + cleaned.substring(end + 1).trim();
      }
    }
    
    return cleaned.trim();
  }

  Future<void> _loadWallets() async {
    final wallets = await _dataService.getWallets();
    setState(() {
      _wallets = wallets;
      _loading = false;
    });
  }

  Future<void> _deleteWallet(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cüzdanı Sil'),
        content: const Text('Bu cüzdanı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dataService.deleteWallet(id);
      _loadWallets();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cüzdan silindi')));
      }
    }
  }

  Future<void> _editWallet(Wallet wallet) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditWalletScreen(wallet: wallet)),
    );
    if (result == true) {
      _loadWallets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: const Icon(Icons.arrow_back, color: Color(0xFF5E5CE6)),
                  ),
                  const Expanded(
                    child: Text(
                      'Cüzdanlarım',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddWalletScreen(),
                        ),
                      );
                      if (result == true) {
                        _loadWallets();
                      }
                    },
                    child: const Icon(Icons.add, color: Color(0xFF5E5CE6)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _wallets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Henüz cüzdan yok',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _wallets.length,
                      itemBuilder: (context, index) {
                        final wallet = _wallets[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          elevation: 3,
                          shadowColor: Colors.grey.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(int.parse(wallet.color)),
                                  Color(
                                    int.parse(wallet.color),
                                  ).withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          wallet.type == 'cash'
                                              ? Icons.account_balance_wallet
                                              : wallet.type == 'credit_card'
                                              ? Icons.credit_card
                                              : wallet.type == 'overdraft'
                                              ? Icons.account_balance
                                              : Icons.account_balance,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _cleanWalletName(wallet.name),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₺${NumberFormat('#,##0', 'tr_TR').format(wallet.balance)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if ((wallet.type == 'credit_card' || wallet.type == 'overdraft') && wallet.creditLimit > 0) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Limit: ₺${NumberFormat('#,##0', 'tr_TR').format(wallet.creditLimit)}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                'Kullanılabilir: ₺${NumberFormat('#,##0', 'tr_TR').format(wallet.creditLimit + wallet.balance)}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: Colors.white),
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _editWallet(wallet);
                                          } else if (value == 'delete') {
                                            _deleteWallet(wallet.id);
                                          }
                                        },
                                        itemBuilder: (BuildContext context) {
                                          return [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Düzenle'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Sil'),
                                                ],
                                              ),
                                            ),
                                          ];
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
