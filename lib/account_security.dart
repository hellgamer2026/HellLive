import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserAccountManager {
  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('hell_user_profile');
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hell_user_profile', jsonEncode(user));
  }

  static Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hell_user_profile');
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
  bool _isRegister = false;
  bool _obscurePass = true;

  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _nickCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogleAndAutoRegister() async {
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null || !mounted) return;

      // Diálogo de Partilha de Informações & Confirmação de Identidade
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0B1636),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFF38BDF8))),
          title: const Row(
            children: [
              Icon(Icons.verified_user, color: Color(0xFF38BDF8)),
              SizedBox(width: 8),
              Expanded(child: Text('Partilha de Informações Google', style: TextStyle(fontSize: 15.5))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Confirmas que és ${account.displayName ?? account.email}?', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('• Email: ${account.email}', style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
              Text('• Nome: ${account.displayName ?? 'Criador Google'}', style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
              const SizedBox(height: 10),
              const Text(
                'O teu pré-registo será preenchido automaticamente e entrarás direto na app. Poderás completar dados opcionais mais tarde no teu Perfil.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF7DD3FC)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar e Entrar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final parts = (account.displayName ?? '').split(' ');
        final user = {
          'firstName': parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : 'Criador',
          'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
          'nickname': account.displayName ?? account.email.split('@').first,
          'email': account.email,
          'phone': '',
          'country': '',
          'city': '',
          'address': '',
          'discord': '',
          'whatsapp': '',
          'provider': 'google',
          'avatarPath': null,
          'bio': 'A transmitir com o HELL Live!',
          'status': 'online',
          'followers': 12,
          'following': 5,
          'publicEmail': false,
          'publicPhone': false,
          'publicAddress': false,
          'publicStats': true,
          'securityMethods': <String>[],
          'pinSecret': '',
          'passwordSecret': '',
          'patternSecret': '',
        };
        await UserAccountManager.saveUser(user);
        widget.onAuthenticated(user);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o seletor Google neste dispositivo. Usa email ou cria registo abaixo.')),
        );
      }
    }
  }

  void _completeManualLogin() async {
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insere o teu email para continuar.')));
      return;
    }
    final existing = await UserAccountManager.getSavedUser();
    if (!_isRegister && existing != null) {
      widget.onAuthenticated(existing);
      return;
    }

    final fullName = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();
    final nick = _nickCtrl.text.trim().isEmpty
        ? (fullName.isEmpty ? _emailCtrl.text.trim().split('@').first : fullName)
        : _nickCtrl.text.trim();

    final user = {
      'firstName': _firstNameCtrl.text.trim().isEmpty ? 'Criador' : _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'nickname': nick,
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'country': _countryCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'discord': '',
      'whatsapp': '',
      'provider': 'email',
      'avatarPath': null,
      'bio': 'A transmitir com o HELL Live!',
      'status': 'online',
      'followers': 12,
      'following': 5,
      'publicEmail': false,
      'publicPhone': false,
      'publicAddress': false,
      'publicStats': true,
      'securityMethods': <String>[],
      'pinSecret': '',
      'passwordSecret': '',
      'patternSecret': '',
    };
    await UserAccountManager.saveUser(user);
    widget.onAuthenticated(user);
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
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 96,
                      height: 96,
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
                      child: Image.asset('icon.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, size: 72, color: Color(0xFF38BDF8))),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('HELL ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white)),
                      Text('Live', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Color(0xFF38BDF8))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRegister ? 'Cria o teu perfil oficial de criador' : 'Inicia sessão na tua conta HELL Live',
                    style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF1E429F)),
                    ),
                    child: Column(
                      children: [
                        if (_isRegister) ...[
                          Row(
                            children: [
                              Expanded(child: TextField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'Nome *', isDense: true))),
                              const SizedBox(width: 8),
                              Expanded(child: TextField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Apelido *', isDense: true))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(controller: _nickCtrl, decoration: const InputDecoration(labelText: 'Nome de Criador / Nickname *', prefixIcon: Icon(Icons.alternate_email), isDense: true)),
                          const SizedBox(height: 10),
                          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contacto Telefónico', prefixIcon: Icon(Icons.phone_outlined), isDense: true)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: _countryCtrl, decoration: const InputDecoration(labelText: 'País / Região', isDense: true))),
                              const SizedBox(width: 8),
                              Expanded(child: TextField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'Cidade', isDense: true))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Morada Completa (Opcional)', prefixIcon: Icon(Icons.home_outlined), isDense: true)),
                          const SizedBox(height: 10),
                        ],
                        TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email_outlined), isDense: true)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          decoration: InputDecoration(
                            labelText: 'Palavra-passe *',
                            prefixIcon: const Icon(Icons.lock_outline),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF38BDF8)),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 14)),
                            onPressed: _completeManualLogin,
                            child: Text(_isRegister ? 'Registar & Entrar' : 'Entrar na Conta', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white24)),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('ou entrar rapidamente com', style: TextStyle(fontSize: 11.5, color: Colors.white54))),
                            Expanded(child: Divider(color: Colors.white24)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 11), side: const BorderSide(color: Colors.white24)),
                                onPressed: _signInWithGoogleAndAutoRegister,
                                icon: const Icon(Icons.g_mobiledata, size: 24, color: Colors.redAccent),
                                label: const Text('Google', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 11), side: const BorderSide(color: Colors.white24)),
                                onPressed: () => setState(() => _isRegister = true),
                                icon: const Icon(Icons.apple, size: 22, color: Colors.white),
                                label: const Text('Apple / iOS', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    child: Text(
                      _isRegister ? 'Já tens conta? Iniciar Sessão' : 'Ainda não tens conta? Criar Registo Completo',
                      style: const TextStyle(color: Color(0xFF38BDF8)),
                    ),
                  ),
                ],
              ),
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

  void _togglePatternNode(int node) {
    if (!_selectedPattern.contains(node)) {
      setState(() => _selectedPattern.add(node));
    }
    if (_selectedPattern.join('-') == (widget.user['patternSecret'] ?? '')) {
      widget.onUnlocked();
    }
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
                  const Icon(Icons.lock_person_rounded, size: 60, color: Color(0xFF38BDF8)),
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
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: const Color(0xFF1E78FF),
                      backgroundImage: widget.user['avatarPath'] != null ? FileImage(File(widget.user['avatarPath'])) : null,
                      child: widget.user['avatarPath'] == null ? const Icon(Icons.person, size: 42, color: Colors.white) : null,
                    ),
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
              TextField(controller: _discordCtrl, decoration: const InputDecoration(labelText: 'Link / Tag Discord', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _whatsappCtrl, decoration: const InputDecoration(labelText: 'Grupo / Contacto WhatsApp', isDense: true)),
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
              const Text('🔐 Segurança & Bloqueio Multi-Método (Ativa 1, 2 ou Todos)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 6),
              SwitchListTile(
                dense: true,
                title: const Text('Impressão Digital / Face ID (Biometria)'),
                value: _securityMethods.contains('biometric'),
                onChanged: (v) => _toggleSecurityMethod('biometric', v),
              ),
              SwitchListTile(
                dense: true,
                title: const Text('PIN Numérico'),
                value: _securityMethods.contains('pin'),
                onChanged: (v) => _toggleSecurityMethod('pin', v),
              ),
              SwitchListTile(
                dense: true,
                title: const Text('Senha Forte'),
                value: _securityMethods.contains('password'),
                onChanged: (v) => _toggleSecurityMethod('password', v),
              ),
              SwitchListTile(
                dense: true,
                title: const Text('Padrão Desenhado (3×3)'),
                value: _securityMethods.contains('pattern'),
                onChanged: (v) => _toggleSecurityMethod('pattern', v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: _saveProfile,
          icon: const Icon(Icons.save, color: Colors.white),
          label: const Text('Guardar Todas as Alterações', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Terminar Sessão'),
        ),
      ],
    );
  }
}
