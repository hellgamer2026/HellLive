import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'app_data.dart';
import 'studio_screens.dart';
import 'deck_and_community.dart';
import 'platform_logos.dart';
import 'account_security.dart';
import 'music_and_social.dart';
import 'actions_studio.dart';
import 'live_connectors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();
  LocalObsServer.start();
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();

    Timer(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;
      final savedUser = await UserAccountManager.getSavedUser();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
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
          gradient: RadialGradient(center: Alignment(0, -0.15), radius: 1.0, colors: [Color(0xFF132E73), Color(0xFF07112E), Color(0xFF040817)]),
        ),
        child: FadeTransition(
          opacity: _controller,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('icon.png', height: 120, errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, size: 95, color: Color(0xFF38BDF8))),
              const SizedBox(height: 20),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('HELL ', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white)),
                  Text('Live', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 2, color: Color(0xFF38BDF8))),
                ],
              ),
              const SizedBox(height: 10),
              const Text('A tua live, no teu comando.', style: TextStyle(fontSize: 13.5, color: Color(0xFF7DD3FC))),
            ],
          ),
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
    final methods = _user?['securityMethods'];
    if (_user != null && (methods == null || (methods is List && methods.isEmpty))) {
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
  late IO.Socket socket;
  late LivePlatformConnector _liveConnector;

  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer sfxAudioPlayer = AudioPlayer();
  final AudioPlayer bgMusicPlayer = AudioPlayer();
  final AudioRecorder _voiceRecorder = AudioRecorder();

  final TextEditingController _channelCtrl = TextEditingController();
  String _selectedPlatform = 'tiktok';
  String _selectedEncoder = 'OBS Studio';
  bool _liveConnected = false;
  String _liveStatusText = 'Seleciona uma plataforma abaixo para ligar a transmissão:';
  bool _isMuted = false;

  bool _ttsEnabled = true;
  double _speechRate = 0.5;
  double _voicePitch = 0.72;
  double _voiceVolume = 1.0;

  bool _allGiftsEnabled = true;
  int _sessionLikesCount = 0;

   final List<Map<String, dynamic>> _alertsList = [
    {'id': 'a1', 'trigger': 'follow', 'name': 'Novo Seguidor', 'enabled': true, 'ttsThank': true, 'customVoicePath': null, 'media': DefaultMediaLibrary.builtInGifsAndPngs[0]['url']!, 'sound': ''},
    {'id': 'a2', 'trigger': 'like500', 'name': 'Meta de Gostos da Live', 'enabled': true, 'ttsThank': true, 'customVoicePath': null, 'media': DefaultMediaLibrary.builtInGifsAndPngs[1]['url']!, 'sound': ''},
    {'id': 'a3', 'trigger': 'sub', 'name': 'Novo Subscritor', 'enabled': true, 'ttsThank': true, 'customVoicePath': null, 'media': DefaultMediaLibrary.builtInGifsAndPngs[2]['url']!, 'sound': ''},
    {'id': 'a4', 'trigger': 'share', 'name': 'Partilha da Live', 'enabled': true, 'ttsThank': true, 'customVoicePath': null, 'media': DefaultMediaLibrary.builtInGifsAndPngs[3]['url']!, 'sound': ''},
  ];

  final List<Map<String, dynamic>> _goalsList = [
    {'id': 'm1', 'title': 'Meta de Gostos da Live', 'target': 5000, 'current': 1250, 'overlayType': 'tiktok_heart'},
    {'id': 'm2', 'title': 'Novos Seguidores Hoje', 'target': 100, 'current': 42, 'overlayType': 'tikfinity_neon'},
  ];

  final List<Map<String, dynamic>> _topGifts = [];
  final List<Map<String, dynamic>> _topLikes = [];
  final List<Map<String, String>> _chatFeed = [];
  List<Map<String, String>> _sounds = [];

  @override
  void initState() {
    super.initState();
    _sounds = List<Map<String, String>>.from(DefaultMediaLibrary.builtInSounds);
    MusicDeckController.sharedPlayer = bgMusicPlayer;
    _loadSettings();
    _initConnectors();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _channelCtrl.text = prefs.getString('channel_user') ?? '';
      _selectedPlatform = prefs.getString('platform') ?? 'tiktok';
      _appLang = prefs.getString('app_lang') ?? 'pt';
      _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
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
    await prefs.setDouble('tts_rate', _speechRate);
    await prefs.setDouble('tts_pitch', _voicePitch);
    await prefs.setDouble('tts_volume', _voiceVolume);
  }

  Future<void> _speakRealVoice(String text) async {
    if (_isMuted || text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString('hell_active_voice_id') ?? 'google_pt_duarte';
    final isFemale = activeId.contains('raquel') || activeId.contains('francisca') || activeId.contains('jenny');
    final lang = activeId.contains('_br_') ? 'pt-BR' : (activeId.contains('_en_') ? 'en-US' : (activeId.contains('_es_') ? 'es-ES' : 'pt-PT'));

    try {
      await flutterTts.stop();
      if (Platform.isAndroid) {
        await flutterTts.setEngine('com.google.android.tts');
      }
      await flutterTts.setLanguage(lang);
      await flutterTts.setPitch(isFemale ? 1.18 : (activeId == 'google_pt_locutor' ? 0.55 : 0.72));
      await flutterTts.setSpeechRate(_speechRate);
      await flutterTts.setVolume(_voiceVolume);
      await flutterTts.speak(text);
    } catch (_) {}
  }

  void _initConnectors() {
    socket = IO.io('http://${LocalObsServer.localIp}:${LocalObsServer.port}', IO.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build());

    _liveConnector = LivePlatformConnector(
      onStatusChanged: (connected, statusMsg) {
        if (!mounted) return;
        setState(() {
          _liveConnected = connected;
          _liveStatusText = statusMsg;
        });
        _showSnack(statusMsg);
      },
      onLiveEvent: (event) {
        if (!mounted) return;
        final type = (event['type'] ?? 'chat').toString();
        final user = (event['user'] ?? 'Espectador').toString();
        final msg = (event['message'] ?? '').toString();

        setState(() {
          _chatFeed.insert(0, {'user': user, 'msg': msg, 'type': type});
          if (_chatFeed.length > 40) _chatFeed.removeLast();
        });

        if (_isMuted) return;

        if (type == 'gift' && _allGiftsEnabled) {
          final coins = (event['coins'] ?? 1) as int;
          _updateLeaderboard(_topGifts, user, coins);
          final giftName = (event['giftName'] ?? 'Presente').toString();
          final match = DefaultMediaLibrary.tiktokGiftsCatalog.firstWhere(
            (g) => giftName.toLowerCase().contains(g['name'].toString().toLowerCase()),
            orElse: () => DefaultMediaLibrary.tiktokGiftsCatalog.first,
          );
          if (match['enabled'] == true) {
            final spoken = 'Obrigado $user pelo presente ${match['name']}!';
            LocalObsServer.pushAlert('$user enviou ${match['name']}', spoken, match['png'] ?? '');
            if (match['customVoicePath'] != null) {
              sfxAudioPlayer.play(DeviceFileSource(match['customVoicePath']));
            } else {
              final snd = (match['sound'] ?? '').toString();
              if (snd.isNotEmpty) sfxAudioPlayer.play(UrlSource(snd));
              if (match['ttsThank'] == true && _ttsEnabled) _speakRealVoice(spoken);
            }
          }
          return;
        }

        if (type == 'like') {
          final count = (event['count'] ?? 1) as int;
          _updateLeaderboard(_topLikes, user, count);
          _sessionLikesCount += count;
          if (_sessionLikesCount >= 500) {
            _sessionLikesCount = 0;
            _triggerAlertByKey('like500', 'Comunidade', 'atingiu 500 Gostos!');
          }
          return;
        }

        if (type == 'follow') _triggerAlertByKey('follow', user, 'começou a seguir!');
        if (type == 'sub') _triggerAlertByKey('sub', user, 'subscreveu o canal!');
        if (type == 'share') _triggerAlertByKey('share', user, 'partilhou a transmissão!');

        if (type == 'chat' && _ttsEnabled && msg.isNotEmpty) {
          _speakRealVoice('$user diz: $msg');
        }
      },
    );
  }

  void _updateLeaderboard(List<Map<String, dynamic>> list, String user, int addScore) {
    final idx = list.indexWhere((e) => e['user'] == user);
    if (idx >= 0) {
      list[idx]['score'] = (list[idx]['score'] as int) + addScore;
    } else {
      list.add({'user': user, 'score': addScore, 'avatar': ''});
    }
    list.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
  }

  void _triggerAlertByKey(String triggerKey, String user, String extraText) {
    final alert = _alertsList.firstWhere((a) => a['trigger'] == triggerKey, orElse: () => {});
    if (alert.isEmpty || alert['enabled'] != true) return;
    LocalObsServer.pushAlert('$user $extraText', '', alert['media'] ?? '');
    final snd = (alert['sound'] ?? '').toString();
    if (snd.isNotEmpty) sfxAudioPlayer.play(UrlSource(snd));
  }

  Future<void> _toggleMuteState() async {
    setState(() => _isMuted = !_isMuted);
    if (_isMuted) {
      await sfxAudioPlayer.stop();
      await bgMusicPlayer.pause();
      await flutterTts.stop();
      _showSnack('Todos os sons e alertas foram silenciados.');
    } else {
      _showSnack('Sons e alertas ativos novamente.');
    }
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
          final overlayLink = 'http://${LocalObsServer.localIp}:${LocalObsServer.port}/overlay';

          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
            title: Row(
              children: [
                PlatformBrandLogo(platform: platformId, size: 28),
                const SizedBox(width: 12),
                Text('Ligar $platformName', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                              _showSnack('Link Browser Source copiado para o TikTok Live Studio!');
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copiar Link', style: TextStyle(fontSize: 11.5)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => launchUrl(Uri.parse('https://tiktok.com'), mode: LaunchMode.externalApplication),
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
                          _showSnack('Link Browser Source para $_selectedEncoder copiado!');
                        },
                        icon: const Icon(Icons.link, size: 18),
                        label: Text('Copiar Link para $_selectedEncoder', style: const TextStyle(fontSize: 12)),
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
                    await _liveConnector.connect(platformId, user);
                  }
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('Iniciar Transmissão Ao Vivo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
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
            Icon(Icons.circle, size: 10, color: _liveConnected ? Colors.greenAccent : Colors.orangeAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _liveConnected ? _liveStatusText : 'Toca numa tecla abaixo para ligar a tua live:',
                style: const TextStyle(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.86,
          children: platforms.map((p) {
            final id = p['id']!;
            final name = p['name']!;
            final isActive = _liveConnected && _selectedPlatform == id;
            return PlatformGlassTile(
              platform: id,
              label: name,
              isActive: isActive,
              onTap: () => _openSinglePlatformDialog(id, name),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _menuTile(Icons.bolt_outlined, AppTranslations.t(_appLang, 'actions'), () => setState(() => _selectedIndex = 1), badge: 'ALERTAS & METAS'),
        _menuTile(Icons.record_voice_over_outlined, AppTranslations.t(_appLang, 'chat_tts'), () => setState(() => _selectedIndex = 2), badge: 'VOZES GOOGLE'),
        _menuTile(Icons.volunteer_activism_outlined, AppTranslations.t(_appLang, 'donation'), () => setState(() => _selectedIndex = 3), badge: 'PAGAMENTOS'),
        _menuTile(Icons.music_note_outlined, AppTranslations.t(_appLang, 'music'), () => setState(() => _selectedIndex = 4), badge: 'PLAYLISTS'),
        _menuTile(Icons.casino_outlined, AppTranslations.t(_appLang, 'interaction'), () => setState(() => _selectedIndex = 5), badge: 'ROLETA & PÓDIO'),
        _menuTile(Icons.widgets_outlined, AppTranslations.t(_appLang, 'overlays'), () => setState(() => _selectedIndex = 6), badge: 'OBS STUDIO'),
        _menuTile(Icons.storefront_outlined, AppTranslations.t(_appLang, 'marketplace'), () => setState(() => _selectedIndex = 7), badge: 'LOJA'),
        _menuTile(Icons.workspace_premium_outlined, AppTranslations.t(_appLang, 'creator_pro'), () => setState(() => _selectedIndex = 8), badge: 'PRO'),
        _menuTile(Icons.grid_view_rounded, AppTranslations.t(_appLang, 'stream_deck'), () => setState(() => _selectedIndex = 9), badge: 'VIDRO 3D'),
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
                  DropdownMenuItem(value: 'pt', child: Text('Português (Portugal)')),
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
      AppTranslations.t(_appLang, 'chat_tts'),
      AppTranslations.t(_appLang, 'donation'),
      AppTranslations.t(_appLang, 'music'),
      AppTranslations.t(_appLang, 'interaction'),
      AppTranslations.t(_appLang, 'overlays'),
      AppTranslations.t(_appLang, 'marketplace'),
      AppTranslations.t(_appLang, 'creator_pro'),
      AppTranslations.t(_appLang, 'stream_deck'),
      AppTranslations.t(_appLang, 'community'),
      AppTranslations.t(_appLang, 'profile'),
      AppTranslations.t(_appLang, 'about'),
      AppTranslations.t(_appLang, 'settings'),
    ];

    final screens = [
      _buildHomeTab(),
      ActionsStudioTab(
        alertsList: _alertsList,
        goalsList: _goalsList,
        sounds: _sounds,
        sfxPlayer: sfxAudioPlayer,
        voiceRecorder: _voiceRecorder,
        allGiftsEnabled: _allGiftsEnabled,
        onToggleAllGifts: (v) => setState(() => _allGiftsEnabled = v),
        onSpeakVoice: (txt) => _speakRealVoice(txt),
        onStateChanged: () => setState(() {}),
      ),
      ChatTtsRepositoryScreen(
        ttsEnabled: _ttsEnabled,
        speechRate: _speechRate,
        pitch: _voicePitch,
        volume: _voiceVolume,
        onToggleTts: (v) {
          setState(() => _ttsEnabled = v);
          _saveSettings();
        },
        onParamsChanged: (r, p, vol) {
          setState(() {
            _speechRate = r;
            _voicePitch = p;
            _voiceVolume = vol;
          });
          _saveSettings();
        },
        onTestVoice: (sample) => _speakRealVoice(sample),
      ),
      DonationHubScreen(sfxPlayer: sfxAudioPlayer, onSpeakVoice: (txt) => _speakRealVoice(txt)),
      MusicBackgroundScreen(bgPlayer: bgMusicPlayer),
      InteractionScreen(socket: socket, roomName: _channelCtrl.text.trim(), topGifts: _topGifts, topLikes: _topLikes),
      OverlayStudioScreen(socket: socket, serverUrl: 'http://${LocalObsServer.localIp}:${LocalObsServer.port}', roomName: _channelCtrl.text.trim()),
      const MarketplacePublicScreen(),
      CreatorStudioProScreen(creatorName: widget.user['nickname'] ?? 'Criador'),
      const SizedBox(),
      DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: Color(0xFF38BDF8),
              labelColor: Color(0xFF38BDF8),
              unselectedLabelColor: Colors.white54,
              tabs: [Tab(text: '🌍 Globo 3D NASA'), Tab(text: '👥 Perfis & Chat')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  CommunityGlobeScreen(serverUrl: 'http://${LocalObsServer.localIp}:${LocalObsServer.port}'),
                  CommunitySocialScreen(serverUrl: 'http://${LocalObsServer.localIp}:${LocalObsServer.port}', currentUser: widget.user),
                ],
              ),
            ),
          ],
        ),
      ),
      ProfilePrivacySecurityScreen(user: widget.user, onUserUpdated: widget.onUserUpdated, onLogout: widget.onLogout),
      const AboutAndSupportScreen(),
      _buildSettingsTab(),
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
      child: _selectedIndex == 9
          ? StreamDeckScreen(
              socket: socket,
              activeRoom: _channelCtrl.text.trim(),
              generatedCode: null,
              pairedRoom: null,
              isMuted: _isMuted,
              onToggleMute: _toggleMuteState,
              onGenerateCode: () {},
              onJoinWithCode: (_) {},
              onSendCommand: (cmd, val) async {
                if (cmd == 'music_toggle') {
                  MusicDeckController.sharedPlayer = bgMusicPlayer;
                  await MusicDeckController.togglePlayPause();
                } else if (cmd == 'music_next') {
                  MusicDeckController.sharedPlayer = bgMusicPlayer;
                  await MusicDeckController.nextTrack();
                } else if (cmd == 'tts_read_last' && _chatFeed.isNotEmpty) {
                  await _speakRealVoice('${_chatFeed.first['user']} diz: ${_chatFeed.first['msg']}');
                } else if (cmd == 'sound_clap' && !_isMuted) {
                  await sfxAudioPlayer.play(UrlSource(DefaultMediaLibrary.onlineSoundsRepository.first['url']!));
                } else if (cmd == 'sound_horn' && !_isMuted) {
                  await sfxAudioPlayer.play(UrlSource(DefaultMediaLibrary.onlineSoundsRepository.last['url']!));

                } else if (cmd == 'test_alert') {
                  LocalObsServer.pushAlert('Stream Deck Pro', 'Alerta disparado pela consola!', DefaultMediaLibrary.builtInGifsAndPngs.first['url']!);
                }
              },
              onMinimizeDeck: () => setState(() => _selectedIndex = 0),
            )
          : Scaffold(
              appBar: AppBar(
                centerTitle: true,
                leading: _selectedIndex == 0
                    ? GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 11),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              UserAccountManager.buildUserAvatar(widget.user, radius: 17),
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
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('HELL ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 2.5, color: Colors.white)),
                          Text('LIVE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 2, color: Color(0xFF38BDF8))),
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
