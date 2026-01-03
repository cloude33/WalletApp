import 'package:uuid/uuid.dart';
import '../models/wallet.dart';
import '../models/payment_plan.dart';
import '../models/payment_scenario.dart';
import '../repositories/payment_plan_repository.dart';
import 'kmh_interest_calculator.dart';
import 'kmh_payment_reminder_service.dart';
class PaymentPlannerService {
  final KmhInterestCalculator _calculator;
  final PaymentPlanRepository _repository;
  final KmhPaymentReminderService _reminderService;
  final _uuid = const Uuid();

  PaymentPlannerService({
    KmhInterestCalculator? calculator,
    PaymentPlanRepository? repository,
    KmhPaymentReminderService? reminderService,
  })  : _calculator = calculator ?? KmhInterestCalculator(),
        _repository = repository ?? PaymentPlanRepository(),
        _reminderService = reminderService ?? KmhPaymentReminderService();
  PaymentPlan? calculatePaymentPlan({
    required Wallet account,
    required double monthlyPayment,
  }) {
    if (!account.isKmhAccount) {
      return null;
    }

    final currentDebt = account.usedCredit;
    if (currentDebt <= 0) {
      return null;
    }

    final annualRate = account.interestRate ?? 24.0;
    final calculation = _calculator.calculatePayoffTime(
      currentDebt: currentDebt,
      monthlyPayment: monthlyPayment,
      monthlyRate: annualRate,
    );
    if (!calculation.isPossible) {
      return null;
    }
    return PaymentPlan(
      id: _uuid.v4(),
      walletId: account.id,
      initialDebt: currentDebt,
      monthlyPayment: monthlyPayment,
      monthlyRate: annualRate,
      durationMonths: calculation.months,
      totalInterest: calculation.totalInterest,
      totalPayment: calculation.totalPaid,
      createdAt: DateTime.now(),
      isActive: false,
    );
  }
  List<PaymentScenario> generatePaymentScenarios({
    required Wallet account,
  }) {
    final scenarios = <PaymentScenario>[];

    if (!account.isKmhAccount) {
      return scenarios;
    }

    final currentDebt = account.usedCredit;
    if (currentDebt <= 0) {
      return scenarios;
    }

    final annualRate = account.interestRate ?? 24.0;
    final monthlyInterest = _calculator.estimateMonthlyInterest(
      balance: -currentDebt,
      monthlyRate: annualRate,
      days: 30,
    );
    final minPayment = monthlyInterest + (currentDebt * 0.05);
    final minCalc = _calculator.calculatePayoffTime(
      currentDebt: currentDebt,
      monthlyPayment: minPayment,
      monthlyRate: annualRate,
    );

    if (minCalc.isPossible) {
      scenarios.add(PaymentScenario(
        name: 'Minimum Ödeme',
        monthlyPayment: minPayment,
        durationMonths: minCalc.months,
        totalInterest: minCalc.totalInterest,
        totalPayment: minCalc.totalPaid,
        warning: 'Uzun vadeli, yüksek faiz maliyeti',
      ));
    }
    final conservativePayment = _findPaymentForDuration(
      currentDebt: currentDebt,
      annualRate: annualRate,
      targetMonths: 48,
      monthlyInterest: monthlyInterest,
    );

    if (conservativePayment != null) {
      final conservativeCalc = _calculator.calculatePayoffTime(
        currentDebt: currentDebt,
        monthlyPayment: conservativePayment,
        monthlyRate: annualRate,
      );

      if (conservativeCalc.isPossible) {
        scenarios.add(PaymentScenario(
          name: 'Muhafazakar',
          monthlyPayment: conservativePayment,
          durationMonths: conservativeCalc.months,
          totalInterest: conservativeCalc.totalInterest,
          totalPayment: conservativeCalc.totalPaid,
        ));
      }
    }
    final moderatePayment = _findPaymentForDuration(
      currentDebt: currentDebt,
      annualRate: annualRate,
      targetMonths: 18,
      monthlyInterest: monthlyInterest,
    );

    if (moderatePayment != null) {
      final moderateCalc = _calculator.calculatePayoffTime(
        currentDebt: currentDebt,
        monthlyPayment: moderatePayment,
        monthlyRate: annualRate,
      );

      if (moderateCalc.isPossible) {
        scenarios.add(PaymentScenario(
          name: 'Dengeli',
          monthlyPayment: moderatePayment,
          durationMonths: moderateCalc.months,
          totalInterest: moderateCalc.totalInterest,
          totalPayment: moderateCalc.totalPaid,
          isRecommended: true,
        ));
      }
    }
    final aggressivePayment = _findPaymentForDuration(
      currentDebt: currentDebt,
      annualRate: annualRate,
      targetMonths: 9,
      monthlyInterest: monthlyInterest,
    );

    if (aggressivePayment != null) {
      final aggressiveCalc = _calculator.calculatePayoffTime(
        currentDebt: currentDebt,
        monthlyPayment: aggressivePayment,
        monthlyRate: annualRate,
      );

      if (aggressiveCalc.isPossible) {
        scenarios.add(PaymentScenario(
          name: 'Agresif',
          monthlyPayment: aggressivePayment,
          durationMonths: aggressiveCalc.months,
          totalInterest: aggressiveCalc.totalInterest,
          totalPayment: aggressiveCalc.totalPaid,
        ));
      }
    }

    return scenarios;
  }
  double? _findPaymentForDuration({
    required double currentDebt,
    required double annualRate,
    required int targetMonths,
    required double monthlyInterest,
  }) {
    double minPayment = monthlyInterest * 1.1;
    double maxPayment = currentDebt * 2;

    const tolerance = 1.0;
    const maxIterations = 50;

    for (int i = 0; i < maxIterations; i++) {
      final midPayment = (minPayment + maxPayment) / 2;

      final calc = _calculator.calculatePayoffTime(
        currentDebt: currentDebt,
        monthlyPayment: midPayment,
        monthlyRate: annualRate,
      );

      if (!calc.isPossible) {
        minPayment = midPayment;
        continue;
      }

      if ((calc.months - targetMonths).abs() <= 1) {
        return midPayment;
      }

      if (calc.months > targetMonths) {
        minPayment = midPayment;
      } else {
        maxPayment = midPayment;
      }
      if ((maxPayment - minPayment) < tolerance) {
        return midPayment;
      }
    }

    return null;
  }
  Map<String, dynamic> compareScenarios({
    required PaymentScenario scenario1,
    required PaymentScenario scenario2,
  }) {
    return {
      'monthlyDifference': scenario2.monthlyPayment - scenario1.monthlyPayment,
      'durationDifference': scenario2.durationMonths - scenario1.durationMonths,
      'interestDifference': scenario2.totalInterest - scenario1.totalInterest,
      'totalDifference': scenario2.totalPayment - scenario1.totalPayment,
      'percentageSavings': scenario2.totalPayment > 0
          ? ((scenario2.totalPayment - scenario1.totalPayment) /
                  scenario2.totalPayment *
                  100)
          : 0.0,
    };
  }
  bool isPaymentSufficient({
    required Wallet account,
    required double monthlyPayment,
  }) {
    if (!account.isKmhAccount) {
      return false;
    }

    final currentDebt = account.usedCredit;
    if (currentDebt <= 0) {
      return true;
    }

    final annualRate = account.interestRate ?? 24.0;
    final monthlyInterest = _calculator.estimateMonthlyInterest(
      balance: -currentDebt,
      monthlyRate: annualRate,
      days: 30,
    );

    return monthlyPayment > monthlyInterest;
  }
  double? getRecommendedPayment({
    required Wallet account,
  }) {
    if (!account.isKmhAccount) {
      return null;
    }

    final currentDebt = account.usedCredit;
    if (currentDebt <= 0) {
      return null;
    }

    final annualRate = account.interestRate ?? 24.0;
    final monthlyInterest = _calculator.estimateMonthlyInterest(
      balance: -currentDebt,
      monthlyRate: annualRate,
      days: 30,
    );

    return _findPaymentForDuration(
      currentDebt: currentDebt,
      annualRate: annualRate,
      targetMonths: 15,
      monthlyInterest: monthlyInterest,
    );
  }
  PaymentPlan? createPaymentPlanWithReminder({
    required Wallet account,
    required double monthlyPayment,
    String reminderSchedule = 'monthly',
  }) {
    final plan = calculatePaymentPlan(
      account: account,
      monthlyPayment: monthlyPayment,
    );

    if (plan == null) {
      return null;
    }

    return plan.copyWith(
      isActive: true,
      reminderSchedule: reminderSchedule,
    );
  }
  Future<void> savePaymentPlan(PaymentPlan plan) async {
    await _repository.init();
    if (plan.isActive) {
      await _repository.deactivateAllPlans(plan.walletId);
    }
    await _repository.addPlan(plan);
    if (plan.isActive) {
      try {
        await _reminderService.schedulePaymentReminder(plan);
      } catch (e) {
        print('Failed to schedule payment reminder: $e');
      }
    }
  }
  Future<PaymentPlan?> getActivePlan(String walletId) async {
    await _repository.init();
    return await _repository.getActivePlan(walletId);
  }
  Future<List<PaymentPlan>> getPlansByWallet(String walletId) async {
    await _repository.init();
    return await _repository.getPlansByWallet(walletId);
  }
  Future<void> deletePlan(String planId) async {
    await _repository.init();
    try {
      await _reminderService.cancelPaymentReminder(planId);
    } catch (e) {
      print('Failed to cancel payment reminder: $e');
    }
    
    await _repository.deletePlan(planId);
  }
  Future<void> updatePlan(PaymentPlan plan) async {
    await _repository.init();
    await _repository.updatePlan(plan);
    try {
      await _reminderService.updatePaymentReminder(plan);
    } catch (e) {
      print('Failed to update payment reminder: $e');
    }
  }
}
