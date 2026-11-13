class AppLockScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onUnlocked;
  final VoidCallback onLogout;

  const AppLockScreen({super.key, required this.user, required this.onUnlocked, required this.onLogout});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  final TextEditingController _secretCtrl = TextEditingController();
  final List<int> _patternPoints = [];
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    if (widget.user['securityType'] == 'biometric') {
      _triggerBiometric();
    }
  }

  Future<void> _triggerBiometric() async {
    try {
      final didAuth = await _auth.authenticate(
        localizedReason: 'Desbloqueia a tua conta HELL Live (Impressão Digital / Face ID)',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (didAuth) widget.onUnlocked();
    } catch (_) {
      setState(() => _errorMsg = 'Biometria indisponível neste dispositivo.');
    }
  }

  void _verifyTextSecret() {
    final saved = (widget.user['securitySecret'] ?? '').toString();
    if (_secretCtrl.text == saved) {
      widget.onUnlocked();
    } else {
      setState(() => _errorMsg = 'Código ou palavra-passe incorreta.');
    }
  }

  void _verifyPattern() {
    final saved = (widget.user['securitySecret'] ?? '').toString();
    if (_patternPoints.join('-') == saved) {
      widget.onUnlocked();
    } else {
      setState(() {
        _errorMsg = 'Padrão incorreto. Tenta novamente.';
        _patternPoints.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.user['securityType'] ?? 'none';

    return Scaffold(
      backgroundColor: const Color(0xFF050B1E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                children: [
                  Image.asset('icon.png', height: 64, errorBuilder: (_, __, ___) => const Icon(Icons.lock, size: 54, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 12),
                  Text('Olá, ${widget.user['nickname'] ?? 'Criador'}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Conta protegida · Desbloqueia para continuar', style: TextStyle(color: Colors.white60, fontSize: 12.5)),
                  const SizedBox(height: 24),
                  if (type == 'biometric') ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                      onPressed: _triggerBiometric,
                      icon: const Icon(Icons.fingerprint, size: 28, color: Colors.white),
                      label: const Text('Desbloquear com Biometria / Face ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ] else if (type == 'pin' || type == 'password') ...[
                    TextField(
                      controller: _secretCtrl,
                      obscureText: true,
                      keyboardType: type == 'pin' ? TextInputType.number : TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: type == 'pin' ? 'Insere o teu PIN (mín. 4 números)' : 'Insere a tua Senha Forte',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: _verifyTextSecret,
                        child: const Text('Desbloquear Conta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else if (type == 'pattern') ...[
                    const Text('Toca na sequência de pontos do teu padrão:', style: TextStyle(fontSize: 12.5, color: Colors.white70)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 18, mainAxisSpacing: 18),
                        itemCount: 9,
                        itemBuilder: (_, idx) {
                          final selected = _patternPoints.contains(idx);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (!selected) _patternPoints.add(idx);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected ? const Color(0xFF38BDF8) : const Color(0xFF0E1D47),
                                border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                              ),
                              child: Center(
                                child: Text(selected ? '${_patternPoints.indexOf(idx) + 1}' : '•', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(onPressed: () => setState(() => _patternPoints.clear()), child: const Text('Limpar')),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                          onPressed: _verifyPattern,
                          child: const Text('Confirmar Padrão', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                  if (_errorMsg.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_errorMsg, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 24),
                  TextButton(onPressed: widget.onLogout, child: const Text('Terminar Sessão (Logout)', style: TextStyle(color: Colors.white54))),
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

  const ProfilePrivacySecurityScreen({
    super.key,
    required this.user,
    required this.onUserUpdated,
    required this.onLogout,
  });

  @override
  State<ProfilePrivacySecurityScreen> createState() => _ProfilePrivacySecurityScreenState();
}

class _ProfilePrivacySecurityScreenState extends State<ProfilePrivacySecurityScreen> {
  late Map<String, dynamic> _u;
  late TextEditingController _nickCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _discordCtrl;
  late TextEditingController _whatsappCtrl;

  @override
  void initState() {
    super.initState();
    _u = Map<String, dynamic>.from(widget.user);
    _nickCtrl = TextEditingController(text: _u['nickname'] ?? '');
    _bioCtrl = TextEditingController(text: _u['bio'] ?? '');
    _discordCtrl = TextEditingController(text: _u['discord'] ?? '');
    _whatsappCtrl = TextEditingController(text: _u['whatsapp'] ?? '');
  }

  Future<void> _saveChanges() async {
    _u['nickname'] = _nickCtrl.text.trim().isEmpty ? 'Criador' : _nickCtrl.text.trim();
    _u['bio'] = _bioCtrl.text.trim();
    _u['discord'] = _discordCtrl.text.trim();
    _u['whatsapp'] = _whatsappCtrl.text.trim();
    await UserAccountManager.saveUser(_u);
    widget.onUserUpdated(_u);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil e definições guardados!')));
  }

  void _configureSecuritySecret(String type) {
    if (type == 'none' || type == 'biometric') {
      setState(() {
        _u['securityType'] = type;
        _u['securitySecret'] = '';
      });
      _saveChanges();
      return;
    }

    final secretCtrl = TextEditingController();
    final List<int> newPattern = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF0B1636),
          title: Text(
            type == 'pin'
                ? 'Definir PIN (Mín. 4 Números)'
                : (type == 'password' ? 'Definir Senha Forte (6+ Caracteres)' : 'Desenhar Padrão 3×3'),
            style: const TextStyle(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type == 'pin' || type == 'password')
                TextField(
                  controller: secretCtrl,
                  obscureText: true,
                  keyboardType: type == 'pin' ? TextInputType.number : TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    hintText: type == 'pin' ? 'Ex: 2580' : 'Ex: Hell@2026 (Letras, Nº e Símbolo)',
                  ),
                )
              else
                SizedBox(
                  width: 200,
                  height: 200,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 14, mainAxisSpacing: 14),
                    itemCount: 9,
                    itemBuilder: (_, idx) {
                      final sel = newPattern.contains(idx);
                      return GestureDetector(
                        onTap: () => setModalState(() {
                          if (!sel) newPattern.add(idx);
                        }),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sel ? const Color(0xFF38BDF8) : const Color(0xFF050B1E),
                            border: Border.all(color: const Color(0xFF38BDF8)),
                          ),
                          child: Center(child: Text(sel ? '${newPattern.indexOf(idx) + 1}' : '•')),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
              onPressed: () {
                if (type == 'pin') {
                  if (secretCtrl.text.length < 4 || int.tryParse(secretCtrl.text) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O PIN tem de ter pelo menos 4 números!')));
                    return;
                  }
                  setState(() {
                    _u['securityType'] = 'pin';
                    _u['securitySecret'] = secretCtrl.text;
                  });
                } else if (type == 'password') {
                  final v = secretCtrl.text;
                  final hasLetter = RegExp(r'[A-Za-z]').hasMatch(v);
                  final hasNum = RegExp(r'[0-9]').hasMatch(v);
                  final hasSpec = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v);
                  if (v.length < 6 || !hasLetter || !hasNum || !hasSpec) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mínimo 6 caracteres com letras, números e símbolo!')));
                    return;
                  }
                  setState(() {
                    _u['securityType'] = 'password';
                    _u['securitySecret'] = v;
                  });
                } else if (type == 'pattern') {
                  if (newPattern.length < 4) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Liga pelo menos 4 pontos no padrão!')));
                    return;
                  }
                  setState(() {
                    _u['securityType'] = 'pattern';
                    _u['securitySecret'] = newPattern.join('-');
                  });
                }
                _saveChanges();
                Navigator.pop(ctx);
              },
              child: const Text('Guardar Segurança', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _u['status'] ?? 'online';
    final statusCol = UserAccountManager.statusColor(status);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cartão de Perfil & Foto
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
                    setState(() => _u['avatarPath'] = res.files.single.path);
                    _saveChanges();
                  }
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: const Color(0xFF1E78FF),
                      backgroundImage: _u['avatarPath'] != null ? FileImage(File(_u['avatarPath'])) : null,
                      child: _u['avatarPath'] == null ? const Icon(Icons.person, size: 42, color: Colors.white) : null,
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(color: statusCol, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF050B1E), width: 3)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('${_u['firstName'] ?? ''} ${_u['lastName'] ?? ''}'.trim(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text('${_u['followers'] ?? 0} Seguidores  ·  A seguir ${_u['following'] ?? 0}', style: const TextStyle(fontSize: 12, color: Color(0xFF38BDF8))),
              const SizedBox(height: 12),
              TextField(controller: _nickCtrl, decoration: const InputDecoration(labelText: 'Nome de Criador / Nickname', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _bioCtrl, decoration: const InputDecoration(labelText: 'Biografia do Perfil', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _discordCtrl, decoration: const InputDecoration(labelText: 'Link Discord da Comunidade (Opcional)', isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _whatsappCtrl, decoration: const InputDecoration(labelText: 'Link Grupo WhatsApp (Opcional)', isDense: true)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                  onPressed: _saveChanges,
                  child: const Text('Guardar Dados do Perfil', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 4 Estados Visuais com as Cores Exatas
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF0B1636), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E429F))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estado de Presença na App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF38BDF8))),
              const SizedBox(height: 8),
              ...[
                {'id': 'online', 'title': 'Online', 'sub': 'Visível para todos na Comunidade', 'color': Colors.green},
                {'id': 'dnd', 'title': 'Não Incomodar', 'sub': 'Bloqueia convites e mensagens diretas', 'color': Colors.orange},
                {'id': 'invisible', 'title': 'Invisível (Furtivo)', 'sub': 'Navega sem aparecer online para ninguém', 'color': Colors.white},
                {'id': 'offline', 'title': 'Offline', 'sub': 'Aparência desconectada', 'color': Colors.redAccent},
              ].map((st) {
                final id = st['id'] as String;
                final col = st['color'] as Color;
                return RadioListTile<String>(
                  dense: true,
                  activeColor: col,
                  value: id,
                  groupValue: status,
                  title: Row(
                    children: [
                      Icon(Icons.circle, size: 12, color: col),
                      const SizedBox(width: 8),
                      Text(st['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  subtitle: Text(st['sub'] as String, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _u['status'] = v);
                      _saveChanges();
                    }
                  },
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF0B1636), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E429F))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Privacidade das Informações', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF38BDF8))),
              SwitchListTile(
                dense: true,
                title: const Text('Mostrar Email no Perfil Público'),
                value: _u['publicEmail'] == true,
                onChanged: (v) {
                  setState(() => _u['publicEmail'] = v);
                  _saveChanges();
                },
              ),
              SwitchListTile(
                dense: true,
                title: const Text('Mostrar Contacto Telefónico'),
                value: _u['publicPhone'] == true,
                onChanged: (v) {
                  setState(() => _u['publicPhone'] = v);
                  _saveChanges();
                },
              ),
              SwitchListTile(
                dense: true,
                title: const Text('Mostrar Estatísticas de Live'),
                value: _u['publicStats'] != false,
                onChanged: (v) {
                  setState(() => _u['publicStats'] = v);
                  _saveChanges();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF0B1636), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E429F))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Segurança & Bloqueio da Conta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF38BDF8))),
              const Text('Pedida ao abrir a app após encerrar ou fazer logout:', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
              const SizedBox(height: 8),
              ...[
                {'id': 'none', 'label': 'Desligado (Entrar Direto)'},
                {'id': 'biometric', 'label': 'Impressão Digital / Face ID / Íris'},
                {'id': 'pin', 'label': 'PIN Numérico (Mín. 4 Números)'},
                {'id': 'password', 'label': 'Senha Forte (6+ Letras, Números e Símbolos)'},
                {'id': 'pattern', 'label': 'Padrão na Tela (3×3 Pontos)'},
              ].map((sec) => RadioListTile<String>(
                    dense: true,
                    activeColor: const Color(0xFF38BDF8),
                    title: Text(sec['label']!),
                    value: sec['id']!,
                    groupValue: _u['securityType'] ?? 'none',
                    onChanged: (v) {
                      if (v != null) _configureSecuritySecret(v);
                    },
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text('Terminar Sessão (Logout)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class HelpFaqAndContactScreen extends StatelessWidget {
  const HelpFaqAndContactScreen({super.key});

  static final List<Map<String, String>> _faqItems = [
    {
      'q': 'Como ligar a minha live no TikTok, Twitch, YouTube ou Kick?',
      'a': 'No ecrã inicial, toca no cartão oficial da tua plataforma. No TikTok, insere o teu utilizador e copia o diretório para o TikTok Live Studio. Na Twitch, YouTube ou Kick, escolhe OBS Studio ou Streamlabs e cola o diretório como Browser Source.'
    },
    {
      'q': 'Como colocar GIFs e sons nos presentes, seguidores e likes?',
      'a': 'Abre a aba "Alertas, Metas & Doações". Em cada presente ou alerta, toca no ícone de edição (ou botão GIF / Som) para pesquisar GIFs online, escolher sons da biblioteca ou carregar ficheiros MP3/PNG do teu aparelho.'
    },
    {
      'q': 'Como personalizar os botões, cores e fundo do Stream Deck?',
      'a': 'Abre o "Stream Deck Pro". Toca no ícone de paleta no topo para mudar a cor de fundo da consola. Para personalizar qualquer botão (cor, ícone da biblioteca, imagem PNG do aparelho, som ou posição esquerda/direita), mantém o dedo pressionado sobre o botão.'
    },
    {
      'q': 'A app continua a funcionar se eu bloquear o ecrã ou minimizar?',
      'a': 'Sim! O HELL Live mantém o áudio, a leitura de comentários por voz e o emparelhamento do Stream Deck ativos em segundo plano mesmo com o ecrã desligado ou minimizado.'
    },
    {
      'q': 'Como funciona o Marketplace e o Plano HELL Live PRO?',
      'a': 'Na aba "Estúdio & Marketplace", podes usar overlays gratuitos ou adquirir criações da comunidade. Com o Plano PRO, podes criar os teus próprios overlays, roletas, alertas e packs de sons e colocá-los à venda na loja oficial.'
    },
    {
      'q': 'Como ativar o estado Invisível (Furtivo) ou bloqueio por Impressão Digital?',
      'a': 'Toca no teu ícone de perfil no topo da app. Lá podes mudar o teu estado para Online, Não Incomodar, Invisível (Furtivo) ou Offline, e ativar o bloqueio por Impressão Digital/Face ID, PIN, Senha Forte ou Padrão.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Center(child: Text('Tem algumas dúvidas?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
        const SizedBox(height: 4),
        const Center(child: Text('Nós temos as respostas', style: TextStyle(fontSize: 13.5, color: Colors.white60))),
        const SizedBox(height: 20),
        ..._faqItems.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1636),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: ExpansionTile(
                iconColor: const Color(0xFF38BDF8),
                collapsedIconColor: Colors.white70,
                trailing: const Icon(Icons.add, size: 20),
                title: Text(item['q']!, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(item['a']!, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.white70)),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 28),
        const Divider(color: Colors.white12),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF08112B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF1E429F)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset('icon.png', height: 36, errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, color: Color(0xFF38BDF8), size: 32)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Faça Stream com Confiança', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'O HELL Live foi desenvolvido a pensar em ti por uma equipa dedicada a criadores de conteúdo. A nossa missão é tornar as tuas transmissões mais interativas, divertidas e profissionais — quer jogues num telemóvel ou num estúdio completo.\n\nPrecisas de ajuda ou procuras uma colaboração? Entra em contacto connosco!',
                style: TextStyle(fontSize: 13.5, height: 1.55, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                    onPressed: () => launchUrl(Uri.parse('https://discord.com'), mode: LaunchMode.externalApplication),
                    child: const Text('Discord da Comunidade', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                    onPressed: () => launchUrl(Uri.parse('mailto:suporte@helllive.app')),
                    child: const Text('E-Mail', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                    onPressed: () => launchUrl(Uri.parse('mailto:parceiros@helllive.app')),
                    child: const Text('Contacto de Parceiro', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
