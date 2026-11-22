import 'transaction_entry.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final List<String> memberNames;
  final int balance;
  final Map<String, TransactionEntry> transactions;

  const GroupModel({
    required this.id,
    required this.name,
    this.description = '',
    this.memberNames = const [],
    required this.balance,
    this.transactions = const {},
  });

  factory GroupModel.fromMap(String id, Map<dynamic, dynamic> data) {
    final Map<String, TransactionEntry> txns = {};
    if (data['transactions'] != null) {
      final transData = data['transactions'];
      if (transData is Map) {
        transData.forEach((key, value) {
          txns[key.toString()] = TransactionEntry.fromMap(key.toString(), value);
        });
      } else if (transData is List) {
        for (int i = 0; i < transData.length; i++) {
          if (transData[i] != null) {
            txns[i.toString()] = TransactionEntry.fromMap(i.toString(), transData[i]);
          }
        }
      }
    }

    final List<String> members = [];
    if (data['memberNames'] != null) {
      final mData = data['memberNames'];
      if (mData is List) {
        members.addAll(mData.map((e) => e.toString()));
      } else if (mData is Map) {
        members.addAll(mData.values.map((e) => e.toString()));
      }
    }

    int storedBalance = int.tryParse((data['balance'] ?? 0).toString()) ?? 0;
    int calculatedBalance = txns.values.fold(0, (sum, t) => sum + t.amount);
    int finalBalance = (storedBalance != 0 || txns.isEmpty) ? storedBalance : calculatedBalance;

    return GroupModel(
      id: id,
      name: (data['name'] ?? id).toString(),
      description: (data['description'] ?? '').toString(),
      memberNames: members,
      balance: finalBalance,
      transactions: txns,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'memberNames': memberNames,
      'balance': balance,
      'transactions': transactions.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}
