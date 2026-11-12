import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:file_picker/file_picker.dart';

class PodiumAndWheelScreen extends StatefulWidget {
  final IO.Socket socket;
  final String roomName;
  final List<Map<String, dynamic>> topGifts;
  final List<Map<String, dynamic>> topLikes;

  const PodiumAndWheelScreen({
    super.key,
    required this.socket,
    required this.roomName,
    required this.topGifts,
    required this.topLikes,
  });

  @override
  State<PodiumAndWheelScreen> createState() => _PodiumAndWheelScreenState();
}

class _PodiumAndWheelScreenState extends State<PodiumAndWheelScreen> with SingleTickerProviderStateMixin {
  late AnimationController _wheelCtrl;
  double _currentAngle = 0;
  String _lastWinner = 'Toca em Girar!';
  final TextEditingController _optionCtrl = TextEditingController();
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
    super.dispose();
  }

  void _spinWheel() {
    if (_options.isEmpty) return;
    final rnd = Random();
    final extraSpins = (4 + rnd.nextInt(4)) * 2 * pi;
    final targetOffset = rnd.nextDouble() * 2 * pi;
    final start = _currentAngle;
    final end = start + extraSpins + targetOffset;

    final anim = Tween<double>(begin: start, end: end).animate(
      CurvedAnimation(parent: _wheelCtrl, curve: Curves.easeOutCubic),
    );

    anim.addListener(() {
      setState(() => _currentAngle = anim.value);
    });

    _wheelCtrl.forward(from: 0).then((_) {
      final winner = _options[rnd.nextInt(_options.length)];
      setState(() => _lastWinner = '🎉 $winner');
      if (widget.roomName.isNotEmpty) {
        widget.socket.emit('remote_command', {
          'room': widget.roomName,
          'command': 'wheel',
          'payload': _options,
        });
      }
    });
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E429F), width: 1.2),
      );

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF38BDF8),
            labelColor: Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white54,
            tabs: [Tab(text: '🎡 Roleta Interativa'), Tab(text: '🏆 Pódio Oficial')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: _cardDeco(),
                      child: Column(
                        children: [
                          Transform.rotate(
                            angle: _currentAngle,
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const SweepGradient(
                                  colors: [Color(0xFF1E78FF), Color(0xFF38BDF8), Color(0xFF6366F1), Color(0xFF0EA5E9), Color(0xFF1E78FF)],
                                ),
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [BoxShadow(color: const Color(0xFF38BDF8).withOpacity(0.5), blurRadius: 20)],
                              ),
                              child: const Center(
                                child: Icon(Icons.casino, size: 54, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(_lastWinner, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                              onPressed: _spinWheel,
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              label: const Text('GIRAR ROLETA (App + Live)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: _cardDeco(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Opções da Roleta:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _optionCtrl,
                                  decoration: const InputDecoration(hintText: 'Novo desafio ou prémio...', isDense: true),
                                ),
                              ),
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
                            children: _options
                                .map((o) => Chip(
                                      label: Text(o, style: const TextStyle(fontSize: 12)),
                                      onDeleted: () => setState(() => _options.remove(o)),
                                    ))
                                .toList(),
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
                      decoration: _cardDeco(),
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
                      decoration: _cardDeco(),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StudioAndDonationsScreen extends StatefulWidget {
  final IO.Socket socket;
  final String serverUrl;
  final String roomName;

  const StudioAndDonationsScreen({
    super.key,
    required this.socket,
    required this.serverUrl,
    required this.roomName,
  });

  @override
  State<StudioAndDonationsScreen> createState() => _StudioAndDonationsScreenState();
}

class _StudioAndDonationsScreenState extends State<StudioAndDonationsScreen> {
  final TextEditingController _goalTitleCtrl = TextEditingController(text: 'Meta de Likes da Live');
  final TextEditingController _goalTargetCtrl = TextEditingController(text: '5000');
  final TextEditingController _mbwayCtrl = TextEditingController();
  final TextEditingController _pixCtrl = TextEditingController();
  String _donationImageBase64OrUrl = 'https://giphy.com';
  String _selectedFileLabel = 'Imagem padrão selecionada';

  Future<void> _pickLocalDonationImage() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res != null && res.files.single.path != null) {
      final bytes = await File(res.files.single.path!).readAsBytes();
      final ext = (res.files.single.extension ?? 'png').toLowerCase();
      final mime = ext == 'gif' ? 'image/gif' : 'image/png';
      setState(() {
        _donationImageBase64OrUrl = 'data:$mime;base64,${base64Encode(bytes)}';
        _selectedFileLabel = res.files.single.name;
      });
    }
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E429F), width: 1.2),
      );

  @override
  Widget build(BuildContext context) {
    final cleanRoom = (widget.roomName.isEmpty ? 'teu_canal' : widget.roomName).toLowerCase().replaceAll('@', '');
    final studioUrl = '${widget.serverUrl}/overlay/$cleanRoom';
    final donateUrl = '${widget.serverUrl}/doar/$cleanRoom';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎬 Estúdio de Cenas (OBS / Live Studio / Streamlabs)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _sceneBtn('Início de Live', 'starting'),
                  _sceneBtn('Moldura Câmara', 'cam_frame'),
                  _sceneBtn('Em Jogo (Limpo)', 'live'),
                  _sceneBtn('Pausa (BRB)', 'brb'),
                  _sceneBtn('Fim de Live', 'ending'),
                ],
              ),
              const SizedBox(height: 12),
              SelectableText(studioUrl, style: const TextStyle(fontSize: 12, color: Colors.cyanAccent)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: studioUrl));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link do Estúdio copiado!')));
                  },
                  icon: const Icon(Icons.copy, color: Colors.white),
                  label: const Text('Copiar Link do Estúdio', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎯 Barra de Meta Personalizada', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 8),
              TextField(controller: _goalTitleCtrl, decoration: const InputDecoration(labelText: 'Texto da Meta na Live')),
              const SizedBox(height: 8),
              TextField(controller: _goalTargetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Objetivo (ex: 5000)')),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                  onPressed: () {
                    widget.socket.emit('update_goal', {
                      'room': cleanRoom,
                      'goal': {'title': _goalTitleCtrl.text.trim(), 'target': int.tryParse(_goalTargetCtrl.text.trim()) ?? 5000}
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meta atualizada na live!')));
                  },
                  child: const Text('Atualizar Meta na Live', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💸 Doações Diretas (PNG / GIF Local + MB Way / PIX)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickLocalDonationImage,
                icon: const Icon(Icons.image),
                label: Text('Escolher PNG / GIF da Galeria ($_selectedFileLabel)'),
              ),
              const SizedBox(height: 8),
              TextField(controller: _mbwayCtrl, decoration: const InputDecoration(labelText: 'Número MB Way')),
              const SizedBox(height: 8),
              TextField(controller: _pixCtrl, decoration: const InputDecoration(labelText: 'Chave PIX')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                      onPressed: () {
                        widget.socket.emit('update_donation_config', {
                          'room': cleanRoom,
                          'config': {
                            'mbway': _mbwayCtrl.text.trim(),
                            'pix': _pixCtrl.text.trim(),
                            'imageData': _donationImageBase64OrUrl,
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cartão de doações guardado!')));
                      },
                      child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: donateUrl));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link de Doação copiado!')));
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

  Widget _sceneBtn(String label, String sceneId) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF122B6B)),
      onPressed: () {
        final clean = widget.roomName.toLowerCase().replaceAll('@', '');
        if (clean.isNotEmpty) {
          widget.socket.emit('remote_command', {'room': clean, 'command': 'scene', 'payload': sceneId});
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cena "$label" enviada!')));
      },
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}
