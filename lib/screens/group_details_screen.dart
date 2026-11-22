import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/group.dart';
import '../models/transaction_entry.dart';
import '../services/database_service.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String uid;
  final String groupId;

  const GroupDetailsScreen({super.key, required this.uid, required this.groupId});

  @override
  GroupDetailsScreenState createState() => GroupDetailsScreenState();
}

class GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late final DatabaseService _dbService;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: widget.uid);
  }

  void _addTransaction(bool isGive) {
    if (_noteController.text.isNotEmpty) {
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
        note = amount != 0 ? "Group Entry" : parts.first;
      }

      if (amount == 0) return;

      final finalAmount = isGive ? amount : -amount;
      _dbService.addGroupTransaction(widget.groupId, note, finalAmount);
      _noteController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GroupModel?>(
      stream: _dbService.getGroupStream(widget.groupId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF008080))),
          );
        }

        final group = snapshot.data!;
        final txns = group.transactions.values.toList()
          ..sort((a, b) => b.time.compareTo(a.time));

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  group.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    fontSize: 18,
                  ),
                ),
                if (group.description.isNotEmpty)
                  Text(
                    group.description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          body: Column(
            children: [
              _buildBalanceHeader(group),
              Expanded(
                child: txns.isEmpty
                    ? Center(
                        child: Text(
                          'No group transactions yet',
                          style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
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

  Widget _buildBalanceHeader(GroupModel group) {
    final isPositive = group.balance >= 0;
    final color = isPositive ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Text(
            'Net Balance',
            style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            '₹${group.balance.abs()}',
            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            isPositive ? "Group Owes You / You Gave" : "You Owe Group / You Got",
            style: GoogleFonts.poppins(fontSize: 13, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionBubble(TransactionEntry txn) {
    final isGave = txn.amount > 0;
    final bgColor = isGave ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final borderColor = isGave ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC);
    final textColor = isGave ? const Color(0xFF991B1B) : const Color(0xFF166534);
    final align = isGave ? Alignment.centerRight : Alignment.centerLeft;
    final time = DateFormat('dd MMM, hh:mm a').format(txn.time);

    return Align(
      alignment: align,
      child: GestureDetector(
        onLongPress: () => _showDeleteTransactionDialog(txn),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: isGave ? Radius.zero : const Radius.circular(16),
              bottomLeft: !isGave ? Radius.zero : const Radius.circular(16),
            ),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isGave ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                txn.note,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${txn.amount.abs()}',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  const SizedBox(width: 8),
                  Text(time, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B))),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
            TextField(
              controller: _noteController,
              style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Enter note and amount (e.g. Lunch 350)',
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
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
              _dbService.deleteGroupTransaction(widget.groupId, txn.id, txn.amount);
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
