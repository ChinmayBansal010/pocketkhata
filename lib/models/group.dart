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
    if (data['members'] != null) {
      final mData = data['members'];
      if (mData is Map) {
        members.addAll(mData.keys.map((e) => e.toString()));
      } else if (mData is List) {
        members.addAll(mData.where((e) => e != null).map((e) => e.toString()));
      }
    } else if (data['memberNames'] != null) {
      final mData = data['memberNames'];
      if (mData is List) {
        members.addAll(mData.map((e) => e.toString()));
      } else if (mData is Map) {
        members.addAll(mData.values.map((e) => e.toString()));
      }
    }

    final num rawBalance = data['totalBalance'] ?? data['balance'] ?? data['total_balance'] ?? data['netBalance'] ?? 0;
    int parsedBalance = (num.tryParse(rawBalance.toString()) ?? 0).toInt();

    int calculatedBalance = txns.values.fold(0, (sum, t) => sum + t.amount);
    int finalBalance = (parsedBalance != 0 || txns.isEmpty) ? parsedBalance : calculatedBalance;

    return GroupModel(
      id: id,
      name: (data['name'] ?? data['title'] ?? id).toString(),
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
      'totalBalance': balance,
      'balance': balance,
      'transactions': transactions.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}
