import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _logoScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack)),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.30, curve: Curves.easeIn)),
    );
    _glowRadius = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 12.0, end: 52.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 52.0, end: 32.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _ringScale = Tween<double>(begin: 0.7, end: 1.45).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.75, curve: Curves.easeOut)),
    );
    _ringOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.55), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.80)));

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.28, 0.58, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.28, 0.58, curve: Curves.easeOutCubic)),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.48, 0.78, curve: Curves.easeIn)),
    );
    _progressWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.20, 0.95, curve: Curves.easeInOut)),
    );

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
          gradient: RadialGradient(
            center: Alignment(0, -0.18),
            radius: 1.0,
            colors: [Color(0xFF132E73), Color(0xFF07112E), Color(0xFF040817)],
          ),
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF38BDF8).withOpacity(_ringOpacity.value),
                            width: 1.8,
                          ),
                        ),
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
                              BoxShadow(
                                color: const Color(0xFF1E78FF).withOpacity(0.55),
                                blurRadius: _glowRadius.value,
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withOpacity(0.25),
                                blurRadius: _glowRadius.value * 1.4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Image.asset('icon.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) {
                            return const Icon(Icons.local_fire_department, size: 95, color: Color(0xFF38BDF8));
                          }),
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
                              TextSpan(
                                text: 'HELL ',
                                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white),
                              ),
                              TextSpan(
                                text: 'Live',
                                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: 2, color: Color(0xFF38BDF8)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 160,
                          height: 1.5,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Color(0xFF38BDF8), Colors.transparent],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'LIVE  ·  PLAY  ·  CONNECT',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 3.5, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _subtitleOpacity,
                  child: Column(
                    children: [
                      const Text(
                        'A tua live, no teu comando.',
                        style: TextStyle(fontSize: 13.5, color: Color(0xFF7DD3FC), letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 140,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
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
  int _selectedIndex = 0; // 0: Início, 1: Alertas, 2: Sons/Deck, 3: Voz, 4: Definições, 5: Pódio/Roleta, 6: Overlays/Doações

  final String serverUrl = 'https://onrender.com';
  late IO.Socket socket;
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer ttsAudioPlayer = AudioPlayer();
  final AudioPlayer sfxAudioPlayer = AudioPlayer();

  final TextEditingController _tiktokController = TextEditingController();
  final TextEditingController _mbwayController = TextEditingController();
  final TextEditingController _pixController = TextEditingController();
  final TextEditingController _donationImgController = TextEditingController();
  final TextEditingController _pairCodeInputController = TextEditingController();

  bool _isConnectedToServer = false;
  bool _tiktokActive = false;
  bool _ttsEnabled = true;
  bool _ignoreEmojiOnly = true;
  String? _generatedPairCode;
  String? _pairedRemoteRoom;

  String _selectedVoiceKey = 'pt-PT-DuarteNeural';
  double _speechRate = 0.5;

  // Vozes Neurais Reais (Masculinas e Femininas)
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

    final List<Map<String, dynamic>> _alertRules = [
    {'name': 'Moeda', 'category': 'Presentes', 'sound': 'Moeda.mp3', 'gif': 'https://giphy.com', 'enabled': true, 'icon': Icons.monetization_on, 'color': const Color(0xFFFBBF24)},
    {'name': 'Leão', 'category': 'Presentes', 'sound': 'Leao.mp3', 'gif': 'https://giphy.com', 'enabled': true, 'icon': Icons.pets, 'color': const Color(0xFFF97316)},
    {'name': 'Rosa', 'category': 'Presentes', 'sound': 'Rosa.mp3', 'gif': 'https://giphy.com', 'enabled': true, 'icon': Icons.local_florist, 'color': const Color(0xFFF43F5E)},
    {'name': 'TikTok', 'category': 'Presentes', 'sound': 'TikTok.mp3', 'gif': 'https://giphy.com', 'enabled': true, 'icon': Icons.music_note, 'color': const Color(0xFF22D3EE)},
    {'name': 'GG', 'category': 'Presentes', 'sound': 'GG.mp3', 'gif': 'https://giphy.com', 'enabled': true, 'icon': Icons.sports_esports, 'color': const Color(0xFFEF4444)},
    {'name': 'Novo Seguidor', 'category': 'Seguidores', 'sound': 'Seguidor.mp3', 'gif': 'https://giphy.com', 'enabled': true, 'icon': Icons.person_add, 'color': const Color(0xFF38BDF8)},
    {'name': 'Gostos / Likes', 'category': 'Gostos', 'sound': 'Like.mp3', 'gif': 'https://giphy.com', 'enabled': false, 'icon': Icons.favorite, 'color': const Color(0xFFEC4899)},
    {'name': 'Comentário TTS', 'category': 'Comentários', 'sound': 'Comentario.mp3', 'gif': '', 'enabled': true, 'icon': Icons.chat_bubble, 'color': const Color(0xFF10B981)},
  ];

  final List<Map<String, String>> _soundsLibrary = [
    {'name': 'Aplausos Plateia', 'duration': '00:04', 'cat': 'Eventos', 'url': 'https://google.com', 'path': ''},
    {'name': 'Moeda / Vitória', 'duration': '00:02', 'cat': 'Presentes', 'url': 'https://google.com', 'path': ''},
    {'name': 'Buzina Épica', 'duration': '00:03', 'cat': 'Eventos', 'url': 'https://google.com', 'path': ''},
    {'name': 'Sino de Alerta', 'duration': '00:02', 'cat': 'Presentes', 'url': 'https://google.com', 'path': ''},
    {'name': 'Tambor Suspense', 'duration': '00:04', 'cat': 'Eventos', 'url': 'https://google.com', 'path': ''},
    {'name': 'Foguetes Festa', 'duration': '00:05', 'cat': 'Presentes', 'url': 'https://google.com', 'path': ''},
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
      _mbwayController.text = prefs.getString('mbway_key') ?? '';
      _pixController.text = prefs.getString('pix_key') ?? '';
      _donationImgController.text = prefs.getString('donation_img') ?? '';
      _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
      final savedVoice = prefs.getString('tts_voice') ?? 'pt-PT-DuarteNeural';
      if (_neuralVoices.containsKey(savedVoice)) _selectedVoiceKey = savedVoice;
      _speechRate = prefs.getDouble('tts_rate') ?? 0.5;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tiktok_user', _tiktokController.text.trim());
    await prefs.setString('mbway_key', _mbwayController.text.trim());
    await prefs.setString('pix_key', _pixController.text.trim());
    await prefs.setString('donation_img', _donationImgController.text.trim());
    await prefs.setBool('tts_enabled', _ttsEnabled);
    await prefs.setString('tts_voice', _selectedVoiceKey);
    await prefs.setDouble('tts_rate', _speechRate);
  }

  Future<void> _speakNeural(String text) async {
    try {
      final parts = _selectedVoiceKey.split('|');
      final voiceName = parts[0];
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
    _showSnack('Silêncio ativado! Voz e sons interrompidos.');
  }

  void _initSocket() {
    socket = IO.io(serverUrl, IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build());
    socket.onConnect((_) {
      setState(() => _isConnectedToServer = true);
      final room = _pairedRemoteRoom ?? _tiktokController.text.trim();
      if (room.isNotEmpty) socket.emit('join_room', room);
    });
    socket.onDisconnect((_) => setState(() {
          _isConnectedToServer = false;
          _tiktokActive = false;
        }));
    socket.on('status', (data) {
      setState(() {
        if (data['platform'] == 'tiktok') _tiktokActive = data['connected'] == true;
      });
      if (data['connected'] == false) _showSnack(data['error'] ?? 'Live offline ou utilizador inválido.');
    });
    socket.on('podium_update', (data) {
      setState(() {
        if (data['topGifts'] != null) _topGifts = List<Map<String, dynamic>>.from(data['topGifts']);
        if (data['topLikes'] != null) _topLikes = List<Map<String, dynamic>>.from(data['topLikes']);
      });
    });
    socket.on('pair_code_created', (data) {
      setState(() => _generatedPairCode = data['code']);
    });
    socket.on('pair_approval_needed', (data) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0B1636),
          title: const Text('Pedido de Emparelhamento'),
          content: Text('O dispositivo "${data['deviceName']}" quer ligar-se como Stream Deck. Aceitar?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Recusar')),
            ElevatedButton(
              onPressed: () {
                socket.emit('approve_pair', {'remoteSocketId': data['remoteSocketId'], 'code': data['code']});
                Navigator.pop(ctx);
                _showSnack('Stream Deck emparelhado!');
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
      _showSnack('Ligado ao ecrã principal com sucesso!');
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
        final room = _tiktokController.text.trim();
        final rule = _alertRules.firstWhere((r) => r['enabled'] == true, orElse: () => _alertRules[0]);
        if (room.isNotEmpty) {
          socket.emit('trigger_overlay_alert', {
            'room': room,
            'alertData': {'user': '$user $msg', 'message': '', 'gifUrl': rule['gif'], 'duration': 5}
          });
        }
      }
      if (_ttsEnabled) {
        if (_ignoreEmojiOnly && event['type'] != 'gift') {
          if (!RegExp(r'[a-zA-Z0-9À-ÿ]').hasMatch(msg)) return;
        }
        _speakNeural(event['type'] == 'gift' ? 'Novo presente! $user $msg' : '$user diz: $msg');
      }
    });
    socket.connect();
  }
  void _connectTikTokDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1636),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF1E78FF))),
        title: const Text('Ligar Conta TikTok LIVE'),
        content: TextField(
          controller: _tiktokController,
          decoration: const InputDecoration(hintText: '@teu_utilizador', prefixIcon: Icon(Icons.alternate_email, color: Color(0xFF38BDF8))),
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
        _soundsLibrary.insert(0, {'name': result.files.single.name, 'duration': 'Custom', 'cat': 'Meus Sons', 'url': '', 'path': result.files.single.path!});
      });
      _showSnack('Som "${result.files.single.name}" adicionado!');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  BoxDecoration _neonCardDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF1E429F), width: 1.2),
      boxShadow: [BoxShadow(color: const Color(0xFF1E78FF).withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
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
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (_tiktokActive || _pairedRemoteRoom != null) ? const Color(0xFF22C55E) : const Color(0xFF38BDF8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_tiktokActive ? 'Online' : (_pairedRemoteRoom != null ? 'Stream Deck Ligado' : 'Tocar para Ligar'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
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
          _neonMenuTile(Icons.notifications_none, 'Alertas & GIFs', () => setState(() => _selectedIndex = 1)),
          _neonMenuTile(Icons.volume_up_outlined, 'Sons & Stream Deck', () => setState(() => _selectedIndex = 2)),
          _neonMenuTile(Icons.chat_bubble_outline, 'Comentários & Vozes', () => setState(() => _selectedIndex = 3)),
          _neonMenuTile(Icons.emoji_events_outlined, 'Pódio & Roleta Interativa', () => setState(() => _selectedIndex = 5)),
          _neonMenuTile(Icons.volunteer_activism_outlined, 'Overlays & Doações MB Way/PIX', () => setState(() => _selectedIndex = 6)),
          _neonMenuTile(Icons.devices, 'Emparelhar 2.º Ecrã (QR / Código)', () => setState(() => _selectedIndex = 7)),
          _neonMenuTile(Icons.settings_outlined, 'Definições & PRO', () => setState(() => _selectedIndex = 4)),
          const SizedBox(height: 20),
          const Text('HELL Live', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2.5, color: Colors.white70)),
          const SizedBox(height: 4),
          const Text('LIVE  ·  PLAY  ·  CONNECT', style: TextStyle(fontSize: 10, letterSpacing: 2.5, color: Color(0xFF38BDF8))),
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
              decoration: BoxDecoration(color: const Color(0xFF1E78FF).withOpacity(0.18), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4))),
              child: Icon(icon, color: const Color(0xFF38BDF8), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))),
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
                width: 44, height: 44,
                decoration: BoxDecoration(color: (item['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(item['icon'], color: item['color'], size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(item['gif'].toString().isNotEmpty ? 'GIF + Som ativos' : 'Apenas Voz/Som', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.play_circle_outline, color: Color(0xFF38BDF8)),
                tooltip: 'Testar Alerta na Live',
                onPressed: () {
                  final room = _pairedRemoteRoom ?? _tiktokController.text.trim();
                  if (room.isNotEmpty) {
                    socket.emit('trigger_overlay_alert', {
                      'room': room,
                      'alertData': {'user': 'Teste HELL Live', 'message': 'enviou ${item['name']}!', 'gifUrl': item['gif'], 'duration': 5}
                    });
                    _showSnack('Alerta de teste enviado para o Overlay!');
                  } else {
                    _showSnack('Define primeiro o teu @utilizador TikTok no Início!');
                  }
                },
              ),
              Switch(activeColor: Colors.white, activeTrackColor: const Color(0xFF1E78FF), value: item['enabled'], onChanged: (v) => setState(() => item['enabled'] = v)),
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
            indicatorColor: Color(0xFF38BDF8), labelColor: Color(0xFF38BDF8), unselectedLabelColor: Colors.white54,
            tabs: [Tab(text: 'Presentes'), Tab(text: 'Seguidores'), Tab(text: 'Gostos'), Tab(text: 'Comentários')],
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _importSound,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Adicionar Som Personalizado (.MP3)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySounds(String tabCat) {
    final list = tabCat == 'Todos' ? _soundsLibrary : _soundsLibrary.where((s) => s['cat'] == tabCat).toList();
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
                  await sfxAudioPlayer.stop();
                  if (s['path']!.isNotEmpty) {
                    await sfxAudioPlayer.play(DeviceFileSource(s['path']!));
                  } else if (s['url'] != null && s['url']!.isNotEmpty) {
                    await sfxAudioPlayer.play(UrlSource(s['url']!));
                    final room = _pairedRemoteRoom ?? _tiktokController.text.trim();
                    if (room.isNotEmpty) socket.emit('remote_command', {'room': room, 'command': 'sound', 'payload': s['url']});
                  }
                },
                child: const Icon(Icons.play_arrow, color: Color(0xFF38BDF8), size: 32),
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
              const Icon(Icons.volume_up, color: Colors.white38, size: 18),
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
            tabs: [Tab(text: 'Todos'), Tab(text: 'Presentes'), Tab(text: 'Eventos'), Tab(text: 'Meus Sons')],
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
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _importSound,
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: const Text('Importar Som (.MP3)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ignorar mensagens só com emojis', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  Switch(activeColor: Colors.white, activeTrackColor: const Color(0xFF1E78FF), value: _ignoreEmojiOnly, onChanged: (v) => setState(() => _ignoreEmojiOnly = v)),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Voz Real (Masculina / Feminina)', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                  await _saveSettings();
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF050B1E), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                child: Row(
                  children: [
                    const Expanded(child: Text('"Obrigado pelo apoio!\nVamos com tudo na live!"', style: TextStyle(fontSize: 13, color: Colors.white70))),
                    GestureDetector(
                      onTap: () => _speakNeural('Obrigado pelo apoio! Vamos com tudo na live!'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF1E78FF), borderRadius: BorderRadius.circular(8)),
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
  Widget _buildPodiumTab() {
    final medals = ['🥇', '🥈', '🥉'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _neonCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🏆 TOP PRESENTEADORES', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 12),
              if (_topGifts.isEmpty)
                const Text('Ainda sem presentes nesta sessão.', style: TextStyle(color: Colors.white54))
              else
                ..._topGifts.take(5).toList().asMap().entries.map((e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(e.key < 3 ? medals[e.key] : '#${e.key + 1}', style: const TextStyle(fontSize: 20)),
                      title: Text(e.value['user'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text('${e.value['score']} pts', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                    )),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _neonCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('❤️ TOP LIKES DA LIVE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFF43F5E))),
              const SizedBox(height: 12),
              if (_topLikes.isEmpty)
                const Text('Ainda sem likes registados.', style: TextStyle(color: Colors.white54))
              else
                ..._topLikes.take(5).toList().asMap().entries.map((e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(e.key < 3 ? medals[e.key] : '#${e.key + 1}', style: const TextStyle(fontSize: 20)),
                      title: Text(e.value['user'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text('${e.value['score']} likes', style: const TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold)),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverlaysAndDonationsTab() {
    final cleanRoom = (_tiktokController.text.trim().isEmpty ? 'teu_canal' : _tiktokController.text.trim()).toLowerCase().replaceAll('@', '');
    final overlayUrl = '$serverUrl/overlay/$cleanRoom';
    final donateUrl = '$serverUrl/doar/$cleanRoom';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _neonCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📺 Overlay Transparente (OBS / Live Studio)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 8),
              const Text('Cola este link como Fonte de Navegador (Browser Source) na tua live para mostrar GIFs, Pódio e Meta:', style: TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 10),
              SelectableText(overlayUrl, style: const TextStyle(fontSize: 12, color: Colors.cyanAccent)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: overlayUrl));
                    _showSnack('Link do Overlay copiado!');
                  },
                  icon: const Icon(Icons.copy, color: Colors.white),
                  label: const Text('Copiar Link do Overlay', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _neonCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💸 Doações Diretas (MB Way / PIX)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 10),
              TextField(controller: _mbwayController, decoration: const InputDecoration(labelText: 'Número MB Way (Portugal)', prefixIcon: Icon(Icons.phone_android))),
              const SizedBox(height: 10),
              TextField(controller: _pixController, decoration: const InputDecoration(labelText: 'Chave PIX (Brasil)', prefixIcon: Icon(Icons.pix))),
              const SizedBox(height: 10),
              TextField(controller: _donationImgController, decoration: const InputDecoration(labelText: 'Link da Imagem / GIF da Página', prefixIcon: Icon(Icons.image))),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                      onPressed: () {
                        _saveSettings();
                        socket.emit('update_donation_config', {
                          'room': cleanRoom,
                          'config': {
                            'mbway': _mbwayController.text.trim(),
                            'pix': _pixController.text.trim(),
                            'imageUrl': _donationImgController.text.trim(),
                          }
                        });
                        _showSnack('Cartão de doações guardado!');
                      },
                      child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
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
              const Padding(padding: EdgeInsets.only(left: 12, top: 4, bottom: 4), child: Text('Tema', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
              RadioListTile<String>(activeColor: const Color(0xFF38BDF8), title: const Text('Azul (Padrão)'), value: 'azul', groupValue: widget.currentTheme, onChanged: (v) => widget.onThemeChanged(v!)),
              RadioListTile<String>(activeColor: const Color(0xFF38BDF8), title: const Text('Escuro'), value: 'escuro', groupValue: widget.currentTheme, onChanged: (v) => widget.onThemeChanged(v!)),
              RadioListTile<String>(activeColor: const Color(0xFF38BDF8), title: const Text('Claro'), value: 'claro', groupValue: widget.currentTheme, onChanged: (v) => widget.onThemeChanged(v!)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _neonMenuTile(Icons.music_note, _tiktokController.text.isEmpty ? 'Conta TikTok (Ligação pendente)' : 'Conta TikTok (${_tiktokController.text})', _connectTikTokDialog),
        _neonMenuTile(Icons.qr_code_2, 'Emparelhar Telemóvel / Tablet (Stream Deck)', _openPairDialog),
        _neonMenuTile(Icons.workspace_premium, 'HELL Live PRO & Vouchers de Oferta', () => _showSnack('Loja PRO & Vouchers chegam na v3.0!')),
        _neonMenuTile(Icons.info_outline, 'Sobre a Aplicação (HELL Live v2.0.0)', () => _showSnack('HELL Live · LIVE · PLAY · CONNECT')),
      ],
    );
  }
  void _openPairDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1636),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF1E78FF))),
        title: const Text('Emparelhar Stream Deck'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('1. No aparelho principal (Tablet/PC), gera um código de 6 dígitos:', style: TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
              onPressed: () {
                final room = _tiktokController.text.trim();
                if (room.isEmpty) {
                  _showSnack('Liga primeiro a tua conta TikTok no Início!');
                } else {
                  socket.emit('create_pair_code', room);
                }
              },
              icon: const Icon(Icons.qr_code, color: Colors.white),
              label: const Text('Gerar Código (60s)', style: TextStyle(color: Colors.white)),
            ),
            if (_generatedPairCode != null) ...[
              const SizedBox(height: 8),
              SelectableText('Código: $_generatedPairCode', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
            ],
            const Divider(height: 24, color: Colors.white24),
            const Text('2. No Telemóvel (Comando Remoto), insere o código:', style: TextStyle(fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              controller: _pairCodeInputController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Ex: 482910', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  final code = _pairCodeInputController.text.trim();
                  if (code.length == 6) {
                    socket.emit('request_pair', {'code': code, 'deviceName': 'Telemóvel Stream Deck'});
                    Navigator.pop(ctx);
                    _showSnack('Pedido enviado! Aceita no Tablet/PC.');
                  }
                },
                child: const Text('Ligar como Stream Deck'),
              ),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['HELL Live', 'Alertas', 'Sons & Deck', 'Vozes Neurais', 'Definições', 'Pódio ao Vivo', 'Overlays & Doações'];
    final screens = [
      _buildHomeTab(),
      _buildAlertsTab(),
      _buildSoundsTab(),
      _buildCommentsTab(),
      _buildSettingsTab(),
      _buildPodiumTab(),
      _buildOverlaysAndDonationsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: _selectedIndex == 0
            ? Padding(padding: const EdgeInsets.all(10.0), child: Image.asset('icon.png', errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: Color(0xFF38BDF8))))
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedIndex = 0)),
        title: Text(titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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
          BottomNavigationBarItem(icon: Icon(Icons.music_note_outlined), activeIcon: Icon(Icons.music_note), label: 'Sons'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Definições'),
        ],
      ),
    );
  }
}
