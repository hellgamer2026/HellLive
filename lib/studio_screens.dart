import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'app_data.dart';

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
  bool _isProMember = false;

  Widget _buildLiveOverlayPreview(String type, String title) {
    switch (type) {
      case 'bar':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF04091A), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('75%', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const LinearProgressIndicator(value: 0.75, minHeight: 8, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(Color(0xFF38BDF8))),
              ),
            ],
          ),
        );
      case 'timer':
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFF04091A), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amberAccent.withOpacity(0.6))),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('⏱️ CONTAGEM ATIVA', style: TextStyle(fontSize: 10, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
              Text('00:29:45', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
            ],
          ),
        );
      case 'wheel':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF04091A), borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors: [Color(0xFF1E78FF), Color(0xFF38BDF8), Color(0xFFEC4899)])),
                child: const Icon(Icons.refresh, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text('Roleta Giratória Ao Vivo', style: TextStyle(fontSize: 11.5, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
            ],
          ),
        );
      case 'podium':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF04091A), borderRadius: BorderRadius.circular(10)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('🥇 @TopApoiante · 5.000 💎', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
              Text('🔥 Streak x14', style: TextStyle(fontSize: 11, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF04091A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
          ),
          child: Center(
            child: Text('✨ Pré-visualização HUD · $title', style: const TextStyle(fontSize: 11, color: Color(0xFF7DD3FC), fontWeight: FontWeight.w600)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanRoom = (widget.roomName.isEmpty ? 'teu_canal' : widget.roomName).toLowerCase().replaceAll('@', '');
    final baseOverlayUrl = '${widget.serverUrl}/overlay/$cleanRoom';

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF38BDF8),
            labelColor: Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: '🎨 Galeria com Pré-Visualização'),
              Tab(text: '✨ Marketplace PRO'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: _studioCardDeco(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🔗 URL Geral Browser Source (OBS / Live Studio)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 13)),
                          const SizedBox(height: 4),
                          SelectableText(baseOverlayUrl, style: const TextStyle(fontSize: 11.5, color: Colors.cyanAccent)),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: baseOverlayUrl));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL copiado!')));
                              },
                              icon: const Icon(Icons.copy, size: 17, color: Colors.white),
                              label: const Text('Copiar Link Principal', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...DefaultMediaLibrary.tikfinityOverlayCategories.map((cat) {
                      final items = List<Map<String, String>>.from(cat['items']);
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
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(ov['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                            Text(ov['desc']!, style: const TextStyle(fontSize: 11, color: Colors.white60)),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: widgetUrl));
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Link "${ov['name']}" copiado!')));
                                        },
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(horizontal: 10)),
                                        onPressed: () {
                                          if (widget.roomName.isNotEmpty) {
                                            widget.socket.emit('remote_command', {'room': cleanRoom, 'command': 'scene', 'payload': ov['scene']});
                                          }
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Overlay "${ov['name']}" ativado!')));
                                        },
                                        child: const Text('Ativar', style: TextStyle(color: Colors.white, fontSize: 11.5)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: _studioCardDeco(),
                      child: Column(
                        children: [
                          Icon(Icons.workspace_premium, color: _isProMember ? Colors.greenAccent : const Color(0xFFF59E0B), size: 46),
                          const SizedBox(height: 8),
                          Text(_isProMember ? 'Conta Criador PRO Ativa' : 'Estúdio Criador & Loja PRO', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Publica e vende os teus próprios Overlays e Packs no Marketplace HELL Live.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Colors.white70)),
                          const SizedBox(height: 12),
                          if (!_isProMember)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
                              onPressed: () => setState(() => _isProMember = true),
                              child: const Text('Ativar Plano PRO (4.99 €/mês)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
}


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
    _wheelCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    widget.socket.on('live_event', (data) {
      if (!mounted || !_subathonRunning) return;
      if (data['type'] == 'gift') {
        final coins = (data['coins'] ?? 1) as int;
        setState(() => _subathonSeconds += (coins * _secPerCoin));
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
      setState(() => _subathonRunning = false);
    } else {
      setState(() => _subathonRunning = true);
      _subathonTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_subathonSeconds > 0) {
          setState(() => _subathonSeconds--);
        } else {
          _subathonTimer?.cancel();
          setState(() => _subathonRunning = false);
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
    final end = _currentAngle + (4 + rnd.nextInt(4)) * 2 * pi + rnd.nextDouble() * 2 * pi;
    final anim = Tween<double>(begin: _currentAngle, end: end).animate(CurvedAnimation(parent: _wheelCtrl, curve: Curves.easeOutCubic));
    anim.addListener(() => setState(() => _currentAngle = anim.value));
    _wheelCtrl.forward(from: 0).then((_) {
      final winner = _options[rnd.nextInt(_options.length)];
      setState(() => _lastWinner = '🎉 $winner');
      final clean = widget.roomName.toLowerCase().replaceAll('@', '');
      if (clean.isNotEmpty) {
        widget.socket.emit('remote_command', {'room': clean, 'command': 'wheel', 'payload': _options});
      }
    });
  }

  List<Color> _wheelColors() {
    if (_wheelTheme == 'fire') return [const Color(0xFFEF4444), const Color(0xFFF97316), const Color(0xFFFACC15), const Color(0xFFDC2626)];
    if (_wheelTheme == 'toxic') return [const Color(0xFF22C55E), const Color(0xFF10B981), const Color(0xFF84CC16), const Color(0xFF059669)];
    return [const Color(0xFF1E78FF), const Color(0xFF38BDF8), const Color(0xFF6366F1), const Color(0xFF0EA5E9)];
  }
  @override
  Widget build(BuildContext context) {
    final cleanRoom = widget.roomName.toLowerCase().replaceAll('@', '');
    final medals = ['🥇', '🥈', '🥉'];

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
              Tab(text: '🎡 Roleta & Votação'),
              Tab(text: '🏆 Pódio Oficial'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: _studioCardDeco(),
                      child: Column(
                        children: [
                          const Text('CONTAGEM REGRESSIVA INTERATIVA', style: TextStyle(fontSize: 11, letterSpacing: 2, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Os presentes dos espectadores aumentam o relógio automaticamente!', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white60)),
                          const SizedBox(height: 16),
                          Text(_formatDuration(_subathonSeconds), style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: _subathonRunning ? Colors.amber : Colors.green),
                                onPressed: _toggleSubathon,
                                icon: Icon(_subathonRunning ? Icons.pause : Icons.play_arrow, color: Colors.black),
                                label: Text(_subathonRunning ? 'Pausar' : 'Iniciar Relógio', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: () => setState(() => _subathonSeconds += 300),
                                child: const Text('+5 Min'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => setState(() => _subathonSeconds = 1800),
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tempo ganho por cada moeda:', style: TextStyle(fontSize: 12.5)),
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
                      decoration: _studioCardDeco(),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('🎡 Roleta Interativa', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 15)),
                              DropdownButton<String>(
                                value: _wheelTheme,
                                dropdownColor: const Color(0xFF0B1636),
                                items: const [
                                  DropdownMenuItem(value: 'neon', child: Text('Néon')),
                                  DropdownMenuItem(value: 'fire', child: Text('Fogo')),
                                  DropdownMenuItem(value: 'toxic', child: Text('Tóxico')),
                                ],
                                onChanged: (v) => setState(() => _wheelTheme = v ?? 'neon'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.rotate(
                                angle: _currentAngle,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors: _wheelColors()), border: Border.all(color: Colors.white, width: 3)),
                                ),
                              ),
                              Container(
                                width: 56,
                                height: 56,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFF050B1E), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF38BDF8), width: 2)),
                                child: Image.asset('icon.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, color: Color(0xFF38BDF8))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(_lastWinner, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                              onPressed: _spinWheel,
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              label: const Text('GIRAR ROLETA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(child: TextField(controller: _optionCtrl, decoration: const InputDecoration(hintText: 'Adicionar opção...', isDense: true))),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Color(0xFF38BDF8)),
                                onPressed: () {
                                  if (_optionCtrl.text.trim().isNotEmpty) {
                                    setState(() {
                                      _options.add(_optionCtrl.text.trim());
                                      _optionCtrl.clear();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 6,
                            children: _options.map((o) => Chip(label: Text(o, style: const TextStyle(fontSize: 11)), onDeleted: () => setState(() => _options.remove(o)))).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _studioCardDeco(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('📊 Votação Ao Vivo (!sim / !nao)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                              Switch(
                                activeColor: Colors.white,
                                activeTrackColor: const Color(0xFF1E78FF),
                                value: _pollActive,
                                onChanged: (v) {
                                  setState(() => _pollActive = v);
                                  if (cleanRoom.isNotEmpty) {
                                    widget.socket.emit('update_poll', {
                                      'room': cleanRoom,
                                      'poll': {'active': v, 'question': _pollQuestionCtrl.text.trim(), 'opt1Label': 'SIM (!sim)', 'opt2Label': 'NÃO (!nao)', 'opt1Key': '!sim', 'opt2Key': '!nao'}
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          TextField(controller: _pollQuestionCtrl, decoration: const InputDecoration(labelText: 'Pergunta para o Chat')),
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
                      decoration: _studioCardDeco(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💎 TOP PRESENTES DA LIVE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                          const SizedBox(height: 10),
                          if (widget.topGifts.isEmpty)
                            const Text('Ainda sem presentes registados nesta sessão.', style: TextStyle(color: Colors.white54))
                          else
                            ...widget.topGifts.take(5).toList().asMap().entries.map((e) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Text(e.key < 3 ? medals[e.key] : '#${e.key + 1}', style: const TextStyle(fontSize: 20)),
                                  title: Text(e.value['user'] ?? ''),
                                  trailing: Text('${e.value['score']} moedas', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                                )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _studioCardDeco(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('❤️ TOP LIKES DA LIVE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF43F5E))),
                          const SizedBox(height: 10),
                          if (widget.topLikes.isEmpty)
                            const Text('Ainda sem likes registados nesta sessão.', style: TextStyle(color: Colors.white54))
                          else
                            ...widget.topLikes.take(5).toList().asMap().entries.map((e) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Text(e.key < 3 ? medals[e.key] : '#${e.key + 1}', style: const TextStyle(fontSize: 20)),
                                  title: Text(e.value['user'] ?? ''),
                                  trailing: Text('${e.value['score']} likes', style: const TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold)),
                                )),
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
}
