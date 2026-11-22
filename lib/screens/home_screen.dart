import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/contact.dart';
import '../models/group.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'contact_details_screen.dart';
import 'group_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final String uid;
  const HomeScreen({super.key, required this.uid});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late final DatabaseService _dbService;
  final AuthService _authService = AuthService.instance;

  int _currentIndex = 0;
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
    Widget content = Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Pocket Khata',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF475569)),
            tooltip: 'Log out',
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildCustomersTab(),
          _buildGroupsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _currentIndex == 0 ? _showAddContactDialog : _showAddGroupDialog,
        backgroundColor: const Color(0xFF008080),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: Icon(_currentIndex == 0 ? Icons.person_add_rounded : Icons.group_add_rounded),
        label: Text(
          _currentIndex == 0 ? 'Add Customer' : 'Add Group',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
                _searchController.clear();
                _searchQuery = '';
              });
            },
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFE0F2F1),
            elevation: 0,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B)),
                selectedIcon: const Icon(Icons.person_rounded, color: Color(0xFF008080)),
                label: 'Customers',
              ),
              NavigationDestination(
                icon: const Icon(Icons.groups_outlined, color: Color(0xFF64748B)),
                selectedIcon: const Icon(Icons.groups_rounded, color: Color(0xFF008080)),
                label: 'Groups',
              ),
            ],
          ),
        ),
      ),
    );

    // Responsive container for web desktop/tablet
    if (kIsWeb) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Material(
            elevation: 8,
            shadowColor: Colors.black26,
            child: content,
          ),
        ),
      );
    }

    return content;
  }

  // --- Customers Tab ---
  Widget _buildCustomersTab() {
    return Column(
      children: [
        _buildSearchField('Search customers/contacts...'),
        Expanded(
          child: StreamBuilder<List<Contact>>(
            stream: _dbService.contactsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
              }

              final contacts = snapshot.data ?? [];
              final filtered = contacts
                  .where((c) => c.name.toLowerCase().contains(_searchQuery))
                  .toList();

              int totalGet = 0;
              int totalGive = 0;

              for (var c in contacts) {
                if (c.balance > 0) {
                  totalGet += c.balance;
                } else if (c.balance < 0) {
                  totalGive += c.balance.abs();
                }
              }

              return Column(
                children: [
                  _buildSummaryCard(
                    getAmount: totalGet,
                    giveAmount: totalGive,
                    title: 'Khata Overview',
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.people_outline_rounded,
                            message: _searchQuery.isEmpty ? 'No customers added yet' : 'No matching customers found',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final contact = filtered[index];
                              return _buildContactCard(contact);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Groups Tab ---
  Widget _buildGroupsTab() {
    return Column(
      children: [
        _buildSearchField('Search groups...'),
        Expanded(
          child: StreamBuilder<List<GroupModel>>(
            stream: _dbService.groupsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
              }

              final groups = snapshot.data ?? [];
              final filtered = groups
                  .where((g) => g.name.toLowerCase().contains(_searchQuery))
                  .toList();

              int totalGet = 0;
              int totalGive = 0;

              for (var g in groups) {
                if (g.balance > 0) {
                  totalGet += g.balance;
                } else if (g.balance < 0) {
                  totalGive += g.balance.abs();
                }
              }

              return Column(
                children: [
                  _buildSummaryCard(
                    getAmount: totalGet,
                    giveAmount: totalGive,
                    title: 'Group Balance Overview',
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.groups_outlined,
                            message: _searchQuery.isEmpty ? 'No groups created yet' : 'No matching groups found',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final group = filtered[index];
                              return _buildGroupCard(group);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(String hint) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF008080)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF008080), width: 2),
          ),
        ),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
      ),
    );
  }

  Widget _buildSummaryCard({
    required int getAmount,
    required int giveAmount,
    required String title,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "You'll Get",
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF991B1B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹$getAmount',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "You'll Give",
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF166534)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹$giveAmount',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    final balanceColor = contact.balance >= 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final balanceText = contact.balance >= 0
        ? "You'll Get: ₹${contact.balance.abs()}"
        : "You'll Give: ₹${contact.balance.abs()}";

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFCCFBF1),
          foregroundColor: const Color(0xFF0F766E),
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'C',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        title: Text(
          contact.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A)),
        ),
        subtitle: Text(
          balanceText,
          style: GoogleFonts.poppins(color: balanceColor, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContactDetailsScreen(uid: widget.uid, contactId: contact.id),
          ),
        ),
        onLongPress: () => _showDeleteContactDialog(contact),
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    final balanceColor = group.balance >= 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final balanceText = group.balance >= 0
        ? "Group Owes: ₹${group.balance.abs()}"
        : "You Owe Group: ₹${group.balance.abs()}";

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE0F2FE),
          foregroundColor: const Color(0xFF0369A1),
          child: const Icon(Icons.groups_rounded, size: 20),
        ),
        title: Text(
          group.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A)),
        ),
        subtitle: Text(
          group.description.isNotEmpty ? group.description : balanceText,
          style: GoogleFonts.poppins(
            color: group.description.isNotEmpty ? const Color(0xFF64748B) : balanceColor,
            fontWeight: group.description.isNotEmpty ? FontWeight.normal : FontWeight.w600,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupDetailsScreen(uid: widget.uid, groupId: group.id),
          ),
        ),
        onLongPress: () => _showDeleteGroupDialog(group),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('New Customer', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        content: TextField(
          controller: controller,
          style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter customer / contact name',
            hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
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
              if (controller.text.trim().isNotEmpty) {
                _dbService.addContact(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008080),
              foregroundColor: Colors.white,
            ),
            child: Text('Add', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('New Group Khata', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Group Name (e.g. Roommates)',
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: GoogleFonts.poppins(color: const Color(0xFF0F172A), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Description (optional)',
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
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
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                _dbService.addGroup(nameController.text.trim(), descController.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008080),
              foregroundColor: Colors.white,
            ),
            child: Text('Create Group', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteContactDialog(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete ${contact.name}?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        content: Text('All transactions for this customer will be permanently removed.', style: GoogleFonts.poppins(color: const Color(0xFF334155))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              _dbService.deleteContact(contact.id);
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

  void _showDeleteGroupDialog(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete Group ${group.name}?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        content: Text('All group transactions will be permanently removed.', style: GoogleFonts.poppins(color: const Color(0xFF334155))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              _dbService.deleteGroup(group.id);
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
