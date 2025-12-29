import 'package:flutter/material.dart';
import '../../utils/debounce_throttle.dart';
import 'debounced_filter_bar.dart';
import 'throttled_scroll_view.dart';
import '../../models/category.dart';
import '../../models/wallet.dart';
class DebounceThrottleDemo extends StatefulWidget {
  const DebounceThrottleDemo({super.key});

  @override
  State<DebounceThrottleDemo> createState() => _DebounceThrottleDemoState();
}

class _DebounceThrottleDemoState extends State<DebounceThrottleDemo> {
  late Debouncer _searchDebouncer;
  late Throttler _scrollThrottler;
  String _searchQuery = '';
  int _searchCallCount = 0;
  int _scrollEventCount = 0;
  int _throttledScrollCount = 0;
  double _scrollPosition = 0;
  String _selectedTimeFilter = 'Aylık';
  List<String> _selectedCategories = [];
  List<String> _selectedWallets = [];
  String _selectedTransactionType = 'all';
  int _filterApplyCount = 0;
  final List<Category> _categories = [
    Category(
      id: '1',
      name: 'Market',
      icon: Icons.shopping_cart,
      color: Colors.green,
      type: 'expense',
    ),
    Category(
      id: '2',
      name: 'Ulaşım',
      icon: Icons.directions_car,
      color: Colors.blue,
      type: 'expense',
    ),
    Category(
      id: '3',
      name: 'Eğlence',
      icon: Icons.movie,
      color: Colors.purple,
      type: 'expense',
    ),
  ];
  
  final List<Wallet> _wallets = [
    Wallet(
      id: '1',
      name: 'Ana Cüzdan',
      balance: 1000,
      type: 'cash',
      color: '0xFF4CAF50',
      icon: 'wallet',
      creditLimit: 0,
    ),
    Wallet(
      id: '2',
      name: 'Banka Hesabı',
      balance: 5000,
      type: 'bank',
      color: '0xFF2196F3',
      icon: 'bank',
      creditLimit: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
    _scrollThrottler = Throttler(duration: const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _scrollThrottler.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _searchCallCount++;
    });
  }

  void _handleScroll(ScrollNotification notification) {
    setState(() {
      _scrollEventCount++;
      _scrollPosition = notification.metrics.pixels;
    });
    
    _scrollThrottler.call(() {
      setState(() {
        _throttledScrollCount++;
      });
    });
  }

  void _applyFilters() {
    setState(() {
      _filterApplyCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debounce & Throttle Demo'),
        backgroundColor: const Color(0xFF00BFA5),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[100],
            child: Column(
              children: [
                const Text(
                  'Performance Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Search Calls',
                        _searchCallCount.toString(),
                        Icons.search,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Filter Applies',
                        _filterApplyCount.toString(),
                        Icons.filter_list,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Scroll Events',
                        _scrollEventCount.toString(),
                        Icons.event,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Throttled',
                        _throttledScrollCount.toString(),
                        Icons.speed,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                if (_scrollEventCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Reduction: ${(100 - (_throttledScrollCount / _scrollEventCount * 100)).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debounced Search (300ms)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) {
                    _searchDebouncer.call(() => _performSearch(value));
                  },
                  decoration: InputDecoration(
                    hintText: 'Type to search...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Searching for: "$_searchQuery"',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debounced Filters (300ms)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DebouncedFilterBar(
                  selectedTimeFilter: _selectedTimeFilter,
                  selectedCategories: _selectedCategories,
                  selectedWallets: _selectedWallets,
                  selectedTransactionType: _selectedTransactionType,
                  availableCategories: _categories,
                  availableWallets: _wallets,
                  onTimeFilterChanged: (filter) {
                    setState(() => _selectedTimeFilter = filter);
                    _applyFilters();
                  },
                  onCategoriesChanged: (categories) {
                    setState(() => _selectedCategories = categories);
                    _applyFilters();
                  },
                  onWalletsChanged: (wallets) {
                    setState(() => _selectedWallets = wallets);
                    _applyFilters();
                  },
                  onTransactionTypeChanged: (type) {
                    setState(() => _selectedTransactionType = type);
                    _applyFilters();
                  },
                  onClearFilters: () {
                    setState(() {
                      _selectedCategories = [];
                      _selectedWallets = [];
                      _selectedTransactionType = 'all';
                    });
                    _applyFilters();
                  },
                  onCustomDateRange: () {},
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Throttled Scroll (100ms)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ThrottledScrollView(
                      throttleMilliseconds: 100,
                      onScroll: _handleScroll,
                      child: ListView.builder(
                        itemCount: 100,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 0,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF00BFA5),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text('Item ${index + 1}'),
                              subtitle: Text('Scroll position: ${_scrollPosition.toStringAsFixed(0)}px'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _searchCallCount = 0;
            _scrollEventCount = 0;
            _throttledScrollCount = 0;
            _filterApplyCount = 0;
            _searchQuery = '';
          });
        },
        backgroundColor: const Color(0xFF00BFA5),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
