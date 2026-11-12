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
        primaryColor: const Color(0xFF1E60D5),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1E60D5),
          secondary: Color(0xFF00A8E8),
        ),
      );
    } else if (_themeMode == 'escuro') {
      return ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090A0F),
        cardColor: const Color(0xFF14161F),
        primaryColor: const Color(0xFF2563EB),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2563EB),
          secondary: Color(0xFF38BDF8),
        ),
      );
    }
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF070E24),
      cardColor: const Color(0xFF0F1B3D),
      primaryColor: const Color(0xFF1D6CE0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A1430),
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0A1430),
        selectedItemColor: Color(0xFF38BDF8),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF1D6CE0),
        secondary: Color(0xFF38BDF8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HELL LIVE',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: MainShell(
        currentTheme: _themeMode,
        onThemeChanged: _changeTheme,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final String currentTheme;
  final Function(String) onThemeChanged;

  const MainShell({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

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
  final TextEditingController _twitchController = TextEditingController();

  bool _isConnectedToServer = false;
  bool _tiktokActive = false;
  bool _twitchActive = false;
  bool _ttsEnabled = true;

  String _selectedLanguage = 'pt-PT';
  double _speechRate = 0.5;

  final Map<String, String> _supportedLanguages = {
    'pt-PT': 'Português (Portugal)',
    'pt-BR': 'Português (Brasil)',
    'en-US': 'Inglês (EUA)',
    'es-ES': 'Espanhol (Espanha)',
    'fr-FR': 'Francês (França)',
  };

  final List<Map<String, dynamic>> _events = [];

  final List<Map<String, dynamic>> _alertRules = [
    {'id': 'moeda', 'name': 'Moeda', 'category': 'Presentes', 'sound': 'Moeda.mp3', 'enabled': true, 'icon': Icons.monetization_on, 'color': Colors.amber},
    {'id': 'leao', 'name': 'Leão', 'category': 'Presentes', 'sound': 'Leao.mp3', 'enabled': true, 'icon': Icons.pets, 'color': Colors.orange},
    {'id': 'rosa', 'name': 'Rosa', 'category': 'Presentes', 'sound': 'Rosa.mp3', 'enabled': true, 'icon': Icons.local_florist, 'color': Colors.pinkAccent},
    {'id': 'gg', 'name': 'GG', 'category': 'Presentes', 'sound': 'GG.mp3', 'enabled': true, 'icon': Icons.sports_esports, 'color': Colors.cyanAccent},
    {'id': 'outro', 'name': 'Outro Presente', 'category': 'Presentes', 'sound': 'Presente.mp3', 'enabled': true, 'icon': Icons.card_giftcard, 'color': Colors.purpleAccent},
    {'id': 'seguidor', 'name': 'Novo Seguidor', 'category': 'Seguidores', 'sound': 'Seguidor.mp3', 'enabled': true, 'icon': Icons.person_add, 'color': Colors.lightBlueAccent},
    {'id': 'gosto', 'name': 'Gostos / Likes', 'category': 'Gostos', 'sound': 'Like.mp3', 'enabled': false, 'icon': Icons.favorite, 'color': Colors.redAccent},
    {'id': 'comentario', 'name': 'Comentário TTS', 'category': 'Comentários', 'sound': 'Comentario.mp3', 'enabled': true, 'icon': Icons.chat_bubble, 'color': Colors.tealAccent},
  ];

  final List<Map<String, String>> _soundsLibrary = [
    {'name': 'Moeda.mp3', 'duration': '00:05', 'path': ''},
    {'name': 'Leao.mp3', 'duration': '00:06', 'path': ''},
    {'name': 'Rosa.mp3', 'duration': '00:04', 'path': ''},
    {'name': 'GG.mp3', 'duration': '00:04', 'path': ''},
    {'name': 'Seguidor.mp3', 'duration': '00:05', 'path': ''},
    {'name': 'Comentario.mp3', 'duration': '00:06', 'path': ''},
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
      _twitchController.text = prefs.getString('twitch_user') ?? '';
      _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
      _selectedLanguage = prefs.getString('tts_lang') ?? 'pt-PT';
      _speechRate = prefs.getDouble('tts_rate') ?? 0.5;
    });
    await _applyTtsSettings();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tiktok_user', _tiktokController.text.trim());
    await prefs.setString('twitch_user', _twitchController.text.trim());
    await prefs.setBool('tts_enabled', _ttsEnabled);
    await prefs.setString('tts_lang', _selectedLanguage);
    await prefs.setDouble('tts_rate', _speechRate);
  }

  Future<void> _applyTtsSettings() async {
    await flutterTts.setLanguage(_selectedLanguage);
    await flutterTts.setSpeechRate(_speechRate);
    await flutterTts.setVolume(1.0);
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
          _twitchActive = false;
        }));

    socket.on('status', (data) {
      setState(() {
        if (data['platform'] == 'tiktok') _tiktokActive = data['connected'] == true;
        if (data['platform'] == 'twitch') _twitchActive = data['connected'] == true;
      });
      if (data['connected'] == false) {
        _showSnack(data['error'] ?? 'Erro ao ligar à live.');
      }
    });

    socket.on('live_event', (data) {
      final event = Map<String, dynamic>.from(data);
      setState(() {
        _events.insert(0, event);
        if (_events.length > 100) _events.removeLast();
      });

      if (_ttsEnabled) {
        final user = event['user'] ?? 'Alguém';
        final msg = event['message'] ?? '';
        if (event['type'] == 'gift') {
          flutterTts.speak('Novo presente! $user $msg');
        } else {
          flutterTts.speak('$user diz: $msg');
        }
      }
    });

    socket.connect();
  }

  void _connectPlatforms() {
    _saveSettings();
    if (!_isConnectedToServer) {
      socket.connect();
      _showSnack('A acordar servidor HELL LIVE, aguarda 10 segundos...');
      return;
    }
    if (_tiktokController.text.trim().isNotEmpty) {
      socket.emit('connect_tiktok', _tiktokController.text.trim());
    }
    if (_twitchController.text.trim().isNotEmpty) {
      socket.emit('connect_twitch', _twitchController.text.trim());
    }
  }

  Future<void> _importCustomSound() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _soundsLibrary.insert(0, {
          'name': result.files.single.name,
          'duration': 'Custom',
          'path': result.files.single.path!,
        });
      });
      _showSnack('Som "${result.files.single.name}" importado com sucesso!');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF132554), Color(0xFF0D193B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF284B9E), width: 1),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estado da Live', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: [

