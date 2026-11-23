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
      'totalBalance': 0,
      'transactions': {},
    });
  }

  Future<void> updateContactName(String contactId, String newName) async {
    await _userRef.child(contactId).child('name').set(newName);
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
    if (currentBalance == 0) {
      final totalSnap = await contactRef.child('totalBalance').get();
      currentBalance = int.tryParse(totalSnap.value?.toString() ?? '0') ?? 0;
    }
    final newBalance = currentBalance + amount;
    await contactRef.child('balance').set(newBalance);
    await contactRef.child('totalBalance').set(newBalance);
  }

  Future<void> updateTransaction(
    String contactId,
    TransactionEntry oldTxn,
    String newNote,
    int newAmount,
  ) async {
    final contactRef = _userRef.child(contactId);
    final updatedTxn = TransactionEntry(
      id: oldTxn.id,
      note: newNote,
      amount: newAmount,
      time: oldTxn.time,
    );

    await contactRef.child('transactions').child(oldTxn.id).set(updatedTxn.toMap());

    final snapshot = await contactRef.child('balance').get();
    int currentBalance = int.tryParse(snapshot.value?.toString() ?? '0') ?? 0;
    if (currentBalance == 0) {
      final totalSnap = await contactRef.child('totalBalance').get();
      currentBalance = int.tryParse(totalSnap.value?.toString() ?? '0') ?? 0;
    }
    final newBalance = currentBalance - oldTxn.amount + newAmount;
    await contactRef.child('balance').set(newBalance);
    await contactRef.child('totalBalance').set(newBalance);
  }

  Future<void> deleteTransaction(String contactId, String txnId, int txnAmount) async {
    final contactRef = _userRef.child(contactId);
    await contactRef.child('transactions').child(txnId).remove();

    final snapshot = await contactRef.child('balance').get();
    int currentBalance = int.tryParse(snapshot.value?.toString() ?? '0') ?? 0;
    if (currentBalance == 0) {
      final totalSnap = await contactRef.child('totalBalance').get();
      currentBalance = int.tryParse(totalSnap.value?.toString() ?? '0') ?? 0;
    }
    final newBalance = currentBalance - txnAmount;
    await contactRef.child('balance').set(newBalance);
    await contactRef.child('totalBalance').set(newBalance);
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

  Future<void> addGroup(String name, String description, [List<String> memberIds = const []]) async {
    final String groupId = _groupsRef.push().key!;
    final Map<String, bool> membersMap = {};
    for (var id in memberIds) {
      membersMap[id] = true;
    }

    await _groupsRef.child(groupId).set({
      'name': name,
      'description': description,
      'members': membersMap,
    });
  }

  Future<void> updateGroupDetails(String groupId, String newName, String newDescription) async {
    await _groupsRef.child(groupId).child('name').set(newName);
    await _groupsRef.child(groupId).child('description').set(newDescription);
  }

  Future<void> addMemberToGroup(String groupId, String contactId) async {
    await _groupsRef.child(groupId).child('members').child(contactId).set(true);
  }

  Future<void> removeMemberFromGroup(String groupId, String contactId) async {
    await _groupsRef.child(groupId).child('members').child(contactId).remove();
  }

  Future<void> deleteGroupOnly(String groupId) async {
    await _groupsRef.child(groupId).remove();
  }

  Future<void> deleteGroupAndMembers(String groupId, List<String> memberIds) async {
    await _groupsRef.child(groupId).remove();
    for (var contactId in memberIds) {
      await _userRef.child(contactId).remove();
    }
  }

  Stream<GroupModel?> getGroupStream(String groupId) {
    return _groupsRef.child(groupId).onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return null;
      return GroupModel.fromMap(groupId, data);
    });
  }
}
