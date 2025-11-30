import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../services/data_service.dart';
import '../utils/currency_helper.dart';
import '../models/user.dart';
import 'add_budget_screen.dart';

class ManageBudgetsScreen extends StatefulWidget {
  const ManageBudgetsScreen({super.key});

  @override
  State<ManageBudgetsScreen> createState() => _ManageBudgetsScreenState();
}

class _ManageBudgetsScreenState extends State<ManageBudgetsScreen> {
  final DataService _dataService = DataService();
  List<Budget> _budgets = [];
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBudgets();
  }

  Future<void> _loadUserData() async {
    final user = await _dataService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _loadBudgets() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final budgets = await _dataService.getBudgets();
      setState(() {
        _budgets = budgets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bütçeler yüklenirken hata oluştu')),
        );
      }
    }
  }

  Future<void> _refreshBudgets() async {
    await _loadBudgets();
  }

  void _addBudget() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddBudgetScreen()),
    );
    
    if (result == true) {
      _loadBudgets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bütçe başarıyla eklendi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bütçelerim'),
        backgroundColor: const Color(0xFFFDB32A),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBudgets,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _budgets.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _budgets.length,
                    itemBuilder: (context, index) {
                      return _buildBudgetCard(_budgets[index]);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBudget,
        backgroundColor: const Color(0xFFFDB32A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz bütçe eklenmemiş',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _addBudget,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDB32A),
            ),
            child: const Text('İlk Bütçeni Oluştur'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    final remaining = budget.remaining;
    final percentage = budget.percentage;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        budget.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: percentage > 90 
                        ? Colors.red.withOpacity(0.2)
                        : percentage > 75
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: percentage > 90 
                          ? Colors.red
                          : percentage > 75
                              ? Colors.orange
                              : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 90 
                      ? Colors.red
                      : percentage > 75
                          ? Colors.orange
                          : Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Amount info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Harcanan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      CurrencyHelper.formatAmount(budget.spent, _currentUser),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Kalan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      CurrencyHelper.formatAmount(remaining, _currentUser),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: remaining < 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Total budget
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toplam Bütçe',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  CurrencyHelper.formatAmount(budget.amount, _currentUser),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}