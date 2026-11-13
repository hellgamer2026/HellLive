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
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _titleOpacity,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('icon.png', height: 42, errorBuilder: (_, __, ___) => const Text('H', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white))),
                            const SizedBox(width: 2),
                            const Text('ELL ', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white)),
                            const Text('Live', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: 2, color: Color(0xFF38BDF8))),
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
  final TextEditingController _goalTitleCtrl = TextEditingController(text: 'Meta de Likes da Live');
  final TextEditingController _goalTargetCtrl = TextEditingController(text: '5000');
  final TextEditingController _mbwayCtrl = TextEditingController();
  final TextEditingController _pixCtrl = TextEditingController();

  String _selectedPlatform = 'tiktok';
  String _selectedEncoder = 'OBS Studio';
  bool _isConnectedToServer = false;
  bool _liveConnected = false;
  bool _isMuted = false;
  bool _ttsEnabled = true;
  bool _ignoreEmojiOnly = true;
  String? _generatedPairCode;
  String? _pairedRemoteRoom;

  String _selectedVoiceKey = 'pt-PT-DuarteNeural';
  double _speechRate = 0.5;
  List<dynamic> _deviceVoices = [];

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

  final List<Map<String, dynamic>> _customAlerts = [];
  String _followerGif = 'https://giphy.com';
  String _followerSound = 'https://google.com';
  String _likeMilestoneGif = 'https://giphy.com';
  String _likeMilestoneSound = 'https://google.com';
  String _donationImageBase64OrUrl = 'https://giphy.com';
  String _donationFileLabel = 'Imagem padrão';
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
            return name.contains('male') || name.contains('duarte') || name.contains('antonio') || name.contains('daniel') || name.contains('pt-pt-x-jfb') || name.contains('pt-br-x-afs');
          } else {
            return name.contains('female') || name.contains('raquel') || name.contains('francisca') || name.contains('maria');
          }
        }).toList();
        if (matching.isNotEmpty) {
          await flutterTts.setVoice({'name': matching.first['name'], 'locale': matching.first['locale']});
        }
      }
      await flutterTts.setPitch(isMale ? 0.58 : 1.15);
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

  void _openMediaPickerForAlert({required String title, required Function(String gifUrl, String soundUrl) onSelected}) {
    String chosenGif = _gifs.first['url']!;
    String chosenSound = _sounds.first['url']!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SizedBox(
            height: 440,
            child: ListView(
              children: [
                Text('Biblioteca GIF & Som · $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
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
                  height: 85,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._onlineGifResults.map((item) => GestureDetector(
                            onTap: () => setModalState(() => chosenGif = item['url']),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(border: Border.all(color: chosenGif == item['url'] ? Colors.cyanAccent : Colors.transparent, width: 2), borderRadius: BorderRadius.circular(8)),
                              child: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(item['url'], width: 80, height: 80, fit: BoxFit.cover)),
                            ),
                          )),
                      ..._gifs.map((g) => GestureDetector(
                            onTap: () => setModalState(() => chosenGif = g['url']!),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(border: Border.all(color: chosenGif == g['url'] ? Colors.cyanAccent : Colors.transparent, width: 2), borderRadius: BorderRadius.circular(8)),
                              child: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(g['url']!, width: 80, height: 80, fit: BoxFit.cover)),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Escolher Efeito Sonoro:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                ..._sounds.take(6).map((s) => RadioListTile<String>(
                      dense: true,
                      activeColor: const Color(0xFF38BDF8),
                      title: Text(s['name'] ?? ''),
                      value: s['url'] ?? '',
                      groupValue: chosenSound,
                      onChanged: (v) async {
                        if (v != null) {
                          setModalState(() => chosenSound = v);
                          await sfxAudioPlayer.stop();
                          if (v.startsWith('http')) {
                            await sfxAudioPlayer.play(UrlSource(v));
                          } else {
                            await sfxAudioPlayer.play(DeviceFileSource(v));
                          }
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
                  child: const Text('Aplicar GIF e Som', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createNewCustomAlert() {
    final nameCtrl = TextEditingController();
    String gif = _gifs.first['url']!;
    String snd = _sounds.first['url']!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1636),
        title: const Text('Criar Novo Alerta Personalizado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome do Alerta (ex: Sub / Raid / Chat)')),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openMediaPickerForAlert(
                title: 'Novo Alerta',
                onSelected: (g, s) {
                  gif = g;
                  snd = s;
                },
              ),
              icon: const Icon(Icons.perm_media),
              label: const Text('Escolher GIF & Som na Biblioteca'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() => _customAlerts.add({'name': nameCtrl.text.trim(), 'gif': gif, 'sound': snd}));
                Navigator.pop(ctx);
                _showSnack('Novo alerta adicionado!');
              }
            },
            child: const Text('Criar'),
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
        _menuTile(Icons.notifications_active_outlined, AppTranslations.t(_appLang, 'alerts'), () => setState(() => _selectedIndex = 1), badge: 'TIKFINITY'),
        _menuTile(Icons.chat_bubble_outline, AppTranslations.t(_appLang, 'comments'), () => setState(() => _selectedIndex = 2)),
        _menuTile(Icons.music_note_outlined, 'Música & Áudio de Fundo', () => setState(() => _selectedIndex = 10), badge: 'SPOTIFY/MP3'),
        _menuTile(Icons.emoji_events_outlined, AppTranslations.t(_appLang, 'podium'), () => setState(() => _selectedIndex = 3)),
        _menuTile(Icons.casino_outlined, AppTranslations.t(_appLang, 'interaction'), () => setState(() => _selectedIndex = 4)),
        _menuTile(Icons.storefront_outlined, AppTranslations.t(_appLang, 'studio'), () => setState(() => _selectedIndex = 5), badge: 'PRO / LOJA'),
        _menuTile(Icons.grid_view_rounded, AppTranslations.t(_appLang, 'stream_deck'), () => setState(() => _selectedIndex = 6), badge: 'DECK'),
        _menuTile(Icons.public, 'Comunidade Global & Chat', () => setState(() => _selectedIndex = 7), badge: 'SOCIAL'),
        _menuTile(Icons.help_outline, 'Dúvidas & Contacto', () => setState(() => _selectedIndex = 11), badge: 'AJUDA'),
        _menuTile(Icons.favorite_border, AppTranslations.t(_appLang, 'about'), () => setState(() => _selectedIndex = 8)),
        _menuTile(Icons.settings_outlined, AppTranslations.t(_appLang, 'settings'), () => setState(() => _selectedIndex = 9)),
      ],
    );
  }
  Widget _buildSuperAlertsTab() {
    final cleanRoom = (_channelCtrl.text.trim().isEmpty ? 'teu_canal' : _channelCtrl.text.trim()).toLowerCase().replaceAll('@', '');
    final donateUrl = '$serverUrl/doar/$cleanRoom';

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF38BDF8),
            labelColor: Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: '🎁 Presentes TikTok'),
              Tab(text: '❤️ Seguidores, Likes & Novos'),
              Tab(text: '🎯 Metas & Doações'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...DefaultMediaLibrary.tiktokGiftsCatalog.map((g) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: _neonCard(),
                          child: ListTile(
                            leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(g['gif'], width: 42, height: 42, fit: BoxFit.cover)),
                            title: Text(g['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${g['coins']} moedas', style: const TextStyle(fontSize: 11.5, color: Colors.white54)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                                  tooltip: 'Biblioteca GIF & Som',
                                  onPressed: () => _openMediaPickerForAlert(
                                    title: g['name'],
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
                                    _showSnack('Alerta "${g['name']}" disparado!');
                                  },
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _createNewCustomAlert,
                      icon: const Icon(Icons.add_alert, color: Colors.white),
                      label: const Text('+ Criar Novo Alerta Personalizado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: _neonCard(),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_followerGif, width: 54, height: 54, fit: BoxFit.cover)),
                        title: const Text('Novo Seguidor', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('GIF & Som configurados', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                        trailing: OutlinedButton(
                          onPressed: () => _openMediaPickerForAlert(
                            title: 'Novo Seguidor',
                            onSelected: (g, s) => setState(() {
                              _followerGif = g;
                              _followerSound = s;
                            }),
                          ),
                          child: const Text('GIF / Som'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: _neonCard(),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_likeMilestoneGif, width: 54, height: 54, fit: BoxFit.cover)),
                        title: const Text('Meta 500 Likes (Com Foto)', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Exibe a foto de perfil do seguidor', style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                        trailing: OutlinedButton(
                          onPressed: () => _openMediaPickerForAlert(
                            title: 'Meta Likes',
                            onSelected: (g, s) => setState(() {
                              _likeMilestoneGif = g;
                              _likeMilestoneSound = s;
                            }),
                          ),
                          child: const Text('GIF / Som'),
                        ),
                      ),
                    ),
                    ..._customAlerts.map((ca) => Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: _neonCard(),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(ca['gif'], width: 50, height: 50, fit: BoxFit.cover)),
                            title: Text(ca['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: IconButton(
                              icon: const Icon(Icons.play_arrow, color: Color(0xFF38BDF8)),
                              onPressed: () {
                                if (_channelCtrl.text.trim().isNotEmpty) {
                                  socket.emit('trigger_overlay_alert', {
                                    'room': _channelCtrl.text.trim(),
                                    'alertData': {'user': ca['name'], 'message': 'Alerta personalizado!', 'gifUrl': ca['gif'], 'soundUrl': ca['sound'], 'duration': 5}
                                  });
                                }
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
                          const Text('💸 Doações Diretas (PNG/GIF + Biblioteca + MB Way/PIX)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: OutlinedButton.icon(onPressed: _pickLocalDonationImage, icon: const Icon(Icons.upload_file), label: Text(_donationFileLabel, overflow: TextOverflow.ellipsis))),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => _openMediaPickerForAlert(
                                  title: 'Alerta Doação',
                                  onSelected: (g, _) => setState(() => _donationImageBase64OrUrl = g),
                                ),
                                child: const Text('Biblioteca GIF'),
                              ),
                            ],
                          ),
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
              'alertData': {'user': 'Teste Stream Deck', 'message': 'Alerta disparado pela consola!', 'gifUrl': _followerGif, 'soundUrl': _followerSound, 'duration': 5}
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
      'Comunidade & Chat',
      AppTranslations.t(_appLang, 'about'),
      AppTranslations.t(_appLang, 'settings'),
      'Música & Áudio de Fundo',
      'Dúvidas & Contacto',
      'Perfil, Privacidade & Segurança',
    ];

    final screens = [
      _buildHomeTab(),
      _buildSuperAlertsTab(),
      _buildCommentsTab(),
      PodiumScreen(socket: socket, roomName: _channelCtrl.text.trim(), topGifts: _topGifts, topLikes: _topLikes),
      InteractionScreen(socket: socket, roomName: _channelCtrl.text.trim()),
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
              tabs: [Tab(text: '🌍 Globo Ao Vivo'), Tab(text: '👥 Criadores & Chat')],
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

    return Scaffold(
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
                  Image.asset('icon.png', height: 34, errorBuilder: (_, __, ___) => const Text('H', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24))),
                  const SizedBox(width: 2),
                  const Text('ELL ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 23, letterSpacing: 2)),
                  const Text('Live', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 23, color: Color(0xFF38BDF8))),
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
