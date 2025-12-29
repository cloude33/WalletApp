import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money/services/notification_service.dart';
import 'package:money/services/data_service.dart';
import 'package:money/models/transaction.dart';
import 'package:money/models/app_notification.dart';

// Simple mock for DataService since we can inject it now
class MockDataService extends DataService {
  MockDataService() : super.forTesting();

  List<Transaction> mockTransactions = [];

  @override
  Future<List<Transaction>> getTransactions() async {
    return mockTransactions;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NotificationService notificationService;
  late MockDataService mockDataService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    
    mockDataService = MockDataService();
    notificationService = NotificationService();
    notificationService.dataService = mockDataService;
    
    // Clear notifications
    await notificationService.clearAll();
  });

  group('NotificationService Tests', () {
    test('generateMonthlySummary should return null if no transactions in current month', () async {
      mockDataService.mockTransactions = [];
      
      final result = await notificationService.generateMonthlySummary();
      
      expect(result, isNull);
    });

    test('generateMonthlySummary should calculate correct summary for current month', () async {
      final now = DateTime.now();
      mockDataService.mockTransactions = [
        Transaction(
          id: '1',
          amount: 1000,
          type: 'income',
          category: 'cat1', // Changed from categoryId
          walletId: 'wallet1',
          date: now,
          description: 'Salary',
        ),
        Transaction(
          id: '2',
          amount: 200,
          type: 'expense',
          category: 'cat2', // Changed from categoryId
          walletId: 'wallet1',
          date: now,
          description: 'Groceries',
        ),
        // Transaction from last month (should be ignored)
        Transaction(
          id: '3',
          amount: 500,
          type: 'expense',
          category: 'cat2', // Changed from categoryId
          walletId: 'wallet1',
          date: now.subtract(const Duration(days: 40)),
          description: 'Old Expense',
        ),
      ];

      final result = await notificationService.generateMonthlySummary();

      expect(result, isNotNull);
      expect(result!.type, NotificationType.monthlySummary);
      expect(result.data!['income'], 1000.0);
      expect(result.data!['expense'], 200.0);
      expect(result.data!['netAmount'], 800.0);
      expect(result.data!['transactionCount'], 2); // Only current month transactions
    });
  });
}
