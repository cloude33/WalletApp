import 'package:hive/hive.dart';
import '../models/payment_plan.dart';
class PaymentPlanRepository {
  static const String _boxName = 'payment_plans';
  Box<PaymentPlan>? _box;
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<PaymentPlan>(_boxName);
    }
  }
  Future<List<PaymentPlan>> getAllPlans() async {
    await init();
    return _box!.values.toList();
  }
  Future<List<PaymentPlan>> getPlansByWallet(String walletId) async {
    await init();
    return _box!.values.where((plan) => plan.walletId == walletId).toList();
  }
  Future<PaymentPlan?> getActivePlan(String walletId) async {
    await init();
    try {
      return _box!.values.firstWhere(
        (plan) => plan.walletId == walletId && plan.isActive,
      );
    } catch (e) {
      return null;
    }
  }
  Future<void> addPlan(PaymentPlan plan) async {
    await init();
    await _box!.put(plan.id, plan);
    await plan.save();
  }
  Future<void> updatePlan(PaymentPlan plan) async {
    await init();
    await plan.save();
  }
  Future<void> deletePlan(String planId) async {
    await init();
    await _box!.delete(planId);
  }
  Future<void> deletePlansByWallet(String walletId) async {
    await init();
    final plans = await getPlansByWallet(walletId);
    for (final plan in plans) {
      await _box!.delete(plan.id);
    }
  }
  Future<void> deactivateAllPlans(String walletId) async {
    await init();
    final plans = await getPlansByWallet(walletId);
    for (final plan in plans) {
      if (plan.isActive) {
        plan.isActive = false;
        await plan.save();
      }
    }
  }
  Future<void> setActivePlan(String planId) async {
    await init();
    final plan = _box!.get(planId);
    if (plan == null) return;
    await deactivateAllPlans(plan.walletId);
    plan.isActive = true;
    await plan.save();
  }
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
