import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'app_data.dart';
import 'lib/studio_screens.dart';
import 'deck_and_community.dart';

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

  void _changeTheme(String mode) => setState(() => _themeMode = mode);

  ThemeData _buildTheme() {
    if (_themeMode == 'claro') {
      return ThemeData.light().copyWith(
        primaryColor: const Color(0xFF1D6CE0),
        colorScheme: const ColorScheme.light(primary: Color(0xFF1D6CE0), secondary: Color(0xFF38BDF8)),
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
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF050B1E), elevation: 0),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF07102B),
        selectedItemColor: Color(0xFF38BDF8),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF1E78FF), secondary: Color(0xFF38BDF8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HELL Live',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: SplashScreen(currentTheme: _themeMode, onThemeChanged: _changeTheme),
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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _glowRadius;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _progressWidth;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    _logoScale = Tween<double>(begin: 0.78, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack)));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.30, curve: Curves.easeIn)));
    _glowRadius = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 12.0, end: 52.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 52.0, end: 32.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _ringScale = Tween<double>(begin: 0.7, end: 1.45).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.75, curve: Curves.easeOut)));
    _ringOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.55), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.80)));
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.28, 0.58, curve: Curves.easeOut)));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.28, 0.58, curve: Curves.easeOutCubic)));
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.48, 0.78, curve: Curves.easeIn)));
    _progressWidth = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.20, 0.95, curve: Curves.easeInOut)));
    _controller.forward();

    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, __, ___) => MainShell(currentTheme: widget.currentTheme, onThemeChanged: widget.onThemeChanged),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.18), radius: 1.0, colors: [Color(0xFF132E73), Color(0xFF07112E), Color(0xFF040817)]),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: _ringScale.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF38BDF8).withOpacity(_ringOpacity.value), width: 1.8)),
                      ),
                    ),
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF1E78FF).withOpacity(0.55), blurRadius: _glowRadius.value, spreadRadius: 4),
                              BoxShadow(color: const Color(0xFF38BDF8).withOpacity(0.25), blurRadius: _glowRadius.value * 1.4, spreadRadius: 1),
                            ],
                          ),
                          child: Image.asset('icon.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, size: 95, color: Color(0xFF38BDF8))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _titleOpacity,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: Column(
                      children: [
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(text: 'HELL ', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white)),
                              TextSpan(text: 'Live', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: 2, color: Color(0xFF38BDF8))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(width: 160, height: 1.5, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Color(0xFF38BDF8), Colors.transparent]))),
                        const SizedBox(height: 10),
                        const Text('LIVE  ·  PLAY  ·  CONNECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 3.5, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _subtitleOpacity,
                  child: Column(
                    children: [
                      const Text('A tua live, no teu comando.', style: TextStyle(fontSize: 13.5, color: Color(0xFF7DD3FC), letterSpacing: 0.8)),
                      const SizedBox(height: 16),
                      Container(
                        width: 140,
                        height: 3,
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _progressWidth.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF1E78FF), Color(0xFF38BDF8)]),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [BoxShadow(color: Color(0xFF38BDF8), blurRadius: 6)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 42),
              ],
            );
          },
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
  String _appLang = 'pt';
  final String serverUrl = 'https://onrender.com';
  late IO.Socket socket;
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer ttsAudioPlayer = AudioPlayer();
  final AudioPlayer sfxAudioPlayer = AudioPlayer();

  final TextEditingController _channelCtrl = TextEditingController();
  final TextEditingController _gifSearchCtrl = TextEditingController();
  String _selectedPlatform = 'tiktok';

  bool _isConnectedToServer = false;
  bool _liveConnected = false;
  bool _ttsEnabled = true;
  bool _ignoreEmojiOnly = true;
  String? _generatedPairCode;
  String? _pairedRemoteRoom;

  String _selectedVoiceKey = 'pt-PT-DuarteNeural';
  double _speechRate = 0.5;

  final Map<String, Map<String, String>> _neuralVoices = {
    'pt-PT-DuarteNeural': {'label': 'Masculina PT-PT (Duarte)', 'pitch': '+0Hz'},
    'pt-PT-DuarteNeural|grave': {'label': 'Masculina PT-PT Grave (Locutor)', 'pitch': '-15Hz'},
    'pt-PT-RaquelNeural': {'label': 'Feminina PT-PT (Raquel)', 'pitch': '+0Hz'},
    'pt-PT-RaquelNeural|aguda': {'label': 'Feminina PT-PT Energética', 'pitch': '+12Hz'},
    'pt-BR-AntonioNeural': {'label': 'Masculina PT-BR (António)', 'pitch': '+0Hz'},
    'pt-BR-FranciscaNeural': {'label': 'Feminina PT-BR (Francisca)', 'pitch': '+0Hz'},
    'en-US-GuyNeural': {'label': 'Masculina Inglês (Guy)', 'pitch': '+0Hz'},
    'en-US-JennyNeural': {'label': 'Feminina Inglês (Jenny)', 'pitch': '+0Hz'},
    'es-ES-AlvaroNeural': {'label': 'Masculina Espanhol (Álvaro)', 'pitch': '+0Hz'},
  };

  List<Map<String, dynamic>> _topGifts = [];
  List<Map<String, dynamic>> _topLikes = [];
  List<Map<String, String>> _sounds = [];
  List<Map<String, String>> _gifs = [];
  List<dynamic> _onlineGifResults = [];
  bool _searchingGifs = false;

  final List<Map<String, dynamic>> _alertRules = [
    {'name': 'Presente / Moeda', 'gif': 'https://giphy.com', 'enabled': true, 'icon': Icons.card_giftcard, 'color': const Color(0xFFFBBF24)},
    {'name': 'Novo Seguidor', 'gif': 'https://giphy.com', 'enabled': true, 'icon': Icons.person_add, 'color': const Color(0xFF38BDF8)},
    {'name': 'Meta 500 Likes (Com Foto)', 'gif': 'https://giphy.com', 'enabled': true, 'icon': Icons.favorite, 'color': const Color(0xFFF43F5E)},
  ];
  @override
  void initState() {
    super.initState();
    _sounds = List<Map<String, String>>.from(DefaultMediaLibrary.builtInSounds);
    _gifs = List<Map<String, String>>.from(DefaultMediaLibrary.builtInGifs);
    _loadSettings();
    _initSocket();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _channelCtrl.text = prefs.getString('channel_user') ?? '';
      _selectedPlatform = prefs.getString('platform') ?? 'tiktok';
      _appLang = prefs.getString('app_lang') ?? 'pt';
      _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
      final savedVoice = prefs.getString('tts_voice') ?? 'pt-PT-DuarteNeural';
      if (_neuralVoices.containsKey(savedVoice)) _selectedVoiceKey = savedVoice;
      _speechRate = prefs.getDouble('tts_rate') ?? 0.5;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('channel_user', _channelCtrl.text.trim());
    await prefs.setString('platform', _selectedPlatform);
    await prefs.setString('app_lang', _appLang);
    await prefs.setBool('tts_enabled', _ttsEnabled);
    await prefs.setString('tts_voice', _selectedVoiceKey);
    await prefs.setDouble('tts_rate', _speechRate);
  }

  Future<void> _speakNeural(String text) async {
    try {
      final voiceName = _selectedVoiceKey.split('|').first;
      final pitch = _neuralVoices[_selectedVoiceKey]?['pitch'] ?? '+0Hz';
      final ratePct = '${((_speechRate - 0.5) * 100).round() >= 0 ? "+" : ""}${((_speechRate - 0.5) * 100).round()}%';
      final uri = Uri.parse('$serverUrl/tts').replace(queryParameters: {
        'text': text,
        'voice': voiceName,
        'rate': ratePct,
        'pitch': pitch,
      });
      await ttsAudioPlayer.stop();
      await ttsAudioPlayer.play(UrlSource(uri.toString()));
    } catch (_) {
      await flutterTts.speak(text);
    }
  }

  Future<void> _panicSilenceAll() async {
    await ttsAudioPlayer.stop();
    await sfxAudioPlayer.stop();
    await flutterTts.stop();
    _showSnack('Silêncio ativado!');
  }

  void _initSocket() {
    socket = IO.io(serverUrl, IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build());
    socket.onConnect((_) {
      setState(() => _isConnectedToServer = true);
      final room = _pairedRemoteRoom ?? _channelCtrl.text.trim();
      if (room.isNotEmpty) socket.emit('join_room', room);
    });
    socket.onDisconnect((_) => setState(() {
          _isConnectedToServer = false;
          _liveConnected = false;
        }));
    socket.on('status', (data) {
      setState(() => _liveConnected = data['connected'] == true);
      if (data['connected'] == false) _showSnack(data['error'] ?? 'Live offline ou utilizador inválido.');
    });
    socket.on('podium_update', (data) {
      setState(() {
        if (data['topGifts'] != null) _topGifts = List<Map<String, dynamic>>.from(data['topGifts']);
        if (data['topLikes'] != null) _topLikes = List<Map<String, dynamic>>.from(data['topLikes']);
      });
    });
    socket.on('pair_code_created', (data) => setState(() => _generatedPairCode = data['code']));
    socket.on('pair_approval_needed', (data) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0B1636),
          title: const Text('Pedido de Emparelhamento'),
          content: Text('Aceitar ligação de "${data['deviceName']}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Recusar')),
            ElevatedButton(
              onPressed: () {
                socket.emit('approve_pair', {'remoteSocketId': data['remoteSocketId'], 'code': data['code']});
                Navigator.pop(ctx);
                _showSnack('Stream Deck ligado!');
              },
              child: const Text('Aceitar'),
            ),
          ],
        ),
      );
    });
    socket.on('pair_approved', (data) {
      setState(() => _pairedRemoteRoom = data['room']);
      socket.emit('join_room', data['room']);
      _showSnack('Emparelhado com sucesso!');
    });
    socket.on('execute_remote_command', (data) {
      if (data['command'] == 'panic') _panicSilenceAll();
      if (data['command'] == 'sound' && data['payload'] != null) {
        sfxAudioPlayer.play(UrlSource(data['payload']));
      }
    });
    socket.on('live_event', (data) {
      final event = Map<String, dynamic>.from(data);
      final user = event['user'] ?? 'Alguém';
      final msg = (event['message'] ?? '').toString();
      if (event['type'] == 'gift') {
        final room = _channelCtrl.text.trim();
        final rule = _alertRules.first;
        if (room.isNotEmpty) {
          socket.emit('trigger_overlay_alert', {
            'room': room,
            'alertData': {'user': '$user $msg', 'message': '', 'gifUrl': rule['gif'], 'duration': 5}
          });
        }
      }
      if (_ttsEnabled) {
        if (_ignoreEmojiOnly && event['type'] != 'gift' && !RegExp(r'[a-zA-Z0-9À-ÿ]').hasMatch(msg)) return;
        _speakNeural(event['type'] == 'gift' ? 'Novo presente! $user $msg' : '$user diz: $msg');
      }
    });
    socket.connect();
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }
  void _openMultiPlatformDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final platforms = [
            {'id': 'tiktok', 'name': 'TikTok', 'icon': Icons.music_note, 'color': const Color(0xFF22D3EE)},
            {'id': 'twitch', 'name': 'Twitch', 'icon': Icons.videogame_asset, 'color': const Color(0xFFA855F7)},
            {'id': 'youtube', 'name': 'YouTube', 'icon': Icons.play_circle_fill, 'color': const Color(0xFFEF4444)},
            {'id': 'kick', 'name': 'Kick', 'icon': Icons.bolt, 'color': const Color(0xFF22C55E)},
          ];
          return AlertDialog(
            backgroundColor: const Color(0xFF0B1636),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFF1E78FF))),
            title: const Text('Escolher Plataforma'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.1,
                  children: platforms.map((p) {
                    final selected = _selectedPlatform == p['id'];
                    return InkWell(
                      onTap: () => setDialogState(() => _selectedPlatform = p['id'] as String),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? (p['color'] as Color).withOpacity(0.25) : const Color(0xFF050B1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? (p['color'] as Color) : Colors.white24, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(p['icon'] as IconData, color: p['color'] as Color, size: 20),
                            const SizedBox(width: 6),
                            Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _channelCtrl,
                  decoration: InputDecoration(
                    labelText: 'Canal / Utilizador (${_selectedPlatform.toUpperCase()})',
                    prefixIcon: const Icon(Icons.alternate_email),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                onPressed: () async {
                  await _saveSettings();
                  final user = _channelCtrl.text.trim();
                  if (user.isNotEmpty) {
                    socket.emit('connect_platform', {'platform': _selectedPlatform, 'username': user});
                  }
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('Ligar Agora', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _searchOnlineGifs(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _searchingGifs = true);
    try {
      final res = await http.get(Uri.parse('$serverUrl/search/gifs?q=${Uri.encodeComponent(query)}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _onlineGifResults = data['results'] ?? []);
      }
    } catch (_) {}
    setState(() => _searchingGifs = false);
  }

  Future<void> _importLocalSound() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _sounds.insert(0, {'name': result.files.single.name, 'cat': 'Meus Sons', 'url': '', 'path': result.files.single.path!});
      });
      _showSnack('Som adicionado!');
    }
  }

  BoxDecoration _neonCard() => BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E429F), width: 1.2),
      );

  Widget _menuTile(IconData icon, String title, VoidCallback onTap, {String? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _neonCard(),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF38BDF8), size: 22),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600))),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF1E78FF), borderRadius: BorderRadius.circular(8)),
                child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GestureDetector(
          onTap: _openMultiPlatformDialog,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: _neonCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: _liveConnected ? Colors.greenAccent : (_isConnectedToServer ? Colors.orangeAccent : Colors.redAccent)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _liveConnected ? 'Ao Vivo (${_selectedPlatform.toUpperCase()}: ${_channelCtrl.text})' : AppTranslations.t(_appLang, 'tap_connect'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.grid_view_rounded, color: Color(0xFF38BDF8)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Chip(label: Text('TikTok', style: TextStyle(fontSize: 11))),
                    Chip(label: Text('Twitch', style: TextStyle(fontSize: 11))),
                    Chip(label: Text('YouTube', style: TextStyle(fontSize: 11))),
                    Chip(label: Text('Kick', style: TextStyle(fontSize: 11))),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _menuTile(Icons.notifications_active, AppTranslations.t(_appLang, 'alerts'), () => setState(() => _selectedIndex = 1)),
        _menuTile(Icons.library_music, AppTranslations.t(_appLang, 'sounds'), () => setState(() => _selectedIndex = 2)),
        _menuTile(Icons.record_voice_over, AppTranslations.t(_appLang, 'voices'), () => setState(() => _selectedIndex = 3)),
        _menuTile(Icons.emoji_events, AppTranslations.t(_appLang, 'podium_wheel'), () => setState(() => _selectedIndex = 5), badge: 'NOVO'),
        _menuTile(Icons.live_tv, AppTranslations.t(_appLang, 'studio'), () => setState(() => _selectedIndex = 6), badge: 'OBS / MBWay'),
        _menuTile(Icons.grid_on, AppTranslations.t(_appLang, 'stream_deck'), () => setState(() => _selectedIndex = 7)),
        _menuTile(Icons.public, AppTranslations.t(_appLang, 'community'), () => setState(() => _selectedIndex = 8), badge: 'MUNDO'),
        _menuTile(Icons.info_outline, AppTranslations.t(_appLang, 'about'), () => setState(() => _selectedIndex = 9)),
      ],
    );
  }
  Widget _buildAlertsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._alertRules.map((rule) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: _neonCard(),
              child: Row(
                children: [
                  Icon(rule['icon'], color: rule['color'], size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rule['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('GIF ativo configurado', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                      ],
                    ),
                  ),
                  Switch(
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF1E78FF),
                    value: rule['enabled'],
                    onChanged: (v) => setState(() => rule['enabled'] = v),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: () {
            final room = _channelCtrl.text.trim();
            if (room.isEmpty) {
              _showSnack('Liga primeiro a tua live no Início!');
              return;
            }
            socket.emit('trigger_overlay_alert', {
              'room': room,
              'alertData': {'user': 'Teste HELL Live', 'message': 'Alerta funcionando na tela!', 'gifUrl': _alertRules.first['gif'], 'duration': 5}
            });
            _showSnack('Alerta de teste enviado para o Estúdio!');
          },
          icon: const Icon(Icons.play_arrow, color: Colors.white),
          label: const Text('Testar Alerta na Live (OBS / Live Studio)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSoundsAndGifsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF38BDF8),
            labelColor: Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white54,
            tabs: [Tab(text: '🔊 Sons & Efeitos'), Tab(text: '🎞️ GIFs & Pesquisa Online')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sounds.length,
                        itemBuilder: (ctx, i) {
                          final s = _sounds[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: _neonCard(),
                            child: ListTile(
                              leading: const Icon(Icons.play_circle_fill, color: Color(0xFF38BDF8), size: 32),
                              title: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(s['cat'] ?? ''),
                              onTap: () async {
                                await sfxAudioPlayer.stop();
                                if ((s['path'] ?? '').isNotEmpty) {
                                  await sfxAudioPlayer.play(DeviceFileSource(s['path']!));
                                } else if ((s['url'] ?? '').isNotEmpty) {
                                  await sfxAudioPlayer.play(UrlSource(s['url']!));
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                          onPressed: _importLocalSound,
                          icon: const Icon(Icons.upload_file, color: Colors.white),
                          label: const Text('Importar Som (.MP3 / .WAV)', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _gifSearchCtrl,
                            decoration: const InputDecoration(hintText: 'Pesquisar milhares de GIFs...', border: OutlineInputBorder(), isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                          onPressed: () => _searchOnlineGifs(_gifSearchCtrl.text),
                          child: const Icon(Icons.search, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_searchingGifs) const Center(child: CircularProgressIndicator()),
                    if (_onlineGifResults.isNotEmpty) ...[
                      const Text('Resultados Online (Toca para guardar):', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                        itemCount: _onlineGifResults.length,
                        itemBuilder: (ctx, i) {
                          final item = _onlineGifResults[i];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _gifs.insert(0, {'name': item['title'] ?? 'GIF Online', 'url': item['url']});
                                _alertRules.first['gif'] = item['url'];
                              });
                              _showSnack('GIF copiado e aplicado aos alertas!');
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(item['url'], fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 24),
                    ],
                    const Text('Biblioteca da App:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: _gifs.length,
                      itemBuilder: (ctx, i) {
                        final g = _gifs[i];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _alertRules.first['gif'] = g['url']);
                            _showSnack('GIF "${g['name']}" selecionado!');
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(g['url']!, fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoicesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _neonCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Leitura por Voz Neural', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 12),
              const Text('Escolher Voz (Masculina / Feminina)', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedVoiceKey,
                dropdownColor: const Color(0xFF0B1636),
                decoration: InputDecoration(filled: true, fillColor: const Color(0xFF050B1E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                items: _neuralVoices.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value['label']!))).toList(),
                onChanged: (v) async {
                  if (v != null) {
                    setState(() => _selectedVoiceKey = v);
                    await _saveSettings();
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                  onPressed: () => _speakNeural('Olá! Esta é a voz oficial do HELL Live a funcionar perfeitamente!'),
                  icon: const Icon(Icons.volume_up, color: Colors.white),
                  label: const Text('Testar Voz Agora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.all(14),
          decoration: _neonCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Idioma da Aplicação', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _appLang,
                dropdownColor: const Color(0xFF0B1636),
                items: const [
                  DropdownMenuItem(value: 'pt', child: Text('Português')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'es', child: Text('Español')),
                ],
                onChanged: (v) async {
                  if (v != null) {
                    setState(() => _appLang = v);
                    await _saveSettings();
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _neonCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(left: 12, top: 4, bottom: 4), child: Text('Tema Visual', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
              RadioListTile<String>(activeColor: const Color(0xFF38BDF8), title: const Text('Azul Néon (Padrão)'), value: 'azul', groupValue: widget.currentTheme, onChanged: (v) => widget.onThemeChanged(v!)),
              RadioListTile<String>(activeColor: const Color(0xFF38BDF8), title: const Text('Escuro Profundo'), value: 'escuro', groupValue: widget.currentTheme, onChanged: (v) => widget.onThemeChanged(v!)),
              RadioListTile<String>(activeColor: const Color(0xFF38BDF8), title: const Text('Claro'), value: 'claro', groupValue: widget.currentTheme, onChanged: (v) => widget.onThemeChanged(v!)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'HELL Live',
      AppTranslations.t(_appLang, 'alerts'),
      AppTranslations.t(_appLang, 'sounds'),
      AppTranslations.t(_appLang, 'voices'),
      AppTranslations.t(_appLang, 'settings'),
      AppTranslations.t(_appLang, 'podium_wheel'),
      AppTranslations.t(_appLang, 'studio'),
      AppTranslations.t(_appLang, 'stream_deck'),
      AppTranslations.t(_appLang, 'community'),
      AppTranslations.t(_appLang, 'about'),
    ];

    final screens = [
      _buildHomeTab(),
      _buildAlertsTab(),
      _buildSoundsAndGifsTab(),
      _buildVoicesTab(),
      _buildSettingsTab(),
      PodiumAndWheelScreen(socket: socket, roomName: _channelCtrl.text.trim(), topGifts: _topGifts, topLikes: _topLikes),
      StudioAndDonationsScreen(socket: socket, serverUrl: serverUrl, roomName: _channelCtrl.text.trim()),
      StreamDeckScreen(
        socket: socket,
        activeRoom: _channelCtrl.text.trim(),
        generatedCode: _generatedPairCode,
        pairedRoom: _pairedRemoteRoom,
        onGenerateCode: () {
          final room = _channelCtrl.text.trim();
          if (room.isEmpty) {
            _showSnack('Liga primeiro uma live no Início!');
          } else {
            socket.emit('create_pair_code', room);
          }
        },
        onJoinWithCode: (code) => socket.emit('request_pair', {'code': code, 'deviceName': 'Stream Deck'}),
        onSendCommand: (cmd, val) {
          final target = _pairedRemoteRoom ?? _channelCtrl.text.trim();
          if (cmd == 'panic') _panicSilenceAll();
          if (cmd == 'sound' && val != null) sfxAudioPlayer.play(UrlSource(val));
          if (target.isNotEmpty) socket.emit('remote_command', {'room': target, 'command': cmd, 'payload': val});
        },
      ),
      CommunityGlobeScreen(serverUrl: serverUrl),
      const AboutHellLiveScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: _selectedIndex == 0
            ? Padding(padding: const EdgeInsets.all(10.0), child: Image.asset('icon.png', errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: Color(0xFF38BDF8))))
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedIndex = 0)),
        title: Text(titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        actions: [
          IconButton(icon: const Icon(Icons.volume_off, color: Colors.redAccent), tooltip: 'Silenciar Tudo', onPressed: _panicSilenceAll),
          if (_selectedIndex == 0) IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white70), onPressed: () => setState(() => _selectedIndex = 4)),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex > 3 ? 3 : _selectedIndex,
        onTap: (idx) => setState(() => _selectedIndex = idx == 3 ? 4 : idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), activeIcon: Icon(Icons.notifications), label: 'Alertas'),
          BottomNavigationBarItem(icon: Icon(Icons.music_note_outlined), activeIcon: Icon(Icons.music_note), label: 'Sons/GIF'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Definições'),
        ],
      ),
    );
  }
}
