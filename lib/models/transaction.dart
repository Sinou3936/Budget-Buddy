import 'package:flutter/foundation.dart';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String type; // 'income' or 'expense'
  final DateTime date;
  final String? memo;
  final String? bankName;
  final bool isAiClassified;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.memo,
    this.bankName,
    this.isAiClassified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'type': type,
      'date': date.toIso8601String(),
      'memo': memo,
      'bankName': bankName,
      'isAiClassified': isAiClassified,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      type: map['type'] as String,
      date: DateTime.parse(map['date'] as String),
      memo: map['memo'] as String?,
      bankName: map['bankName'] as String?,
      isAiClassified: map['isAiClassified'] as bool? ?? false,
    );
  }

  /// API(snake_case) 응답에서 생성
  factory Transaction.fromApiMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      type: map['type'] as String,
      date: DateTime.parse(map['date'] as String),
      memo: map['memo'] as String?,
      bankName: map['bank_name'] as String?,
      isAiClassified: (map['is_ai_classified'] as int? ?? 0) == 1,
    );
  }

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? type,
    DateTime? date,
    String? memo,
    String? bankName,
    bool? isAiClassified,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      date: date ?? this.date,
      memo: memo ?? this.memo,
      bankName: bankName ?? this.bankName,
      isAiClassified: isAiClassified ?? this.isAiClassified,
    );
  }
}

class Budget {
  final String category;
  double limit;
  double spent;

  Budget({
    required this.category,
    required this.limit,
    this.spent = 0,
  });

  double get percentage => limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
  double get remaining => limit - spent;
  bool get isOverBudget => spent > limit;

  Map<String, dynamic> toMap() => {
        'category': category,
        'limit': limit,
        'spent': spent,
      };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        category: map['category'] as String,
        limit: (map['limit'] as num).toDouble(),
        spent: (map['spent'] as num? ?? 0).toDouble(),
      );
}

class BankAccount {
  final String id;
  final String bankName;
  final String accountNumber;
  final double balance;
  final String accountType;
  final bool isLinked;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.balance,
    required this.accountType,
    this.isLinked = false,
  });
}

@immutable
class AiInsight {
  final String title;
  final String message;
  final String type; // 'warning', 'tip', 'achievement'
  final String category;
  final DateTime createdAt;

  const AiInsight({
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.createdAt,
  });
}
