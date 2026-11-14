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
  static const String _activeKey = 'hell_user_profile';
  static const String _dbKey = 'hell_registered_users_db';
  static const String _credsKey = 'hell_saved_credentials';

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeKey);
    return raw == null ? null : Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<List<Map<String, dynamic>>> getAllRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dbKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<Map<String, dynamic>?> findRegisteredUser(String id) async {
    final clean = id.trim().toLowerCase();
    if (clean.isEmpty) return null;
    for (final u in await getAllRegisteredUsers()) {
      final email = (u['email'] ?? '').toString().trim().toLowerCase();
      final nick = (u['nickname'] ?? '').toString().trim().toLowerCase();
      final phone = (u['phone'] ?? '').toString().trim();
      if (email == clean || nick == clean || (phone.isNotEmpty && phone == id.trim())) return u;
    }
    return null;
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    final email = (user['email'] ?? '').toString().trim().toLowerCase();
    final users = await getAllRegisteredUsers();
    users.removeWhere((u) => (u['email'] ?? '').toString().trim().toLowerCase() == email);
    users.insert(0, user);
    await prefs.setString(_dbKey, jsonEncode(users));
    await prefs.setString(_activeKey, jsonEncode(user));
  }

  static Future<List<Map<String, String>>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_credsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Map<String, String>.from(e)).toList();
  }

  static Future<void> saveCredentials(String email, String username, String password) async {
    if (password.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = await getSavedCredentials();
    list.removeWhere((c) => c['email']?.toLowerCase() == email.toLowerCase());
    list.insert(0, {'email': email, 'username': username, 'password': password});
    await prefs.setString(_credsKey, jsonEncode(list));
  }

  static Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeKey);
  }

  static Widget buildUserAvatar(Map<String, dynamic> user, {double radius = 36}) {
    final path = (user['avatarPath'] ?? '').toString();
    final url = (user['avatarUrl'] ?? '').toString();
    if (path.isNotEmpty && File(path).existsSync()) {
      return CircleAvatar(radius: radius, backgroundColor: const Color(0xFF1E78FF), backgroundImage: FileImage(File(path)));
    }
    if (url.startsWith('http')) {
      return CircleAvatar(radius: radius, backgroundColor: const Color(0xFF1E78FF), backgroundImage: NetworkImage(url));
    }
    return CircleAvatar(radius: radius, backgroundColor: const Color(0xFF1E78FF), child: Icon(Icons.person, size: radius, color: Colors.white));
  }

  static Color statusColor(String status) {
    if (status == 'dnd') return Colors.orange;
    if (status == 'invisible') return Colors.white;
    if (status == 'offline') return Colors.redAccent;
    return Colors.green;
  }

  static String statusLabel(String status) {
    if (status == 'dnd') return 'Não Incomodar';
    if (status == 'invisible') return 'Invisível';
    if (status == 'offline') return 'Offline';
    return 'Online';
  }
}
class AuthScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegister = false;
  bool _obscure = true;
  bool _busy = false;
  final _nickCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: Colors.redAccent));
  }

  Future<void> _googleAuth() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final gs = GoogleSignIn(scopes: ['email', 'profile']);
      await gs.signOut();
      final acc = await gs.signIn();
      if (acc == null) return;

      final existing = await UserAccountManager.findRegisteredUser(acc.email);
      if (_isRegister) {
        if (existing != null) {
          _msg('Conta Google já registada. Usa "Entrar".');
          setState(() => _isRegister = false);
          return;
        }
        final user = _buildProfile(
          nickname: acc.displayName ?? acc.email.split('@').first,
          email: acc.email,
          provider: 'google',
          avatarUrl: acc.photoUrl ?? '',
        );
        await UserAccountManager.saveUser(user);
        if (mounted) widget.onAuthenticated(user);
      } else {
        if (existing == null) {
          _msg('Conta Google não registada. Cria primeiro o registo.');
          setState(() => _isRegister = true);
          return;
        }
        if ((acc.photoUrl ?? '').isNotEmpty) existing['avatarUrl'] = acc.photoUrl;
        await UserAccountManager.saveUser(existing);
        if (mounted) widget.onAuthenticated(existing);
      }
    } catch (_) {
      _msg('Erro ao ligar ao Google. Usa o registo/login manual abaixo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, dynamic> _buildProfile({
    required String nickname,
    required String email,
    required String provider,
    String password = '',
    String phone = '',
    String avatarUrl = '',
  }) {
    final parts = nickname.trim().split(' ');
    return {
      'firstName': parts.first,
      'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
      'nickname': nickname.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'provider': provider,
      'avatarPath': null,
      'avatarUrl': avatarUrl,
      'bio': 'A transmitir com o HELL Live!',
      'status': 'online',
      'securityMethods': password.isNotEmpty ? <String>['password'] : <String>[],
      'pinSecret': '',
      'passwordSecret': password,
      'patternSecret': '',
    };
  }

  Future<void> _submitManual() async {
    final id = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (id.isEmpty || pass.length < 4) {
      _msg('Preenche o email/utilizador e senha (mínimo 4 caracteres).');
      return;
    }

    final existing = await UserAccountManager.findRegisteredUser(id);
    if (_isRegister) {
      if (existing != null) {
        _msg('Conta já registada. Usa "Entrar".');
        setState(() => _isRegister = false);
        return;
      }
      final email = id.contains('@') ? id : '$id@helllive.app';
      final nick = _nickCtrl.text.trim().isEmpty ? id.split('@').first : _nickCtrl.text.trim();
      final user = _buildProfile(nickname: nick, email: email, provider: 'manual', password: pass, phone: _phoneCtrl.text);
      await UserAccountManager.saveCredentials(email, nick, pass);
      await UserAccountManager.saveUser(user);
      if (mounted) widget.onAuthenticated(user);
    } else {
      if (existing == null) {
        _msg('Conta não encontrada. Cria primeiro o registo.');
        setState(() => _isRegister = true);
        return;
      }
      if ((existing['passwordSecret'] ?? '') != pass) {
        _msg('Palavra-passe incorreta.');
        return;
      }
      await UserAccountManager.saveUser(existing);
      if (mounted) widget.onAuthenticated(existing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B1E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const Text('HELL LIVE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF38BDF8), letterSpacing: 2)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: !_isRegister ? const Color(0xFF1E78FF) : const Color(0xFF0E1D47)), onPressed: () => setState(() => _isRegister = false), child: const Text('Entrar', style: TextStyle(color: Colors.white)))),
                    const SizedBox(width: 8),
                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _isRegister ? const Color(0xFF1E78FF) : const Color(0xFF0E1D47)), onPressed: () => setState(() => _isRegister = true), child: const Text('Criar Registo', style: TextStyle(color: Colors.white)))),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: _busy ? null : _googleAuth,
                    icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.redAccent),
                    label: Text(_isRegister ? 'Registar com Google' : 'Entrar com Google'),
                  ),
                ),
                const SizedBox(height: 14),
                if (_isRegister) ...[
                  TextField(controller: _nickCtrl, decoration: const InputDecoration(labelText: 'Nome de Criador', isDense: true)),
                  const SizedBox(height: 10),
                  TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telemóvel (Opcional)', isDense: true)),
                  const SizedBox(height: 10),
                ],
                TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email ou Utilizador', isDense: true)),
                const SizedBox(height: 10),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Palavra-passe',
                    isDense: true,
                    suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure)),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: _submitManual,
                    child: Text(_isRegister ? 'Concluir Registo' : 'Entrar Agora', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class AppLockScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onUnlocked;
  final VoidCallback onLogout;
  const AppLockScreen({super.key, required this.user, required this.onUnlocked, required this.onLogout});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _localAuth = LocalAuthentication();
  final _ctrl = TextEditingController();
  String _error = '';

  List<String> get _methods => List<String>.from(widget.user['securityMethods'] ?? []);

  @override
  void initState() {
    super.initState();
    if (_methods.contains('biometric')) _tryBio();
  }

  Future<void> _tryBio() async {
    try {
      final ok = await _localAuth.authenticate(localizedReason: 'Desbloqueia o HELL Live');
      if (ok) widget.onUnlocked();
    } catch (_) {
      setState(() => _error = 'Falha na biometria. Usa a senha abaixo.');
    }
  }

  void _check() {
    final val = _ctrl.text.trim();
    if (val == (widget.user['pinSecret'] ?? '') || val == (widget.user['passwordSecret'] ?? '')) {
      widget.onUnlocked();
    } else {
      setState(() => _error = 'PIN ou senha incorretos.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B1E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                UserAccountManager.buildUserAvatar(widget.user, radius: 38),
                const SizedBox(height: 12),
                Text('Olá, ${widget.user['nickname'] ?? 'Criador'}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_methods.contains('biometric'))
                  ElevatedButton.icon(onPressed: _tryBio, icon: const Icon(Icons.fingerprint), label: const Text('Desbloquear com Biometria')),
                const SizedBox(height: 12),
                TextField(controller: _ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'PIN ou Palavra-passe', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)), onPressed: _check, child: const Text('Entrar', style: TextStyle(color: Colors.white))),
                ),
                if (_error.isNotEmpty) ...[const SizedBox(height: 8), Text(_error, style: const TextStyle(color: Colors.redAccent))],
                TextButton(onPressed: widget.onLogout, child: const Text('Trocar Conta', style: TextStyle(color: Colors.white54))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePrivacySecurityScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(Map<String, dynamic>) onUserUpdated;
  final VoidCallback onLogout;
  const ProfilePrivacySecurityScreen({super.key, required this.user, required this.onUserUpdated, required this.onLogout});

  @override
  State<ProfilePrivacySecurityScreen> createState() => _ProfilePrivacySecurityScreenState();
}

class _ProfilePrivacySecurityScreenState extends State<ProfilePrivacySecurityScreen> {
  late TextEditingController _nickCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _phoneCtrl;
  late String _status;
  late List<String> _methods;

  @override
  void initState() {
    super.initState();
    _nickCtrl = TextEditingController(text: widget.user['nickname'] ?? '');
    _bioCtrl = TextEditingController(text: widget.user['bio'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.user['phone'] ?? '');
    _status = widget.user['status'] ?? 'online';
    _methods = List<String>.from(widget.user['securityMethods'] ?? []);
  }

  Future<void> _save() async {
    final updated = Map<String, dynamic>.from(widget.user);
    updated['nickname'] = _nickCtrl.text.trim();
    updated['bio'] = _bioCtrl.text.trim();
    updated['phone'] = _phoneCtrl.text.trim();
    updated['status'] = _status;
    updated['securityMethods'] = _methods;
    await UserAccountManager.saveUser(updated);
    widget.onUserUpdated(updated);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: GestureDetector(
            onTap: () async {
              final res = await FilePicker.platform.pickFiles(type: FileType.image);
              if (res != null && res.files.single.path != null) {
                final updated = Map<String, dynamic>.from(widget.user);
                updated['avatarPath'] = res.files.single.path!;
                await UserAccountManager.saveUser(updated);
                widget.onUserUpdated(updated);
              }
            },
            child: UserAccountManager.buildUserAvatar(widget.user, radius: 42),
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: _nickCtrl, decoration: const InputDecoration(labelText: 'Nickname')),
        const SizedBox(height: 8),
        TextField(controller: _bioCtrl, decoration: const InputDecoration(labelText: 'Bio')),
        const SizedBox(height: 8),
        TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Telemóvel')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _status,
          items: const [
            DropdownMenuItem(value: 'online', child: Text('Online')),
            DropdownMenuItem(value: 'dnd', child: Text('Não Incomodar')),
            DropdownMenuItem(value: 'invisible', child: Text('Invisível')),
            DropdownMenuItem(value: 'offline', child: Text('Offline')),
          ],
          onChanged: (v) => setState(() => _status = v ?? 'online'),
        ),
        SwitchListTile(
          title: const Text('Bloqueio por Biometria'),
          value: _methods.contains('biometric'),
          onChanged: (v) => setState(() => v ? _methods.add('biometric') : _methods.remove('biometric')),
        ),
        const SizedBox(height: 12),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)), onPressed: _save, child: const Text('Guardar', style: TextStyle(color: Colors.white))),
        TextButton(onPressed: widget.onLogout, child: const Text('Terminar Sessão', style: TextStyle(color: Colors.redAccent))),
      ],
    );
  }
}
