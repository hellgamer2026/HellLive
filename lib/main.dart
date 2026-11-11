import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const HellLiveApp());
}

class HellLiveApp extends StatelessWidget {
  const HellLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HellLive Alertas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        primaryColor: const Color(0xFFFF2E63),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF2E63),
          secondary: Color(0xFF08D9D6),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String serverUrl = 'https://onrender.com';
  late IO.Socket socket;
  final FlutterTts flutterTts = FlutterTts();

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
    'en-GB': 'Inglês (Reino Unido)',
    'es-ES': 'Espanhol (Espanha)',
    'fr-FR': 'Francês (França)',
  };

  final List<Map<String, dynamic>> _events = [];

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
    await flutterTts.setPitch(1.0);
  }

  void _initSocket() {
    socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      setState(() => _isConnectedToServer = true);
    });

    socket.onDisconnect((_) {
      setState(() {
        _isConnectedToServer = false;
        _tiktokActive = false;
        _twitchActive = false;
      });
    });

    socket.on('status', (data) {
      setState(() {
        if (data['platform'] == 'tiktok') {
          _tiktokActive = data['connected'] == true;
        } else if (data['platform'] == 'twitch') {
          _twitchActive = data['connected'] == true;
        }
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
          flutterTts.speak('Alerta de presente! $user $msg');
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
      _showSnack('A acordar servidor na nuvem, aguarda 10 segundos...');
      return;
    }

    if (_tiktokController.text.trim().isNotEmpty) {
      socket.emit('connect_tiktok', _tiktokController.text.trim());
    }
    if (_twitchController.text.trim().isNotEmpty) {
      socket.emit('connect_twitch', _twitchController.text.trim());
    }
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1D2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Definições de Voz e Idioma',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Idioma da Leitura (TTS):'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    dropdownColor: const Color(0xFF0F111A),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: _supportedLanguages.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        setState(() => _selectedLanguage = val);
                        setModalState(() {});
                        await _applyTtsSettings();
                        await _saveSettings();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Velocidade da Voz: ${(_speechRate * 2).toStringAsFixed(1)}x'),
                  Slider(
                    value: _speechRate,
                    min: 0.25,
                    max: 1.0,
                    divisions: 6,
                    onChanged: (val) async {
                      setState(() => _speechRate = val);
                      setModalState(() {});
                      await _applyTtsSettings();
                      await _saveSettings();
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          flutterTts.speak('Olá! Teste de voz em ${_supportedLanguages[_selectedLanguage]}.');
                        },
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Testar Voz'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showSnack('Para descarregar novas vozes offline, vai às Definições > Acessibilidade > Texto para fala do teu telemóvel.');
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Mais Vozes'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    socket.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HellLive Alertas'),
        backgroundColor: const Color(0xFF1A1D2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Definições de Voz e Idioma',
            onPressed: _openSettingsModal,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.cloud_done,
              color: _isConnectedToServer ? Colors.greenAccent : Colors.redAccent,
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: const Color(0xFF1A1D2E),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _tiktokController,
                      decoration: InputDecoration(
                        labelText: 'Utilizador TikTok (ex: @nome)',
                        suffixIcon: Icon(
                          Icons.circle,
