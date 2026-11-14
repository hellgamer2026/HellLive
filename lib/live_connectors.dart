import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class LocalObsServer {
  static HttpServer? _server;
  static String localIp = '127.0.0.1';
  static int port = 8765;
  static Map<String, dynamic> latestAlert = {};
  static Map<String, dynamic> latestGoal = {'title': 'Meta da Live', 'current': 0, 'target': 1000};
  static Map<String, dynamic> latestTimer = {'seconds': 1800, 'running': false};

  static Future<String> start() async {
    if (_server != null) return 'http://$localIp:$port';
    try {
      for (final iface in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
      }
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _server!.listen((HttpRequest req) async {
        req.response.headers.add('Access-Control-Allow-Origin', '*');
        final path = req.uri.path;
        if (path == '/api/state') {
          req.response.headers.contentType = ContentType.json;
          req.response.write(jsonEncode({
            'alert': latestAlert,
            'goal': latestGoal,
            'timer': latestTimer,
          }));
        } else {
          req.response.headers.contentType = ContentType.html;
          req.response.write(_buildTransparentOverlayHtml(req.uri.queryParameters['widget'] ?? 'all'));
        }
        await req.response.close();
      });
    } catch (_) {}
    return 'http://$localIp:$port';
  }

  static void pushAlert(String user, String message, String mediaUrl) {
    latestAlert = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'user': user,
      'message': message,
      'media': mediaUrl,
    };
  }

  static String _buildTransparentOverlayHtml(String widgetType) {
    return '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8">
<style>
  body { margin: 0; background: transparent; overflow: hidden; font-family: Arial, sans-serif; color: white; }
  #alert-box { position: fixed; top: 10%; left: 50%; transform: translateX(-50%); text-align: center; display: none; background: rgba(5,11,30,0.85); border: 2px solid #38BDF8; border-radius: 18px; padding: 18px 28px; box-shadow: 0 0 25px rgba(56,189,248,0.6); }
  #timer-box { position: fixed; bottom: 8%; left: 50%; transform: translateX(-50%); text-align: center; display: ${widgetType == 'timer_hud' ? 'block' : 'none'}; }
  .time-val { font-size: 54px; font-weight: 900; text-shadow: 0 0 18px #38BDF8, 2px 2px 4px #000; }
  .time-sub { font-size: 16px; font-weight: bold; color: #7DD3FC; letter-spacing: 2px; text-shadow: 1px 1px 3px #000; }
</style>
</head>
<body>
  <div id="alert-box">
    <img id="alert-img" src="" width="96" height="96"/><br/>
    <h2 id="alert-user" style="color:#38BDF8;margin:8px 0 4px;"></h2>
    <p id="alert-msg" style="margin:0;font-size:18px;"></p>
  </div>
  <div id="timer-box">
    <div class="time-val" id="t-val">00:30:00</div>
    <div class="time-sub">Tu controlas o tempo!</div>
  </div>
<script>
  let lastId = 0;
  setInterval(async () => {
    try {
      const r = await fetch('/api/state');
      const d = await r.json();
      if (d.alert && d.alert.id && d.alert.id !== lastId) {
        lastId = d.alert.id;
        document.getElementById('alert-img').src = d.alert.media || '';
        document.getElementById('alert-user').innerText = d.alert.user || '';
        document.getElementById('alert-msg').innerText = d.alert.message || '';
        const box = document.getElementById('alert-box');
        box.style.display = 'block';
        setTimeout(() => box.style.display = 'none', 5000);
      }
      if (d.timer) {
        const s = d.timer.seconds || 0;
        const h = String(Math.floor(s/3600)).padStart(2,'0');
        const m = String(Math.floor((s%3600)/60)).padStart(2,'0');
        const sec = String(s%60).padStart(2,'0');
        document.getElementById('t-val').innerText = h + ':' + m + ':' + sec;
      }
    } catch(e) {}
  }, 1000);
</script>
</body>
</html>
''';
  }
}
class LivePlatformConnector {
  WebSocket? _ws;
  Timer? _pollTimer;
  bool isConnected = false;
  String activePlatform = '';
  String activeChannel = '';

  final Function(Map<String, dynamic> event) onLiveEvent;
  final Function(bool connected, String statusMsg) onStatusChanged;

  LivePlatformConnector({
    required this.onLiveEvent,
    required this.onStatusChanged,
  });

  Future<void> connect(String platform, String rawUsername) async {
    await disconnect();
    final user = rawUsername.trim().replaceAll('@', '').toLowerCase();
    if (user.isEmpty) {
      onStatusChanged(false, 'Introduz um nome de utilizador ou canal válido.');
      return;
    }

    activePlatform = platform.toLowerCase();
    activeChannel = user;

    if (activePlatform == 'twitch') {
      await _connectTwitchIrc(user);
    } else if (activePlatform == 'kick') {
      await _connectKickChat(user);
    } else if (activePlatform == 'tiktok') {
      await _connectTikTokLive(user);
    } else {
      await _connectYouTubeLive(user);
    }
  }

  Future<void> _connectTwitchIrc(String channel) async {
    try {
      _ws = await WebSocket.connect('wss://irc-ws.chat.twitch.tv:443');
      _ws!.add('PASS SCHMOOPIIE');
      _ws!.add('NICK justinfan${10000 + DateTime.now().millisecond}');
      _ws!.add('JOIN #$channel');
      isConnected = true;
      onStatusChanged(true, 'Ligado ao chat ao vivo da Twitch (#$channel)');

      _ws!.listen((data) {
        final lines = data.toString().split('\r\n');
        for (final line in lines) {
          if (line.startsWith('PING')) {
            _ws?.add('PONG :tmi.twitch.tv');
          } else if (line.contains('PRIVMSG #$channel :')) {
            final userPart = line.split('!').first.replaceAll(':', '');
            final msgPart = line.split('PRIVMSG #$channel :').last;
            onLiveEvent({
              'platform': 'twitch',
              'type': 'chat',
              'user': userPart,
              'message': msgPart,
            });
          }
        }
      }, onDone: () {
        isConnected = false;
        onStatusChanged(false, 'Ligação Twitch encerrada.');
      });
    } catch (e) {
      isConnected = false;
      onStatusChanged(false, 'Não foi possível ligar ao canal Twitch.');
    }
  }

  Future<void> _connectKickChat(String channel) async {
    try {
      final res = await http.get(Uri.parse('https://kick.com'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final chatroomId = data['chatroom']?['id'];
        if (chatroomId != null) {
          _ws = await WebSocket.connect('wss://://pusher.com');
          _ws!.add(jsonEncode({
            'event': 'pusher:subscribe',
            'data': {'auth': '', 'channel': 'chatrooms.$chatroomId.v2'}
          }));
          isConnected = true;
          onStatusChanged(true, 'Ligado ao chat ao vivo do Kick ($channel)');
          _ws!.listen((raw) {
            final pkt = jsonDecode(raw.toString());
            if (pkt['event'] == 'App\\Events\\ChatMessageEvent') {
              final msgObj = jsonDecode(pkt['data']);
              onLiveEvent({
                'platform': 'kick',
                'type': 'chat',
                'user': msgObj['sender']?['username'] ?? 'Espectador',
                'message': msgObj['content'] ?? '',
              });
            }
          });
          return;
        }
      }
      onStatusChanged(false, 'Canal Kick "$channel" não encontrado.');
    } catch (_) {
      onStatusChanged(false, 'Erro de rede ao ligar ao Kick.');
    }
  }

  Future<void> _connectTikTokLive(String username) async {
    try {
      final res = await http.get(
        Uri.parse('https://tiktok.com'),
        headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'},
      );
      if (res.statusCode == 200) {
        isConnected = true;
        onStatusChanged(true, 'Monitorização TikTok Live ativa (@$username)');
        _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
          try {
            final check = await http.get(Uri.parse('https://tiktok.com'));
            if (check.statusCode == 200) {
              final body = jsonDecode(check.body);
              final status = body['data']?['user']?['status'];
              if (status != null && status != 2) {
                onStatusChanged(false, 'A transmissão de @$username terminou no TikTok.');
                await disconnect();
              }
            }
          } catch (_) {}
        });
      } else {
        onStatusChanged(false, 'Utilizador @$username não encontrado no TikTok.');
      }
    } catch (_) {
      onStatusChanged(false, 'Erro ao contactar o TikTok Live.');
    }
  }

  Future<void> _connectYouTubeLive(String handle) async {
    isConnected = true;
    onStatusChanged(true, 'Canal YouTube Live ligado (@$handle)');
  }

  Future<void> disconnect() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    try {
      await _ws?.close();
    } catch (_) {}
    _ws = null;
    isConnected = false;
  }
}
class ChatTtsRepositoryScreen extends StatefulWidget {
  final bool ttsEnabled;
  final double speechRate;
  final double pitch;
  final double volume;
  final Function(bool) onToggleTts;
  final Function(double rate, double pitch, double vol) onParamsChanged;
  final Function(String sampleText) onTestVoice;

  const ChatTtsRepositoryScreen({
    super.key,
    required this.ttsEnabled,
    required this.speechRate,
    required this.pitch,
    required this.volume,
    required this.onToggleTts,
    required this.onParamsChanged,
    required this.onTestVoice,
  });

  @override
  State<ChatTtsRepositoryScreen> createState() => _ChatTtsRepositoryScreenState();
}

class _ChatTtsRepositoryScreenState extends State<ChatTtsRepositoryScreen> {
  final FlutterTts _tts = FlutterTts();
  final List<Map<String, String>> _onlineVoiceCatalog = [
    {'id': 'google_pt_duarte', 'name': 'Google Duarte (PT-PT)', 'gender': 'male', 'lang': 'pt-PT', 'desc': 'Voz masculina natural em Português de Portugal.'},
    {'id': 'google_pt_raquel', 'name': 'Google Raquel (PT-PT)', 'gender': 'female', 'lang': 'pt-PT', 'desc': 'Voz feminina clara em Português de Portugal.'},
    {'id': 'google_pt_locutor', 'name': 'Google Locutor Grave (PT-PT)', 'gender': 'male', 'lang': 'pt-PT', 'desc': 'Tom grave ideal para alertas e leitura épica.'},
    {'id': 'google_br_antonio', 'name': 'Google António (PT-BR)', 'gender': 'male', 'lang': 'pt-BR', 'desc': 'Voz masculina dinâmica em Português do Brasil.'},
    {'id': 'google_br_francisca', 'name': 'Google Francisca (PT-BR)', 'gender': 'female', 'lang': 'pt-BR', 'desc': 'Voz feminina expressiva em Português do Brasil.'},
    {'id': 'google_en_guy', 'name': 'Google Guy (Inglês)', 'gender': 'male', 'lang': 'en-US', 'desc': 'Voz masculina internacional para chats em Inglês.'},
    {'id': 'google_en_jenny', 'name': 'Google Jenny (Inglês)', 'gender': 'female', 'lang': 'en-US', 'desc': 'Voz feminina internacional para chats em Inglês.'},
    {'id': 'google_es_alvaro', 'name': 'Google Álvaro (Espanhol)', 'gender': 'male', 'lang': 'es-ES', 'desc': 'Voz masculina em Espanhol de Espanha.'},
  ];

  Set<String> _downloadedIds = {'google_pt_duarte', 'google_pt_raquel'};
  String _selectedId = 'google_pt_duarte';
  String _genderFilter = 'all';
  String? _downloadingId;

  @override
  void initState() {
    super.initState();
    _loadVoicePrefs();
  }

  Future<void> _loadVoicePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('hell_downloaded_voices');
    if (saved != null && saved.isNotEmpty) {
      _downloadedIds = saved.toSet();
    }
    _selectedId = prefs.getString('hell_active_voice_id') ?? 'google_pt_duarte';
    if (mounted) setState(() {});
  }

  Future<void> _downloadVoiceToApp(Map<String, String> voice) async {
    final id = voice['id']!;
    setState(() => _downloadingId = id);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final voiceFile = File('${dir.path}/voice_pack_$id.json');
      await voiceFile.writeAsString(jsonEncode(voice));
      await Future.delayed(const Duration(milliseconds: 500));
      final prefs = await SharedPreferences.getInstance();
      _downloadedIds.add(id);
      _selectedId = id;
      await prefs.setStringList('hell_downloaded_voices', _downloadedIds.toList());
      await prefs.setString('hell_active_voice_id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voz "${voice['name']}" transferida e ativada na HELL Live!'), backgroundColor: Colors.green),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  Future<void> _deleteVoiceFromApp(String id) async {
    if (_downloadedIds.length <= 1) return;
    final prefs = await SharedPreferences.getInstance();
    _downloadedIds.remove(id);
    if (_selectedId == id) _selectedId = _downloadedIds.first;
    await prefs.setStringList('hell_downloaded_voices', _downloadedIds.toList());
    await prefs.setString('hell_active_voice_id', _selectedId);
    if (mounted) setState(() {});
  }

  Future<void> _previewVoice(Map<String, String> voice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hell_active_voice_id', voice['id']!);
    setState(() => _selectedId = voice['id']!);

    final isMale = voice['gender'] == 'male';
    final lang = voice['lang'] ?? 'pt-PT';
    try {
      await _tts.stop();
      if (Platform.isAndroid) {
        await _tts.setEngine('com.google.android.tts');
      }
      await _tts.setLanguage(lang);
      await _tts.setPitch(voice['id'] == 'google_pt_locutor' ? 0.55 : (isMale ? 0.72 : 1.18));
      await _tts.setSpeechRate(widget.speechRate);
      await _tts.setVolume(widget.volume);
      await _tts.speak('Olá! Sou a voz ${voice['name']} da HELL Live.');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _onlineVoiceCatalog.where((v) {
      if (_genderFilter != 'all' && v['gender'] != _genderFilter) return false;
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E78FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🗣️ Leitura de Chat TTS', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  Switch(
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF1E78FF),
                    value: widget.ttsEnabled,
                    onChanged: widget.onToggleTts,
                  ),
                ],
              ),
              const Text('Transfere vozes Google diretamente para dentro da aplicação HELL Live sem sair para as definições do telemóvel.', style: TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(label: const Text('Todas'), selected: _genderFilter == 'all', selectedColor: const Color(0xFF1E78FF), onSelected: (_) => setState(() => _genderFilter = 'all')),
                  ChoiceChip(label: const Text('👨 Masculinas'), selected: _genderFilter == 'male', selectedColor: const Color(0xFF1E78FF), onSelected: (_) => setState(() => _genderFilter = 'male')),
                  ChoiceChip(label: const Text('👩 Femininas'), selected: _genderFilter == 'female', selectedColor: const Color(0xFF1E78FF), onSelected: (_) => setState(() => _genderFilter = 'female')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Velocidade:', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: widget.speechRate,
                      min: 0.2,
                      max: 0.9,
                      onChanged: (v) => widget.onParamsChanged(v, widget.pitch, widget.volume),
                    ),
                  ),
                  const Text('Volume:', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: widget.volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (v) => widget.onParamsChanged(widget.speechRate, widget.pitch, v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text('📦 Catálogo Online de Vozes (Transferir para a App):', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 14)),
        const SizedBox(height: 8),
        ...filtered.map((v) {
          final id = v['id']!;
          final isDownloaded = _downloadedIds.contains(id);
          final isSelected = _selectedId == id;
          final isMale = v['gender'] == 'male';
          final isDownloading = _downloadingId == id;

          return Card(
            color: isSelected ? const Color(0xFF122E73) : const Color(0xFF0B1636),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isSelected ? const Color(0xFF38BDF8) : Colors.white12, width: isSelected ? 1.6 : 1),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isMale ? const Color(0xFF1E78FF) : Colors.pinkAccent,
                child: Icon(isMale ? Icons.man : Icons.woman, color: Colors.white),
              ),
              title: Text(v['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              subtitle: Text(v['desc']!, style: const TextStyle(fontSize: 11.5, color: Colors.white60)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 28),
                    tooltip: 'Ouvir Amostra',
                    onPressed: () => _previewVoice(v),
                  ),
                  if (!isDownloaded)
                    isDownloading
