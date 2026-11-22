import 'package:firebase_database/firebase_database.dart';
import '../models/contact.dart';
import '../models/transaction_entry.dart';

class DatabaseService {
  final String uid;
  late final DatabaseReference _userRef;

  DatabaseService({required this.uid}) {
    _userRef = FirebaseDatabase.instance.ref().child(uid).child('users');
  }

  Stream<List<Contact>> get contactsStream {
    return _userRef.onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return [];

      return data.entries.map((e) {
        return Contact.fromMap(e.key.toString(), e.value);
      }).toList();
    });
  }

  Future<void> addContact(String name) async {
    final String contactId = _userRef.push().key!;
    await _userRef.child(contactId).set({
      'name': name,
      'balance': 0,
      'transactions': {},
    });
  }

  Future<void> deleteContact(String contactId) async {
    await _userRef.child(contactId).remove();
  }

  Future<void> addTransaction(String contactId, String note, int amount) async {
    final contactRef = _userRef.child(contactId);
    final String txnId = contactRef.child('transactions').push().key!;
    
    final txn = TransactionEntry(
      id: txnId,
      note: note,
      amount: amount,
      time: DateTime.now(),
    );

    await contactRef.child('transactions').child(txnId).set(txn.toMap());

    // Update balance
    final snapshot = await contactRef.child('balance').get();
    int currentBalance = int.tryParse(snapshot.value.toString()) ?? 0;
    await contactRef.child('balance').set(currentBalance + amount);
  }

  Future<void> deleteTransaction(String contactId, String txnId, int txnAmount) async {
    final contactRef = _userRef.child(contactId);
    await contactRef.child('transactions').child(txnId).remove();

    // Update balance
    final snapshot = await contactRef.child('balance').get();
    int currentBalance = int.tryParse(snapshot.value.toString()) ?? 0;
    await contactRef.child('balance').set(currentBalance - txnAmount);
  }

  Stream<Contact?> getContactStream(String contactId) {
    return _userRef.child(contactId).onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return null;
      return Contact.fromMap(contactId, data);
    });
  }
}
