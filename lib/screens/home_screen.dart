import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../models/group.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/excel_export_service.dart';
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

  // For Desktop/Large screen split view
  String? _selectedContactId;
  String? _selectedGroupId;

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

  void _exportMasterExcel() async {
    final contacts = await _dbService.contactsStream.first;
    if (contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No customer records available to export')),
        );
      }
      return;
    }
    await ExcelExportService.exportAllCustomers(contacts);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF16A34A),
          content: Text('Master Excel report exported successfully!'),
        ),
      );
    }
  }

  void _showPasswordResetDialog() {
    final email = _authService.currentUser?.email ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        content: Text(
          email.isNotEmpty
              ? 'Send a password reset email to $email?'
              : 'Send a password reset link to your account email address?',
          style: const TextStyle(color: Color(0xFF334155), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (email.isNotEmpty) {
                try {
                  await _authService.sendPasswordResetEmail(email);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF16A34A),
                        content: Text('Password reset link sent to $email. Please check your inbox.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFFDC2626),
                        content: Text('Error: ${e.toString().split(']').last.trim()}'),
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008080),
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Email', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth >= 800;

        if (isLargeScreen) {
          return _buildLargeScreenLayout();
        } else {
          return _buildMobileScreenLayout();
        }
      },
    );
  }

  // ==========================================
  // LARGE SCREEN / DESKTOP RESPONSIVE LAYOUT
  // ==========================================
  Widget _buildLargeScreenLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // Left Sidebar (Navigation & Master List)
          SizedBox(
            width: 380,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildLargeScreenHeader(),
                  _buildLargeScreenTabToggle(),
                  Expanded(
                    child: _currentIndex == 0
                        ? _buildCustomersTabContent(isLargeScreen: true)
                        : _buildGroupsTabContent(isLargeScreen: true),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Right Workspace Pane (Detail View / Dashboard)
          Expanded(
            child: _buildRightWorkspacePane(),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeScreenHeader() {
    final userEmail = _authService.currentUser?.email ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF008080), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pocket Khata',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (userEmail.isNotEmpty)
                  Text(
                    userEmail,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B), size: 20),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              if (value == 'export') {
                _exportMasterExcel();
              } else if (value == 'reset') {
                _showPasswordResetDialog();
              } else if (value == 'logout') {
                _authService.signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, color: Color(0xFF008080), size: 18),
                    SizedBox(width: 10),
                    Text('Export Master Excel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, color: Color(0xFF008080), size: 18),
                    SizedBox(width: 10),
                    Text('Reset Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                    SizedBox(width: 10),
                    Text('Log Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFDC2626))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeScreenTabToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() {
                _currentIndex = 0;
                _selectedGroupId = null;
                _searchController.clear();
                _searchQuery = '';
              }),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _currentIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _currentIndex == 0
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Customers',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _currentIndex == 0 ? const Color(0xFF008080) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() {
                _currentIndex = 1;
                _selectedContactId = null;
                _searchController.clear();
                _searchQuery = '';
              }),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _currentIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _currentIndex == 1
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Groups',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _currentIndex == 1 ? const Color(0xFF008080) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightWorkspacePane() {
    if (_currentIndex == 0 && _selectedContactId != null) {
      return ContactDetailsScreen(
        key: ValueKey(_selectedContactId),
        uid: widget.uid,
        contactId: _selectedContactId!,
        isEmbedded: true,
      );
    }

    if (_currentIndex == 1 && _selectedGroupId != null) {
      return GroupDetailsScreen(
        key: ValueKey(_selectedGroupId),
        uid: widget.uid,
        groupId: _selectedGroupId!,
        isEmbedded: true,
      );
    }

    // Default Welcome & Dashboard Workspace View
    return StreamBuilder<List<Contact>>(
      stream: _dbService.contactsStream,
      builder: (context, snapshot) {
        final contacts = snapshot.data ?? [];
        int totalGet = 0;
        int totalGive = 0;
        for (var c in contacts) {
          if (c.balance > 0) totalGet += c.balance;
          if (c.balance < 0) totalGive += c.balance.abs();
        }
        final netTotal = totalGet - totalGive;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, size: 64, color: Color(0xFF008080)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome to Pocket Khata',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a customer or group from the left menu to view and add transactions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 32),

                  // Overall Dashboard Cards
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        const Text(
                          'Overall Net Financial Position',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${netTotal.abs()}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: netTotal >= 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          ),
                        ),
                        Text(
                          netTotal >= 0 ? "You Gave More (Net Receivable)" : "You Got More (Net Payable)",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: netTotal >= 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Column(
                                  children: [
                                    const Text("You'll Get", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF991B1B))),
                                    const SizedBox(height: 4),
                                    Text('₹$totalGet', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF86EFAC)),
                                ),
                                child: Column(
                                  children: [
                                    const Text("You'll Give", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF166534))),
                                    const SizedBox(height: 4),
                                    Text('₹$totalGive', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showAddContactDialog,
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('Add Customer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008080),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _exportMasterExcel,
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('Export Excel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF008080),
                          side: const BorderSide(color: Color(0xFF008080)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // MOBILE SCREEN LAYOUT (< 800px)
  // ==========================================
  Widget _buildMobileScreenLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Pocket Khata',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined, color: Color(0xFF008080)),
            tooltip: 'Export Master Excel Report',
            onPressed: _exportMasterExcel,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF475569)),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              if (value == 'export') {
                _exportMasterExcel();
              } else if (value == 'reset') {
                _showPasswordResetDialog();
              } else if (value == 'logout') {
                _authService.signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, color: Color(0xFF008080), size: 18),
                    SizedBox(width: 10),
                    Text('Export Master Excel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, color: Color(0xFF008080), size: 18),
                    SizedBox(width: 10),
                    Text('Reset Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                    SizedBox(width: 10),
                    Text('Log Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFDC2626))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildCustomersTabContent(isLargeScreen: false),
          _buildGroupsTabContent(isLargeScreen: false),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
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
            indicatorColor: const Color(0xFFCCFBF1),
            elevation: 0,
            height: 62,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, color: Color(0xFF64748B)),
                selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF0F766E)),
                label: 'Customers',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined, color: Color(0xFF64748B)),
                selectedIcon: Icon(Icons.groups_rounded, color: Color(0xFF0F766E)),
                label: 'Groups',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Customers Tab Content ---
  Widget _buildCustomersTabContent({required bool isLargeScreen}) {
    return Column(
      children: [
        _buildSearchField('Search customers...'),
        Expanded(
          child: StreamBuilder<List<GroupModel>>(
            stream: _dbService.groupsStream,
            builder: (context, groupsSnapshot) {
              final groups = groupsSnapshot.data ?? [];
              final Set<String> groupedContactIds = {};
              for (var g in groups) {
                groupedContactIds.addAll(g.memberIds);
              }

              return StreamBuilder<List<Contact>>(
                stream: _dbService.contactsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
                  }

                  final allContacts = snapshot.data ?? [];

                  // Filter out contacts that are in any group!
                  final standaloneContacts = allContacts
                      .where((c) => !groupedContactIds.contains(c.id))
                      .where((c) => c.name.toLowerCase().contains(_searchQuery))
                      .toList();

                  int totalGet = 0;
                  int totalGive = 0;

                  for (var c in standaloneContacts) {
                    if (c.balance > 0) {
                      totalGet += c.balance;
                    } else if (c.balance < 0) {
                      totalGive += c.balance.abs();
                    }
                  }

                  return Column(
                    children: [
                      _buildCompactSummaryBar(
                        getAmount: totalGet,
                        giveAmount: totalGive,
                      ),
                      Expanded(
                        child: standaloneContacts.isEmpty
                            ? _buildEmptyState(
                                icon: Icons.people_outline_rounded,
                                message: _searchQuery.isEmpty
                                    ? (allContacts.isNotEmpty && groupedContactIds.isNotEmpty
                                        ? 'All customers are grouped in Groups'
                                        : 'No customers added yet')
                                    : 'No matching customers found',
                              )
                            : ListView.builder(
                                padding: EdgeInsets.only(
                                  left: 12,
                                  right: 12,
                                  top: 4,
                                  bottom: isLargeScreen ? 30 : 100,
                                ),
                                itemCount: standaloneContacts.length,
                                itemBuilder: (context, index) {
                                  final contact = standaloneContacts[index];
                                  return _buildContactCard(contact, isLargeScreen: isLargeScreen);
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Groups Tab Content ---
  Widget _buildGroupsTabContent({required bool isLargeScreen}) {
    return Column(
      children: [
        _buildSearchField('Search groups...'),
        Expanded(
          child: StreamBuilder<List<Contact>>(
            stream: _dbService.contactsStream,
            builder: (context, contactsSnapshot) {
              final allContacts = contactsSnapshot.data ?? [];

              return StreamBuilder<List<GroupModel>>(
                stream: _dbService.groupsStream,
                builder: (context, groupsSnapshot) {
                  if (groupsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
                  }

                  final groups = groupsSnapshot.data ?? [];
                  final filtered = groups
                      .where((g) => g.name.toLowerCase().contains(_searchQuery))
                      .toList();

                  int overallGet = 0;
                  int overallGive = 0;

                  for (var c in allContacts) {
                    if (c.balance > 0) overallGet += c.balance;
                    if (c.balance < 0) overallGive += c.balance.abs();
                  }

                  return Column(
                    children: [
                      _buildCompactSummaryBar(
                        getAmount: overallGet,
                        giveAmount: overallGive,
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? _buildEmptyState(
                                icon: Icons.groups_outlined,
                                message: _searchQuery.isEmpty ? 'No groups created yet' : 'No matching groups found',
                              )
                            : ListView.builder(
                                padding: EdgeInsets.only(
                                  left: 12,
                                  right: 12,
                                  top: 4,
                                  bottom: isLargeScreen ? 30 : 100,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final group = filtered[index];
                                  final memberContacts = allContacts
                                      .where((c) => group.memberIds.contains(c.id))
                                      .toList();
                                  final groupNet = memberContacts.fold<int>(0, (sum, c) => sum + c.balance);

                                  return _buildGroupCard(group, memberContacts.length, groupNet, isLargeScreen: isLargeScreen);
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(String hint) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
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
              const Text(
                "You'll Get",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
              ),
              Text(
                '₹$getAmount',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
              ),
            ],
          ),
          Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "You'll Give",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
              ),
              Text(
                '₹$giveAmount',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
              ),
            ],
          ),
          Container(height: 24, width: 1, color: const Color(0xFFE2E8F0)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Net Total',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
              Text(
                '₹${netBalance.abs()}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: netColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Contact contact, {required bool isLargeScreen}) {
    final balanceColor = contact.balance >= 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final balanceText = contact.balance >= 0
        ? "You'll Get: ₹${contact.balance.abs()}"
        : "You'll Give: ₹${contact.balance.abs()}";

    final isSelected = isLargeScreen && _selectedContactId == contact.id;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isSelected ? const Color(0xFF008080) : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
      ),
      elevation: 0,
      color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFCCFBF1),
          foregroundColor: const Color(0xFF0F766E),
          radius: 20,
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'C',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
        ),
        subtitle: Text(
          balanceText,
          style: TextStyle(color: balanceColor, fontWeight: FontWeight.w600, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.description_outlined, color: Color(0xFF008080), size: 18),
              tooltip: 'Export Customer Excel Statement',
              onPressed: () => ExcelExportService.exportSingleCustomer(contact),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
        onTap: () {
          if (isLargeScreen) {
            setState(() => _selectedContactId = contact.id);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContactDetailsScreen(uid: widget.uid, contactId: contact.id),
              ),
            );
          }
        },
        onLongPress: () => _showDeleteContactDialog(contact),
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group, int memberCount, int groupNetBalance, {required bool isLargeScreen}) {
    final balanceColor = groupNetBalance >= 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    final isSelected = isLargeScreen && _selectedGroupId == group.id;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isSelected ? const Color(0xFF008080) : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
      ),
      elevation: 0,
      color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE0F2FE),
          foregroundColor: Color(0xFF0369A1),
          radius: 20,
          child: Icon(Icons.groups_rounded, size: 18),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                '$memberCount Members${group.description.isNotEmpty ? " • ${group.description}" : ""}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '₹${groupNetBalance.abs()}',
              style: TextStyle(color: balanceColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
        onTap: () {
          if (isLargeScreen) {
            setState(() => _selectedGroupId = group.id);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupDetailsScreen(uid: widget.uid, groupId: group.id),
              ),
            );
          }
        },
        onLongPress: () => _showDeleteGroupDialog(group),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
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
        title: const Text('New Customer', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter customer / contact name',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
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
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final Set<String> selectedMemberIds = {};

    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<Contact>>(
        stream: _dbService.contactsStream,
        builder: (context, snapshot) {
          final allContacts = snapshot.data ?? [];

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('New Group Khata', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Group Name (e.g. Roommates)',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descController,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Description (optional)',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Select Members:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      allContacts.isEmpty
                          ? const Text(
                              'No customers available yet. You can add members after creating the group.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            )
                          : Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: ListView.builder(
                                itemCount: allContacts.length,
                                itemBuilder: (context, index) {
                                  final contact = allContacts[index];
                                  final isSelected = selectedMemberIds.contains(contact.id);

                                  return CheckboxListTile(
                                    dense: true,
                                    activeColor: const Color(0xFF008080),
                                    title: Text(
                                      contact.name,
                                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    value: isSelected,
                                    onChanged: (val) {
                                      setDialogState(() {
                                        if (val == true) {
                                          selectedMemberIds.add(contact.id);
                                        } else {
                                          selectedMemberIds.remove(contact.id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isNotEmpty) {
                        _dbService.addGroup(
                          nameController.text.trim(),
                          descController.text.trim(),
                          selectedMemberIds.toList(),
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008080),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Create Group', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteContactDialog(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete ${contact.name}?', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        content: const Text('All transactions for this customer will be permanently removed.', style: TextStyle(color: Color(0xFF334155))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              _dbService.deleteContact(contact.id);
              if (_selectedContactId == contact.id) {
                setState(() => _selectedContactId = null);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ${group.name}?', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        content: const Text(
          'Choose how you want to delete this group:',
          style: TextStyle(color: Color(0xFF334155), fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed: () {
                  _dbService.deleteGroupOnly(group.id);
                  if (_selectedGroupId == group.id) {
                    setState(() => _selectedGroupId = null);
                  }
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF008080)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Delete Group Only (Keep Customers)',
                  style: TextStyle(color: Color(0xFF008080), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  _dbService.deleteGroupAndMembers(group.id, group.memberIds);
                  if (_selectedGroupId == group.id) {
                    setState(() => _selectedGroupId = null);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Delete Group & All Member Customers',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
