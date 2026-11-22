import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/contact.dart';
import '../models/transaction_entry.dart';
import '../services/database_service.dart';

class ContactDetailsScreen extends StatefulWidget {
  final String uid;
  final String contactId;

  const ContactDetailsScreen({super.key, required this.uid, required this.contactId});

  @override
  ContactDetailsScreenState createState() => ContactDetailsScreenState();
}

class ContactDetailsScreenState extends State<ContactDetailsScreen> {
  late final DatabaseService _dbService;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: widget.uid);
  }

  void _addTransaction(bool isGive) {
    if (_noteController.text.isNotEmpty) {
      // Simple parser: "Tea 20" -> note: "Tea", amount: 20
      final parts = _noteController.text.trim().split(' ');
      int amount = 0;
      String note = _noteController.text;

      if (parts.length > 1) {
        amount = int.tryParse(parts.last) ?? 0;
        if (amount != 0) {
          note = parts.sublist(0, parts.length - 1).join(' ');
        }
      } else {
        amount = int.tryParse(parts.first) ?? 0;
        note = amount != 0 ? "Entry" : parts.first;
      }

      if (amount == 0) return;

      // Positive amount = You Gave (Red), Negative amount = You Got (Green)
      final finalAmount = isGive ? amount : -amount;
      _dbService.addTransaction(widget.contactId, note, finalAmount);
      _noteController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Contact?>(
      stream: _dbService.getContactStream(widget.contactId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final contact = snapshot.data!;
        final txns = contact.transactions.values.toList()
          ..sort((a, b) => b.time.compareTo(a.time));

        return Scaffold(
          appBar: AppBar(
            title: Text(contact.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
          body: Column(
            children: [
              _buildBalanceHeader(contact),
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: txns.length,
                  itemBuilder: (context, index) {
                    final txn = txns[index];
                    return _buildTransactionBubble(txn);
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceHeader(Contact contact) {
    final color = contact.balance >= 0 ? Colors.red.shade400 : Colors.green.shade400;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: Colors.teal.shade50,
      child: Column(
        children: [
          Text(
            '₹${contact.balance.abs()}',
            style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            contact.balance >= 0 ? "You Gave (To Get)" : "You Got (To Give)",
            style: GoogleFonts.poppins(fontSize: 16, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionBubble(TransactionEntry txn) {
    final isGave = txn.amount > 0;
    final color = isGave ? Colors.red.shade50 : Colors.green.shade50;
    final textColor = isGave ? Colors.red.shade900 : Colors.green.shade900;
    final align = isGave ? Alignment.centerRight : Alignment.centerLeft;
    final time = DateFormat('dd MMM, hh:mm a').format(txn.time);

    return Align(
      alignment: align,
      child: GestureDetector(
        onLongPress: () => _showDeleteTransactionDialog(txn),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15).copyWith(
              bottomRight: isGave ? const Radius.circular(0) : null,
              bottomLeft: !isGave ? const Radius.circular(0) : null,
            ),
            border: Border.all(color: isGave ? Colors.red.shade100 : Colors.green.shade100),
          ),
          child: Column(
            crossAxisAlignment: isGave ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(txn.note, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('₹${txn.amount.abs()}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(width: 10),
                  Text(time, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Enter note and amount (e.g. Tea 20)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _addTransaction(false),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('YOU GOT'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _addTransaction(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('YOU GAVE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteTransactionDialog(TransactionEntry txn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _dbService.deleteTransaction(widget.contactId, txn.id, txn.amount);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
