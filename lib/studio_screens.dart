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

class PodiumScreen extends StatefulWidget {
  final IO.Socket socket;
  final String roomName;
  final List<Map<String, dynamic>> topGifts;
  final List<Map<String, dynamic>> topLikes;

  const PodiumScreen({
    super.key,
    required this.socket,
    required this.roomName,
    required this.topGifts,
    required this.topLikes,
  });

  @override
  State<PodiumScreen> createState() => _PodiumScreenState();
}

class _PodiumScreenState extends State<PodiumScreen> {
  String _selectedStyle = 'neon';

  void _applyStyle(String style) {
    setState(() => _selectedStyle = style);
    final clean = widget.roomName.toLowerCase().replaceAll('@', '');
    if (clean.isNotEmpty) {
      widget.socket.emit('set_podium_style', {'room': clean, 'style': style});
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Estilo "$style" aplicado ao Pódio!')));
  }

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _studioCardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎨 Estilo Visual do Pódio (Estilo TikFinity)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _styleBtn('Azul Néon', 'neon', const Color(0xFF1E78FF))),
                  const SizedBox(width: 8),
                  Expanded(child: _styleBtn('Ouro Imperial', 'gold', const Color(0xFFF59E0B))),
                  const SizedBox(width: 8),
                  Expanded(child: _styleBtn('Minimalista', 'minimal', Colors.white24)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _studioCardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💎 TOP PRESENTES (Moedas × Qtd)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 10),
              if (widget.topGifts.isEmpty)
                const Text('Ainda sem presentes nesta live.', style: TextStyle(color: Colors.white54))
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
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _studioCardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('❤️ TOP LIKES (1 Toque = 1 Ponto)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF43F5E))),
              const SizedBox(height: 10),
              if (widget.topLikes.isEmpty)
                const Text('Ainda sem likes nesta live.', style: TextStyle(color: Colors.white54))
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
    );
  }

  Widget _styleBtn(String label, String id, Color color) {
    final active = _selectedStyle == id;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? color : const Color(0xFF050B1E),
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onPressed: () => _applyStyle(id),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
    );
  }
}
class InteractionScreen extends StatefulWidget {
  final IO.Socket socket;
  final String roomName;

  const InteractionScreen({super.key, required this.socket, required this.roomName});

  @override
  State<InteractionScreen> createState() => _InteractionScreenState();
}

class _InteractionScreenState extends State<InteractionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _wheelCtrl;
  double _currentAngle = 0;
  String _lastWinner = 'Toca em Girar!';
  String _wheelTheme = 'neon';
  bool _chatJoinActive = false;

  final TextEditingController _optionCtrl = TextEditingController();
  final TextEditingController _pollQuestionCtrl = TextEditingController(text: 'Jogo a próxima partida de sniper?');
  bool _pollActive = false;

  final List<String> _options = [
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
  }

  @override
  void dispose() {
    _wheelCtrl.dispose();
    _optionCtrl.dispose();
    _pollQuestionCtrl.dispose();
    super.dispose();
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _studioCardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('📊 Votação Ao Vivo pelo Chat', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 15)),
                  Switch(
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF1E78FF),
                    value: _pollActive,
                    onChanged: (v) {
                      setState(() => _pollActive = v);
                      if (cleanRoom.isNotEmpty) {
                        widget.socket.emit('update_poll', {
                          'room': cleanRoom,
                          'poll': {
                            'active': v,
                            'question': _pollQuestionCtrl.text.trim(),
                            'opt1Label': 'SIM (!sim)',
                            'opt2Label': 'NÃO (!nao)',
                            'opt1Key': '!sim',
                            'opt2Key': '!nao',
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              const Text('O chat vota escrevendo !sim ou !nao e as barras sobem na tela:', style: TextStyle(fontSize: 12, color: Colors.white60)),
              const SizedBox(height: 8),
              TextField(controller: _pollQuestionCtrl, decoration: const InputDecoration(labelText: 'Pergunta para a Live')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
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
                      DropdownMenuItem(value: 'neon', child: Text('Tema Néon')),
                      DropdownMenuItem(value: 'fire', child: Text('Tema Fogo')),
                      DropdownMenuItem(value: 'toxic', child: Text('Tema Tóxico')),
                    ],
                    onChanged: (v) => setState(() => _wheelTheme = v ?? 'neon'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Transform.rotate(
                angle: _currentAngle,
                child: Container(
                  width: 155,
                  height: 155,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: _wheelColors()),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Center(child: Icon(Icons.casino, size: 48, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              Text(_lastWinner, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                  onPressed: _spinWheel,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('GIRAR ROLETA (App + Tela)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sorteio do Chat (!entrar)', style: TextStyle(fontSize: 13)),
                subtitle: const Text('Quem escrever !entrar no chat entra na roleta', style: TextStyle(fontSize: 11, color: Colors.white54)),
                value: _chatJoinActive,
                onChanged: (v) {
                  setState(() => _chatJoinActive = v);
                  if (cleanRoom.isNotEmpty) {
                    widget.socket.emit('toggle_chat_wheel_join', {'room': cleanRoom, 'open': v, 'keyword': '!entrar'});
                  }
                },
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
      ],
    );
  }
}

class OverlayStudioScreen extends StatelessWidget {
  final IO.Socket socket;
  final String serverUrl;
  final String roomName;

  const OverlayStudioScreen({super.key, required this.socket, required this.serverUrl, required this.roomName});

  @override
  Widget build(BuildContext context) {
    final cleanRoom = (roomName.isEmpty ? 'teu_canal' : roomName).toLowerCase().replaceAll('@', '');
    final studioUrl = '$serverUrl/overlay/$cleanRoom';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _studioCardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔗 Link Único para OBS / TikTok Live Studio / Streamlabs', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 8),
              SelectableText(studioUrl, style: const TextStyle(fontSize: 12, color: Colors.cyanAccent)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: studioUrl));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link do Overlay copiado!')));
                  },
                  icon: const Icon(Icons.copy, color: Colors.white),
                  label: const Text('Copiar Link de Navegador', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('📦 Biblioteca Gratuita de Overlays & Cenas Prontas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...DefaultMediaLibrary.overlayPresets.map((preset) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: _studioCardDeco(),
              child: ListTile(
                leading: const Icon(Icons.layers, color: Color(0xFF38BDF8), size: 30),
                title: Text(preset['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(preset['desc']!, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF122B6B)),
                  onPressed: () {
                    if (roomName.isNotEmpty) {
                      socket.emit('remote_command', {'room': cleanRoom, 'command': 'scene', 'payload': preset['scene']});
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Overlay "${preset['name']}" ativado!')));
                  },
                  child: const Text('Ativar', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            )),
      ],
    );
  }
}
