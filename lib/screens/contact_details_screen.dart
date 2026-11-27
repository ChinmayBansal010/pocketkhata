import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/contact.dart';
import '../models/transaction_entry.dart';
import '../services/database_service.dart';
import '../services/excel_export_service.dart';

class ContactDetailsScreen extends StatefulWidget {
  final String uid;
  final String contactId;
  final bool isEmbedded;

  const ContactDetailsScreen({
    super.key,
    required this.uid,
    required this.contactId,
    this.isEmbedded = false,
  });

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

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _addTransaction(bool isGive) {
    if (_noteController.text.trim().isNotEmpty) {
      final text = _noteController.text.trim();
      final parts = text.split(' ');
      int amount = 0;
      String note = text;

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

      final finalAmount = isGive ? amount : -amount;
      _dbService.addTransaction(widget.contactId, note, finalAmount);
      _noteController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _appendQuickAmount(int value) {
    final current = _noteController.text.trim();
    final parts = current.split(' ');
    if (parts.length > 1 && int.tryParse(parts.last) != null) {
      final note = parts.sublist(0, parts.length - 1).join(' ');
      _noteController.text = '$note $value';
    } else if (current.isNotEmpty && int.tryParse(current) == null) {
      _noteController.text = '$current $value';
    } else {
      _noteController.text = '$value';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Contact?>(
      stream: _dbService.getContactStream(widget.contactId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF008080))),
          );
        }

        final contact = snapshot.data!;
        final txns = contact.transactions.values.toList()
          ..sort((a, b) => b.time.compareTo(a.time));

        int totalGave = 0;
        int totalGot = 0;
        for (var t in txns) {
          if (t.amount > 0) {
            totalGave += t.amount;
          } else {
            totalGot += t.amount.abs();
          }
        }

        Widget screenBody = Column(
          children: [
            _buildBalanceHeader(contact, txns.length, totalGave, totalGot),
            Expanded(
              child: txns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 12),
                          Text(
                            'No transactions yet\nAdd your first transaction below',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.only(left: 14, right: 14, top: 12, bottom: 20),
                      itemCount: txns.length,
                      itemBuilder: (context, index) {
                        final txn = txns[index];
                        return _buildTransactionCard(txn);
                      },
                    ),
            ),
            _buildInputArea(),
          ],
        );

        if (widget.isEmbedded) {
          return Container(
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                _buildEmbeddedHeader(contact),
                Expanded(child: screenBody),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: Text(
              contact.name,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.description_outlined, color: Color(0xFF008080)),
                tooltip: 'Export Excel Statement',
                onPressed: () => ExcelExportService.exportSingleCustomer(contact),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF008080)),
                tooltip: 'Edit Customer Name',
                onPressed: () => _showEditContactDialog(contact),
              ),
            ],
          ),
          body: screenBody,
        );
      },
    );
  }

  Widget _buildEmbeddedHeader(Contact contact) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFCCFBF1),
            foregroundColor: const Color(0xFF0F766E),
            radius: 20,
            child: Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'C',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Customer Ledger',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.description_outlined, color: Color(0xFF008080), size: 20),
            tooltip: 'Export Excel Statement',
            onPressed: () => ExcelExportService.exportSingleCustomer(contact),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF008080), size: 20),
            tooltip: 'Edit Name',
            onPressed: () => _showEditContactDialog(contact),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceHeader(Contact contact, int count, int totalGave, int totalGot) {
    final isPositive = contact.balance >= 0;
    final balanceColor = isPositive ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Net Balance: ',
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              Text(
                '₹${contact.balance.abs()}',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: balanceColor),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isPositive ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC)),
                ),
                child: Text(
                  isPositive ? "You Gave" : "You Got",
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: balanceColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Total Entries', '$count'),
              _buildMiniStat('Total Gave (Out)', '₹$totalGave', color: const Color(0xFFDC2626)),
              _buildMiniStat('Total Got (In)', '₹$totalGot', color: const Color(0xFF16A34A)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF64748B))),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionEntry txn) {
    final isGave = txn.amount > 0;
    final bgColor = isGave ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final borderColor = isGave ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC);
    final textColor = isGave ? const Color(0xFF991B1B) : const Color(0xFF166534);
    final badgeBg = isGave ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);
    final align = isGave ? Alignment.centerRight : Alignment.centerLeft;
    final timeStr = DateFormat('dd MMM, hh:mm a').format(txn.time);

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isGave ? Radius.zero : const Radius.circular(16),
            bottomLeft: !isGave ? Radius.zero : const Radius.circular(16),
          ),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTransactionActionMenu(txn),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: isGave ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGave ? 'YOU GAVE (OUT)' : 'YOU GOT (IN)',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    const Icon(Icons.more_vert_rounded, size: 16, color: Color(0xFF94A3B8)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  txn.note,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${txn.amount.abs()}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Quick amount chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [50, 100, 200, 500, 1000, 2000].map((amt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => _appendQuickAmount(amt),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          '+₹$amt',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF008080),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            TextField(
              controller: _noteController,
              style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Note & amount (e.g. Tea 20 or 500)',
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addTransaction(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('YOU GOT (IN)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addTransaction(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('YOU GAVE (OUT)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionActionMenu(TransactionEntry txn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Color(0xFF008080)),
                title: Text('Edit Transaction', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                onTap: () {
                  Navigator.pop(context);
                  _showEditTransactionDialog(txn);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                title: Text('Delete Transaction', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFFDC2626))),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteTransactionDialog(txn);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditTransactionDialog(TransactionEntry txn) {
    final noteCtrl = TextEditingController(text: txn.note);
    final amountCtrl = TextEditingController(text: txn.amount.abs().toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Transaction', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteCtrl,
              style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Note / Item Name',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Amount (₹)',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  final newNote = noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : "Entry";
                  final amt = int.tryParse(amountCtrl.text.trim()) ?? 0;
                  if (amt > 0) {
                    _dbService.updateTransaction(widget.contactId, txn, newNote, -amt);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                ),
                child: Text('YOU GOT', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final newNote = noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : "Entry";
                  final amt = int.tryParse(amountCtrl.text.trim()) ?? 0;
                  if (amt > 0) {
                    _dbService.updateTransaction(widget.contactId, txn, newNote, amt);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                child: Text('YOU GAVE', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditContactDialog(Contact contact) {
    final nameCtrl = TextEditingController(text: contact.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Customer Name', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        content: TextField(
          controller: nameCtrl,
          style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter customer name',
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                _dbService.updateContactName(contact.id, nameCtrl.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008080),
              foregroundColor: Colors.white,
            ),
            child: Text('Save', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteTransactionDialog(TransactionEntry txn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete Transaction?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        content: Text('Are you sure you want to delete this transaction?', style: GoogleFonts.poppins(color: const Color(0xFF334155))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              _dbService.deleteTransaction(widget.contactId, txn.id, txn.amount);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
