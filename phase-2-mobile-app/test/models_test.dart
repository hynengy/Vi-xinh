import 'package:flutter_test/flutter_test.dart';
import 'package:vi_xinh_mobile/models/transaction_model.dart';
import 'package:vi_xinh_mobile/models/user_model.dart';
import 'package:vi_xinh_mobile/models/budget_model.dart';

void main() {
  group('Models serialization tests', () {
    test('TransactionModel toMap and fromMap', () {
      final tx = TransactionModel(
        id: 1,
        userId: 1,
        merchantName: 'Highlands Coffee',
        amount: 85000.0,
        transactionDate: '2026-10-23',
        category: 'food',
        type: 'expense',
        notes: 'Ca phe sang',
      );

      final map = tx.toMap();
      expect(map['merchant_name'], 'Highlands Coffee');
      expect(map['amount'], 85000.0);
      expect(map['type'], 'expense');

      final restored = TransactionModel.fromMap(map);
      expect(restored.id, 1);
      expect(restored.merchantName, 'Highlands Coffee');
      expect(restored.amount, 85000.0);
      expect(restored.notes, 'Ca phe sang');
    });

    test('UserModel toMap and fromMap', () {
      final user = UserModel(
        id: 10,
        username: 'user1',
        fullName: 'Thành viên 1',
        phone: '0987654321',
        email: 'user1@example.com',
        bankBin: '970436',
        bankAccount: '123456789',
      );

      final map = user.toMap();
      expect(map['full_name'], 'Thành viên 1');
      expect(map['bank_bin'], '970436');
      expect(map['bank_account'], '123456789');

      final restored = UserModel.fromMap(map);
      expect(restored.fullName, 'Thành viên 1');
      expect(restored.bankAccount, '123456789');
    });

    test('BudgetModel toMap and fromMap', () {
      final budget = BudgetModel(
        id: 2,
        userId: 1,
        category: 'food',
        limitAmount: 3000000.0,
      );

      final map = budget.toMap();
      expect(map['category'], 'food');
      expect(map['limit_amount'], 3000000.0);

      final restored = BudgetModel.fromMap(map);
      expect(restored.category, 'food');
      expect(restored.limitAmount, 3000000.0);
    });
  });
}
