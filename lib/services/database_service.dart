import 'package:firebase_database/firebase_database.dart';
import '../models/contact.dart';
import '../models/group.dart';
import '../models/transaction_entry.dart';

class DatabaseService {
  final String uid;
  late final DatabaseReference _userRef;
  late final DatabaseReference _groupsRef;

  DatabaseService({required this.uid}) {
    final baseRef = FirebaseDatabase.instance.ref().child(uid);
    _userRef = baseRef.child('users');
    _groupsRef = baseRef.child('groups');
  }

  // --- Contacts / Users ---
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

    final snapshot = await contactRef.child('balance').get();
    int currentBalance = int.tryParse(snapshot.value?.toString() ?? '0') ?? 0;
    await contactRef.child('balance').set(currentBalance + amount);
  }

  Future<void> deleteTransaction(String contactId, String txnId, int txnAmount) async {
    final contactRef = _userRef.child(contactId);
    await contactRef.child('transactions').child(txnId).remove();

    final snapshot = await contactRef.child('balance').get();
    int currentBalance = int.tryParse(snapshot.value?.toString() ?? '0') ?? 0;
    await contactRef.child('balance').set(currentBalance - txnAmount);
  }

  Stream<Contact?> getContactStream(String contactId) {
    return _userRef.child(contactId).onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return null;
      return Contact.fromMap(contactId, data);
    });
  }

  // --- Groups ---
  Stream<List<GroupModel>> get groupsStream {
    return _groupsRef.onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return [];

      return data.entries.map((e) {
        return GroupModel.fromMap(e.key.toString(), e.value);
      }).toList();
    });
  }

  Future<void> addGroup(String name, String description, [List<String> memberNames = const []]) async {
    final String groupId = _groupsRef.push().key!;
    await _groupsRef.child(groupId).set({
      'name': name,
      'description': description,
      'memberNames': memberNames,
      'balance': 0,
      'transactions': {},
    });
  }

  Future<void> deleteGroup(String groupId) async {
    await _groupsRef.child(groupId).remove();
  }

  Future<void> addGroupTransaction(String groupId, String note, int amount) async {
    final groupRef = _groupsRef.child(groupId);
    final String txnId = groupRef.child('transactions').push().key!;

    final txn = TransactionEntry(
      id: txnId,
      note: note,
      amount: amount,
      time: DateTime.now(),
    );

    await groupRef.child('transactions').child(txnId).set(txn.toMap());

    final snapshot = await groupRef.child('balance').get();
    int currentBalance = int.tryParse(snapshot.value?.toString() ?? '0') ?? 0;
    await groupRef.child('balance').set(currentBalance + amount);
  }

  Future<void> deleteGroupTransaction(String groupId, String txnId, int txnAmount) async {
    final groupRef = _groupsRef.child(groupId);
    await groupRef.child('transactions').child(txnId).remove();

    final snapshot = await groupRef.child('balance').get();
    int currentBalance = int.tryParse(snapshot.value?.toString() ?? '0') ?? 0;
    await groupRef.child('balance').set(currentBalance - txnAmount);
  }

  Stream<GroupModel?> getGroupStream(String groupId) {
    return _groupsRef.child(groupId).onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return null;
      return GroupModel.fromMap(groupId, data);
    });
  }
}
