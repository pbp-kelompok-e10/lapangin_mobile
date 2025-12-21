import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:lapangin/screens/user_admin/user.dart';
import 'package:lapangin/screens/user_admin/user_service.dart';
import 'package:lapangin/screens/user_admin/user_form_page.dart';
import 'package:lapangin/screens/user_admin/user_detail_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late UserService _userService;
  List<User> _users = [];
  List<User> _filteredUsers = [];

  bool _isLoading = true;
  String _errorMessage = '';

  // Filter & Search
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'inactive'

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final request = context.read<CookieRequest>();
    _userService = UserService(request);
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load users from API
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String? statusParam;
      if (_statusFilter == 'active') statusParam = 'active';
      if (_statusFilter == 'inactive') statusParam = 'inactive';

      List<User> users = await _userService.getUserList(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: statusParam,
      );

      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// Search handler
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadUsers();
  }

  /// Status filter handler
  void _onStatusFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _statusFilter = value;
      });
      _loadUsers();
    }
  }

  /// Refresh handler (Pull to refresh)
  Future<void> _onRefresh() async {
    await _loadUsers();
  }

  /// Navigate to create user page
  void _navigateToCreateUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserFormPage(),
      ),
    );

    // Reload if user was created
    if (result == true) {
      _loadUsers();
    }
  }

  /// Navigate to user detail page
  void _navigateToUserDetail(User user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailPage(user: user),
      ),
    );

    // Reload if user was updated or deleted
    if (result == true) {
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar & Filter
          _buildSearchAndFilter(),

          // User Stats
          _buildUserStats(),

          // User List
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateUser,
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Search Bar & Filter Dropdown
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by username, name, or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: _onSearchChanged,
          ),

          const SizedBox(height: 12),

          // Filter Dropdown
          Row(
            children: [
              const Icon(Icons.filter_list, color: Colors.grey),
              const SizedBox(width: 8),
              const Text('Filter by status:'),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Users')),
                    DropdownMenuItem(value: 'active', child: Text('Active Only')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive Only')),
                  ],
                  onChanged: _onStatusFilterChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// User Stats (Total, Active, Inactive)
  Widget _buildUserStats() {
    int totalUsers = _filteredUsers.length;
    int activeUsers = _filteredUsers.where((u) => u.isActive).length;
    int inactiveUsers = _filteredUsers.where((u) => !u.isActive).length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.blue[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', totalUsers, Colors.blue),
          _buildStatItem('Active', activeUsers, Colors.green),
          _buildStatItem('Inactive', inactiveUsers, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Main Body (Loading, Error, Empty, or List)
  Widget _buildBody() {
    // Loading State
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading users...'),
          ],
        ),
      );
    }

    // Error State
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty State
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search or filter',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // User List
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          User user = _filteredUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  /// User Card Widget
  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),

        // Avatar
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: user.isActive ? Colors.blue : Colors.grey,
          child: Text(
            user.username[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // User Info
        title: Text(
          user.name ?? user.username,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('@${user.username}'),
            if (user.email != null && user.email!.isNotEmpty)
              Text(
                user.email!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: user.isActive ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: user.isActive ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Role Badge
                if (user.isSuperuser)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Superuser',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                  )
                else if (user.isStaff)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Staff',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Actions
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () => _navigateToUserDetail(user),
        ),

        // On Tap
        onTap: () => _navigateToUserDetail(user),
      ),
    );
  }
}