import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserAccountManager {
  static const String _activeProfileKey = 'hell_user_profile';
  static const String _registeredUsersKey = 'hell_registered_users_db';
  static const String _savedCredentialsKey = 'hell_saved_credentials';

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeProfileKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<List<Map<String, dynamic>>> getAllRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_registeredUsersKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<Map<String, dynamic>?> findRegisteredUser(String identifier) async {
    final clean = identifier.trim().toLowerCase();
    if (clean.isEmpty) return null;
    final users = await getAllRegisteredUsers();
    for (final u in users) {
      final email = (u['email'] ?? '').toString().trim().toLowerCase();
      final nick = (u['nickname'] ?? '').toString().trim().toLowerCase();
      final phone = (u['phone'] ?? '').toString().trim();
      if (email == clean || nick == clean || (phone.isNotEmpty && phone == identifier.trim())) {
        return u;
      }
    }
    return null;
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    final email = (user['email'] ?? '').toString().trim().toLowerCase();
    final users = await getAllRegisteredUsers();
    users.removeWhere((u) => (u['email'] ?? '').toString().trim().toLowerCase() == email);
    users.insert(0, user);
    await prefs.setString(_registeredUsersKey, jsonEncode(users));
    await prefs.setString(_activeProfileKey, jsonEncode(user));
  }

  static Future<List<Map<String, String>>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedCredentialsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Map<String, String>.from(e)).toList();
  }

  static Future<void> saveCredentials(String email, String username, String password) async {
    if (password.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await getSavedCredentials();
    current.removeWhere((c) => c['email']?.toLowerCase() == email.toLowerCase() || c['username']?.toLowerCase() == username.toLowerCase());
    current.insert(0, {'email': email, 'username': username, 'password': password});
    await prefs.setString(_savedCredentialsKey, jsonEncode(current));
  }

  static Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeProfileKey);
  }

  static Widget buildUserAvatar(Map<String, dynamic> user, {double radius = 36}) {
    final avatarPath = (user['avatarPath'] ?? '').toString();
    final avatarUrl = (user['avatarUrl'] ?? '').toString();

    if (avatarPath.isNotEmpty && File(avatarPath).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF1E78FF),
        backgroundImage: FileImage(File(avatarPath)),
      );
    }
    if (avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF1E78FF),
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF1E78FF),
      child: Icon(Icons.person, size: radius, color: Colors.white),
    );
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'dnd':
        return Colors.orange;
      case 'invisible':
        return Colors.white;
      case 'offline':
        return Colors.redAccent;
      case 'online':
      default:
        return Colors.green;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'dnd':
        return 'Não Incomodar';
      case 'invisible':
        return 'Invisível (Furtivo)';
      case 'offline':
        return 'Offline';
      case 'online':
      default:
        return 'Online';
    }
  }
}

class AuthScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _isRegisterMode = false;
  String _loginMethod = 'email';
  bool _obscurePass = true;
  bool _rememberPassword = true;
  bool _isGoogleBusy = false;
  List<Map<String, String>> _savedAccounts = [];
  final TextEditingController _nickCtrl = TextEditingController();
  final TextEditingController _identifierCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    final list = await UserAccountManager.getSavedCredentials();
    if (mounted) {
      setState(() {
        _savedAccounts = list;
        if (_savedAccounts.isNotEmpty) {
          _identifierCtrl.text = _savedAccounts.first['email'] ?? _savedAccounts.first['username'] ?? '';
          _passCtrl.text = _savedAccounts.first['password'] ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _nickCtrl.dispose();
    _identifierCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _handleGoogleAuth({required bool isNewRegister}) async {
    if (_isGoogleBusy) return;
    setState(() => _isGoogleBusy = true);

    String? chosenEmail;
    String? chosenName;
    String? chosenPhotoUrl;

    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account != null) {
        chosenEmail = account.email.trim();
        chosenName = (account.displayName ?? account.email.split('@').first).trim();
        chosenPhotoUrl = account.photoUrl;
      }
    } catch (_) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final registered = await UserAccountManager.getAllRegisteredUsers();
        final googleAccounts = registered.where((u) => u['provider'] == 'google').toList();
        if (!isNewRegister && googleAccounts.isNotEmpty && mounted) {
          final picked = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF0B1636),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFF38BDF8))),
              title: const Text('Selecionar Conta Google Registada', style: TextStyle(fontSize: 16)),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: googleAccounts.map((acc) {
                    return ListTile(
                      leading: UserAccountManager.buildUserAvatar(acc, radius: 20),
                      title: Text(acc['nickname'] ?? 'Criador', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(acc['email'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      onTap: () => Navigator.pop(ctx, acc),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ],
            ),
          );
          if (picked != null) {
            chosenEmail = picked['email'];
            chosenName = picked['nickname'];
            chosenPhotoUrl = picked['avatarUrl'];
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isGoogleBusy = false);
    }

    if (chosenEmail == null || chosenEmail.isEmpty || !mounted) {
      if (Platform.isWindows) {
        _showError('No Windows, regista primeiro a conta abaixo ou configura o ClientID OAuth Desktop.');
      }
      return;
    }

    final existingUser = await UserAccountManager.findRegisteredUser(chosenEmail);

    if (isNewRegister) {
      if (existingUser != null) {
        _showError('A conta Google $chosenEmail já está registada! Usa "Entrar na Conta".');
        setState(() => _isRegisterMode = false);
        return;
      }

      final completedUser = await _openGoogleCompleteRegistrationModal(
        email: chosenEmail,
        displayName: chosenName ?? chosenEmail.split('@').first,
        photoUrl: chosenPhotoUrl,
      );
