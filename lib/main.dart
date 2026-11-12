import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const HellLiveApp());
}

class HellLiveApp extends StatefulWidget {
  const HellLiveApp({super.key});

  @override
  State<HellLiveApp> createState() => _HellLiveAppState();
}

class _HellLiveAppState extends State<HellLiveApp> {
  String _themeMode = 'azul';

  void _changeTheme(String mode) {
    setState(() => _themeMode = mode);
  }

  ThemeData _buildTheme() {
    if (_themeMode == 'claro') {
      return ThemeData.light().copyWith(
        primaryColor: const Color(0xFF1D6CE0),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1D6CE0),
          secondary: Color(0xFF38BDF8),
        ),
      );
    } else if (_themeMode == 'escuro') {
      return ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF07090E),
        cardColor: const Color(0xFF10131C),
        primaryColor: const Color(0xFF2563EB),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF07090E), elevation: 0),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0A0D14),
          selectedItemColor: Color(0xFF38BDF8),
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
        ),
      );
    }
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF050B1E),
      cardColor: const Color(0xFF0B1636),
      primaryColor: const Color(0xFF1E78FF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF050B1E),
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF07102B),
        selectedItemColor: Color(0xFF38BDF8),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF1E78FF),
        secondary: Color(0xFF38BDF8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HELL Live',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: SplashScreen(
        currentTheme: _themeMode,
        onThemeChanged: _changeTheme,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final String currentTheme;
  final Function(String) onThemeChanged;

  const SplashScreen({super.key, required this.currentTheme, required this.onThemeChanged});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainShell(
              currentTheme: widget.currentTheme,
              onThemeChanged: widget.onThemeChanged,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.15),
            radius: 0.9,
            colors: [Color(0xFF122B6B), Color(0xFF050B1E)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1E78FF).withOpacity(0.5), blurRadius: 40, spreadRadius: 5),
                ],
              ),
              child: Image.asset('icon.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) {
                return const Icon(Icons.local_fire_department, size: 90, color: Color(0xFF38BDF8));
              }),
            ),
            const SizedBox(height: 20),
            const Text(
              'HELL',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white),
            ),
            const Text(
              'Live',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 4, color: Color(0xFF38BDF8)),
            ),
            const SizedBox(height: 12),
            const Text(
              'LIVE  ·  PLAY  ·  CONNECT',
              style: TextStyle(fontSize: 11, letterSpacing: 3, color: Colors.white60),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Text(
                'A tua live, no teu comando.',
                style: TextStyle(fontSize: 14, color: Color(0xFF7DD3FC), letterSpacing: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final String currentTheme;
  final Function(String) onThemeChanged;

  const MainShell({super.key, required this.currentTheme, required this.onThemeChanged});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final String serverUrl = 'https://onrender.com';
  late IO.Socket socket;
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();

  final TextEditingController _tiktokController = TextEditingController();
  bool _isConnectedToServer = false;
  bool _tiktokActive = false;
  bool _ttsEnabled = true;
  bool _ignoreEmojiOnly = true;

  String _selectedLanguage = 'pt-PT';
  String _selectedVoicePreset = 'Feminina Normal';
  double _speechRate = 0.5;

  final Map<String, String> _supportedLanguages = {
    'pt-PT': 'Português (Portugal)',
    'pt-BR': 'Português (Brasil)',
    'en-US': 'Inglês (EUA)',
    'es-ES': 'Espanhol (Espanha)',
    'fr-FR': 'Francês (França)',
  };

  final Map<String, double> _voicePresets = {
    'Feminina Normal': 1.05,
    'Feminina Energética': 1.25,
    'Feminina Grave': 0.90,
    'Masculina Normal': 0.85,
    'Masculina Grave (Locutor)': 0.65,
    'Masculina Jovem': 0.98,
  };

  final List<Map<String, dynamic>> _events = [];

  final List<Map<String, dynamic>> _alertRules = [
    {'name': 'Moeda', 'category': 'Presentes', 'sound': 'Moeda.mp3', 'enabled': true, 'icon': Icons.monetization_on, 'color': const Color(0xFFFBBF24)},
    {'name': 'Leão', 'category': 'Presentes', 'sound': 'Leao.mp3', 'enabled': true, 'icon': Icons.pets, 'color': const Color(0xFFF97316)},
    {'name': 'Rosa', 'category': 'Presentes', 'sound': 'Rosa.mp3', 'enabled': true, 'icon': Icons.local_florist, 'color': const Color(0xFFF43F5E)},
    {'name': 'TikTok', 'category': 'Presentes', 'sound': 'TikTok.mp3', 'enabled': true, 'icon': Icons.music_note, 'color': const Color(0xFF22D3EE)},
    {'name': 'GG', 'category': 'Presentes', 'sound': 'GG.mp3', 'enabled': true, 'icon': Icons.sports_esports, 'color': const Color(0xFFEF4444)},
    {'name': 'Outro Presente', 'category': 'Presentes', 'sound': 'Presente.mp3', 'enabled': true, 'icon': Icons.card_giftcard, 'color': const Color(0xFFA855F7)},
    {'name': 'Novo Seguidor', 'category': 'Seguidores', 'sound': 'Seguidor.mp3', 'enabled': true, 'icon': Icons.person_add, 'color': const Color(0xFF38BDF8)},
    {'name': 'Gostos / Likes', 'category': 'Gostos', 'sound': 'Like.mp3', 'enabled': false, 'icon': Icons.favorite, 'color': const Color(0xFFEC4899)},
    {'name': 'Comentário TTS', 'category': 'Comentários', 'sound': 'Comentario.mp3', 'enabled': true, 'icon': Icons.chat_bubble, 'color': const Color(0xFF10B981)},
  ];

  final List<Map<String, String>> _soundsLibrary = [
    {'name': 'Moeda.mp3', 'duration': '00:05', 'cat': 'Presentes', 'path': ''},
    {'name': 'Leao.mp3', 'duration': '00:06', 'cat': 'Presentes', 'path': ''},
    {'name': 'Rosa.mp3', 'duration': '00:04', 'cat': 'Presentes', 'path': ''},
    {'name': 'TikTok.mp3', 'duration': '00:05', 'cat': 'Presentes', 'path': ''},
    {'name': 'GG.mp3', 'duration': '00:04', 'cat': 'Presentes', 'path': ''},
    {'name': 'Seguidor.mp3', 'duration': '00:05', 'cat': 'Eventos', 'path': ''},
    {'name': 'Comentário.mp3', 'duration': '00:06', 'cat': 'Eventos', 'path': ''},
  ];
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initSocket();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tiktokController.text = prefs.getString('tiktok_user') ?? '';
      _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
      _selectedLanguage = prefs.getString('tts_lang') ?? 'pt-PT';
      _speechRate = prefs.getDouble('tts_rate') ?? 0.5;
      final savedPreset = prefs.getString('tts_preset') ?? 'Feminina Normal';
      if (_voicePresets.containsKey(savedPreset)) {
        _selectedVoicePreset = savedPreset;
      }
    });
    await _applyTtsSettings();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tiktok_user', _tiktokController.text.trim());
    await prefs.setBool('tts_enabled', _ttsEnabled);
    await prefs.setString('tts_lang', _selectedLanguage);
    await prefs.setDouble('tts_rate', _speechRate);
    await prefs.setString('tts_preset', _selectedVoicePreset);
  }

  Future<void> _applyTtsSettings() async {
    await flutterTts.setLanguage(_selectedLanguage);
    await flutterTts.setSpeechRate(_speechRate);
    await flutterTts.setPitch(_voicePresets[_selectedVoicePreset] ?? 1.0);
  }

  Future<void> _panicSilenceAll() async {
    await flutterTts.stop();
    await audioPlayer.stop();
    _showSnack('Silêncio ativado! Voz e sons interrompidos.');
  }

  void _initSocket() {
    socket = IO.io(
      serverUrl,
      IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );
    socket.onConnect((_) => setState(() => _isConnectedToServer = true));
    socket.onDisconnect((_) => setState(() {
          _isConnectedToServer = false;
          _tiktokActive = false;
        }));
    socket.on('status', (data) {
      setState(() {
        if (data['platform'] == 'tiktok') _tiktokActive = data['connected'] == true;
      });
      if (data['connected'] == false) {
        _showSnack(data['error'] ?? 'Live offline ou utilizador inválido.');
      }
    });
    socket.on('live_event', (data) {
      final event = Map<String, dynamic>.from(data);
      setState(() {
        _events.insert(0, event);
        if (_events.length > 50) _events.removeLast();
      });
      if (_ttsEnabled) {
        final user = event['user'] ?? 'Alguém';
        final msg = (event['message'] ?? '').toString();
        if (_ignoreEmojiOnly && event['type'] != 'gift') {
          final hasLettersOrDigits = RegExp(r'[a-zA-Z0-9À-ÿ]').hasMatch(msg);
          if (!hasLettersOrDigits) return;
        }
        flutterTts.speak(event['type'] == 'gift' ? 'Novo presente! $user $msg' : '$user diz: $msg');
      }
    });
    socket.connect();
  }

  void _connectTikTokDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1636),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E78FF)),
        ),
        title: const Text('Ligar Conta TikTok LIVE'),
        content: TextField(
          controller: _tiktokController,
          decoration: const InputDecoration(
            hintText: '@teu_utilizador',
            prefixIcon: Icon(Icons.alternate_email, color: Color(0xFF38BDF8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
            onPressed: () {
              Navigator.pop(ctx);
              _saveSettings();
              if (!_isConnectedToServer) {
                socket.connect();
                _showSnack('A acordar servidor HELL Live, aguarda 15 segundos...');
              } else if (_tiktokController.text.trim().isNotEmpty) {
                socket.emit('connect_tiktok', _tiktokController.text.trim());
                _showSnack('A ligar a ${_tiktokController.text.trim()}...');
              }
            },
            child: const Text('Ligar Agora', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _importSound() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _soundsLibrary.insert(0, {
          'name': result.files.single.name,
          'duration': 'Custom',
          'cat': 'Meus Sons',
          'path': result.files.single.path!,
        });
      });
      _showSnack('Som "${result.files.single.name}" adicionado!');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  BoxDecoration _neonCardDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0E1D47), Color(0xFF08112B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF1E429F), width: 1.2),
      boxShadow: [
        BoxShadow(color: const Color(0xFF1E78FF).withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: _connectTikTokDialog,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _neonCardDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estado da Live', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _tiktokActive ? const Color(0xFF22C55E) : const Color(0xFF38BDF8),
                              boxShadow: [
                                BoxShadow(
                                  color: (_tiktokActive ? const Color(0xFF22C55E) : const Color(0xFF38BDF8)).withOpacity(0.8),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _tiktokActive ? 'Online' : 'Tocar para Ligar',
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(Icons.music_note, color: Color(0xFF38BDF8), size: 22),
                      ),
                      const SizedBox(height: 4),
                      const Text('TikTok LIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _neonMenuTile(Icons.notifications_none, 'Alertas', () => setState(() => _selectedIndex = 1)),
          _neonMenuTile(Icons.volume_up_outlined, 'Sons & Stream Deck', () => setState(() => _selectedIndex = 2)),
          _neonMenuTile(Icons.chat_bubble_outline, 'Comentários & Vozes', () => setState(() => _selectedIndex = 3)),
          _neonMenuTile(Icons.emoji_events_outlined, 'Pódio & Roleta Interativa', () => _showSnack('Pódio & Roleta Interativa chegam na v2.0!')),
          _neonMenuTile(Icons.volunteer_activism_outlined, 'Overlays & Doações MB Way/PIX', () => _showSnack('Overlays & Doações Diretas chegam na v2.0!')),
          _neonMenuTile(Icons.settings_outlined, 'Definições & PRO', () => setState(() => _selectedIndex = 4)),
          const SizedBox(height: 24),
          const Text(
            'HELL Live',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2.5, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          const Text(
            'LIVE  ·  PLAY  ·  CONNECT',
            style: TextStyle(fontSize: 10, letterSpacing: 2.5, color: Color(0xFF38BDF8)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _neonMenuTile(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _neonCardDecoration(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E78FF).withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
              ),
              child: Icon(icon, color: const Color(0xFF38BDF8), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAlerts(String cat) {
    final items = _alertRules.where((e) => e['category'] == cat).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: _neonCardDecoration(),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item['icon'], color: item['color'], size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Som: ${item['sound']}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              Switch(
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF1E78FF),
                value: item['enabled'],
                onChanged: (v) => setState(() => item['enabled'] = v),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF38BDF8),
            labelColor: Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Presentes'),
              Tab(text: 'Seguidores'),
              Tab(text: 'Gostos'),
              Tab(text: 'Comentários'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCategoryAlerts('Presentes'),
                _buildCategoryAlerts('Seguidores'),
                _buildCategoryAlerts('Gostos'),
                _buildCategoryAlerts('Comentários'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E78FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _importSound,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Adicionar Som Personalizado', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySounds(String tabCat) {
    final list = tabCat == 'Todos'
        ? _soundsLibrary
        : _soundsLibrary.where((s) => s['cat'] == tabCat).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final s = list[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: _neonCardDecoration(),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  if (s['path']!.isNotEmpty) {
                    await audioPlayer.play(DeviceFileSource(s['path']!));
                  } else {
                    flutterTts.speak('A reproduzir ${s['name']}');
                  }
                },
                child: const Icon(Icons.play_arrow, color: Color(0xFF38BDF8), size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['name']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(s['duration']!, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.white54),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSoundsTab() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF38BDF8),
            labelColor: Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Todos'),
              Tab(text: 'Presentes'),
              Tab(text: 'Eventos'),
              Tab(text: 'Meus Sons'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCategorySounds('Todos'),
                _buildCategorySounds('Presentes'),
                _buildCategorySounds('Eventos'),
                _buildCategorySounds('Meus Sons'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E78FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _importSound,
                child: const Text('Importar Som', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCommentsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _neonCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Leitura por Voz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Switch(
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF1E78FF),
                    value: _ttsEnabled,
                    onChanged: (v) {
                      setState(() => _ttsEnabled = v);
                      _saveSettings();
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ignorar mensagens só com emojis', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  Switch(
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF1E78FF),
                    value: _ignoreEmojiOnly,
                    onChanged: (v) => setState(() => _ignoreEmojiOnly = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Idioma', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                dropdownColor: const Color(0xFF0B1636),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF050B1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _supportedLanguages.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) async {
                  if (v != null) {
                    setState(() => _selectedLanguage = v);
                    await _applyTtsSettings();
                    await _saveSettings();
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Timbre & Voz', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedVoicePreset,
                dropdownColor: const Color(0xFF0B1636),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF050B1E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _voicePresets.keys
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (v) async {
                  if (v != null) {
                    setState(() => _selectedVoicePreset = v);
                    await _applyTtsSettings();
                    await _saveSettings();
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Velocidade da Voz', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('${(_speechRate * 2).toStringAsFixed(1)}x', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                activeColor: const Color(0xFF38BDF8),
                value: _speechRate,
                min: 0.25,
                max: 1.0,
                divisions: 6,
                onChanged: (v) async {
                  setState(() => _speechRate = v);
                  await _applyTtsSettings();
                  await _saveSettings();
                },
              ),
              const SizedBox(height: 12),
              const Text('Exemplo de Leitura', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF050B1E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '"Obrigado pelo apoio!\nVamos com tudo!"',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => flutterTts.speak('Obrigado pelo apoio! Vamos com tudo!'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E78FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _neonCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 4, bottom: 4),
                child: Text('Tema', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              RadioListTile<String>(
                activeColor: const Color(0xFF38BDF8),
                title: const Text('Azul (Padrão)'),
                value: 'azul',
                groupValue: widget.currentTheme,
                onChanged: (v) => widget.onThemeChanged(v!),
              ),
              RadioListTile<String>(
                activeColor: const Color(0xFF38BDF8),
                title: const Text('Escuro'),
                value: 'escuro',
                groupValue: widget.currentTheme,
                onChanged: (v) => widget.onThemeChanged(v!),
              ),
              RadioListTile<String>(
                activeColor: const Color(0xFF38BDF8),
                title: const Text('Claro'),
                value: 'claro',
                groupValue: widget.currentTheme,
                onChanged: (v) => widget.onThemeChanged(v!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _neonMenuTile(
          Icons.music_note,
          _tiktokController.text.isEmpty ? 'Conta TikTok (Ligação pendente)' : 'Conta TikTok (${_tiktokController.text})',
          _connectTikTokDialog,
        ),
        _neonMenuTile(Icons.workspace_premium, 'HELL Live PRO & Vouchers de Oferta', () => _showSnack('Loja PRO & Vouchers de 1, 3, 6 e 12 meses chegam na v3.0!')),
        _neonMenuTile(Icons.info_outline, 'Sobre a Aplicação (HELL Live v1.5.0)', () => _showSnack('HELL Live · LIVE · PLAY · CONNECT')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['HELL Live', 'Alertas', 'Sons', 'Comentários', 'Definições'];
    final screens = [
      _buildHomeTab(),
      _buildAlertsTab(),
      _buildSoundsTab(),
      _buildCommentsTab(),
      _buildSettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: _selectedIndex == 0
            ? Padding(
                padding: const EdgeInsets.all(10.0),
                child: Image.asset('icon.png', errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: Color(0xFF38BDF8))),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedIndex = 0),
              ),
        title: Text(
          titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_off, color: Colors.redAccent),
            tooltip: 'Botão de Pânico (Silenciar Tudo)',
            onPressed: _panicSilenceAll,
          ),
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white70),
              onPressed: () => setState(() => _selectedIndex = 4),
            ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex == 4 ? 3 : _selectedIndex,
        onTap: (idx) {
          if (idx == 3) {
            setState(() => _selectedIndex = 4);
          } else {
            setState(() => _selectedIndex = idx);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), activeIcon: Icon(Icons.notifications), label: 'Alertas'),
          BottomNavigationBarItem(icon: Icon(Icons.music_note_outlined), activeIcon: Icon(Icons.music_note), label: 'Sons'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Definições'),
        ],
      ),
    );
  }
}
