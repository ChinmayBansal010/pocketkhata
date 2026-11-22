class TransactionEntry {
  final String id;
  final String note;
  final int amount;
  final DateTime time;

  const TransactionEntry({
    required this.id,
    required this.note,
    required this.amount,
    required this.time,
  });

  factory TransactionEntry.fromMap(String id, Map<dynamic, dynamic> data) {
    DateTime parsedTime;
    try {
      parsedTime = DateTime.parse(data['time'].toString());
    } catch (_) {
      parsedTime = DateTime.now();
    }
    return TransactionEntry(
      id: id,
      note: (data['note'] ?? '').toString(),
      amount: int.tryParse((data['amount'] ?? 0).toString()) ?? 0,
      time: parsedTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'note': note,
      'amount': amount,
      'time': time.toIso8601String(),
    };
  }

  bool get isCredit => amount < 0;
}
