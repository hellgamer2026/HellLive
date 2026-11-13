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
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'app_data.dart';
import 'studio_screens.dart';
import 'deck_and_community.dart';
import 'platform_logos.dart';
import 'account_security.dart';
import 'music_and_social.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
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

    Timer(const Duration(milliseconds: 2400), () async {
      if (!mounted) return;
      final savedUser = await UserAccountManager.getSavedUser();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, __, ___) => AuthGateScreen(
            initialUser: savedUser,
            currentTheme: widget.currentTheme,
            onThemeChanged: widget.onThemeChanged,
          ),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
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
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _titleOpacity,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: Column(
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('HELL ', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white)),
                            Text('Live', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: 2, color: Color(0xFF38BDF8))),
                          ],
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

class AuthGateScreen extends StatefulWidget {
  final Map<String, dynamic>? initialUser;
  final String currentTheme;
  final Function(String) onThemeChanged;

  const AuthGateScreen({super.key, required this.initialUser, required this.currentTheme, required this.onThemeChanged});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  Map<String, dynamic>? _user;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    if (_user != null && (_user!['securityType'] == null || _user!['securityType'] == 'none')) {
      _unlocked = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return AuthScreen(
        onAuthenticated: (u) => setState(() {
          _user = u;
          _unlocked = true;
        }),
      );
    }

    if (!_unlocked) {
      return AppLockScreen(
        user: _user!,
        onUnlocked: () => setState(() => _unlocked = true),
        onLogout: () async {
          await UserAccountManager.logout();
          setState(() {
            _user = null;
            _unlocked = false;
          });
        },
      );
    }

    return MainShell(
      user: _user!,
      onUserUpdated: (updated) => setState(() => _user = updated),
      onLogout: () async {
        await UserAccountManager.logout();
        setState(() {
          _user = null;
          _unlocked = false;
        });
      },
      currentTheme: widget.currentTheme,
      onThemeChanged: widget.onThemeChanged,
    );
  }
}

class MainShell extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(Map<String, dynamic>) onUserUpdated;
  final VoidCallback onLogout;
  final String currentTheme;
  final Function(String) onThemeChanged;

  const MainShell({
    super.key,
    required this.user,
    required this.onUserUpdated,
    required this.onLogout,
    required this.currentTheme,
    required this.onThemeChanged,
  });

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
  final AudioPlayer bgMusicPlayer = AudioPlayer();

  final TextEditingController _channelCtrl = TextEditingController();
  final TextEditingController _gifSearchCtrl = TextEditingController();
  final TextEditingController _mbwayCtrl = TextEditingController();
  final TextEditingController _pixCtrl = TextEditingController();
  final TextEditingController _paypalCtrl = TextEditingController();
  final TextEditingController _revolutCtrl = TextEditingController();
  final TextEditingController _donateMsgCtrl = TextEditingController(text: 'Apoia a live e aparece no ecrã!');

  String _selectedPlatform = 'tiktok';
  String _selectedEncoder = 'OBS Studio';
  bool _isConnectedToServer = false;
  bool _liveConnected = false;
  bool _isMuted = false;

  // Configurações Chat TTS & Voz Masculina Real
  bool _ttsEnabled = true;
  String _selectedVoiceKey = 'pt-PT-DuarteNeural';
  double _speechRate = 0.5;
  double _voicePitch = 0.72; // Tom grave masculino por defeito
  double _voiceVolume = 1.0;
  List<dynamic> _deviceVoices = [];

  // Permissões de Utilizadores no Chat TTS
  bool _allowAllUsers = true;
  bool _allowFollowers = true;
  bool _allowSubscribers = true;
  bool _allowModerators = true;
  bool _allowTeamLevel1 = true;
  bool _allowTop3Donors = true;
  final List<String> _specialUsers = ['hellgamer2026'];

  // Filtros de Conteúdo Pop-up
  bool _filterProfanity = true;
  bool _exemptModerators = true;
  bool _blockOtherAlphabets = false;
  String _filterLanguage = 'Português';
  final List<String> _blockedWords = ['spam', 'bot'];

  final Map<String, Map<String, String>> _neuralVoices = {
    'pt-PT-DuarteNeural': {'label': 'Masculina PT-PT (Duarte)', 'pitch': '-8Hz', 'gender': 'male'},
    'pt-PT-DuarteNeural|grave': {'label': 'Masculina PT-PT Grave (Locutor)', 'pitch': '-22Hz', 'gender': 'male'},
    'pt-BR-AntonioNeural': {'label': 'Masculina PT-BR (António)', 'pitch': '-6Hz', 'gender': 'male'},
    'pt-PT-RaquelNeural': {'label': 'Feminina PT-PT (Raquel)', 'pitch': '+0Hz', 'gender': 'female'},
    'pt-BR-FranciscaNeural': {'label': 'Feminina PT-BR (Francisca)', 'pitch': '+0Hz', 'gender': 'female'},
    'en-US-GuyNeural': {'label': 'Masculina Inglês (Guy)', 'pitch': '-6Hz', 'gender': 'male'},
    'en-US-JennyNeural': {'label': 'Feminina Inglês (Jenny)', 'pitch': '+0Hz', 'gender': 'female'},
    'es-ES-AlvaroNeural': {'label': 'Masculina Espanhol (Álvaro)', 'pitch': '-6Hz', 'gender': 'male'},
  };

  // Listas Dinâmicas da Aba Ações (Presentes, Alertas e Metas)
  bool _allGiftsEnabled = true;
  final List<Map<String, dynamic>> _alertsList = [
    {'id': 'a1', 'name': 'Novo Seguidor', 'enabled': true, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'id': 'a2', 'name': 'Meta 500 Likes', 'enabled': true, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'id': 'a3', 'name': 'Novo Subscritor / VIP', 'enabled': true, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'id': 'a4', 'name': 'Partilha da Live (Share)', 'enabled': true, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'id': 'a5', 'name': 'Comentário Especial Chat', 'enabled': false, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
  ];

  final List<Map<String, dynamic>> _goalsList = [
    {'id': 'm1', 'title': 'Meta de Likes da Live', 'target': 5000, 'current': 1250, 'style': 'Néon Cyber', 'enabled': true},
    {'id': 'm2', 'title': 'Novos Seguidores Hoje', 'target': 100, 'current': 42, 'style': 'Fogo TikFinity', 'enabled': true},
  ];

  List<Map<String, dynamic>> _topGifts = [];
  List<Map<String, dynamic>> _topLikes = [];
  final List<Map<String, String>> _chatFeed = [];
  List<Map<String, String>> _sounds = [];
  List<Map<String, String>> _gifs = [];
  List<dynamic> _onlineGifResults = [];
  bool _searchingGifs = false;

  String _donationImageBase64OrUrl = 'https://giphy.com';
  String _donationSoundUrl = 'https://google.com';
  String _donationFileLabel = 'Imagem padrão';
  String? _generatedPairCode;
  String? _pairedRemoteRoom;

  @override
  void initState() {
    super.initState();
    _sounds = List<Map<String, String>>.from(DefaultMediaLibrary.builtInSounds);
    _gifs = List<Map<String, String>>.from(DefaultMediaLibrary.builtInGifs);
    _initLocalVoices();
    _loadSettings();
    _initSocket();
  }

  Future<void> _initLocalVoices() async {
    try {
      final voices = await flutterTts.getVoices;
      if (voices is List) _deviceVoices = voices;
    } catch (_) {}
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
      _voicePitch = prefs.getDouble('tts_pitch') ?? 0.72;
      _voiceVolume = prefs.getDouble('tts_volume') ?? 1.0;
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
    await prefs.setDouble('tts_pitch', _voicePitch);
    await prefs.setDouble('tts_volume', _voiceVolume);
  }

  Future<void> _speakNeural(String text) async {
    if (_isMuted) return;
    final info = _neuralVoices[_selectedVoiceKey]!;
    final voiceName = _selectedVoiceKey.split('|').first;
    final isMale = info['gender'] == 'male';
    final pitchDelta = ((_voicePitch - 1.0) * 35).round();
    final pitchStr = '${pitchDelta >= 0 ? "+" : ""}${pitchDelta}Hz';
    final ratePct = '${((_speechRate - 0.5) * 100).round() >= 0 ? "+" : ""}${((_speechRate - 0.5) * 100).round()}%';

    try {
      final uri = Uri.parse('$serverUrl/tts').replace(queryParameters: {
        'text': text,
        'voice': voiceName,
        'rate': ratePct,
        'pitch': pitchStr,
      });
      await ttsAudioPlayer.stop();
      await ttsAudioPlayer.setVolume(_voiceVolume);
      await ttsAudioPlayer.play(UrlSource(uri.toString())).timeout(const Duration(seconds: 5));
    } catch (_) {
      final langCode = voiceName.startsWith('pt-BR') ? 'pt-BR' : (voiceName.startsWith('en') ? 'en-US' : 'pt-PT');
      await flutterTts.setLanguage(langCode);

      if (_deviceVoices.isNotEmpty) {
        final matching = _deviceVoices.where((v) {
          final loc = (v['locale'] ?? '').toString().toLowerCase();
          final name = (v['name'] ?? '').toString().toLowerCase();
          final langMatch = loc.contains(langCode.toLowerCase().substring(0, 2));
          if (!langMatch) return false;
          if (isMale) {
            return name.contains('male') || name.contains('duarte') || name.contains('antonio') || name.contains('daniel') || name.contains('jfb') || name.contains('afs');
          } else {
            return name.contains('female') || name.contains('raquel') || name.contains('francisca') || name.contains('maria');
          }
        }).toList();
        if (matching.isNotEmpty) {
          await flutterTts.setVoice({'name': matching.first['name'], 'locale': matching.first['locale']});
        }
      }
      final effectivePitch = isMale ? (_voicePitch > 0.85 ? 0.65 : _voicePitch) : _voicePitch;
      await flutterTts.setPitch(effectivePitch);
      await flutterTts.setVolume(_voiceVolume);
      await flutterTts.setSpeechRate(_speechRate);
      await flutterTts.speak(text);
    }
  }

  Future<void> _toggleMuteState() async {
    setState(() => _isMuted = !_isMuted);
    if (_isMuted) {
      await ttsAudioPlayer.stop();
      await sfxAudioPlayer.stop();
      await bgMusicPlayer.pause();
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

      if (event['type'] == 'gift' && _allGiftsEnabled) {
        final room = _channelCtrl.text.trim();
        final giftName = (event['giftName'] ?? '').toString().toLowerCase();
        final match = DefaultMediaLibrary.tiktokGiftsCatalog.firstWhere(
          (g) => giftName.contains(g['name'].toString().split(' ').first.toLowerCase()),
          orElse: () => DefaultMediaLibrary.tiktokGiftsCatalog.first,
        );
        if (room.isNotEmpty && match['enabled'] == true) {
          socket.emit('trigger_overlay_alert', {
            'room': room,
            'alertData': {'user': '$user $msg', 'message': '', 'gifUrl': match['gif'], 'soundUrl': match['sound'], 'duration': 5}
          });
        }
      }

      if (_ttsEnabled) {
        if (_filterProfanity && _blockedWords.any((w) => msg.toLowerCase().contains(w.toLowerCase()))) return;
        if (_blockOtherAlphabets && RegExp(r'[^\x00-\x7FÀ-ÿ]').hasMatch(msg)) return;
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
    final isTikTok = platformId == 'tiktok';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cleanUser = (_channelCtrl.text.trim().isEmpty ? 'teu_canal' : _channelCtrl.text.trim()).toLowerCase().replaceAll('@', '');
          final overlayLink = '$serverUrl/overlay/$cleanUser';

          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFF1E78FF))),
            title: Row(
              children: [
                PlatformBrandLogo(platform: platformId, size: 22),
                const SizedBox(width: 10),
                Text('Ligar $platformName'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _channelCtrl,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Utilizador / Canal ($platformName)',
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isTikTok) ...[
                    const Text('Integração Direta TikTok Live Studio:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: overlayLink));
                              _showSnack('Link para TikTok Live Studio copiado!');
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copiar Diretório', style: TextStyle(fontSize: 11.5)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse('https://tiktok.com');
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Abrir Studio', style: TextStyle(fontSize: 11.5)),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text('Conectar Transmissão via Software:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                    const SizedBox(height: 6),
                    Row(
                      children: ['OBS Studio', 'Streamlabs'].map((enc) {
                        final sel = _selectedEncoder == enc;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ChoiceChip(
                              label: Text(enc, style: const TextStyle(fontSize: 11.5)),
                              selected: sel,
                              selectedColor: const Color(0xFF1E78FF),
                              onSelected: (_) => setDialogState(() => _selectedEncoder = enc),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: overlayLink));
                          _showSnack('Diretório Browser Source para $_selectedEncoder copiado!');
                        },
                        icon: const Icon(Icons.link, size: 18),
                        label: Text('Copiar Diretório para $_selectedEncoder', style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ],
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
                child: const Text('Iniciar Interação', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _searchOnlineGifs(String query, StateSetter setModalState) async {
    if (query.trim().isEmpty) return;
    setModalState(() => _searchingGifs = true);
    try {
      final res = await http.get(Uri.parse('$serverUrl/search/gifs?q=${Uri.encodeComponent(query)}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setModalState(() => _onlineGifResults = data['results'] ?? []);
      }
    } catch (_) {}
    setModalState(() => _searchingGifs = false);
  }

  void _openMediaPickerForAlert({
    required String title,
    String? initialGif,
    String? initialSound,
    required Function(String gifUrl, String soundUrl) onSelected,
  }) {
    String chosenGif = initialGif ?? DefaultMediaLibrary.builtInGifs.first['url']!;
    String chosenSound = initialSound ?? DefaultMediaLibrary.builtInSounds.first['url']!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SizedBox(
            height: 490,
            child: ListView(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Biblioteca GIF & Som · $title', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)))),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                      onPressed: () async {
                        await sfxAudioPlayer.stop();
                        if (chosenSound.startsWith('http')) {
                          await sfxAudioPlayer.play(UrlSource(chosenSound));
                        } else {
                          await sfxAudioPlayer.play(DeviceFileSource(chosenSound));
                        }
                      },
                      icon: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                      label: const Text('Testar em Off', style: TextStyle(color: Colors.white, fontSize: 11.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(chosenGif, width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.gif, size: 60)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _gifSearchCtrl, decoration: const InputDecoration(hintText: 'Pesquisar GIFs online...', isDense: true, border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                      onPressed: () => _searchOnlineGifs(_gifSearchCtrl.text, setModalState),
                      child: const Icon(Icons.search, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_searchingGifs) const Center(child: CircularProgressIndicator()),
                SizedBox(
                  height: 76,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._onlineGifResults.map((item) => GestureDetector(
                            onTap: () => setModalState(() => chosenGif = item['url']),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(border: Border.all(color: chosenGif == item['url'] ? Colors.cyanAccent : Colors.transparent, width: 2), borderRadius: BorderRadius.circular(8)),
                              child: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(item['url'], width: 72, height: 72, fit: BoxFit.cover)),
                            ),
                          )),
                      ...DefaultMediaLibrary.builtInGifs.map((g) => GestureDetector(
                            onTap: () => setModalState(() => chosenGif = g['url']!),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(border: Border.all(color: chosenGif == g['url'] ? Colors.cyanAccent : Colors.transparent, width: 2), borderRadius: BorderRadius.circular(8)),
                              child: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(g['url']!, width: 72, height: 72, fit: BoxFit.cover)),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Escolher Som (Toca para ouvir em off):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    TextButton.icon(
                      onPressed: () async {
                        final res = await FilePicker.platform.pickFiles(type: FileType.audio);
                        if (res != null && res.files.single.path != null) {
                          setModalState(() {
                            chosenSound = res.files.single.path!;
                            _sounds.insert(0, {'name': res.files.single.name, 'url': res.files.single.path!});
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text('+ MP3 Local'),
                    ),
                  ],
                ),
                ...DefaultMediaLibrary.builtInSounds.map((s) => RadioListTile<String>(
                      dense: true,
                      activeColor: const Color(0xFF38BDF8),
                      title: Text(s['name'] ?? ''),
                      value: s['url'] ?? '',
                      groupValue: chosenSound,
                      onChanged: (v) async {
                        if (v != null) {
                          setModalState(() => chosenSound = v);
                          await sfxAudioPlayer.stop();
                          await sfxAudioPlayer.play(UrlSource(v));
                        }
                      },
                    )),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 13)),
                  onPressed: () {
                    onSelected(chosenGif, chosenSound);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Guardar GIF e Som', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCreatePresentDialog() {
    final nameCtrl = TextEditingController();
    final coinsCtrl = TextEditingController(text: '10');
    String gif = DefaultMediaLibrary.builtInGifs.first['url']!;
    String snd = DefaultMediaLibrary.builtInSounds.first['url']!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1636),
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Color(0xFF38BDF8)),
            SizedBox(width: 8),
            Text('Criar Novo Presente Personalizado', style: TextStyle(fontSize: 15)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome do Presente')),
            const SizedBox(height: 8),
            TextField(controller: coinsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor em Moedas')),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openMediaPickerForAlert(
                title: 'Novo Presente',
                onSelected: (g, s) {
                  gif = g;
                  snd = s;
                },
              ),
              icon: const Icon(Icons.perm_media),
              label: const Text('Escolher GIF & Som'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  DefaultMediaLibrary.tiktokGiftsCatalog.insert(0, {
                    'id': 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    'name': nameCtrl.text.trim(),
                    'coins': int.tryParse(coinsCtrl.text.trim()) ?? 10,
                    'enabled': true,
                    'gif': gif,
                    'sound': snd,
                  });
                });
                Navigator.pop(ctx);
                _showSnack('Presente criado!');
              }
            },
            child: const Text('Criar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openGoalStyleDialog(Map<String, dynamic> goal) {
    final titleCtrl = TextEditingController(text: goal['title']);
    final targetCtrl = TextEditingController(text: '${goal['target']}');
    String selectedStyle = goal['style'] ?? 'Néon Cyber';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF0B1636),
          title: const Text('Personalizar Barra de Meta', style: TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título da Meta')),
              const SizedBox(height: 8),
              TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Objetivo')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedStyle,
                dropdownColor: const Color(0xFF050B1E),
                decoration: const InputDecoration(labelText: 'Estilo Visual da Barra (TikFinity)'),
                items: const [
                  DropdownMenuItem(value: 'Néon Cyber', child: Text('Néon Cyber (Azul Elétrico)')),
                  DropdownMenuItem(value: 'Fogo TikFinity', child: Text('Fogo TikFinity (Laranja/Vermelho)')),
                  DropdownMenuItem(value: 'Ouro VIP', child: Text('Ouro VIP (Dourado Brilhante)')),
                  DropdownMenuItem(value: 'Minimalista Glass', child: Text('Minimalista Glass (Transparente)')),
                ],
                onChanged: (v) => setModalState(() => selectedStyle = v ?? 'Néon Cyber'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
              onPressed: () {
                setState(() {
                  goal['title'] = titleCtrl.text.trim();
                  goal['target'] = int.tryParse(targetCtrl.text.trim()) ?? 5000;
                  goal['style'] = selectedStyle;
                });
                Navigator.pop(ctx);
                _showSnack('Barra de meta atualizada!');
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddGoalDialog() {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '1000');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1636),
        title: const Text('+ Nova Meta da Live', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Nome da Meta (ex: Meta Subscritores)')),
            const SizedBox(height: 8),
            TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Objetivo Numérico')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _goalsList.add({
                    'id': 'm_${DateTime.now().millisecondsSinceEpoch}',
                    'title': titleCtrl.text.trim(),
                    'target': int.tryParse(targetCtrl.text.trim()) ?? 1000,
                    'current': 0,
                    'style': 'Néon Cyber',
                    'enabled': true,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Criar Meta', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
              _liveConnected ? 'Em Direto: ${_selectedPlatform.toUpperCase()} (${_channelCtrl.text})' : 'Toca numa plataforma para iniciar a ligação:',
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
        _menuTile(Icons.bolt_outlined, AppTranslations.t(_appLang, 'actions'), () => setState(() => _selectedIndex = 1), badge: 'TTS & ALERTAS'),
        _menuTile(Icons.volunteer_activism_outlined, AppTranslations.t(_appLang, 'donation'), () => setState(() => _selectedIndex = 2), badge: 'PAGAMENTOS'),
        _menuTile(Icons.music_note_outlined, AppTranslations.t(_appLang, 'music'), () => setState(() => _selectedIndex = 10), badge: 'SPOTIFY/MP3'),
        _menuTile(Icons.casino_outlined, AppTranslations.t(_appLang, 'interaction'), () => setState(() => _selectedIndex = 4), badge: 'PÓDIO & TEMPO'),
        _menuTile(Icons.widgets_outlined, AppTranslations.t(_appLang, 'overlays'), () => setState(() => _selectedIndex = 5), badge: '1.119 GIFTS'),
        _menuTile(Icons.grid_view_rounded, AppTranslations.t(_appLang, 'stream_deck'), () => setState(() => _selectedIndex = 6), badge: 'DECK'),
        _menuTile(Icons.public, AppTranslations.t(_appLang, 'community'), () => setState(() => _selectedIndex = 7), badge: 'GLOBO 3D'),
        _menuTile(Icons.help_outline, AppTranslations.t(_appLang, 'faq'), () => setState(() => _selectedIndex = 11), badge: 'AJUDA'),
        _menuTile(Icons.favorite_border, AppTranslations.t(_appLang, 'about'), () => setState(() => _selectedIndex = 8)),
        _menuTile(Icons.settings_outlined, AppTranslations.t(_appLang, 'settings'), () => setState(() => _selectedIndex = 9)),
      ],
    );
  }
  void _openContentFiltersPopup() {
    final wordCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF0B1636),
          title: const Text('Filtros de Conteúdo (Chat TTS)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  dense: true,
                  title: const Text('Filtro de Palavrões'),
                  value: _filterProfanity,
                  onChanged: (v) {
                    setState(() => _filterProfanity = v);
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  dense: true,
                  title: const Text('Moderadores Isentos'),
                  value: _exemptModerators,
                  onChanged: (v) {
                    setState(() => _exemptModerators = v);
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  dense: true,
                  title: const Text('Bloquear Outros Alfabetos'),
                  value: _blockOtherAlphabets,
                  onChanged: (v) {
                    setState(() => _blockOtherAlphabets = v);
                    setModalState(() {});
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _filterLanguage,
                  dropdownColor: const Color(0xFF050B1E),
                  decoration: const InputDecoration(labelText: 'Idioma do Filtro', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'Português', child: Text('Português')),
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Español', child: Text('Español')),
                  ],
                  onChanged: (v) {
                    setState(() => _filterLanguage = v ?? 'Português');
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: wordCtrl, decoration: const InputDecoration(hintText: 'Adicionar palavra bloqueada...', isDense: true))),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF38BDF8)),
                      onPressed: () {
                        if (wordCtrl.text.trim().isNotEmpty) {
                          setState(() => _blockedWords.add(wordCtrl.text.trim()));
                          wordCtrl.clear();
                          setModalState(() {});
                        }
                      },
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  children: _blockedWords
                      .map((w) => Chip(
                            label: Text(w, style: const TextStyle(fontSize: 11)),
                            onDeleted: () {
                              setState(() => _blockedWords.remove(w));
                              setModalState(() {});
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Concluir'))],
        ),
      ),
    );
  }

  Widget _buildActionsUnifiedTab() {
    final specialUserCtrl = TextEditingController();

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
              Tab(text: '🎁 Presentes'),
              Tab(text: '🔔 Alertas'),
              Tab(text: '🎯 Metas'),
              Tab(text: '🗣️ Chat TTS'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 1. PRESENTES (Interruptor Geral + Sino Criar + Botão - Eliminar + Lápis Editar)
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: _neonCard(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ativar Todos os Presentes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Switch(
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF1E78FF),
                            value: _allGiftsEnabled,
                            onChanged: (v) => setState(() => _allGiftsEnabled = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _openCreatePresentDialog,
                      icon: const Icon(Icons.notifications_active, color: Colors.white),
                      label: const Text('+ Criar Presente Personalizado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    ...DefaultMediaLibrary.tiktokGiftsCatalog.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final g = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: _neonCard(),
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                tooltip: 'Eliminar Presente',
                                onPressed: () => setState(() => DefaultMediaLibrary.tiktokGiftsCatalog.removeAt(idx)),
                              ),
                              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(g['gif'], width: 38, height: 38, fit: BoxFit.cover)),
                            ],
                          ),
                          title: Text(g['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          subtitle: Text('${g['coins']} moedas', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                                tooltip: 'Personalizar GIF & Som',
                                onPressed: () => _openMediaPickerForAlert(
                                  title: g['name'],
                                  initialGif: g['gif'],
                                  initialSound: g['sound'],
                                  onSelected: (newGif, newSound) => setState(() {
                                    g['gif'] = newGif;
                                    g['sound'] = newSound;
                                  }),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill, color: Color(0xFF38BDF8)),
                                onPressed: () {
                                  if (_channelCtrl.text.trim().isNotEmpty) {
                                    socket.emit('trigger_overlay_alert', {
                                      'room': _channelCtrl.text.trim(),
                                      'alertData': {'user': 'Apoiante enviou ${g['name']}!', 'message': '', 'gifUrl': g['gif'], 'soundUrl': g['sound'], 'duration': 5}
                                    });
                                  }
                                  sfxAudioPlayer.play(UrlSource(g['sound']));
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                // 2. ALERTAS (Seguidores, Likes, Chat, Partilhas, Subs + Botão - + Lápis + Switch Individual)
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () {
                        setState(() {
                          _alertsList.add({
                            'id': 'a_${DateTime.now().millisecondsSinceEpoch}',
                            'name': 'Novo Alerta Personalizado',
                            'enabled': true,
                            'gif': DefaultMediaLibrary.builtInGifs.first['url']!,
                            'sound': DefaultMediaLibrary.builtInSounds.first['url']!,
                          });
                        });
                      },
                      icon: const Icon(Icons.add_alert, color: Colors.white),
                      label: const Text('+ Criar Novo Alerta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    ..._alertsList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final al = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: _neonCard(),
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                tooltip: 'Eliminar Alerta',
                                onPressed: () => setState(() => _alertsList.removeAt(idx)),
                              ),
                              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(al['gif'], width: 38, height: 38, fit: BoxFit.cover)),
                            ],
                          ),
                          title: Text(al['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                                tooltip: 'Personalizar Alerta',
                                onPressed: () => _openMediaPickerForAlert(
                                  title: al['name'],
                                  initialGif: al['gif'],
                                  initialSound: al['sound'],
                                  onSelected: (g, s) => setState(() {
                                    al['gif'] = g;
                                    al['sound'] = s;
                                  }),
                                ),
                              ),
                              Switch(
                                activeColor: Colors.white,
                                activeTrackColor: const Color(0xFF1E78FF),
                                value: al['enabled'] == true,
                                onChanged: (v) => setState(() => al['enabled'] = v),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                // 3. METAS (+ Metas + Botão - + Lápis Estilo TikFinity + Switch Individual)
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _openAddGoalDialog,
                      icon: const Icon(Icons.add_chart, color: Colors.white),
                      label: const Text('+ Metas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    ..._goalsList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final goal = entry.value;
                      final pct = ((goal['current'] as int) / ((goal['target'] as int) == 0 ? 1 : (goal['target'] as int))).clamp(0.0, 1.0);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: _neonCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => setState(() => _goalsList.removeAt(idx)),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(goal['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text('Estilo: ${goal['style']} · ${goal['current']}/${goal['target']}', style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8))),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                                  onPressed: () => _openGoalStyleDialog(goal),
                                ),
                                Switch(
                                  activeColor: Colors.white,
                                  activeTrackColor: const Color(0xFF1E78FF),
                                  value: goal['enabled'] == true,
                                  onChanged: (v) => setState(() => goal['enabled'] = v),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 10,
                                backgroundColor: Colors.white12,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  goal['style'] == 'Fogo TikFinity'
                                      ? Colors.orangeAccent
                                      : (goal['style'] == 'Ouro VIP' ? const Color(0xFFFACC15) : const Color(0xFF38BDF8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                // 4. CHAT TTS (Ativar + Descrição + Voz + Velocidade + Tom + Volume + Permissões + Filtros Pop-up)
                ListView(
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
                              const Text('Chat TTS', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
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
                          const Text(
                            'Aqui podes ouvir os comentários do chat dos teus espetadores lidos automaticamente via Text-to-Speech (TTS).',
                            style: TextStyle(fontSize: 11.5, color: Colors.white60),
                          ),
                          const SizedBox(height: 12),
                          const Text('Voz:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _selectedVoiceKey,
                            dropdownColor: const Color(0xFF0B1636),
                            decoration: InputDecoration(filled: true, fillColor: const Color(0xFF050B1E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true),
                            items: _neuralVoices.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value['label']!))).toList(),
                            onChanged: (v) async {
                              if (v != null) {
                                setState(() => _selectedVoiceKey = v);
                                await _saveSettings();
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          Text('Velocidade Padrão: ${(_speechRate * 2).toStringAsFixed(1)}x', style: const TextStyle(fontSize: 12)),
                          Slider(
                            value: _speechRate,
                            min: 0.2,
                            max: 0.9,
                            activeColor: const Color(0xFF38BDF8),
                            onChanged: (v) {
                              setState(() => _speechRate = v);
                              _saveSettings();
                            },
                          ),
                          Text('Tom Padrão (Grave ↔ Agudo): ${_voicePitch.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                          Slider(
                            value: _voicePitch,
                            min: 0.5,
                            max: 1.5,
                            activeColor: const Color(0xFF38BDF8),
                            onChanged: (v) {
                              setState(() => _voicePitch = v);
                              _saveSettings();
                            },
                          ),
                          Text('Volume: ${(_voiceVolume * 100).round()}%', style: const TextStyle(fontSize: 12)),
                          Slider(
                            value: _voiceVolume,
                            min: 0.0,
                            max: 1.0,
                            activeColor: const Color(0xFF38BDF8),
                            onChanged: (v) {
                              setState(() => _voiceVolume = v);
                              _saveSettings();
                            },
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                              onPressed: () => _speakNeural('Olá! Esta é a voz masculina do HELL Live a ler o chat da tua transmissão!'),
                              icon: const Icon(Icons.volume_up, color: Colors.white),
                              label: const Text('Testar Voz Agora', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: _neonCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Utilizadores Permitidos & Especiais', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                          SwitchListTile(dense: true, title: const Text('Todos os Utilizadores'), value: _allowAllUsers, onChanged: (v) => setState(() => _allowAllUsers = v)),
                          SwitchListTile(dense: true, title: const Text('Seguidores'), value: _allowFollowers, onChanged: (v) => setState(() => _allowFollowers = v)),
                          SwitchListTile(dense: true, title: const Text('Super Fãs / Assinantes'), value: _allowSubscribers, onChanged: (v) => setState(() => _allowSubscribers = v)),
                          SwitchListTile(dense: true, title: const Text('Moderadores'), value: _allowModerators, onChanged: (v) => setState(() => _allowModerators = v)),
                          SwitchListTile(dense: true, title: const Text('Membros da Equipa (Nível mín. 1)'), value: _allowTeamLevel1, onChanged: (v) => setState(() => _allowTeamLevel1 = v)),
                          SwitchListTile(dense: true, title: const Text('Maiores Doadores (Top 3)'), value: _allowTop3Donors, onChanged: (v) => setState(() => _allowTop3Donors = v)),
                          const Divider(color: Colors.white12),
                          const Text('Utilizadores Especiais (Lista TikTok):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: specialUserCtrl, decoration: const InputDecoration(hintText: '@utilizador_tiktok', isDense: true))),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Color(0xFF38BDF8)),
                                onPressed: () {
                                  if (specialUserCtrl.text.trim().isNotEmpty) {
                                    setState(() => _specialUsers.add(specialUserCtrl.text.trim()));
                                    specialUserCtrl.clear();
                                  }
                                },
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 6,
                            children: _specialUsers.map((u) => Chip(label: Text(u, style: const TextStyle(fontSize: 11)), onDeleted: () => setState(() => _specialUsers.remove(u)))).toList(),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _openContentFiltersPopup,
                              icon: const Icon(Icons.shield_outlined, color: Color(0xFF38BDF8)),
                              label: const Text('Filtros de Conteúdo & Palavras Bloqueadas'),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildDonationScreen() {
    final cleanRoom = (_channelCtrl.text.trim().isEmpty ? 'teu_canal' : _channelCtrl.text.trim()).toLowerCase().replaceAll('@', '');
    final donateUrl = '$serverUrl/doar/$cleanRoom';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _neonCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💸 Central Donation & Apoios Diretos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 4),
              const Text('Configura todos os métodos de recebimento e personaliza o alerta que aparece na tua transmissão.', style: TextStyle(fontSize: 12, color: Colors.white60)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(onPressed: _pickLocalDonationImage, icon: const Icon(Icons.upload_file), label: Text(_donationFileLabel, overflow: TextOverflow.ellipsis))),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _openMediaPickerForAlert(
                      title: 'Alerta Donation',
                      initialGif: _donationImageBase64OrUrl,
                      initialSound: _donationSoundUrl,
                      onSelected: (g, s) => setState(() {
                        _donationImageBase64OrUrl = g;
                        _donationSoundUrl = s;
                      }),
                    ),
                    child: const Text('GIF / Som'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: _mbwayCtrl, decoration: const InputDecoration(labelText: 'Número MB Way', prefixIcon: Icon(Icons.phone_android), isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _pixCtrl, decoration: const InputDecoration(labelText: 'Chave PIX', prefixIcon: Icon(Icons.qr_code), isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _paypalCtrl, decoration: const InputDecoration(labelText: 'Link PayPal.me / Email PayPal', prefixIcon: Icon(Icons.account_balance_wallet_outlined), isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _revolutCtrl, decoration: const InputDecoration(labelText: 'Link Revolut / Stripe / Ko-fi', prefixIcon: Icon(Icons.credit_card), isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _donateMsgCtrl, decoration: const InputDecoration(labelText: 'Mensagem de Incentivo na Página', prefixIcon: Icon(Icons.message_outlined), isDense: true)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () {
                        socket.emit('update_donation_config', {
                          'room': cleanRoom,
                          'config': {
                            'mbway': _mbwayCtrl.text.trim(),
                            'pix': _pixCtrl.text.trim(),
                            'paypal': _paypalCtrl.text.trim(),
                            'revolut': _revolutCtrl.text.trim(),
                            'message': _donateMsgCtrl.text.trim(),
                            'imageData': _donationImageBase64OrUrl,
                          }
                        });
                        _showSnack('Métodos de Donation guardados!');
                      },
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Guardar Tudo', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: donateUrl));
                        _showSnack('Link de Donation copiado!');
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar Link'),
                    ),
                  ),
                ],
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
      '',
      AppTranslations.t(_appLang, 'actions'),
      AppTranslations.t(_appLang, 'donation'),
      '',
      AppTranslations.t(_appLang, 'interaction'),
      AppTranslations.t(_appLang, 'overlays'),
      'Stream Deck Pro',
      AppTranslations.t(_appLang, 'community'),
      AppTranslations.t(_appLang, 'about'),
      AppTranslations.t(_appLang, 'settings'),
      AppTranslations.t(_appLang, 'music'),
      AppTranslations.t(_appLang, 'faq'),
      'Perfil, Privacidade & Segurança',
    ];

    final screens = [
      _buildHomeTab(),
      _buildActionsUnifiedTab(),
      _buildDonationScreen(),
      const SizedBox(),
      InteractionScreen(socket: socket, roomName: _channelCtrl.text.trim(), topGifts: _topGifts, topLikes: _topLikes),
      OverlayStudioScreen(socket: socket, serverUrl: serverUrl, roomName: _channelCtrl.text.trim()),
      const SizedBox(),
      DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: Color(0xFF38BDF8),
              labelColor: Color(0xFF38BDF8),
              unselectedLabelColor: Colors.white54,
              tabs: [Tab(text: '🌍 Globo 3D Ao Vivo'), Tab(text: '👥 Criadores & Chat')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  CommunityGlobeScreen(serverUrl: serverUrl),
                  CommunitySocialScreen(serverUrl: serverUrl, currentUser: widget.user),
                ],
              ),
            ),
          ],
        ),
      ),
      const AboutHellLiveScreen(),
      _buildSettingsTab(),
      MusicBackgroundScreen(bgPlayer: bgMusicPlayer),
      const HelpFaqAndContactScreen(),
      ProfilePrivacySecurityScreen(user: widget.user, onUserUpdated: widget.onUserUpdated, onLogout: widget.onLogout),
    ];

    final userStatus = widget.user['status'] ?? 'online';
    final statusCol = UserAccountManager.statusColor(userStatus);

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: _selectedIndex == 6
          ? StreamDeckScreen(
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
                    'alertData': {'user': 'Teste Stream Deck', 'message': 'Alerta disparado pela consola!', 'gifUrl': _alertsList.first['gif'], 'soundUrl': _alertsList.first['sound'], 'duration': 5}
                  });
                } else if (target.isNotEmpty) {
                  socket.emit('remote_command', {'room': target, 'command': cmd, 'payload': val});
                }
              },
              onMinimizeDeck: () => setState(() => _selectedIndex = 0),
            )
          : Scaffold(
              appBar: AppBar(
                centerTitle: true,
                leading: _selectedIndex == 0
                    ? GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 12),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 17,
                                backgroundColor: const Color(0xFF1E78FF),
                                backgroundImage: widget.user['avatarPath'] != null ? FileImage(File(widget.user['avatarPath'])) : null,
                                child: widget.user['avatarPath'] == null ? const Icon(Icons.person, size: 18, color: Colors.white) : null,
                              ),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: statusCol, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF050B1E), width: 1.5)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedIndex = 0)),
                title: _selectedIndex == 0
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('icon.png', height: 32, errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, color: Color(0xFF38BDF8))),
                          const SizedBox(width: 10),
                          const Text('HELL ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 2, color: Colors.white)),
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
            ),
    );
  }
}
