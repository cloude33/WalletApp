import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../services/data_service.dart';
import 'add_goal_screen.dart';
import 'edit_goal_screen.dart';

class ManageGoalsScreen extends StatefulWidget {
  const ManageGoalsScreen({super.key});

  @override
  State<ManageGoalsScreen> createState() => _ManageGoalsScreenState();
}

class _ManageGoalsScreenState extends State<ManageGoalsScreen> {
  final DataService _dataService = DataService();
  List<Goal> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await _dataService.getGoals();
    setState(() {
      _goals = goals;
      _loading = false;
    });
  }

  Future<void> _deleteGoal(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hedefi Sil'),
        content: const Text('Bu hedefi silmek istediğinizden emin misiniz?'),
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
      await _dataService.deleteGoal(id);
      _loadGoals();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Hedef silindi')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF5E5CE6),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                  const Expanded(
                    child: Text(
                      'Hedefleri Yönet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddGoalScreen(),
                        ),
                      );
                      if (result == true) {
                        _loadGoals();
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _goals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.flag,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Henüz hedef yok',
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
                      itemCount: _goals.length,
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            goal.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            '₺ ${NumberFormat('#,##0', 'tr_TR').format(goal.currentAmount)} / ₺ ${NumberFormat('#,##0', 'tr_TR').format(goal.targetAmount)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          if (goal.deadline != null) ...[
                                            const SizedBox(height: 5),
                                            Text(
                                              'Son Tarih: ${DateFormat('dd/MM/yyyy').format(goal.deadline!)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 60,
                                          height: 60,
                                          child: CircularProgressIndicator(
                                            value: goal.progress,
                                            strokeWidth: 5,
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  goal.progress >= 1.0
                                                      ? Colors.green
                                                      : goal.progress >= 0.5
                                                      ? Colors.orange
                                                      : Colors.red,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          '${(goal.progress * 100).toInt()}%',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditGoalScreen(goal: goal),
                                          ),
                                        );
                                        if (result == true) {
                                          _loadGoals();
                                        }
                                      },
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Düzenle'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _deleteGoal(goal.id),
                                      icon: const Icon(Icons.delete, size: 18),
                                      label: const Text('Sil'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
