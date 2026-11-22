import 'transaction_entry.dart';

class Contact {
  final String id;
  final String name;
  final int balance;
  final Map<String, TransactionEntry> transactions;

  const Contact({
    required this.id,
    required this.name,
    required this.balance,
    this.transactions = const {},
  });

  factory Contact.fromMap(String id, Map<dynamic, dynamic> data) {
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

    return Contact(
      id: id,
      name: (data['name'] ?? id).toString(),
      balance: int.tryParse((data['balance'] ?? 0).toString()) ?? 0,
      transactions: txns,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'balance': balance,
      'transactions': transactions.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  bool get owesYou => balance >= 0;
}
