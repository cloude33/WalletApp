import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/data_service.dart';
import 'add_user_screen.dart';
import 'home_screen.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final DataService _dataService = DataService();
  List<User> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _dataService.getAllUsers();
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  Future<void> _selectUser(User user) async {
    await _dataService.saveUser(user);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: Text('${user.name} adlı kullanıcıyı silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final users = List<User>.from(_users);
      users.removeWhere((u) => u.id == user.id);
      await _dataService.saveAllUsers(users);
      
      // If the deleted user was the current user, clear current user?
      // For now just reload
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF00BFA5),
              ),
              child: const Center(
                child: Text(
                  'Kullanıcı Seçin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_off, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'Henüz kullanıcı yok',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddUserScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadUsers();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00BFA5),
                                ),
                                child: const Text('Kullanıcı Oluştur', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _users.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _users.length) {
                              return _buildAddUserCard();
                            }
                            return _buildUserCard(_users[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return GestureDetector(
      onTap: () => _selectUser(user),
      onLongPress: () => _deleteUser(user),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF00BFA5).withOpacity(0.1),
              backgroundImage: user.avatar != null
                  ? MemoryImage(base64Decode(user.avatar!))
                  : null,
              child: user.avatar == null
                  ? Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00BFA5),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (user.email != null) ...[
              const SizedBox(height: 4),
              Text(
                user.email!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddUserCard() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddUserScreen()),
        );
        if (result == true) {
          _loadUsers();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00BFA5), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BFA5).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 40,
                color: Color(0xFF00BFA5),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Yeni Kullanıcı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00BFA5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
