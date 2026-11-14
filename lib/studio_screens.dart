import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'app_data.dart';
import 'live_connectors.dart';

BoxDecoration _studioCardDeco() => BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF1E429F), width: 1.2),
    );

class OverlayStudioScreen extends StatefulWidget {
  final IO.Socket socket;
  final String serverUrl;
  final String roomName;

  const OverlayStudioScreen({super.key, required this.socket, required this.serverUrl, required this.roomName});

  @override
  State<OverlayStudioScreen> createState() => _OverlayStudioScreenState();
}

class _OverlayStudioScreenState extends State<OverlayStudioScreen> {
  String _localServerUrl = 'http://127.0.0.1:8765';
  final TextEditingController _customGifCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initLocalServer();
  }

  Future<void> _initLocalServer() async {
    final url = await LocalObsServer.start();
    if (mounted) setState(() => _localServerUrl = url);
  }

  Widget _buildLiveOverlayPreview(String type, String title) {
    switch (type) {
      case 'bar':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF04091A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF25F4EE), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('750 / 1000', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF25F4EE))),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(value: 0.75, minHeight: 8, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(Color(0xFF25F4EE))),
              ),
            ],
          ),
        );
      case 'timer':
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: const Column(
            children: [
              Text('00:29:45', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white, shadows: [Shadow(color: Color(0xFF38BDF8), blurRadius: 12)])),
              Text('Tu controlas o tempo!', style: TextStyle(fontSize: 11, color: Color(0xFF7DD3FC), fontWeight: FontWeight.bold)),
            ],
          ),
        );
      case 'wheel':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF04091A), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(colors: [Color(0xFF1E78FF), Color(0xFF38BDF8), Color(0xFFEC4899), Color(0xFFFACC15)]),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.casino, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text('Roleta 3D Interativa Ao Vivo', style: TextStyle(fontSize: 12, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
            ],
          ),
        );
      case 'podium':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF04091A), borderRadius: BorderRadius.circular(12)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('🥇 @TopApoiante · 5.000 💎', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
              Text('🔥 Top Geral', style: TextStyle(fontSize: 11, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF04091A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF38BDF8), width: 1.8),
            boxShadow: [BoxShadow(color: const Color(0xFF38BDF8).withOpacity(0.25), blurRadius: 10)],
          ),
          child: Center(
            child: Text('✨ HUD 3D Transparente · $title', style: const TextStyle(fontSize: 11.5, color: Color(0xFF7DD3FC), fontWeight: FontWeight.bold)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseOverlayUrl = '$_localServerUrl/overlay';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _studioCardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.sensors, color: Colors.greenAccent, size: 18),
                  SizedBox(width: 8),
                  Text('Servidor Local Browser Source Ativo (OBS / Live Studio)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              SelectableText(baseOverlayUrl, style: const TextStyle(fontSize: 12.5, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: baseOverlayUrl));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link Browser Source copiado para colar no OBS / TikTok Live Studio!')));
                  },
                  icon: const Icon(Icons.copy, size: 17, color: Colors.white),
                  label: const Text('Copiar Link Principal (OBS / Studio)', style: TextStyle(color: Colors.white)),
                ),
              ),
              const Divider(color: Colors.white12, height: 20),
              const Text('Incorporar GIF Externo Personalizado no Overlay:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customGifCtrl,
                      decoration: const InputDecoration(hintText: 'Colar URL direto do GIF (.gif)...', isDense: true, border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF122B6B)),
                    onPressed: () {
                      final url = _customGifCtrl.text.trim();
                      if (url.isNotEmpty) {
                        LocalObsServer.pushAlert('Overlay Personalizado', 'GIF Ativado na Live!', url);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GIF enviado para o ecrã da live!')));
                      }
                    },
                    child: const Text('Disparar GIF', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...DefaultMediaLibrary.tikfinityOverlayCategories.map((cat) {
          final items = List<Map<String, dynamic>>.from(cat['items']);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(cat['category'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF38BDF8))),
              ),
              ...items.map((ov) {
                final widgetUrl = '$baseOverlayUrl?widget=${ov['scene']}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: _studioCardDeco(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLiveOverlayPreview(ov['previewType'] ?? 'frame', ov['name']!),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
class InteractionScreen extends StatefulWidget {
  final IO.Socket socket;
  final String roomName;
  final List<Map<String, dynamic>> topGifts;
  final List<Map<String, dynamic>> topLikes;

  const InteractionScreen({
    super.key,
    required this.socket,
    required this.roomName,
    required this.topGifts,
    required this.topLikes,
  });

  @override
  State<InteractionScreen> createState() => _InteractionScreenState();
}

class _InteractionScreenState extends State<InteractionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _wheelCtrl;
  double _currentAngle = 0;
  String _lastWinner = 'Toca em Girar!';
  String _wheelTheme = 'neon';

  int _subathonSeconds = 1800;
  bool _subathonRunning = false;
  Timer? _subathonTimer;
  int _secPerCoin = 2;

  final TextEditingController _optionCtrl = TextEditingController();
  final TextEditingController _pollQuestionCtrl = TextEditingController(text: 'Jogo a próxima partida de sniper?');
  bool _pollActive = false;

  List<String> _options = [
    '10 Flexões',
    'Escolher Música',
    'Sem Mira 1 Ronda',
    'Salve Especial',
    'Desafio do Chat',
    'Sorte Grande!',
  ];

  @override
  void initState() {
    super.initState();
    _wheelCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    widget.socket.on('live_event', (data) {
      if (!mounted || !_subathonRunning) return;
      if (data['type'] == 'gift') {
        final coins = (data['coins'] ?? 1) as int;
        setState(() {
          _subathonSeconds += (coins * _secPerCoin);
          LocalObsServer.latestTimer = {'seconds': _subathonSeconds, 'running': _subathonRunning};
        });
      }
    });
  }

  @override
  void dispose() {
    _subathonTimer?.cancel();
    _wheelCtrl.dispose();
    _optionCtrl.dispose();
    _pollQuestionCtrl.dispose();
    super.dispose();
  }

  void _toggleSubathon() {
    if (_subathonRunning) {
      _subathonTimer?.cancel();
      setState(() {
        _subathonRunning = false;
        LocalObsServer.latestTimer = {'seconds': _subathonSeconds, 'running': false};
      });
    } else {
      setState(() {
        _subathonRunning = true;
        LocalObsServer.latestTimer = {'seconds': _subathonSeconds, 'running': true};
      });
      _subathonTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_subathonSeconds > 0) {
          setState(() {
            _subathonSeconds--;
            LocalObsServer.latestTimer = {'seconds': _subathonSeconds, 'running': true};
          });
        } else {
          _subathonTimer?.cancel();
          setState(() {
            _subathonRunning = false;
            LocalObsServer.latestTimer = {'seconds': 0, 'running': false};
          });
        }
      });
    }
  }

  String _formatDuration(int totalSeconds) {
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _spinWheel() {
    if (_options.isEmpty) return;
    final rnd = Random();
    final end = _currentAngle + (5 + rnd.nextInt(4)) * 2 * pi + rnd.nextDouble() * 2 * pi;
    final anim = Tween<double>(begin: _currentAngle, end: end).animate(CurvedAnimation(parent: _wheelCtrl, curve: Curves.easeOutQuart));
    anim.addListener(() => setState(() => _currentAngle = anim.value));
    _wheelCtrl.forward(from: 0).then((_) {
      final winner = _options[rnd.nextInt(_options.length)];
      setState(() => _lastWinner = '🎉 $winner');
      LocalObsServer.pushAlert('Roleta 3D HELL Live', 'Resultado: $winner', 'https://jsdelivr.net');
    });
  }

  List<Color> _wheelColors() {
    if (_wheelTheme == 'gold') return [const Color(0xFFFACC15), const Color(0xFFD97706), const Color(0xFFFEF08A), const Color(0xFFB45309)];
    if (_wheelTheme == 'fire') return [const Color(0xFFEF4444), const Color(0xFFF97316), const Color(0xFFFACC15), const Color(0xFFDC2626)];
    if (_wheelTheme == 'toxic') return [const Color(0xFF22C55E), const Color(0xFF10B981), const Color(0xFF84CC16), const Color(0xFF059669)];
    return [const Color(0xFF1E78FF), const Color(0xFF38BDF8), const Color(0xFF6366F1), const Color(0xFF0EA5E9)];
  }
  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    final timerUrl = 'http://${LocalObsServer.localIp}:${LocalObsServer.port}/overlay?widget=timer_hud';

    final Map<String, Map<String, dynamic>> overallMap = {};
    for (final g in widget.topGifts) {
      final u = (g['user'] ?? '').toString();
      if (u.isEmpty) continue;
      overallMap[u] = {
        'user': u,
        'avatar': g['avatar'] ?? '',
        'score': (overallMap[u]?['score'] ?? 0) + ((g['score'] ?? 0) as int) * 10,
      };
    }
    for (final l in widget.topLikes) {
      final u = (l['user'] ?? '').toString();
      if (u.isEmpty) continue;
      overallMap[u] = {
        'user': u,
        'avatar': l['avatar'] ?? (overallMap[u]?['avatar'] ?? ''),
        'score': (overallMap[u]?['score'] ?? 0) + ((l['score'] ?? 0) as int),
      };
    }
    final topOverall = overallMap.values.toList()..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF38BDF8),
            labelColor: Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: '⏱️ Temporizador'),
              Tab(text: '🎡 Roleta 3D'),
              Tab(text: '🏆 Pódio & Tops'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 1. CONTAGEM REGRESSIVA SEM FUNDO ("Tu controlas o tempo!")
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5), width: 1.4),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatDuration(_subathonSeconds),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              color: Colors.white,
                              shadows: [Shadow(color: Color(0xFF38BDF8), blurRadius: 18)],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tu controlas o tempo!',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Color(0xFF7DD3FC)),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: _subathonRunning ? Colors.amber : Colors.green),
                                onPressed: _toggleSubathon,
                                icon: Icon(_subathonRunning ? Icons.pause : Icons.play_arrow, color: Colors.black),
                                label: Text(_subathonRunning ? 'Pausar' : 'Iniciar', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => setState(() {
                                  _subathonSeconds += 300;
                                  LocalObsServer.latestTimer = {'seconds': _subathonSeconds, 'running': _subathonRunning};
                                }),
                                child: const Text('+5 Min'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => setState(() {
                                  _subathonSeconds = 1800;
                                  LocalObsServer.latestTimer = {'seconds': _subathonSeconds, 'running': _subathonRunning};
                                }),
                                child: const Text('Repor'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tempo ganho por moeda:', style: TextStyle(fontSize: 12.5)),
                              DropdownButton<int>(
                                value: _secPerCoin,
                                dropdownColor: const Color(0xFF0B1636),
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('+1 seg / moeda')),
                                  DropdownMenuItem(value: 2, child: Text('+2 seg / moeda')),
                                  DropdownMenuItem(value: 5, child: Text('+5 seg / moeda')),
                                  DropdownMenuItem(value: 10, child: Text('+10 seg / moeda')),
                                ],
                                onChanged: (v) => setState(() => _secPerCoin = v ?? 2),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: timerUrl));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link Transparente do Temporizador copiado para OBS / Studio!')));
                              },
                              icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                              label: const Text('Copiar Link Sem Fundo (OBS / Studio)', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // 2. ROLETA 3D MULTI-ESTILO PERSONALIZÁVEL
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _studioCardDeco(),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('🎡 Roleta 3D Personalizável', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 15)),
                              DropdownButton<String>(
                                value: _wheelTheme,
                                dropdownColor: const Color(0xFF0B1636),
                                items: const [
                                  DropdownMenuItem(value: 'neon', child: Text('Néon Cyber')),
                                  DropdownMenuItem(value: 'gold', child: Text('Ouro VIP')),
                                  DropdownMenuItem(value: 'fire', child: Text('Fogo Épico')),
                                  DropdownMenuItem(value: 'toxic', child: Text('Esmeralda PRO')),
                                ],
                                onChanged: (v) => setState(() => _wheelTheme = v ?? 'neon'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Icon(Icons.arrow_drop_down, size: 36, color: Colors.amberAccent),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.rotate(
                                angle: _currentAngle,
                                child: Container(
                                  width: 175,
                                  height: 175,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: _wheelColors().first.withOpacity(0.5), blurRadius: 22)],
                                    border: Border.all(color: Colors.white, width: 4),
                                  ),
                                  child: CustomPaint(
                                    painter: _Wheel3DPainter(options: _options, colors: _wheelColors()),
                                  ),
                                ),
                              ),
                              Container(
                                width: 52,
                                height: 52,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF050B1E),
