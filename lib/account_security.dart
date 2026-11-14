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

      if (completedUser != null && mounted) {
        await UserAccountManager.saveUser(completedUser);
        widget.onAuthenticated(completedUser);
      }
      return;
    }

    if (existingUser == null) {
      _showError('A conta Google $chosenEmail não está registada no HELL Live. Cria primeiro o registo.');
      setState(() => _isRegisterMode = true);
      return;
    }

    if (chosenPhotoUrl != null && chosenPhotoUrl.isNotEmpty) {
      existingUser['avatarUrl'] = chosenPhotoUrl;
    }

    final methods = List<String>.from(existingUser['securityMethods'] ?? []);
    if (methods.isNotEmpty) {
      final unlocked = await _verifyUnlockOnLogin(existingUser);
      if (!unlocked) return;
    }

    if (existingUser['phoneAlertsEnabled'] == true && (existingUser['phone'] ?? '').toString().isNotEmpty) {
      final smsOk = await _verifyPhoneSmsCode(existingUser['phone'].toString());
      if (!smsOk) return;
    }

    await UserAccountManager.saveUser(existingUser);
    if (mounted) widget.onAuthenticated(existingUser);
  }
  Future<Map<String, dynamic>?> _openGoogleCompleteRegistrationModal({
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    final nickController = TextEditingController(text: displayName);
    final phoneController = TextEditingController();
    final secretController = TextEditingController();
    String selectedUnlock = 'pin';
    bool useBiometric = false;
    final LocalAuthentication localAuth = LocalAuthentication();

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF0B1636),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
          title: const Row(
            children: [
              Icon(Icons.verified_user, color: Color(0xFF38BDF8)),
              SizedBox(width: 8),
              Expanded(child: Text('Concluir Registo Google', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF1E78FF),
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                  child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, size: 36, color: Colors.white) : null,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF050B1E), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 6),
                      Flexible(child: Text(email, style: const TextStyle(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nickController,
                  decoration: const InputDecoration(labelText: 'Nome de Criador / Nickname', prefixIcon: Icon(Icons.person_outline), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telemóvel (Opcional - Alertas SMS 2FA)', prefixIcon: Icon(Icons.phone_android), isDense: true),
                ),
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Método de desbloqueio para entrar na app:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('PIN Numérico', style: TextStyle(fontSize: 12)),
                      selected: selectedUnlock == 'pin',
                      selectedColor: const Color(0xFF1E78FF),
                      onSelected: (_) => setModalState(() {
                        selectedUnlock = 'pin';
                        secretController.clear();
                      }),
                    ),
                    ChoiceChip(
                      label: const Text('Senha', style: TextStyle(fontSize: 12)),
                      selected: selectedUnlock == 'password',
                      selectedColor: const Color(0xFF1E78FF),
                      onSelected: (_) => setModalState(() {
                        selectedUnlock = 'password';
                        secretController.clear();
                      }),
                    ),
                    ChoiceChip(
                      label: const Text('Padrão (3×3)', style: TextStyle(fontSize: 12)),
                      selected: selectedUnlock == 'pattern',
                      selectedColor: const Color(0xFF1E78FF),
                      onSelected: (_) => setModalState(() {
                        selectedUnlock = 'pattern';
                        secretController.clear();
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: secretController,
                  obscureText: true,
                  keyboardType: selectedUnlock == 'password' ? TextInputType.text : TextInputType.number,
                  decoration: InputDecoration(
                    labelText: selectedUnlock == 'pin'
                        ? 'Cria um PIN (mínimo 4 dígitos)'
                        : (selectedUnlock == 'password' ? 'Cria uma Senha Forte' : 'Padrão (ex: 12369)'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    isDense: true,
                  ),
                ),
                CheckboxListTile(
                  value: useBiometric,
                  onChanged: (val) async {
                    if (val == true) {
                      try {
                        final canCheck = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
                        if (!canCheck) return;
                      } catch (_) {}
                    }
                    setModalState(() => useBiometric = val ?? false);
                  },
                  title: const Text('Ativar também Biometria / Face ID', style: TextStyle(fontSize: 12)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
              onPressed: () {
                final secret = secretController.text.trim();
                if (secret.length < 4) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Define um código/senha com pelo menos 4 caracteres.')),
                  );
                  return;
                }
                final methods = <String>[selectedUnlock];
                if (useBiometric) methods.add('biometric');

                final finalNick = nickController.text.trim().isEmpty ? displayName : nickController.text.trim();
                final parts = finalNick.split(' ');
                Navigator.pop(ctx, {
                  'firstName': parts.first,
                  'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
                  'nickname': finalNick,
                  'email': email,
                  'phone': phoneController.text.trim(),
                  'phoneAlertsEnabled': phoneController.text.trim().isNotEmpty,
                  'country': '',
                  'city': '',
                  'address': '',
                  'discord': '',
                  'whatsapp': '',
                  'provider': 'google',
                  'avatarPath': null,
                  'avatarUrl': photoUrl ?? '',
                  'bio': 'A transmitir com o HELL Live!',
                  'status': 'online',
                  'followers': 12,
                  'following': 5,
                  'publicEmail': false,
                  'publicPhone': false,
                  'publicAddress': false,
                  'publicStats': true,
                  'securityMethods': methods,
                  'pinSecret': selectedUnlock == 'pin' ? secret : '',
                  'passwordSecret': selectedUnlock == 'password' ? secret : '',
                  'patternSecret': selectedUnlock == 'pattern' ? secret : '',
                });
              },
              child: const Text('Concluir Registo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
  Future<bool> _verifyUnlockOnLogin(Map<String, dynamic> user) async {
    final methods = List<String>.from(user['securityMethods'] ?? []);
    if (methods.isEmpty) return true;

    String activeMethod = methods.first;
    final secretCtrl = TextEditingController();
    String errorMsg = '';
    final LocalAuthentication localAuth = LocalAuthentication();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF0B1636),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
          title: Row(
            children: [
              UserAccountManager.buildUserAvatar(user, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['nickname'] ?? 'Conta Google', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(user['email'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Desbloqueia o acesso à tua conta:', style: TextStyle(fontSize: 12.5, color: Colors.white70)),
              const SizedBox(height: 10),
              if (methods.length > 1)
                Wrap(
                  spacing: 6,
                  children: methods.map((m) {
                    final labels = {'biometric': 'Biometria', 'pin': 'PIN', 'password': 'Senha', 'pattern': 'Padrão'};
                    return ChoiceChip(
                      label: Text(labels[m] ?? m, style: const TextStyle(fontSize: 11.5)),
                      selected: activeMethod == m,
                      selectedColor: const Color(0xFF1E78FF),
                      onSelected: (_) => setModalState(() {
                        activeMethod = m;
                        errorMsg = '';
                        secretCtrl.clear();
                      }),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),
              if (activeMethod == 'biometric')
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                  onPressed: () async {
                    try {
                      final ok = await localAuth.authenticate(
                        localizedReason: 'Confirma a tua identidade no HELL Live',
                        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
                      );
                      if (ok && ctx.mounted) Navigator.pop(ctx, true);
                    } catch (_) {
                      setModalState(() => errorMsg = 'Falha na biometria. Tenta outro método.');
                    }
                  },
                  icon: const Icon(Icons.fingerprint, color: Colors.white),
                  label: const Text('Validar Biometria / Face ID', style: TextStyle(color: Colors.white)),
                )
              else
                TextField(
                  controller: secretCtrl,
                  obscureText: true,
                  keyboardType: activeMethod == 'password' ? TextInputType.text : TextInputType.number,
                  decoration: InputDecoration(
                    labelText: activeMethod == 'pin' ? 'Insere o teu PIN' : (activeMethod == 'password' ? 'Insere a Senha' : 'Sequência do Padrão (ex: 12369)'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              if (errorMsg.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(errorMsg, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            if (activeMethod != 'biometric')
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                onPressed: () {
                  final input = secretCtrl.text.trim();
                  final expected = activeMethod == 'pin'
                      ? (user['pinSecret'] ?? '').toString()
                      : (activeMethod == 'password' ? (user['passwordSecret'] ?? '').toString() : (user['patternSecret'] ?? '').toString());
                  if (input.isNotEmpty && input == expected) {
                    Navigator.pop(ctx, true);
                  } else {
                    setModalState(() => errorMsg = 'Código ou senha incorretos.');
                  }
                },
                child: const Text('Entrar', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
    return result == true;
  }

  Future<bool> _verifyPhoneSmsCode(String phone) async {
    final code = (100000 + Random().nextInt(900000)).toString();
    final smsUri = Uri.parse('sms:$phone?body=${Uri.encodeComponent("HELL LIVE SEGURANÇA: Código de aprovação de acesso: $code")}');
    try {
      await launchUrl(smsUri, mode: LaunchMode.externalApplication);
    } catch (_) {}

    if (!mounted) return false;
    final codeCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1636),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Colors.amberAccent, width: 1.5)),
        title: const Row(
          children: [
            Icon(Icons.sms_outlined, color: Colors.amberAccent),
            SizedBox(width: 8),
            Expanded(child: Text('Aprovação por SMS', style: TextStyle(fontSize: 15.5))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código enviado para $phone: $code', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
            const SizedBox(height: 10),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Insere o código SMS para aprovar', isDense: true, border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Rejeitar', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              if (codeCtrl.text.trim() == code) Navigator.pop(ctx, true);
            },
            child: const Text('Sim, sou eu (Aprovar)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result == true;
  }
  void _submitForm() async {
    if (_isRegisterMode) {
      final idText = _identifierCtrl.text.trim();
      final passText = _passCtrl.text.trim();
      if (idText.isEmpty || passText.length < 4) {
        _showError('Preenche o email/utilizador e uma palavra-passe com pelo menos 4 caracteres.');
        return;
      }

      final existing = await UserAccountManager.findRegisteredUser(idText);
      if (existing != null) {
        _showError('Esta conta já está registada! Usa "Entrar na Conta".');
        setState(() => _isRegisterMode = false);
        return;
      }

      final isEmail = idText.contains('@');
      final email = isEmail ? idText : '$idText@helllive.app';
      final nick = _nickCtrl.text.trim().isEmpty ? (isEmail ? idText.split('@').first : idText) : _nickCtrl.text.trim();

      if (_rememberPassword) {
        await UserAccountManager.saveCredentials(email, nick, passText);
      }

      final user = {
        'firstName': nick,
        'lastName': '',
        'nickname': nick,
        'email': email,
        'phone': _phoneCtrl.text.trim(),
        'phoneAlertsEnabled': _phoneCtrl.text.trim().isNotEmpty,
        'country': '',
        'city': '',
        'address': '',
        'discord': '',
        'whatsapp': '',
        'provider': 'manual',
        'avatarPath': null,
        'avatarUrl': '',
        'bio': 'A transmitir com o HELL Live!',
        'status': 'online',
        'followers': 12,
        'following': 5,
        'publicEmail': false,
        'publicPhone': false,
        'publicAddress': false,
        'publicStats': true,
        'securityMethods': <String>['password'],
        'pinSecret': '',
        'passwordSecret': passText,
        'patternSecret': '',
      };
      await UserAccountManager.saveUser(user);
      widget.onAuthenticated(user);
      return;
    }

    if (_loginMethod == 'phone') {
      final phone = _phoneCtrl.text.trim();
      if (phone.isEmpty) {
        _showError('Insere o teu número de telemóvel registado.');
        return;
      }
      final existing = await UserAccountManager.findRegisteredUser(phone);
      if (existing == null) {
        _showError('Este número não pertence a nenhuma conta registada.');
        return;
      }
      final ok = await _verifyPhoneSmsCode(phone);
      if (!ok) return;
      await UserAccountManager.saveUser(existing);
      widget.onAuthenticated(existing);
      return;
    }

    final idText = _identifierCtrl.text.trim();
    final passText = _passCtrl.text.trim();
    if (idText.isEmpty) {
      _showError('Insere o email ou nome de utilizador registado.');
      return;
    }

    final existing = await UserAccountManager.findRegisteredUser(idText);
    if (existing == null) {
      _showError('Conta não encontrada! Cria primeiro o teu registo.');
      return;
    }

    final savedPass = (existing['passwordSecret'] ?? '').toString();
    if (savedPass.isNotEmpty && passText != savedPass) {
      _showError('Palavra-passe incorreta para esta conta.');
      return;
    }

    if (_rememberPassword && passText.isNotEmpty) {
      await UserAccountManager.saveCredentials(existing['email'] ?? idText, existing['nickname'] ?? idText, passText);
    }

    if (existing['phoneAlertsEnabled'] == true && (existing['phone'] ?? '').toString().isNotEmpty) {
      final ok = await _verifyPhoneSmsCode(existing['phone'].toString());
      if (!ok) return;
    }

    await UserAccountManager.saveUser(existing);
    widget.onAuthenticated(existing);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B1E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E78FF).withOpacity(0.35 + (_pulseCtrl.value * 0.3)),
                            blurRadius: 22 + (_pulseCtrl.value * 16),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Image.asset('icon.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, size: 68, color: Color(0xFF38BDF8))),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('HELL ', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white)),
                      Text('LIVE', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF38BDF8))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFF0B1636), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1E429F))),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isRegisterMode = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isRegisterMode ? const Color(0xFF1E78FF) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(child: Text('Entrar na Conta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5))),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isRegisterMode = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isRegisterMode ? const Color(0xFF1E78FF) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(child: Text('Criar Registo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isGoogleBusy ? null : () => _handleGoogleAuth(isNewRegister: _isRegisterMode),
                      icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.redAccent),
                      label: Text(
                        _isRegisterMode ? 'Registar com Google (Automático)' : 'Entrar com Conta Google Registada',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF1E429F)),
                    ),
                    child: Column(
                      children: [
                        if (!_isRegisterMode) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Email / Utilizador', style: TextStyle(fontSize: 12))),
                                  selected: _loginMethod == 'email',
                                  selectedColor: const Color(0xFF1E78FF),
                                  onSelected: (_) => setState(() => _loginMethod = 'email'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Telemóvel (SMS)', style: TextStyle(fontSize: 12))),
                                  selected: _loginMethod == 'phone',
                                  selectedColor: const Color(0xFF1E78FF),
                                  onSelected: (_) => setState(() => _loginMethod = 'phone'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_isRegisterMode) ...[
                          const Text('Registo Manual:', style: TextStyle(fontSize: 12, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(controller: _nickCtrl, decoration: const InputDecoration(labelText: 'Nome de Utilizador', prefixIcon: Icon(Icons.person_outline), isDense: true)),
                          const SizedBox(height: 10),
                          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telemóvel para Alertas SMS (Opcional)', prefixIcon: Icon(Icons.phone_android), isDense: true)),
                          const SizedBox(height: 10),
                        ],
                        if (!_isRegisterMode && _loginMethod == 'phone')
                          TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Número de Telemóvel (Recebe Código SMS)',
                              prefixIcon: Icon(Icons.phone_android),
                              isDense: true,
                            ),
                          )
                        else ...[
                          Autocomplete<Map<String, String>>(
                            initialValue: TextEditingValue(text: _identifierCtrl.text),
                            optionsBuilder: (TextEditingValue textValue) {
                              if (textValue.text.isEmpty) return _savedAccounts;
                              final q = textValue.text.toLowerCase();
                              return _savedAccounts.where((acc) =>
                                  (acc['email'] ?? '').toLowerCase().contains(q) || (acc['username'] ?? '').toLowerCase().contains(q));
                            },
                            displayStringForOption: (opt) => opt['email'] ?? opt['username'] ?? '',
                            onSelected: (selection) {
                              setState(() {
                                _identifierCtrl.text = selection['email'] ?? selection['username'] ?? '';
                                _passCtrl.text = selection['password'] ?? '';
                              });
                            },
                            fieldViewBuilder: (ctx, fieldCtrl, focusNode, onSubmit) {
                              fieldCtrl.addListener(() => _identifierCtrl.text = fieldCtrl.text);
                              return TextField(
                                controller: fieldCtrl,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Email ou Nome de Utilizador',
                                  prefixIcon: Icon(Icons.alternate_email),
                                  isDense: true,
                                ),
                              );
                            },
                          ),
class AppLockScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onUnlocked;
  final VoidCallback onLogout;

  const AppLockScreen({super.key, required this.user, required this.onUnlocked, required this.onLogout});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final TextEditingController _secretCtrl = TextEditingController();
  final List<int> _selectedPattern = [];
  String _error = '';
  String _activeMethod = 'pin';
  bool _obscureSecret = true;

  List<String> get _enabledMethods {
    final raw = widget.user['securityMethods'];
    if (raw is List && raw.isNotEmpty) return List<String>.from(raw);
    return [];
  }

  @override
  void initState() {
    super.initState();
    if (_enabledMethods.isNotEmpty) {
      _activeMethod = _enabledMethods.first;
      if (_activeMethod == 'biometric') _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!supported || !canCheck) {
        setState(() => _error = 'Biometria não configurada neste aparelho. Escolhe outro método ativo abaixo.');
        return;
      }
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Desbloqueia o HELL Live com a tua impressão digital ou rosto',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (didAuth) widget.onUnlocked();
    } catch (_) {
      setState(() => _error = 'Falha na leitura biométrica. Tenta novamente ou escolhe outro método.');
    }
  }

  void _verifySecret() {
    if (_activeMethod == 'pin') {
      if (_secretCtrl.text.trim() == (widget.user['pinSecret'] ?? '')) {
        widget.onUnlocked();
      } else {
        setState(() => _error = 'PIN incorreto. Tenta novamente.');
      }
    } else if (_activeMethod == 'password') {
      if (_secretCtrl.text.trim() == (widget.user['passwordSecret'] ?? '')) {
        widget.onUnlocked();
      } else {
        setState(() => _error = 'Senha incorreta. Tenta novamente.');
      }
    }
  }

  void _togglePatternNode(int idx) {
    setState(() {
      if (!_selectedPattern.contains(idx)) {
        _selectedPattern.add(idx);
      }
      final joined = _selectedPattern.join('');
      final dashed = _selectedPattern.join('-');
      final expected = (widget.user['patternSecret'] ?? '').toString();
      if (expected.isNotEmpty && (joined == expected || dashed == expected)) {
        widget.onUnlocked();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final methods = _enabledMethods;

    return Scaffold(
      backgroundColor: const Color(0xFF050B1E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UserAccountManager.buildUserAvatar(widget.user, radius: 40),
                  const SizedBox(height: 12),
                  Text('Olá, ${widget.user['nickname'] ?? 'Criador'}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Escolhe um dos teus métodos de desbloqueio ativos:', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 12.5)),
                  const SizedBox(height: 14),
                  if (methods.length > 1)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: methods.map((m) {
                        final labels = {'biometric': 'Biometria', 'pin': 'PIN', 'password': 'Senha', 'pattern': 'Padrão'};
                        return ChoiceChip(
                          label: Text(labels[m] ?? m),
                          selected: _activeMethod == m,
                          selectedColor: const Color(0xFF1E78FF),
                          onSelected: (_) {
                            setState(() {
                              _activeMethod = m;
                              _error = '';
                              _secretCtrl.clear();
                              _selectedPattern.clear();
                            });
                            if (m == 'biometric') _tryBiometric();
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),
                  if (_activeMethod == 'biometric')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                      onPressed: _tryBiometric,
                      icon: const Icon(Icons.fingerprint, color: Colors.white),
                      label: const Text('Desbloquear com Biometria / Face ID', style: TextStyle(color: Colors.white)),
                    ),
                  if (_activeMethod == 'pin' || _activeMethod == 'password') ...[
                    TextField(
                      controller: _secretCtrl,
                      obscureText: _obscureSecret,
                      keyboardType: _activeMethod == 'pin' ? TextInputType.number : TextInputType.text,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: _activeMethod == 'pin' ? 'Insere o teu PIN' : 'Insere a tua Senha',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureSecret ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: _verifySecret,
                        child: const Text('Desbloquear App', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                  if (_activeMethod == 'pattern') ...[
                    SizedBox(
                      width: 210,
                      height: 210,
                      child: GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: List.generate(9, (i) {
                          final idx = i + 1;
                          final active = _selectedPattern.contains(idx);
                          return GestureDetector(
                            onTap: () => _togglePatternNode(idx),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: active ? const Color(0xFF1E78FF) : const Color(0xFF0E1D47),
                                border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                              ),
                              child: Center(child: Text('$idx', style: const TextStyle(fontWeight: FontWeight.bold))),
                            ),
                          );
                        }),
                      ),
                    ),
                    TextButton(onPressed: () => setState(() => _selectedPattern.clear()), child: const Text('Limpar Desenho')),
                  ],
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 22),
                  TextButton(onPressed: widget.onLogout, child: const Text('Terminar Sessão / Trocar Conta', style: TextStyle(color: Colors.white54))),
                ],
              ),
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
  late TextEditingController _addressCtrl;
  late TextEditingController _discordCtrl;
  late TextEditingController _whatsappCtrl;

  final LocalAuthentication _localAuth = LocalAuthentication();
  late String _status;
  late bool _publicEmail;
  late bool _publicPhone;
  late bool _publicAddress;
  late bool _publicStats;
  late List<String> _securityMethods;
  late String _pinSecret;
  late String _passwordSecret;
  late String _patternSecret;

  @override
  void initState() {
    super.initState();
    _nickCtrl = TextEditingController(text: widget.user['nickname'] ?? '');
    _bioCtrl = TextEditingController(text: widget.user['bio'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.user['phone'] ?? '');
    _addressCtrl = TextEditingController(text: widget.user['address'] ?? '');
    _discordCtrl = TextEditingController(text: widget.user['discord'] ?? '');
    _whatsappCtrl = TextEditingController(text: widget.user['whatsapp'] ?? '');
    _status = widget.user['status'] ?? 'online';
    _publicEmail = widget.user['publicEmail'] ?? false;
    _publicPhone = widget.user['publicPhone'] ?? false;
    _publicAddress = widget.user['publicAddress'] ?? false;
    _publicStats = widget.user['publicStats'] ?? true;
    _securityMethods = List<String>.from(widget.user['securityMethods'] ?? []);
    _pinSecret = widget.user['pinSecret'] ?? '';
    _passwordSecret = widget.user['passwordSecret'] ?? '';
    _patternSecret = widget.user['patternSecret'] ?? '';
  }

  Future<void> _saveProfile() async {
    final updated = Map<String, dynamic>.from(widget.user);
    updated['nickname'] = _nickCtrl.text.trim();
    updated['bio'] = _bioCtrl.text.trim();
    updated['phone'] = _phoneCtrl.text.trim();
    updated['address'] = _addressCtrl.text.trim();
    updated['discord'] = _discordCtrl.text.trim();
    updated['whatsapp'] = _whatsappCtrl.text.trim();
    updated['status'] = _status;
    updated['publicEmail'] = _publicEmail;
    updated['publicPhone'] = _publicPhone;
    updated['publicAddress'] = _publicAddress;
    updated['publicStats'] = _publicStats;
    updated['securityMethods'] = _securityMethods;
    updated['pinSecret'] = _pinSecret;
    updated['passwordSecret'] = _passwordSecret;
    updated['patternSecret'] = _patternSecret;
    await UserAccountManager.saveUser(updated);
    widget.onUserUpdated(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Perfil, privacidade e segurança atualizados!')));
    }
  }

  Future<void> _toggleSecurityMethod(String method, bool enable) async {
    if (!enable) {
      setState(() => _securityMethods.remove(method));
      await _saveProfile();
      return;
    }

    if (method == 'biometric') {
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        final supported = await _localAuth.isDeviceSupported();
        if (!canCheck || !supported) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Este aparelho não tem sensor biométrico ou Face ID ativo.')),
            );
          }
          return;
        }
        final ok = await _localAuth.authenticate(
          localizedReason: 'Confirma a tua biometria para ativar no HELL Live',
          options: const AuthenticationOptions(biometricOnly: false),
        );
        if (ok) {
          setState(() {
            if (!_securityMethods.contains('biometric')) _securityMethods.add('biometric');
          });
          await _saveProfile();
        }
      } catch (_) {}
      return;
    }

    final ctrl = TextEditingController();
    final labels = {'pin': 'Novo PIN Numérico', 'password': 'Nova Senha Forte', 'pattern': 'Padrão (ex: 1-2-3-6-9)'};
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1636),
        title: Text('Configurar ${labels[method]}'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          keyboardType: method == 'pin' ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: labels[method]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  if (method == 'pin') _pinSecret = ctrl.text.trim();
                  if (method == 'password') _passwordSecret = ctrl.text.trim();
                  if (method == 'pattern') _patternSecret = ctrl.text.trim();
                  if (!_securityMethods.contains(method)) _securityMethods.add(method);
                });
                Navigator.pop(ctx);
                await _saveProfile();
              }
            },
            child: const Text('Ativar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusCol = UserAccountManager.statusColor(_status);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E429F)),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final res = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (res != null && res.files.single.path != null) {
                    final updated = Map<String, dynamic>.from(widget.user);
                    updated['avatarPath'] = res.files.single.path!;
                    await UserAccountManager.saveUser(updated);
                    widget.onUserUpdated(updated);
                  }
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    UserAccountManager.buildUserAvatar(widget.user, radius: 42),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(color: statusCol, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF050B1E), width: 2.5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('${widget.user['firstName'] ?? ''} ${widget.user['lastName'] ?? ''}'.trim(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text(widget.user['email'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.white60)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _status,
                dropdownColor: const Color(0xFF0B1636),
                decoration: const InputDecoration(labelText: 'Estado Atual na Comunidade', isDense: true),
                items: const [
                  DropdownMenuItem(value: 'online', child: Text('🟢 Online')),
                  DropdownMenuItem(value: 'dnd', child: Text('🟠 Não Incomodar')),
                  DropdownMenuItem(value: 'invisible', child: Text('⚪ Invisível (Furtivo)')),
                  DropdownMenuItem(value: 'offline', child: Text('🔴 Offline')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _status = v);
                    _saveProfile();
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF0B1636), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E429F))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('👤 Dados do Perfil (Opcionais e Editáveis)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 8),
              TextField(controller: _nickCtrl, decoration: const InputDecoration(labelText: 'Nome de Criador / Nickname', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _bioCtrl, decoration: const InputDecoration(labelText: 'Bio / Descrição', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Telemóvel', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Morada / Cidade', isDense: true)),
              const SizedBox(height: 8),
