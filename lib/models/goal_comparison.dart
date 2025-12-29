library;
class GoalComparison {
  final String goalId;
  final String goalName;
  final double targetAmount;
  final double actualAmount;
  final double remainingAmount;
  final double achievementPercentage;
  final bool isAchieved;
  final DateTime? deadline;
  final int? daysRemaining;
  final bool? isOverdue;
  final GoalStatus status;

  GoalComparison({
    required this.goalId,
    required this.goalName,
    required this.targetAmount,
    required this.actualAmount,
    required this.remainingAmount,
    required this.achievementPercentage,
    required this.isAchieved,
    this.deadline,
    this.daysRemaining,
    this.isOverdue,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'goalId': goalId,
    'goalName': goalName,
    'targetAmount': targetAmount,
    'actualAmount': actualAmount,
    'remainingAmount': remainingAmount,
    'achievementPercentage': achievementPercentage,
    'isAchieved': isAchieved,
    'deadline': deadline?.toIso8601String(),
    'daysRemaining': daysRemaining,
    'isOverdue': isOverdue,
    'status': status.name,
  };

  factory GoalComparison.fromJson(Map<String, dynamic> json) => GoalComparison(
    goalId: json['goalId'],
    goalName: json['goalName'],
    targetAmount: json['targetAmount'],
    actualAmount: json['actualAmount'],
    remainingAmount: json['remainingAmount'],
    achievementPercentage: json['achievementPercentage'],
    isAchieved: json['isAchieved'],
    deadline: json['deadline'] != null
        ? DateTime.parse(json['deadline'])
        : null,
    daysRemaining: json['daysRemaining'],
    isOverdue: json['isOverdue'],
    status: GoalStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => GoalStatus.inProgress,
    ),
  );
}
class GoalComparisonSummary {
  final List<GoalComparison> goals;
  final int totalGoals;
  final int achievedGoals;
  final int inProgressGoals;
  final int overdueGoals;
  final double overallAchievementRate;
  final double totalTargetAmount;
  final double totalActualAmount;
  final double totalRemainingAmount;
  final List<String> insights;

  GoalComparisonSummary({
    required this.goals,
    required this.totalGoals,
    required this.achievedGoals,
    required this.inProgressGoals,
    required this.overdueGoals,
    required this.overallAchievementRate,
    required this.totalTargetAmount,
    required this.totalActualAmount,
    required this.totalRemainingAmount,
    required this.insights,
  });

  Map<String, dynamic> toJson() => {
    'goals': goals.map((g) => g.toJson()).toList(),
    'totalGoals': totalGoals,
    'achievedGoals': achievedGoals,
    'inProgressGoals': inProgressGoals,
    'overdueGoals': overdueGoals,
    'overallAchievementRate': overallAchievementRate,
    'totalTargetAmount': totalTargetAmount,
    'totalActualAmount': totalActualAmount,
    'totalRemainingAmount': totalRemainingAmount,
    'insights': insights,
  };

  factory GoalComparisonSummary.fromJson(Map<String, dynamic> json) => GoalComparisonSummary(
    goals: (json['goals'] as List)
        .map((g) => GoalComparison.fromJson(g))
        .toList(),
    totalGoals: json['totalGoals'],
    achievedGoals: json['achievedGoals'],
    inProgressGoals: json['inProgressGoals'],
    overdueGoals: json['overdueGoals'],
    overallAchievementRate: json['overallAchievementRate'],
    totalTargetAmount: json['totalTargetAmount'],
    totalActualAmount: json['totalActualAmount'],
    totalRemainingAmount: json['totalRemainingAmount'],
    insights: List<String>.from(json['insights']),
  );
}
enum GoalStatus {
  achieved,
  inProgress,
  behindSchedule,
  overdue,
  atRisk,
}
