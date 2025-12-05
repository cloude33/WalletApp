import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:money/models/credit_card.dart';
import 'package:money/models/credit_card_statement.dart';
import 'package:money/models/credit_card_transaction.dart';
import 'package:money/models/credit_card_payment.dart';
import 'package:money/models/reward_points.dart';
import 'package:money/models/reward_transaction.dart';
import 'package:money/models/limit_alert.dart';
import 'package:money/services/credit_card_notification_service.dart';
import 'package:money/services/notification_scheduler_service.dart';
import 'package:money/services/credit_card_box_service.dart';
import '../property_test_utils.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Hive for testing
    Hive.init('./test_hive_notification');
    
    // Register adapters
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(CreditCardAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(CreditCardTransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(CreditCardStatementAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(CreditCardPaymentAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(RewardPointsAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(RewardTransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(LimitAlertAdapter());
    }
    
    // Initialize notification service (skip if platform not available)
    try {
      await NotificationSchedulerService().initialize();
    } catch (e) {
      // Notification service not available in test environment
      print('Notification service initialization skipped: $e');
    }
    
    // Open boxes
    await CreditCardBoxService.init();
  });

  tearDownAll(() async {
    // Close and delete boxes
    await CreditCardBoxService.close();
    await Hive.deleteFromDisk();
  });

  group('CreditCardNotificationService Property Tests', () {
    late CreditCardNotificationService notificationService;

    setUp(() async {
      notificationService = CreditCardNotificationService();
      // Clear data before each test
      await CreditCardBoxService.creditCardsBox.clear();
      await CreditCardBoxService.statementsBox.clear();
      // Skip notification cancellation in test environment
      try {
        await NotificationSchedulerService().cancelAllNotifications();
      } catch (e) {
        // Notification service not available in test environment
      }
    });

    /// **Feature: enhanced-credit-card-tracking, Property 12: 7 Gün Öncesi Ödeme Hatırlatması**
    /// **Validates: Requirements 5.1**
    /// 
    /// Property: For any card with due date more than 7 days away,
    /// system should send reminder notification 7 days before.
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 12: 7-day payment reminder should be scheduled',
      generator: () {
        final daysUntilDue = PropertyTest.randomInt(min: 8, max: 30);
        final dueDate = DateTime.now().add(Duration(days: daysUntilDue));
        final periodStart = dueDate.subtract(const Duration(days: 30));
        final periodEnd = dueDate.subtract(const Duration(days: 10));
        
        return {
          'cardId': const Uuid().v4(),
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 15),
          'cardName': PropertyTest.randomString(minLength: 5, maxLength: 15),
          'dueDate': dueDate,
          'periodStart': periodStart,
          'periodEnd': periodEnd,
          'minimumPayment': PropertyTest.randomPositiveDouble(min: 100, max: 500),
          'totalDebt': PropertyTest.randomPositiveDouble(min: 500, max: 5000),
        };
      },
      property: (data) async {
        final cardId = data['cardId'] as String;
        final bankName = data['bankName'] as String;
        final cardName = data['cardName'] as String;
        final dueDate = data['dueDate'] as DateTime;
        final periodStart = data['periodStart'] as DateTime;
        final periodEnd = data['periodEnd'] as DateTime;
        final minimumPayment = data['minimumPayment'] as double;
        final totalDebt = data['totalDebt'] as double;

        // Create and save card
        final card = CreditCard(
          id: cardId,
          bankName: bankName,
          cardName: cardName,
          last4Digits: '1234',
          creditLimit: 10000,
          statementDay: periodEnd.day,
          dueDateOffset: 10,
          monthlyInterestRate: 2.5,
          lateInterestRate: 3.5,
          cardColor: 0xFF2196F3,
          createdAt: DateTime.now(),
        );
        await CreditCardBoxService.creditCardsBox.put(card.id, card);

        // Create and save statement
        final statement = CreditCardStatement(
          id: const Uuid().v4(),
          cardId: cardId,
          periodStart: periodStart,
          periodEnd: periodEnd,
          dueDate: dueDate,
          minimumPayment: minimumPayment,
          totalDebt: totalDebt,
          remainingDebt: totalDebt,
          createdAt: DateTime.now(),
        );
        await CreditCardBoxService.statementsBox.put(statement.id, statement);

        // Schedule 7-day reminder
        await notificationService.schedulePaymentReminderWithDays(statement, 7);

        // Get pending notifications
        final pending = await NotificationSchedulerService().getPendingNotifications();

        // Property: A 7-day reminder should be scheduled
        final has7DayReminder = pending.any((n) {
          return n.title?.contains('7 Gün Kaldı') ?? false;
        });

        expect(has7DayReminder, isTrue);

        return true;
      },
      iterations: 100,
    );

    /// **Feature: enhanced-credit-card-tracking, Property 13: 3 Gün Öncesi Ödeme Hatırlatması**
    /// **Validates: Requirements 5.2**
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 13: 3-day payment reminder should be scheduled',
      generator: () {
        final daysUntilDue = PropertyTest.randomInt(min: 4, max: 30);
        final dueDate = DateTime.now().add(Duration(days: daysUntilDue));
        final periodStart = dueDate.subtract(const Duration(days: 30));
        final periodEnd = dueDate.subtract(const Duration(days: 10));
        
        return {
          'cardId': const Uuid().v4(),
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 15),
          'cardName': PropertyTest.randomString(minLength: 5, maxLength: 15),
          'dueDate': dueDate,
          'periodStart': periodStart,
          'periodEnd': periodEnd,
          'minimumPayment': PropertyTest.randomPositiveDouble(min: 100, max: 500),
          'totalDebt': PropertyTest.randomPositiveDouble(min: 500, max: 5000),
        };
      },
      property: (data) async {
        final cardId = data['cardId'] as String;
        final bankName = data['bankName'] as String;
        final cardName = data['cardName'] as String;
        final dueDate = data['dueDate'] as DateTime;
        final periodStart = data['periodStart'] as DateTime;
        final periodEnd = data['periodEnd'] as DateTime;
        final minimumPayment = data['minimumPayment'] as double;
        final totalDebt = data['totalDebt'] as double;

        final card = CreditCard(
          id: cardId,
          bankName: bankName,
          cardName: cardName,
          last4Digits: '1234',
          creditLimit: 10000,
          statementDay: periodEnd.day,
          dueDateOffset: 10,
          monthlyInterestRate: 2.5,
          lateInterestRate: 3.5,
          cardColor: 0xFF2196F3,
          createdAt: DateTime.now(),
        );
        await CreditCardBoxService.creditCardsBox.put(card.id, card);

        final statement = CreditCardStatement(
          id: const Uuid().v4(),
          cardId: cardId,
          periodStart: periodStart,
          periodEnd: periodEnd,
          dueDate: dueDate,
          minimumPayment: minimumPayment,
          totalDebt: totalDebt,
          remainingDebt: totalDebt,
          createdAt: DateTime.now(),
        );
        await CreditCardBoxService.statementsBox.put(statement.id, statement);

        await notificationService.schedulePaymentReminderWithDays(statement, 3);

        final pending = await NotificationSchedulerService().getPendingNotifications();
        final has3DayReminder = pending.any((n) {
          return n.title?.contains('3 Gün Kaldı') ?? false;
        });

        expect(has3DayReminder, isTrue);
        return true;
      },
      iterations: 100,
    );

    /// **Feature: enhanced-credit-card-tracking, Property 14: Son Gün Ödeme Hatırlatması**
    /// **Validates: Requirements 5.3**
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 14: Same-day payment reminder should be scheduled',
      generator: () {
        final daysUntilDue = PropertyTest.randomInt(min: 0, max: 10);
        final dueDate = DateTime.now().add(Duration(days: daysUntilDue));
        final periodStart = dueDate.subtract(const Duration(days: 30));
        final periodEnd = dueDate.subtract(const Duration(days: 10));
        
        return {
          'cardId': const Uuid().v4(),
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 15),
          'cardName': PropertyTest.randomString(minLength: 5, maxLength: 15),
          'dueDate': dueDate,
          'periodStart': periodStart,
          'periodEnd': periodEnd,
          'minimumPayment': PropertyTest.randomPositiveDouble(min: 100, max: 500),
          'totalDebt': PropertyTest.randomPositiveDouble(min: 500, max: 5000),
        };
      },
      property: (data) async {
        final cardId = data['cardId'] as String;
        final bankName = data['bankName'] as String;
        final cardName = data['cardName'] as String;
        final dueDate = data['dueDate'] as DateTime;
        final periodStart = data['periodStart'] as DateTime;
        final periodEnd = data['periodEnd'] as DateTime;
        final minimumPayment = data['minimumPayment'] as double;
        final totalDebt = data['totalDebt'] as double;

        final card = CreditCard(
          id: cardId,
          bankName: bankName,
          cardName: cardName,
          last4Digits: '1234',
          creditLimit: 10000,
          statementDay: periodEnd.day,
          dueDateOffset: 10,
          monthlyInterestRate: 2.5,
          lateInterestRate: 3.5,
          cardColor: 0xFF2196F3,
          createdAt: DateTime.now(),
        );
        await CreditCardBoxService.creditCardsBox.put(card.id, card);

        final statement = CreditCardStatement(
          id: const Uuid().v4(),
          cardId: cardId,
          periodStart: periodStart,
          periodEnd: periodEnd,
          dueDate: dueDate,
          minimumPayment: minimumPayment,
          totalDebt: totalDebt,
          remainingDebt: totalDebt,
          createdAt: DateTime.now(),
        );
        await CreditCardBoxService.statementsBox.put(statement.id, statement);

        await notificationService.schedulePaymentReminderWithDays(statement, 0);

        final pending = await NotificationSchedulerService().getPendingNotifications();
        final hasSameDayReminder = pending.any((n) {
          return n.title?.contains('Son Ödeme Günü') ?? false;
        });

        expect(hasSameDayReminder, isTrue);
        return true;
      },
      iterations: 100,
    );

    /// **Feature: enhanced-credit-card-tracking, Property 15: Bildirim İçeriği Doğruluğu**
    /// **Validates: Requirements 5.4**
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 15: Notification should contain minimum and full payment amounts',
      generator: () {
        final daysUntilDue = PropertyTest.randomInt(min: 4, max: 30);
        final dueDate = DateTime.now().add(Duration(days: daysUntilDue));
        final periodStart = dueDate.subtract(const Duration(days: 30));
        final periodEnd = dueDate.subtract(const Duration(days: 10));
        final minimumPayment = PropertyTest.randomPositiveDouble(min: 100, max: 500);
        final totalDebt = PropertyTest.randomPositiveDouble(min: 500, max: 5000);
        
        return {
          'cardId': const Uuid().v4(),
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 15),
          'cardName': PropertyTest.randomString(minLength: 5, maxLength: 15),
          'dueDate': dueDate,
          'periodStart': periodStart,
          'periodEnd': periodEnd,
          'minimumPayment': minimumPayment,
          'totalDebt': totalDebt,
        };
      },
      property: (data) async {
        final cardId = data['cardId'] as String;
        final bankName = data['bankName'] as String;
        final cardName = data['cardName'] as String;
        final dueDate = data['dueDate'] as DateTime;
        final periodStart = data['periodStart'] as DateTime;
        final periodEnd = data['periodEnd'] as DateTime;
        final minimumPayment = data['minimumPayment'] as double;
        final totalDebt = data['totalDebt'] as double;

        final card = CreditCard(
          id: cardId,
          bankName: bankName,
          cardName: cardName,
          last4Digits: '1234',
          creditLimit: 10000,
          statementDay: periodEnd.day,
          dueDateOffset: 10,
          monthlyInterestRate: 2.5,
          lateInterestRate: 3.5,
          cardColor: 0xFF2196F3,
          createdAt: DateTime.now(),
        );
        await CreditCardBoxService.creditCardsBox.put(card.id, card);

        final statement = CreditCardStatement(
          id: const Uuid().v4(),
          cardId: cardId,
          periodStart: periodStart,
          periodEnd: periodEnd,
          dueDate: dueDate,
          minimumPayment: minimumPayment,
          totalDebt: totalDebt,
          remainingDebt: totalDebt,
          createdAt: DateTime.now(),
        );
        await CreditCardBoxService.statementsBox.put(statement.id, statement);

        await notificationService.schedulePaymentReminderWithDays(statement, 3);

        final pending = await NotificationSchedulerService().getPendingNotifications();
        final notification = pending.firstWhere(
          (n) => n.title?.contains('Ödeme Hatırlatması') ?? false,
          orElse: () => throw Exception('No payment reminder found'),
        );

        final body = notification.body ?? '';
        final containsMinimum = body.contains('Asgari ödeme');
        final containsFull = body.contains('Tam ödeme');

        expect(containsMinimum, isTrue);
        expect(containsFull, isTrue);
        return true;
      },
      iterations: 100,
    );

    /// **Feature: enhanced-credit-card-tracking, Property 16: Bildirim Ayarları Uygulaması**
    /// **Validates: Requirements 5.5**
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 16: System should apply user notification preferences',
      generator: () {
        final customDays = PropertyTest.randomInt(min: 1, max: 10);
        final daysUntilDue = PropertyTest.randomInt(min: customDays + 1, max: 30);
        final dueDate = DateTime.now().add(Duration(days: daysUntilDue));
        final periodStart = dueDate.subtract(const Duration(days: 30));
        final periodEnd = dueDate.subtract(const Duration(days: 10));
        
        return {
          'cardId': const Uuid().v4(),
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 15),
          'cardName': PropertyTest.randomString(minLength: 5, maxLength: 15),
          'dueDate': dueDate,
          'periodStart': periodStart,
          'periodEnd': periodEnd,
          'minimumPayment': PropertyTest.randomPositiveDouble(min: 100, max: 500),
          'totalDebt': PropertyTest.randomPositiveDouble(min: 500, max: 5000),
          'customDays': customDays,
        };
      },
      property: (data) async {
        final cardId = data['cardId'] as String;
        final bankName = data['bankName'] as String;
        final cardName = data['cardName'] as String;
        final dueDate = data['dueDate'] as DateTime;
        final periodStart = data['periodStart'] as DateTime;
        final periodEnd = data['periodEnd'] as DateTime;
        final minimumPayment = data['minimumPayment'] as double;
        final totalDebt = data['totalDebt'] as double;
        final customDays = data['customDays'] as int;

        final card = CreditCard(
          id: cardId,
          bankName: bankName,
          cardName: cardName,
          last4Digits: '1234',
          creditLimit: 10000,
          statementDay: periodEnd.day,
          dueDateOffset: 10,
          monthlyInterestRate: 2.5,
          lateInterestRate: 3.5,
          cardColor: 0xFF2196F3,
          createdAt: DateTime.now(),
        );
        await CreditCardBoxService.creditCardsBox.put(card.id, card);

        final statement = CreditCardStatement(
          id: const Uuid().v4(),
          cardId: cardId,
          periodStart: periodStart,
          periodEnd: periodEnd,
          dueDate: dueDate,
          minimumPayment: minimumPayment,
          totalDebt: totalDebt,
          remainingDebt: totalDebt,
          createdAt: DateTime.now(),
        );
        await CreditCardBoxService.statementsBox.put(statement.id, statement);

        await notificationService.schedulePaymentReminderWithDays(statement, customDays);

        final pending = await NotificationSchedulerService().getPendingNotifications();
        final hasCustomReminder = pending.any((n) {
          return n.title?.contains('Ödeme Hatırlatması') ?? false;
        });

        expect(hasCustomReminder, isTrue);
        return true;
      },
      iterations: 100,
    );

    /// **Feature: enhanced-credit-card-tracking, Property 46: Ekstre Kesim Bildirimi**
    /// **Validates: Requirements 13.1**
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 46: Statement cut notification should be scheduled',
      generator: () {
        final daysUntilCut = PropertyTest.randomInt(min: 1, max: 30);
        final cutDate = DateTime.now().add(Duration(days: daysUntilCut));
        final dueDate = cutDate.add(const Duration(days: 15));
        
        return {
          'cardId': const Uuid().v4(),
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 15),
          'cardName': PropertyTest.randomString(minLength: 5, maxLength: 15),
          'cutDate': cutDate,
          'dueDate': dueDate,
          'periodDebt': PropertyTest.randomPositiveDouble(min: 100, max: 5000),
        };
      },
      property: (data) async {
        final cardId = data['cardId'] as String;
        final bankName = data['bankName'] as String;
        final cardName = data['cardName'] as String;
        final cutDate = data['cutDate'] as DateTime;
        final dueDate = data['dueDate'] as DateTime;
        final periodDebt = data['periodDebt'] as double;

        final card = CreditCard(
          id: cardId,
          bankName: bankName,
          cardName: cardName,
          last4Digits: '1234',
          creditLimit: 10000,
          statementDay: cutDate.day,
          dueDateOffset: 10,
          monthlyInterestRate: 2.5,
          lateInterestRate: 3.5,
          cardColor: 0xFF2196F3,
          createdAt: DateTime.now(),
        );
        await CreditCardBoxService.creditCardsBox.put(card.id, card);

        await notificationService.scheduleStatementCutNotification(
          cardId,
          cutDate,
          periodDebt,
          dueDate,
        );

        final pending = await NotificationSchedulerService().getPendingNotifications();
        final hasStatementCutNotification = pending.any((n) {
          return n.title?.contains('Ekstre Kesildi') ?? false;
        });

        expect(hasStatementCutNotification, isTrue);
        return true;
      },
      iterations: 100,
    );

    /// **Feature: enhanced-credit-card-tracking, Property 47: Ekstre Bildirim İçeriği**
    /// **Validates: Requirements 13.2**
    PropertyTest.forAll<Map<String, dynamic>>(
      description: 'Property 47: Statement notification should contain debt and due date',
      generator: () {
        final daysUntilCut = PropertyTest.randomInt(min: 1, max: 30);
        final cutDate = DateTime.now().add(Duration(days: daysUntilCut));
        final dueDate = cutDate.add(const Duration(days: 15));
        final periodDebt = PropertyTest.randomPositiveDouble(min: 100, max: 5000);
        
        return {
          'cardId': const Uuid().v4(),
          'bankName': PropertyTest.randomString(minLength: 5, maxLength: 15),
          'cardName': PropertyTest.randomString(minLength: 5, maxLength: 15),
          'cutDate': cutDate,
          'dueDate': dueDate,
          'periodDebt': periodDebt,
        };
      },
      property: (data) async {
        final cardId = data['cardId'] as String;
        final bankName = data['bankName'] as String;
        final cardName = data['cardName'] as String;
        final cutDate = data['cutDate'] as DateTime;
        final dueDate = data['dueDate'] as DateTime;
        final periodDebt = data['periodDebt'] as double;

        final card = CreditCard(
          id: cardId,
          bankName: bankName,
          cardName: cardName,
          last4Digits: '1234',
          creditLimit: 10000,
          statementDay: cutDate.day,
          dueDateOffset: 10,
          monthlyInterestRate: 2.5,
          lateInterestRate: 3.5,
          cardColor: 0xFF2196F3,
          createdAt: DateTime.now(),
        );
        await CreditCardBoxService.creditCardsBox.put(card.id, card);

        await notificationService.scheduleStatementCutNotification(
          cardId,
          cutDate,
          periodDebt,
          dueDate,
        );

        final pending = await NotificationSchedulerService().getPendingNotifications();
        final notification = pending.firstWhere(
          (n) => n.title?.contains('Ekstre Kesildi') ?? false,
          orElse: () => throw Exception('No statement cut notification found'),
        );

        final body = notification.body ?? '';
        final containsDebt = body.contains('Dönem borcu');
        final containsDueDate = body.contains('Son ödeme tarihi');

        expect(containsDebt, isTrue);
        expect(containsDueDate, isTrue);
        return true;
      },
      iterations: 100,
    );
  });
}
