import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:file_picker/file_picker.dart';
import 'app_data.dart';

class StreamDeckScreen extends StatefulWidget {
  final IO.Socket socket;
  final String activeRoom;
  final String? generatedCode;
  final String? pairedRoom;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final VoidCallback onGenerateCode;
  final Function(String) onJoinWithCode;
  final Function(String, dynamic) onSendCommand;
  final VoidCallback onMinimizeDeck;

  const StreamDeckScreen({
    super.key,
    required this.socket,
    required this.activeRoom,
    required this.generatedCode,
    required this.pairedRoom,
    required this.isMuted,
    required this.onToggleMute,
    required this.onGenerateCode,
    required this.onJoinWithCode,
    required this.onSendCommand,
    required this.onMinimizeDeck,
  });

  @override
  State<StreamDeckScreen> createState() => _StreamDeckScreenState();
}

class _StreamDeckScreenState extends State<StreamDeckScreen> {
  final TextEditingController _codeInputCtrl = TextEditingController();
  int _cols = 4;
  int _rows = 2;
  String _selectedSoftware = 'OBS Studio';

  final Map<String, IconData> _iconCatalog = {
    'mute': Icons.volume_off_rounded,
    'mic': Icons.mic_off_rounded,
    'scene_live': Icons.videocam_rounded,
    'scene_chat': Icons.chat_bubble_rounded,
    'record': Icons.fiber_manual_record_rounded,
    'stream': Icons.podcasts_rounded,
    'alert': Icons.notifications_active_rounded,
    'tts': Icons.record_voice_over_rounded,
    'wheel': Icons.casino_rounded,
    'clap': Icons.celebration_rounded,
    'horn': Icons.campaign_rounded,
    'custom': Icons.bolt_rounded,
  };

  final List<Color> _colorCatalog = [
    const Color(0xFFEF4444),
    const Color(0xFF38BDF8),
    const Color(0xFF1E78FF),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF64748B),
  ];

  final Map<String, String> _realTasksCatalog = {
    'toggle_mute': 'Cortar / Ativar Todos os Sons (Pânico)',
    'obs_mic_mute': 'Mutar / Desmutar Microfone (OBS / Studio)',
    'obs_scene_live': 'Mudar para Cena Principal (Jogo / Live)',
    'obs_scene_chat': 'Mudar para Cena Just Chatting / Câmara',
    'obs_scene_brb': 'Mudar para Cena Já Volto (BRB)',
    'obs_toggle_record': 'Iniciar / Parar Gravação (OBS / Streamlabs)',
    'obs_toggle_stream': 'Iniciar / Parar Transmissão Ao Vivo',
    'test_alert': 'Disparar Alerta Visual + Som na Live',
    'tts_read_last': 'Ler Último Comentário do Chat por Voz',
    'wheel_spin': 'Girar Roleta Interativa na Tela',
    'sound_clap': 'Tocar Efeito Sonoro: Aplausos',
    'sound_horn': 'Tocar Efeito Sonoro: Buzina Épica',
  };

  late List<Map<String, dynamic>> _buttons;

  @override
  void initState() {
    super.initState();
    _buttons = [
      {'label': 'PÂNICO SOM', 'iconKey': 'mute', 'colorVal': 0xFFEF4444, 'cmd': 'toggle_mute', 'val': null, 'imagePath': null},
      {'label': 'MUTAR MIC', 'iconKey': 'mic', 'colorVal': 0xFFF59E0B, 'cmd': 'obs_mic_mute', 'val': 'mic', 'imagePath': null},
      {'label': 'CENA LIVE', 'iconKey': 'scene_live', 'colorVal': 0xFF38BDF8, 'cmd': 'obs_scene_live', 'val': 'live', 'imagePath': null},
      {'label': 'CENA CHAT', 'iconKey': 'scene_chat', 'colorVal': 0xFF1E78FF, 'cmd': 'obs_scene_chat', 'val': 'chat', 'imagePath': null},
      {'label': 'GRAVAR REC', 'iconKey': 'record', 'colorVal': 0xFFEF4444, 'cmd': 'obs_toggle_record', 'val': 'record', 'imagePath': null},
      {'label': 'DISPARAR ALERTA', 'iconKey': 'alert', 'colorVal': 0xFF8B5CF6, 'cmd': 'test_alert', 'val': null, 'imagePath': null},
      {'label': 'LER CHAT TTS', 'iconKey': 'tts', 'colorVal': 0xFF10B981, 'cmd': 'tts_read_last', 'val': null, 'imagePath': null},
      {'label': 'GIRAR ROLETA', 'iconKey': 'wheel', 'colorVal': 0xFFEC4899, 'cmd': 'wheel_spin', 'val': null, 'imagePath': null},
      ...List.generate(
        8,
        (i) => {'label': 'TECLA ${i + 9}', 'iconKey': 'custom', 'colorVal': 0xFF334155, 'cmd': 'none', 'val': null, 'imagePath': null},
      ),
    ];
  }

  void _editKeyModal(int index) {
    final btn = _buttons[index];
    final labelCtrl = TextEditingController(text: btn['label']);
    String selectedIcon = btn['iconKey'] ?? 'custom';
    int selectedColor = btn['colorVal'] ?? 0xFF38BDF8;
    String selectedTask = _realTasksCatalog.containsKey(btn['cmd']) ? btn['cmd'] : 'obs_scene_live';
    String? customImg = btn['imagePath'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF070C1B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(ctx).viewInsets.bottom + 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personalizar Tecla #${index + 1} ($_selectedSoftware)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                const SizedBox(height: 12),
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(labelText: 'Nome da Tecla', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 12),
                const Text('Tarefa Real a Executar:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedTask,
                  dropdownColor: const Color(0xFF0B1636),
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: _realTasksCatalog.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 12.5))))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedTask = v ?? 'obs_scene_live'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF122B6B)),
                      onPressed: () async {
                        final res = await FilePicker.platform.pickFiles(type: FileType.image);
                        if (res != null && res.files.single.path != null) {
                          setModalState(() => customImg = res.files.single.path);
                        }
                      },
                      icon: const Icon(Icons.image, size: 17, color: Colors.white),
                      label: const Text('Ícone PNG/Foto', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    if (customImg != null) ...[
                      const SizedBox(width: 8),
                      TextButton(onPressed: () => setModalState(() => customImg = null), child: const Text('Remover', style: TextStyle(color: Colors.redAccent))),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _iconCatalog.entries.map((entry) {
                    final sel = selectedIcon == entry.key && customImg == null;
                    return InkWell(
                      onTap: () => setModalState(() {
                        selectedIcon = entry.key;
                        customImg = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: sel ? Color(selectedColor) : const Color(0xFF0E1D47),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? Colors.white : Colors.white12),
                        ),
                        child: Icon(entry.value, size: 20, color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: _colorCatalog.map((c) {
                    final sel = selectedColor == c.value;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = c.value),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 2.5)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: () {
                      setState(() {
                        _buttons[index] = {
                          'label': labelCtrl.text.trim().isEmpty ? 'TECLA ${index + 1}' : labelCtrl.text.trim().toUpperCase(),
                          'iconKey': selectedIcon,
                          'colorVal': selectedColor,
                          'cmd': selectedTask,
                          'val': selectedTask,
                          'imagePath': customImg,
                        };
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Guardar Tarefa da Tecla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _executeKeyAction(Map<String, dynamic> b) {
    HapticFeedback.mediumImpact();
    final cmd = b['cmd'] as String;
    if (cmd == 'toggle_mute') {
      widget.onToggleMute();
    } else if (cmd != 'none') {
      widget.onSendCommand(cmd, {'software': _selectedSoftware, 'action': cmd, 'label': b['label']});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text('⚡ Gatilho enviado para $_selectedSoftware: ${b['label']}'),
        ),
      );
    }
  }

  Widget _buildSingleDeckKey(int index, Map<String, dynamic> b) {
    final isMuteBtn = b['cmd'] == 'toggle_mute';
    final Color accent = isMuteBtn ? (widget.isMuted ? Colors.redAccent : Colors.greenAccent) : Color(b['colorVal'] as int);
    final IconData iconData = isMuteBtn ? (widget.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded) : (_iconCatalog[b['iconKey']] ?? Icons.bolt_rounded);
    final String? imgPath = b['imagePath'];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15203B), Color(0xFF0A0F1D)],
        ),
        border: Border.all(color: accent.withOpacity(0.55), width: 1.5),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.22), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imgPath != null)
            ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(imgPath), width: 34, height: 34, fit: BoxFit.cover))
          else
            Icon(iconData, size: _rows == 2 ? 32 : 24, color: accent),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              isMuteBtn ? (widget.isMuted ? 'CORTADO' : 'SOM ATIVO') : (b['label'] as String),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: _rows == 2 ? 11 : 10, letterSpacing: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalButtons = _cols * _rows;
    final visibleButtons = _buttons.take(totalButtons).toList();
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF040711),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF090F22), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08)))),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF38BDF8)), onPressed: widget.onMinimizeDeck),
                  const Text('STREAM DECK PRO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _selectedSoftware,
                    dropdownColor: const Color(0xFF0B1636),
                    underline: const SizedBox(),
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: 'OBS Studio', child: Text('OBS Studio')),
                      DropdownMenuItem(value: 'Streamlabs', child: Text('Streamlabs')),
                      DropdownMenuItem(value: 'TikTok Live Studio', child: Text('TikTok Live Studio')),
                    ],
                    onChanged: (v) => setState(() => _selectedSoftware = v ?? 'OBS Studio'),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: '${_cols}x$_rows',
                    dropdownColor: const Color(0xFF0B1636),
                    underline: const SizedBox(),
                    style: const TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: '4x2', child: Text('4×2')),
                      DropdownMenuItem(value: '4x3', child: Text('4×3')),
                      DropdownMenuItem(value: '4x4', child: Text('4×4')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        final parts = v.split('x');
                        setState(() {
                          _cols = int.parse(parts.first);
                          _rows = int.parse(parts.last);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Toca para executar · Pressiona longo para personalizar · Arrasta para trocar de lugar',
                style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.5)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isLandscape ? 20 : 12, vertical: 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 10.0;
                    final tileW = (constraints.maxWidth - (spacing * (_cols - 1))) / _cols;
                    final tileH = (constraints.maxHeight - (spacing * (_rows - 1))) / _rows;

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visibleButtons.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _cols,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: tileW / tileH,
                      ),
                      itemBuilder: (ctx, index) {
                        final b = visibleButtons[index];
                        return DragTarget<int>(
                          onAcceptWithDetails: (details) {
                            final fromIdx = details.data;
                            if (fromIdx != index) {
                              setState(() {
                                final temp = _buttons[fromIdx];
                                _buttons[fromIdx] = _buttons[index];
                                _buttons[index] = temp;
                              });
                            }
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Draggable<int>(
                              data: index,
                              feedback: Material(
                                color: Colors.transparent,
                                child: SizedBox(width: tileW, height: tileH, child: _buildSingleDeckKey(index, b)),
                              ),
                              childWhenDragging: Opacity(opacity: 0.3, child: _buildSingleDeckKey(index, b)),
                              child: GestureDetector(
                                onTap: () => _executeKeyAction(b),
                                onLongPress: () => _editKeyModal(index),
                                child: _buildSingleDeckKey(index, b),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityGlobeScreen extends StatefulWidget {
  final String serverUrl;
  const CommunityGlobeScreen({super.key, required this.serverUrl});

  @override
  State<CommunityGlobeScreen> createState() => _CommunityGlobeScreenState();
}

class _CommunityGlobeScreenState extends State<CommunityGlobeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _globeCtrl;
  List<dynamic> _liveStreamers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _globeCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 22))..repeat();
    _fetchLiveStreamers();
  }

  @override
  void dispose() {
    _globeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveStreamers() async {
    try {
      final res = await http.get(Uri.parse('${widget.serverUrl}/community/live'));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _liveStreamers = data['streamers'] ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 320,
          decoration: BoxDecoration(
            gradient: const RadialGradient(colors: [Color(0xFF132E73), Color(0xFF030712)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF1E78FF), width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _globeCtrl,
                builder: (_, __) => CustomPaint(
                  size: const Size(265, 265),
                  painter: _WorldContinentsGlobePainter(_globeCtrl.value * 2 * pi),
                ),
              ),
              const Positioned(
                bottom: 12,
                child: Text('🌍 COMUNIDADE MUNDIAL HELL LIVE', style: TextStyle(fontSize: 11.5, letterSpacing: 2, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('🔴 Criadores em Direto Agora', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF38BDF8)), onPressed: _fetchLiveStreamers),
          ],
        ),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_liveStreamers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0B1636), borderRadius: BorderRadius.circular(12)),
            child: const Text('Nenhum criador em direto neste segundo. Inicia a tua transmissão para apareceres no globo para toda a comunidade!', style: TextStyle(color: Colors.white70)),
          )
        else
          ..._liveStreamers.map((s) => Card(
                color: const Color(0xFF0B1636),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF1E78FF), child: Icon(Icons.live_tv, color: Colors.white)),
                  title: Text(s['user'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Ao vivo no ${s['platform']}'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                    onPressed: () async {
                      final uri = Uri.tryParse(s['url'] ?? '');
                      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: const Text('Assistir', style: TextStyle(color: Colors.white)),
                  ),
                ),
              )),
      ],
    );
  }
}

class _WorldContinentsGlobePainter extends CustomPainter {
  final double rotation;
  _WorldContinentsGlobePainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Halo atmosférico externo estilo NASA
    final atmoGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF38BDF8).withOpacity(0.45),
          const Color(0xFF1E78FF).withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.18));
    canvas.drawCircle(center, radius * 1.18, atmoGlow);

    // Esfera Oceânica 3D
    final oceanPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.4, -0.4),
        radius: 1.1,
        colors: [Color(0xFF1D4ED8), Color(0xFF0A1D56), Color(0xFF020617)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, oceanPaint);

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    // Grelha orbital de latitude e longitude
    final gridPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int lat = -60; lat <= 60; lat += 30) {
      final y = center.dy + sin(lat * pi / 180) * radius;
      final w = cos(lat * pi / 180) * radius;
      canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, y), width: w * 2, height: w * 0.25), gridPaint);
    }
    for (int lon = 0; lon < 6; lon++) {
      final ang = rotation + (lon * pi / 3);
      final w = cos(ang).abs() * radius * 2;
      canvas.drawOval(Rect.fromCenter(center: center, width: w, height: radius * 2), gridPaint);
    }

    // Continentes iluminados em rotação contínua
    final landFill = Paint()..color = const Color(0xFF38BDF8).withOpacity(0.35)..style = PaintingStyle.fill;
    final landStroke = Paint()..color = const Color(0xFFBAE6FD).withOpacity(0.85)..style = PaintingStyle.stroke..strokeWidth = 1.1;

    final mapWidth = radius * 2.0;
    final shift = (rotation / (2 * pi)) * mapWidth;
    for (int rep = -1; rep <= 1; rep++) {
      final ox = center.dx - radius + shift + (rep * mapWidth);
      final continents = [
        Path()..moveTo(ox + radius * 0.14, center.dy - radius * 0.54)..lineTo(ox + radius * 0.48, center.dy - radius * 0.58)..lineTo(ox + radius * 0.40, center.dy - radius * 0.16)..lineTo(ox + radius * 0.26, center.dy - radius * 0.12)..close(),
        Path()..moveTo(ox + radius * 0.36, center.dy - radius * 0.04)..lineTo(ox + radius * 0.54, center.dy + radius * 0.08)..lineTo(ox + radius * 0.44, center.dy + radius * 0.58)..lineTo(ox + radius * 0.34, center.dy + radius * 0.35)..close(),
        Path()..moveTo(ox + radius * 0.86, center.dy - radius * 0.52)..lineTo(ox + radius * 1.18, center.dy - radius * 0.56)..lineTo(ox + radius * 1.15, center.dy - radius * 0.25)..lineTo(ox + radius * 0.85, center.dy - radius * 0.24)..close(),
        Path()..moveTo(ox + radius * 0.86, center.dy - radius * 0.18)..lineTo(ox + radius * 1.16, center.dy - radius * 0.14)..lineTo(ox + radius * 1.08, center.dy + radius * 0.48)..lineTo(ox + radius * 0.92, center.dy + radius * 0.32)..close(),
        Path()..moveTo(ox + radius * 1.22, center.dy - radius * 0.55)..lineTo(ox + radius * 1.78, center.dy - radius * 0.48)..lineTo(ox + radius * 1.72, center.dy + radius * 0.05)..lineTo(ox + radius * 1.25, center.dy - radius * 0.05)..close(),
        Path()..moveTo(ox + radius * 1.52, center.dy + radius * 0.18)..lineTo(ox + radius * 1.78, center.dy + radius * 0.20)..lineTo(ox + radius * 1.74, center.dy + radius * 0.45)..lineTo(ox + radius * 1.50, center.dy + radius * 0.40)..close(),
      ];
      for (final p in continents) {
        canvas.drawPath(p, landFill);
        canvas.drawPath(p, landStroke);
      }
    }

    // Sombra esférica 3D
    final shadow3D = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 1.05,
        colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, shadow3D);

    // Pontos brilhantes pulsantes (utilizadores ativos pelo mundo)
    final pulse = 0.65 + 0.35 * sin(rotation * 4);
    final nodeCore = Paint()..color = const Color(0xFF4ADE80);
    final nodeHalo = Paint()..color = const Color(0xFF4ADE80).withOpacity(0.45 * pulse);
    final cityNodes = [
      Offset(center.dx + cos(rotation) * 58, center.dy - 36),
      Offset(center.dx - sin(rotation) * 68, center.dy + 28),
      Offset(center.dx + cos(rotation + 1.8) * 48, center.dy + 14),
      Offset(center.dx - cos(rotation + 0.9) * 52, center.dy - 48),
      Offset(center.dx + sin(rotation + 2.5) * 72, center.dy - 8),
      Offset(center.dx - sin(rotation + 1.2) * 38, center.dy + 56),
    ];
    for (final pt in cityNodes) {
      canvas.drawCircle(pt, 8 * pulse, nodeHalo);
      canvas.drawCircle(pt, 3.2, nodeCore);
    }
    canvas.restore();

    // Borda atmosférica brillante
    final rimPaint = Paint()
      ..color = const Color(0xFF7DD3FC).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _WorldContinentsGlobePainter oldDelegate) => true;
}

class AboutHellLiveScreen extends StatelessWidget {
  const AboutHellLiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Image.asset('icon.png', height: 105, errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, size: 85, color: Color(0xFF38BDF8))),
        ),
        const SizedBox(height: 14),
        const Center(child: Text('HELL Live', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 2))),
        const Center(child: Text('A tua live, no teu comando. · LIVE · PLAY · CONNECT', style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: Color(0xFF38BDF8)))),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF1E78FF)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Feito a pensar em ti', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              SizedBox(height: 12),
              Text(
                'Sabemos exatamente o que custa começar uma transmissão do zero. Muitas vezes tens o talento, a energia e a vontade de entreter, mas esbarras em ferramentas caras, pesadas ou cheias de bloqueios logo no primeiro dia.\n\nO HELL Live nasceu para mudar isso. Este projeto foi criado a pensar em ti — quer jogues num telemóvel modesto no quarto ou num estúdio completo no PC.\n\nAqui, tu fazes parte da família: cada funcionalidade foi desenhada para aproximar-te do teu chat, dar voz aos teus seguidores e tornar cada live inesquecível sem te cobrar pelo essencial.\n\nObrigado por fazeres parte desta comunidade. Esta casa é tua!',
                style: TextStyle(fontSize: 14.5, height: 1.55, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

