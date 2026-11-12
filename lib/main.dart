import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'app_data.dart';
import 'studio_screens.dart';
import 'deck_and_community.dart';
import 'platform_logos.dart';

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
      );
    }
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF050B1E),
      cardColor: const Color(0xFF0B1636),
      primaryColor: const Color(0xFF1E78FF),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF050B1E), elevation: 0),
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _logoScale = Tween<double>(begin: 0.78, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack)));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.30, curve: Curves.easeIn)));
    _glowRadius = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 12.0, end: 50.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 50.0, end: 30.0), weight: 50),
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

    Timer(const Duration(milliseconds: 2700), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
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
                            boxShadow: [BoxShadow(color: const Color(0xFF1E78FF).withOpacity(0.55), blurRadius: _glowRadius.value, spreadRadius: 4)],
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
  final TextEditingController _goalTitleCtrl = TextEditingController(text: 'Meta de Likes da Live');
  final TextEditingController _goalTargetCtrl = TextEditingController(text: '5000');
  final TextEditingController _mbwayCtrl = TextEditingController();
  final TextEditingController _pixCtrl = TextEditingController();

  String _selectedPlatform = 'tiktok';
  bool _isConnectedToServer = false;
  bool _liveConnected = false;
  bool _isMuted = false;
  bool _ttsEnabled = true;
  bool _ignoreEmojiOnly = true;
  String? _generatedPairCode;
  String? _pairedRemoteRoom;

  String _selectedVoiceKey = 'pt-PT-DuarteNeural';
  double _speechRate = 0.5;

  final Map<String, Map<String, String>> _neuralVoices = {
    'pt-PT-DuarteNeural': {'label': 'Masculina PT-PT (Duarte)', 'pitch': '+0Hz', 'gender': 'male'},
    'pt-PT-DuarteNeural|grave': {'label': 'Masculina PT-PT Grave (Locutor)', 'pitch': '-18Hz', 'gender': 'male'},
    'pt-PT-RaquelNeural': {'label': 'Feminina PT-PT (Raquel)', 'pitch': '+0Hz', 'gender': 'female'},
    'pt-PT-RaquelNeural|aguda': {'label': 'Feminina PT-PT Energética', 'pitch': '+14Hz', 'gender': 'female'},
    'pt-BR-AntonioNeural': {'label': 'Masculina PT-BR (António)', 'pitch': '+0Hz', 'gender': 'male'},
    'pt-BR-FranciscaNeural': {'label': 'Feminina PT-BR (Francisca)', 'pitch': '+0Hz', 'gender': 'female'},
    'en-US-GuyNeural': {'label': 'Masculina Inglês (Guy)', 'pitch': '+0Hz', 'gender': 'male'},
    'en-US-JennyNeural': {'label': 'Feminina Inglês (Jenny)', 'pitch': '+0Hz', 'gender': 'female'},
    'es-ES-AlvaroNeural': {'label': 'Masculina Espanhol (Álvaro)', 'pitch': '+0Hz', 'gender': 'male'},
  };

  List<Map<String, dynamic>> _topGifts = [];
  List<Map<String, dynamic>> _topLikes = [];
  final List<Map<String, String>> _chatFeed = [];
  List<Map<String, String>> _sounds = [];
  List<Map<String, String>> _gifs = [];
  List<dynamic> _onlineGifResults = [];
  bool _searchingGifs = false;

  String _followerGif = 'https://giphy.com';
  String _likeMilestoneGif = 'https://giphy.com';
  String _donationImageBase64OrUrl = 'https://giphy.com';
  String _donationFileLabel = 'Imagem padrão';

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
    if (_isMuted) return;
    final info = _neuralVoices[_selectedVoiceKey]!;
    final voiceName = _selectedVoiceKey.split('|').first;
    final pitch = info['pitch'] ?? '+0Hz';
    final isMale = info['gender'] == 'male';
    final ratePct = '${((_speechRate - 0.5) * 100).round() >= 0 ? "+" : ""}${((_speechRate - 0.5) * 100).round()}%';

    try {
      final uri = Uri.parse('$serverUrl/tts').replace(queryParameters: {
        'text': text,
        'voice': voiceName,
        'rate': ratePct,
        'pitch': pitch,
      });
      await ttsAudioPlayer.stop();
      await ttsAudioPlayer.play(UrlSource(uri.toString())).timeout(const Duration(seconds: 6));
    } catch (_) {
      // Se o servidor estiver a acordar, ajusta o tom do motor local para masculino/feminino real
      await flutterTts.setLanguage(voiceName.startsWith('pt-BR') ? 'pt-BR' : (voiceName.startsWith('en') ? 'en-US' : 'pt-PT'));
      await flutterTts.setPitch(isMale ? 0.62 : 1.18);
      await flutterTts.setSpeechRate(_speechRate);
      await flutterTts.speak(text);
    }
  }

  Future<void> _toggleMuteState() async {
    setState(() => _isMuted = !_isMuted);
    if (_isMuted) {
      await ttsAudioPlayer.stop();
      await sfxAudioPlayer.stop();
      await flutterTts.stop();
      _showSnack('Som e alertas cortados!');
    } else {
      _showSnack('Som e alertas ativos!');
    }
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
          backgroundColor: Theme.of(context).cardColor,
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
      if (data['command'] == 'toggle_mute' || data['command'] == 'panic') _toggleMuteState();
      if (!_isMuted && data['command'] == 'sound' && data['payload'] != null) {
        sfxAudioPlayer.play(UrlSource(data['payload']));
      }
    });
    socket.on('live_event', (data) {
      final event = Map<String, dynamic>.from(data);
      final user = event['user'] ?? 'Alguém';
      final msg = (event['message'] ?? '').toString();

      setState(() {
        _chatFeed.insert(0, {'user': user, 'msg': msg, 'type': event['type'] ?? 'chat'});
        if (_chatFeed.length > 40) _chatFeed.removeLast();
      });

      if (_isMuted) return;

      if (event['type'] == 'gift') {
        final room = _channelCtrl.text.trim();
        final giftName = (event['giftName'] ?? '').toString().toLowerCase();
        final match = DefaultMediaLibrary.tiktokGiftsCatalog.firstWhere(
          (g) => giftName.contains(g['name'].toString().split(' ').first.toLowerCase()),
          orElse: () => DefaultMediaLibrary.tiktokGiftsCatalog.first,
        );
        if (room.isNotEmpty) {
          socket.emit('trigger_overlay_alert', {
            'room': room,
            'alertData': {'user': '$user $msg', 'message': '', 'gifUrl': match['gif'], 'soundUrl': match['sound'], 'duration': 5}
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
  void _openSinglePlatformDialog(String platformId, String platformName) {
    setState(() => _selectedPlatform = platformId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFF1E78FF))),
        title: Row(
          children: [
            PlatformBrandLogo(platform: platformId, size: 22),
            const SizedBox(width: 10),
            Text('Ligar ao $platformName'),
          ],
        ),
        content: TextField(
          controller: _channelCtrl,
          decoration: InputDecoration(
            labelText: 'Nome de utilizador / Canal ($platformName)',
            prefixIcon: const Icon(Icons.alternate_email),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
            onPressed: () async {
              await _saveSettings();
              final user = _channelCtrl.text.trim();
              if (user.isNotEmpty) {
                socket.emit('connect_platform', {'platform': platformId, 'username': user});
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Conectar', style: TextStyle(color: Colors.white)),
          ),
        ],
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
      _showSnack('Som adicionado à biblioteca!');
    }
  }

  Future<void> _pickLocalDonationImage() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res != null && res.files.single.path != null) {
      final bytes = await File(res.files.single.path!).readAsBytes();
      final ext = (res.files.single.extension ?? 'png').toLowerCase();
      final mime = ext == 'gif' ? 'image/gif' : 'image/png';
      setState(() {
        _donationImageBase64OrUrl = 'data:$mime;base64,${base64Encode(bytes)}';
        _donationFileLabel = res.files.single.name;
      });
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
    final platforms = [
      {'id': 'tiktok', 'name': 'TikTok'},
      {'id': 'twitch', 'name': 'Twitch'},
      {'id': 'youtube', 'name': 'YouTube'},
      {'id': 'kick', 'name': 'Kick'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(Icons.circle, size: 10, color: _liveConnected ? Colors.greenAccent : (_isConnectedToServer ? Colors.orangeAccent : Colors.redAccent)),
            const SizedBox(width: 8),
            Text(
              _liveConnected ? 'Em Direto: ${_selectedPlatform.toUpperCase()} (${_channelCtrl.text})' : 'Toca numa plataforma para ligar a tua live:',
              style: const TextStyle(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.92,
          children: platforms.map((p) {
            final id = p['id']!;
            final name = p['name']!;
            final isActive = _liveConnected && _selectedPlatform == id;
            return InkWell(
              onTap: () => _openSinglePlatformDialog(id, name),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isActive ? Colors.greenAccent : const Color(0xFF1E429F), width: isActive ? 2 : 1.2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PlatformBrandLogo(platform: id, size: 26),
                    const SizedBox(height: 6),
                    Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _menuTile(Icons.notifications_active_outlined, AppTranslations.t(_appLang, 'alerts'), () => setState(() => _selectedIndex = 1), badge: 'TIKFINITY'),
        _menuTile(Icons.chat_bubble_outline, AppTranslations.t(_appLang, 'comments'), () => setState(() => _selectedIndex = 2)),
        _menuTile(Icons.emoji_events_outlined, AppTranslations.t(_appLang, 'podium'), () => setState(() => _selectedIndex = 3)),
        _menuTile(Icons.casino_outlined, AppTranslations.t(_appLang, 'interaction'), () => setState(() => _selectedIndex = 4)),
        _menuTile(Icons.layers_outlined, AppTranslations.t(_appLang, 'studio'), () => setState(() => _selectedIndex = 5)),
        _menuTile(Icons.grid_view_rounded, AppTranslations.t(_appLang, 'stream_deck'), () => setState(() => _selectedIndex = 6), badge: 'DECK'),
        _menuTile(Icons.public, AppTranslations.t(_appLang, 'community'), () => setState(() => _selectedIndex = 7), badge: 'MUNDO'),
        _menuTile(Icons.favorite_border, AppTranslations.t(_appLang, 'about'), () => setState(() => _selectedIndex = 8)),
        _menuTile(Icons.settings_outlined, AppTranslations.t(_appLang, 'settings'), () => setState(() => _selectedIndex = 9)),
      ],
    );
  }
  Widget _buildSuperAlertsTab() {
    final cleanRoom = (_channelCtrl.text.trim().isEmpty ? 'teu_canal' : _channelCtrl.text.trim()).toLowerCase().replaceAll('@', '');
    final donateUrl = '$serverUrl/doar/$cleanRoom';

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFF38BDF8),
            labelColor: Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: '🎁 Presentes TikTok'),
              Tab(text: '❤️ Seguidores & Likes'),
              Tab(text: '🎯 Metas & Doações'),
              Tab(text: '🎞️ Biblioteca GIF/Som'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Catálogo de Presentes (Toca para testar na live):', style: TextStyle(fontSize: 13, color: Colors.white70)),
                    const SizedBox(height: 10),
                    ...DefaultMediaLibrary.tiktokGiftsCatalog.map((g) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: _neonCard(),
                          child: ListTile(
                            leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(g['gif'], width: 42, height: 42, fit: BoxFit.cover)),
                            title: Text(g['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${g['coins']} moedas · Som & GIF configurados', style: const TextStyle(fontSize: 11.5, color: Colors.white54)),
                            trailing: IconButton(
                              icon: const Icon(Icons.play_circle_fill, color: Color(0xFF38BDF8)),
                              onPressed: () {
                                if (_channelCtrl.text.trim().isNotEmpty) {
                                  socket.emit('trigger_overlay_alert', {
                                    'room': _channelCtrl.text.trim(),
                                    'alertData': {'user': 'Apoiante enviou ${g['name']}!', 'message': '', 'gifUrl': g['gif'], 'soundUrl': g['sound'], 'duration': 5}
                                  });
                                }
                                sfxAudioPlayer.play(UrlSource(g['sound']));
                                _showSnack('Alerta "${g['name']}" disparado!');
                              },
                            ),
                          ),
                        )),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _neonCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Alerta de Novo Seguidor', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                          const SizedBox(height: 8),
                          ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(_followerGif, height: 100, fit: BoxFit.cover)),
                          const SizedBox(height: 8),
                          const Text('Toca num GIF na aba Biblioteca para trocar este visual.', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _neonCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Alerta de Meta Individual de Likes (Com Foto de Perfil)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF43F5E))),
                          const SizedBox(height: 8),
                          ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(_likeMilestoneGif, height: 100, fit: BoxFit.cover)),
                          const SizedBox(height: 8),
                          const Text('Dispara automaticamente a cada 500 likes enviados por um seguidor com a foto dele na tela!', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                        ],
                      ),
                    ),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _neonCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🎯 Barra de Meta Personalizada', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                          const SizedBox(height: 8),
                          TextField(controller: _goalTitleCtrl, decoration: const InputDecoration(labelText: 'Texto da Meta')),
                          const SizedBox(height: 8),
                          TextField(controller: _goalTargetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Objetivo (ex: 5000)')),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                              onPressed: () {
                                socket.emit('update_goal', {
                                  'room': cleanRoom,
                                  'goal': {'title': _goalTitleCtrl.text.trim(), 'target': int.tryParse(_goalTargetCtrl.text.trim()) ?? 5000}
                                });
                                _showSnack('Meta atualizada na live!');
                              },
                              child: const Text('Atualizar Meta', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _neonCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💸 Doações Diretas (PNG/GIF + MB Way / PIX)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(onPressed: _pickLocalDonationImage, icon: const Icon(Icons.image), label: Text('Imagem ($_donationFileLabel)')),
                          const SizedBox(height: 8),
                          TextField(controller: _mbwayCtrl, decoration: const InputDecoration(labelText: 'MB Way')),
                          const SizedBox(height: 8),
                          TextField(controller: _pixCtrl, decoration: const InputDecoration(labelText: 'Chave PIX')),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                                  onPressed: () {
                                    socket.emit('update_donation_config', {
                                      'room': cleanRoom,
                                      'config': {'mbway': _mbwayCtrl.text.trim(), 'pix': _pixCtrl.text.trim(), 'imageData': _donationImageBase64OrUrl}
                                    });
                                    _showSnack('Doações guardadas!');
                                  },
                                  child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: donateUrl));
                                    _showSnack('Link de Doação copiado!');
                                  },
                                  child: const Text('Copiar Link'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _gifSearchCtrl, decoration: const InputDecoration(hintText: 'Pesquisar GIFs online...', border: OutlineInputBorder(), isDense: true))),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                          onPressed: () => _searchOnlineGifs(_gifSearchCtrl.text),
                          child: const Icon(Icons.search, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_searchingGifs) const Center(child: CircularProgressIndicator()),
                    if (_onlineGifResults.isNotEmpty) ...[
                      const Text('Resultados Online (Toca para aplicar aos Seguidores):', style: TextStyle(fontSize: 12, color: Color(0xFF38BDF8))),
                      const SizedBox(height: 6),
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
                                _followerGif = item['url'];
                                _gifs.insert(0, {'name': item['title'] ?? 'GIF', 'url': item['url']});
                              });
                              _showSnack('GIF aplicado ao alerta de Seguidores!');
                            },
                            child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(item['url'], fit: BoxFit.cover)),
                          );
                        },
                      ),
                      const Divider(height: 20),
                    ],
                    const Text('Biblioteca de GIFs:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: _gifs.length,
                      itemBuilder: (ctx, i) {
                        final g = _gifs[i];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _followerGif = g['url']!);
                            _showSnack('GIF "${g['name']}" aplicado!');
                          },
                          child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(g['url']!, fit: BoxFit.cover)),
                        );
                      },
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Biblioteca de Sons:', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton.icon(onPressed: _importLocalSound, icon: const Icon(Icons.upload_file, size: 18), label: const Text('+ Importar MP3')),
                      ],
                    ),
                    ..._sounds.map((s) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.play_arrow, color: Color(0xFF38BDF8)),
                          title: Text(s['name'] ?? ''),
                          onTap: () async {
                            await sfxAudioPlayer.stop();
                            if ((s['path'] ?? '').isNotEmpty) {
                              await sfxAudioPlayer.play(DeviceFileSource(s['path']!));
                            } else if ((s['url'] ?? '').isNotEmpty) {
                              await sfxAudioPlayer.play(UrlSource(s['url']!));
                            }
                          },
                        )),
                  ],
                ),
              ],
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
          decoration: _neonCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Leitura por Voz do Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 8),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                  onPressed: () => _speakNeural('Olá! Esta é a voz do HELL Live a ler os comentários da tua transmissão!'),
                  icon: const Icon(Icons.volume_up, color: Colors.white),
                  label: const Text('Testar Voz Selecionada', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('💬 Chat Ao Vivo (Toca numa mensagem para destacar na tela)', style: TextStyle(fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 8),
        if (_chatFeed.isEmpty)
          const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Os comentários da tua live vão aparecer aqui.', style: TextStyle(color: Colors.white38))))
        else
          ..._chatFeed.map((c) => Card(
                color: const Color(0xFF0B1636),
                child: ListTile(
                  title: Text(c['user'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 13)),
                  subtitle: Text(c['msg'] ?? ''),
                  trailing: const Icon(Icons.push_pin_outlined, size: 18, color: Colors.white54),
                  onTap: () {
                    final room = _channelCtrl.text.trim();
                    if (room.isNotEmpty) {
                      socket.emit('pin_chat_message', {'room': room, 'user': c['user'], 'message': c['msg']});
                      _showSnack('Comentário destacado na tela da live!');
                    }
                  },
                ),
              )),
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
    if (_selectedIndex == 6) {
      return StreamDeckScreen(
        socket: socket,
        activeRoom: _channelCtrl.text.trim(),
        generatedCode: _generatedPairCode,
        pairedRoom: _pairedRemoteRoom,
        isMuted: _isMuted,
        onToggleMute: _toggleMuteState,
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
          if (cmd == 'sound' && val != null && !_isMuted) {
            if (val.toString().startsWith('http')) {
              sfxAudioPlayer.play(UrlSource(val));
            } else {
              sfxAudioPlayer.play(DeviceFileSource(val));
            }
          }
          if (cmd == 'test_alert' && target.isNotEmpty) {
            socket.emit('trigger_overlay_alert', {
              'room': target,
              'alertData': {'user': 'Teste Stream Deck', 'message': 'Alerta disparado pela consola!', 'gifUrl': _followerGif, 'duration': 5}
            });
          } else if (target.isNotEmpty) {
            socket.emit('remote_command', {'room': target, 'command': cmd, 'payload': val});
          }
        },
        onMinimizeDeck: () => setState(() => _selectedIndex = 0),
      );
    }

    final titles = [
      '',
      AppTranslations.t(_appLang, 'alerts'),
      AppTranslations.t(_appLang, 'comments'),
      AppTranslations.t(_appLang, 'podium'),
      AppTranslations.t(_appLang, 'interaction'),
      AppTranslations.t(_appLang, 'studio'),
      'Stream Deck',
      AppTranslations.t(_appLang, 'community'),
      AppTranslations.t(_appLang, 'about'),
      AppTranslations.t(_appLang, 'settings'),
    ];

    final screens = [
      _buildHomeTab(),
      _buildSuperAlertsTab(),
      _buildCommentsTab(),
      PodiumScreen(socket: socket, roomName: _channelCtrl.text.trim(), topGifts: _topGifts, topLikes: _topLikes),
      InteractionScreen(socket: socket, roomName: _channelCtrl.text.trim()),
      OverlayStudioScreen(socket: socket, serverUrl: serverUrl, roomName: _channelCtrl.text.trim()),
      const SizedBox(),
      CommunityGlobeScreen(serverUrl: serverUrl),
      const AboutHellLiveScreen(),
      _buildSettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: _selectedIndex == 0
            ? const SizedBox()
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedIndex = 0)),
        title: _selectedIndex == 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('icon.png', height: 32, errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, color: Color(0xFF38BDF8), size: 28)),
                  const SizedBox(width: 8),
                  const Text('HELL ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 2)),
                  const Text('Live', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Color(0xFF38BDF8))),
                ],
              )
            : Text(titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _toggleMuteState,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isMuted ? Colors.redAccent : Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: const Text(
          'A tua live, no teu comando.  ·  LIVE  ·  PLAY  ·  CONNECT',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: Color(0xFF7DD3FC), fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
