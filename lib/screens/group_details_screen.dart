import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/contact.dart';
import '../models/group.dart';
import '../services/database_service.dart';
import 'contact_details_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String uid;
  final String groupId;
  final bool isEmbedded;

  const GroupDetailsScreen({
    super.key,
    required this.uid,
    required this.groupId,
    this.isEmbedded = false,
  });

  @override
  GroupDetailsScreenState createState() => GroupDetailsScreenState();
}

class GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late final DatabaseService _dbService;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: widget.uid);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GroupModel?>(
      stream: _dbService.getGroupStream(widget.groupId),
      builder: (context, groupSnapshot) {
        if (!groupSnapshot.hasData || groupSnapshot.data == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF008080))),
          );
        }

        final group = groupSnapshot.data!;

        return StreamBuilder<List<Contact>>(
          stream: _dbService.contactsStream,
          builder: (context, contactsSnapshot) {
            final allContacts = contactsSnapshot.data ?? [];
            final memberContacts = allContacts
                .where((c) => group.memberIds.contains(c.id))
                .toList();

            final filteredMembers = memberContacts
                .where((c) => c.name.toLowerCase().contains(_searchQuery))
                .toList();

            int totalGet = 0;
            int totalGive = 0;

            for (var c in memberContacts) {
              if (c.balance > 0) {
                totalGet += c.balance;
              } else if (c.balance < 0) {
                totalGive += c.balance.abs();
              }
            }

            Widget screenBody = Column(
              children: [
                _buildCompactSummaryBar(
                  getAmount: totalGet,
                  giveAmount: totalGive,
                  memberCount: memberContacts.length,
                ),
                _buildSearchField(),
                Expanded(
                  child: filteredMembers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.group_outlined, size: 56, color: Color(0xFFCBD5E1)),
                                const SizedBox(height: 12),
                                Text(
                                  memberContacts.isEmpty
                                      ? 'No members in this group yet.\nTap + to add members from your customers.'
                                      : 'No matching members found',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13),
                                ),
                                if (memberContacts.isEmpty) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _showAddMemberDialog(group, allContacts),
                                    icon: const Icon(Icons.person_add_rounded, size: 18),
                                    label: const Text('Add Members'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF008080),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 14, right: 14, top: 4, bottom: 40),
                          itemCount: filteredMembers.length,
                          itemBuilder: (context, index) {
                            final contact = filteredMembers[index];
                            return _buildMemberCard(group, contact);
                          },
                        ),
                ),
              ],
            );

            if (widget.isEmbedded) {
              return Container(
                color: const Color(0xFFF8FAFC),
                child: Column(
                  children: [
                    _buildEmbeddedHeader(group, allContacts),
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
                title: Column(
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
                actions: [
                  IconButton(
                    icon: const Icon(Icons.person_add_rounded, color: Color(0xFF008080)),
                    tooltip: 'Add Member to Group',
                    onPressed: () => _showAddMemberDialog(group, allContacts),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                    tooltip: 'Delete Group',
                    onPressed: () => _showDeleteGroupDialog(group),
                  ),
                ],
              ),
              body: screenBody,
            );
          },
        );
      },
    );
  }

  Widget _buildEmbeddedHeader(GroupModel group, List<Contact> allContacts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE0F2FE),
            foregroundColor: Color(0xFF0369A1),
            radius: 20,
            child: Icon(Icons.groups_rounded, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  group.description.isNotEmpty ? group.description : 'Group Ledger',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Color(0xFF008080), size: 20),
            tooltip: 'Add Member',
            onPressed: () => _showAddMemberDialog(group, allContacts),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
            tooltip: 'Delete Group',
            onPressed: () => _showDeleteGroupDialog(group),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search group members...',
          hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF008080), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF008080), width: 2),
          ),
        ),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
      ),
    );
  }

  Widget _buildCompactSummaryBar({
    required int getAmount,
    required int giveAmount,
    required int memberCount,
  }) {
    final netBalance = getAmount - giveAmount;
    final netColor = netBalance >= 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Group Members",
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
              ),
              Text(
                '$memberCount',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0369A1)),
              ),
            ],
          ),
          Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You'll Get",
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF991B1B)),
              ),
              Text(
                '₹$getAmount',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626)),
              ),
            ],
          ),
          Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Group Net",
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
              ),
              Text(
                '₹${netBalance.abs()}',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: netColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(GroupModel group, Contact contact) {
    final balanceColor = contact.balance >= 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final balanceText = contact.balance >= 0
        ? "You'll Get: ₹${contact.balance.abs()}"
        : "You'll Give: ₹${contact.balance.abs()}";

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFCCFBF1),
          foregroundColor: const Color(0xFF0F766E),
          radius: 20,
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'C',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        title: Text(
          contact.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A)),
        ),
        subtitle: Text(
          balanceText,
          style: GoogleFonts.poppins(color: balanceColor, fontWeight: FontWeight.w600, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.person_remove_outlined, color: Color(0xFFE11D48), size: 20),
              tooltip: 'Remove from group',
              onPressed: () => _dbService.removeMemberFromGroup(group.id, contact.id),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContactDetailsScreen(uid: widget.uid, contactId: contact.id),
          ),
        ),
      ),
    );
  }

  void _showAddMemberDialog(GroupModel group, List<Contact> allContacts) {
    final availableContacts = allContacts
        .where((c) => !group.memberIds.contains(c.id))
        .toList();

    final Set<String> selectedContactIds = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Add Members to Group', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            content: availableContacts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'All your customers are already in this group!',
                      style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  )
                : SizedBox(
                    width: double.maxFinite,
                    height: 300,
                    child: ListView.builder(
                      itemCount: availableContacts.length,
                      itemBuilder: (context, index) {
                        final contact = availableContacts[index];
                        final isSelected = selectedContactIds.contains(contact.id);

                        return CheckboxListTile(
                          activeColor: const Color(0xFF008080),
                          title: Text(
                            contact.name,
                            style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(
                            contact.balance >= 0
                                ? "Get: ₹${contact.balance.abs()}"
                                : "Give: ₹${contact.balance.abs()}",
                            style: GoogleFonts.poppins(
                              color: contact.balance >= 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              fontSize: 12,
                            ),
                          ),
                          value: isSelected,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedContactIds.add(contact.id);
                              } else {
                                selectedContactIds.remove(contact.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
              ),
              if (availableContacts.isNotEmpty)
                ElevatedButton(
                  onPressed: () {
                    for (var contactId in selectedContactIds) {
                      _dbService.addMemberToGroup(group.id, contactId);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008080),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Add Selected (${selectedContactIds.length})', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteGroupDialog(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ${group.name}?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        content: Text(
          'Choose how you want to delete this group:',
          style: GoogleFonts.poppins(color: const Color(0xFF334155), fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed: () {
                  _dbService.deleteGroupOnly(group.id);
                  Navigator.pop(context); // Pop dialog
                  if (!widget.isEmbedded) Navigator.pop(context); // Pop details screen
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF008080)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Delete Group Only (Keep Customers)',
                  style: GoogleFonts.poppins(color: const Color(0xFF008080), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  _dbService.deleteGroupAndMembers(group.id, group.memberIds);
                  Navigator.pop(context); // Pop dialog
                  if (!widget.isEmbedded) Navigator.pop(context); // Pop details screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Delete Group & All Member Customers',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
