import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
  int _cols = 4;
  int _rows = 2;
  String _selectedSoftware = 'OBS Studio';
  String _deckWallpaper = 'h_icon';

  final Map<String, IconData> _iconCatalog = {
    'mute': Icons.volume_off_rounded,
    'mic': Icons.mic_off_rounded,
    'scene_live': Icons.videocam_rounded,
    'scene_chat': Icons.chat_bubble_rounded,
    'music_play': Icons.music_note_rounded,
    'music_next': Icons.skip_next_rounded,
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
    'obs_mic_mute': 'Silenciar / Ativar Microfone (OBS / Studio)',
    'obs_scene_live': 'Mudar para Cena Principal (Jogo / Live)',
    'obs_scene_chat': 'Mudar para Cena Just Chatting / Câmara',
    'music_toggle': 'Tocar / Pausar Música de Fundo',
    'music_next': 'Próxima Faixa da Playlist',
    'test_alert': 'Disparar Alerta Visual + Som na Live',
    'tts_read_last': 'Ler Último Comentário do Chat por Voz',
    'wheel_spin': 'Girar Roleta 3D Interativa',
    'sound_clap': 'Efeito Sonoro: Aplausos',
    'sound_horn': 'Efeito Sonoro: Buzina Épica',
  };

  late List<Map<String, dynamic>> _buttons;

  @override
  void initState() {
    super.initState();
    _buttons = [
      {'label': 'PÂNICO SOM', 'iconKey': 'mute', 'colorVal': 0xFFEF4444, 'cmd': 'toggle_mute', 'imagePath': null},
      {'label': 'SILENCIAR MIC', 'iconKey': 'mic', 'colorVal': 0xFFF59E0B, 'cmd': 'obs_mic_mute', 'imagePath': null},
      {'label': 'CENA LIVE', 'iconKey': 'scene_live', 'colorVal': 0xFF38BDF8, 'cmd': 'obs_scene_live', 'imagePath': null},
      {'label': 'MÚSICA PLAY', 'iconKey': 'music_play', 'colorVal': 0xFF10B981, 'cmd': 'music_toggle', 'imagePath': null},
      {'label': 'PRÓX. MÚSICA', 'iconKey': 'music_next', 'colorVal': 0xFF1E78FF, 'cmd': 'music_next', 'imagePath': null},
      {'label': 'ALERTA LIVE', 'iconKey': 'alert', 'colorVal': 0xFF8B5CF6, 'cmd': 'test_alert', 'imagePath': null},
      {'label': 'LER CHAT TTS', 'iconKey': 'tts', 'colorVal': 0xFF38BDF8, 'cmd': 'tts_read_last', 'imagePath': null},
      {'label': 'GIRAR ROLETA', 'iconKey': 'wheel', 'colorVal': 0xFFEC4899, 'cmd': 'wheel_spin', 'imagePath': null},
      ...List.generate(
        8,
        (i) => {'label': 'TECLA ${i + 9}', 'iconKey': 'custom', 'colorVal': 0xFF38BDF8, 'cmd': 'none', 'imagePath': null},
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
                TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Nome da Tecla', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 12),
                const Text('Tarefa Real a Executar:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedTask,
                  dropdownColor: const Color(0xFF0B1636),
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: _realTasksCatalog.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 12.5)))).toList(),
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

  void _executeKeyAction(Map<String, dynamic> b, {bool isOfflinePreview = false}) {
    HapticFeedback.mediumImpact();
    final cmd = b['cmd'] as String;
    if (cmd == 'toggle_mute') {
      widget.onToggleMute();
      return;
    }
    if (cmd != 'none') {
      widget.onSendCommand(cmd, {'software': _selectedSoftware, 'action': cmd, 'label': b['label']});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 900),
          content: Text(isOfflinePreview ? '👁️ Pré-visualização Offline: ${b['label']} ($_selectedSoftware)' : '⚡ Executado em $_selectedSoftware: ${b['label']}'),
        ),
      );
    }
  }

  Widget _buildSingleGlassDeckKey(int index, Map<String, dynamic> b) {
    final isMuteBtn = b['cmd'] == 'toggle_mute';
    final Color accent = isMuteBtn ? (widget.isMuted ? Colors.redAccent : Colors.greenAccent) : Color(b['colorVal'] as int);
    final IconData iconData = isMuteBtn ? (widget.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded) : (_iconCatalog[b['iconKey']] ?? Icons.bolt_rounded);
    final String? imgPath = b['imagePath'];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.14), accent.withOpacity(0.16), const Color(0xFF050B1E).withOpacity(0.75)],
        ),
        border: Border.all(color: accent.withOpacity(0.65), width: 1.6),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 10,
            right: 10,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(0.55), Colors.transparent])),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (imgPath != null && File(imgPath).existsSync())
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
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: _rows == 2 ? 11 : 10, letterSpacing: 0.4, color: Colors.white),
                  ),
                ),
              ],
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
      backgroundColor: const Color(0xFF030612),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF090F22), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08)))),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF38BDF8)), onPressed: widget.onMinimizeDeck),
                  const Text('STREAM DECK PRO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12.5)),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _deckWallpaper,
                    dropdownColor: const Color(0xFF0B1636),
                    underline: const SizedBox(),
                    style: const TextStyle(fontSize: 11, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: 'h_icon', child: Text('Fundo: Ícone H')),
                      DropdownMenuItem(value: 'hell_live', child: Text('Fundo: HELL Live')),
                    ],
                    onChanged: (v) => setState(() => _deckWallpaper = v ?? 'h_icon'),
                  ),
                  const SizedBox(width: 6),
                  DropdownButton<String>(
                    value: _selectedSoftware,
                    dropdownColor: const Color(0xFF0B1636),
                    underline: const SizedBox(),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: 'OBS Studio', child: Text('OBS')),
                      DropdownMenuItem(value: 'Streamlabs', child: Text('Streamlabs')),
                      DropdownMenuItem(value: 'TikTok Live Studio', child: Text('TikTok')),
                    ],
                    onChanged: (v) => setState(() => _selectedSoftware = v ?? 'OBS Studio'),
                  ),
                  const SizedBox(width: 6),
                  DropdownButton<String>(
                    value: '${_cols}x$_rows',
                    dropdownColor: const Color(0xFF0B1636),
                    underline: const SizedBox(),
                    style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
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
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IgnorePointer(
                    child: Opacity(
                      opacity: 0.14,
                      child: _deckWallpaper == 'h_icon'
                          ? Image.asset('icon.png', width: 250, height: 250, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, size: 220, color: Color(0xFF38BDF8)))
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('HELL', style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, letterSpacing: 8, color: Colors.white)),
                                Text('LIVE', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 12, color: Color(0xFF38BDF8))),
                              ],
                            ),
                    ),
                  ),
                  Padding(
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
                                    child: SizedBox(width: tileW, height: tileH, child: _buildSingleGlassDeckKey(index, b)),
                                  ),
                                  childWhenDragging: Opacity(opacity: 0.3, child: _buildSingleGlassDeckKey(index, b)),
                                  child: GestureDetector(
                                    onTap: () => _executeKeyAction(b),
                                    onDoubleTap: () => _executeKeyAction(b, isOfflinePreview: true),
                                    onLongPress: () => _editKeyModal(index),
                                    child: _buildSingleGlassDeckKey(index, b),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
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
  double _manualDragOffset = 0.0;

  final List<Map<String, String>> _globalCreators = [
    {'user': '@HellGamer2026', 'country': 'Portugal · Lisboa', 'platform': 'TikTok Live', 'viewers': '1.4K', 'url': 'https://tiktok.com'},
    {'user': '@SofiaStreamPT', 'country': 'Portugal · Porto', 'platform': 'Twitch', 'viewers': '820', 'url': 'https://twitch.tv'},
    {'user': '@KikoArena', 'country': 'Brasil · São Paulo', 'platform': 'Kick', 'viewers': '2.1K', 'url': 'https://kick.com'},
    {'user': '@LukaCyber', 'country': 'Espanha · Madrid', 'platform': 'YouTube Live', 'viewers': '960', 'url': 'https://youtube.com'},
  ];

  @override
  void initState() {
    super.initState();
    _globeCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 26))..repeat();
  }

  @override
  void dispose() {
    _globeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() => _manualDragOffset += details.delta.dx * 0.012);
          },
          child: Container(
            height: 340,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                center: Alignment(-0.2, -0.2),
                radius: 1.1,
                colors: [Color(0xFF0A1D42), Color(0xFF020612), Color(0xFF000208)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.55), width: 1.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _globeCtrl,
                  builder: (_, __) => CustomPaint(
                    size: const Size(275, 275),
                    painter: _NasaEarth3DGlobePainter((_globeCtrl.value * 2 * pi) + _manualDragOffset),
                  ),
                ),
                const Positioned(
                  top: 12,
                  child: Text('🛰️ VISTA ORBITAL EM TEMPO REAL · ARRASTA PARA RODAR', style: TextStyle(fontSize: 10.5, letterSpacing: 1.5, color: Color(0xFF7DD3FC), fontWeight: FontWeight.bold)),
                ),
                const Positioned(
                  bottom: 12,
                  child: Text('🌍 COMUNIDADE GLOBAL HELL LIVE', style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('🔴 Criadores em Direto pelo Mundo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
        const SizedBox(height: 8),
        ..._globalCreators.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E429F)),
              ),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF1E78FF), child: Icon(Icons.public, color: Colors.white)),
                title: Text(s['user']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${s['country']} · ${s['platform']} (${s['viewers']} a assistir)', style: const TextStyle(fontSize: 11.5, color: Colors.white70)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                  onPressed: () async {
                    final uri = Uri.tryParse(s['url']!);
                    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: const Text('Assistir', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            )),
      ],
    );
  }
}

class _NasaEarth3DGlobePainter extends CustomPainter {
  final double rotation;
  _NasaEarth3DGlobePainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final starPaint = Paint()..color = Colors.white.withOpacity(0.65);
    for (int i = 0; i < 28; i++) {
      final sx = ((i * 73) % size.width.toInt()).toDouble();
      final sy = ((i * 41) % size.height.toInt()).toDouble();
      canvas.drawCircle(Offset(sx, sy), (i % 2 == 0) ? 1.3 : 0.8, starPaint);
    }

    final atmoGlow = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF60A5FA).withOpacity(0.55), const Color(0xFF2563EB).withOpacity(0.22), Colors.transparent],
        stops: const [0.78, 0.92, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.18));
    canvas.drawCircle(center, radius * 1.18, atmoGlow);

    final oceanPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.45, -0.45),
        radius: 1.15,
        colors: [Color(0xFF1E40AF), Color(0xFF0F296E), Color(0xFF061236), Color(0xFF020617)],
        stops: [0.0, 0.45, 0.78, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, oceanPaint);

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    final landFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF15803D), Color(0xFF166534), Color(0xFFA16207), Color(0xFF14532D)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    final coastHighlight = Paint()
      ..color = const Color(0xFF86EFAC).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final mapWidth = radius * 2.2;
    final shift = ((rotation % (2 * pi)) / (2 * pi)) * mapWidth;
    for (int rep = -1; rep <= 1; rep++) {
      final ox = center.dx - radius + shift + (rep * mapWidth);
      final continents = [
        Path()..moveTo(ox + radius * 0.12, center.dy - radius * 0.56)..lineTo(ox + radius * 0.52, center.dy - radius * 0.60)..lineTo(ox + radius * 0.42, center.dy - radius * 0.18)..lineTo(ox + radius * 0.25, center.dy - radius * 0.14)..close(),
        Path()..moveTo(ox + radius * 0.36, center.dy - radius * 0.04)..lineTo(ox + radius * 0.56, center.dy + radius * 0.10)..lineTo(ox + radius * 0.45, center.dy + radius * 0.62)..lineTo(ox + radius * 0.34, center.dy + radius * 0.35)..close(),
        Path()..moveTo(ox + radius * 0.86, center.dy - radius * 0.54)..lineTo(ox + radius * 1.22, center.dy - radius * 0.58)..lineTo(ox + radius * 1.18, center.dy - radius * 0.26)..lineTo(ox + radius * 0.85, center.dy - radius * 0.24)..close(),
        Path()..moveTo(ox + radius * 0.86, center.dy - radius * 0.18)..lineTo(ox + radius * 1.20, center.dy - radius * 0.12)..lineTo(ox + radius * 1.10, center.dy + radius * 0.52)..lineTo(ox + radius * 0.92, center.dy + radius * 0.32)..close(),
        Path()..moveTo(ox + radius * 1.24, center.dy - radius * 0.56)..lineTo(ox + radius * 1.88, center.dy - radius * 0.48)..lineTo(ox + radius * 1.80, center.dy + radius * 0.06)..lineTo(ox + radius * 1.26, center.dy - radius * 0.04)..close(),
        Path()..moveTo(ox + radius * 1.56, center.dy + radius * 0.20)..lineTo(ox + radius * 1.84, center.dy + radius * 0.22)..lineTo(ox + radius * 1.78, center.dy + radius * 0.48)..lineTo(ox + radius * 1.52, center.dy + radius * 0.42)..close(),
      ];
      for (final p in continents) {
        canvas.drawPath(p, landFill);
        canvas.drawPath(p, coastHighlight);
      }
    }

    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (int c = 0; c < 5; c++) {
      final cx = center.dx + cos(rotation * 1.25 + c) * (radius * 0.62);
      final cy = center.dy - (radius * 0.45) + (c * radius * 0.22);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 68, height: 14), cloudPaint);
    }

    final nightShadow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.38, -0.38),
        radius: 1.08,
        colors: [Colors.transparent, Colors.black.withOpacity(0.25), Colors.black.withOpacity(0.85)],
        stops: const [0.48, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, nightShadow);

    final pulse = 0.65 + 0.35 * sin(rotation * 4);
    final liveCore = Paint()..color = const Color(0xFFFACC15);
    final liveHalo = Paint()..color = const Color(0xFF38BDF8).withOpacity(0.55 * pulse);
    for (int i = 0; i < 6; i++) {
      final pt = Offset(center.dx + cos(rotation + i) * (45 + i * 6), center.dy + sin(rotation * 1.2 + i) * (35 + i * 5));
      canvas.drawCircle(pt, 7 * pulse, liveHalo);
      canvas.drawCircle(pt, 2.8, liveCore);
    }
    canvas.restore();

    final rim = Paint()..color = const Color(0xFF7DD3FC).withOpacity(0.85)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, rim);
  }

  @override
  bool shouldRepaint(covariant _NasaEarth3DGlobePainter oldDelegate) => true;
}
class MarketplaceState {
  static final List<Map<String, dynamic>> items = [
    {
      'id': 'mp_1',
      'title': 'Pack Overlays Néon Cyber 3D',
      'creator': '@TugaStream',
      'category': 'Overlays 3D',
      'netPrice': 0.0,
      'desc': 'Moldura de câmara + barra de metas transparente para OBS e TikTok Live Studio.',
      'owned': true,
    },
    {
      'id': 'mp_2',
      'title': 'Banner Animado Fogo & Plasma VIP',
      'creator': '@SofiaLive',
      'category': 'Banners Perfil',
      'netPrice': 5.0,
      'desc': 'Banner animado de alta definição compatível com perfil público e overlays.',
      'owned': false,
    },
    {
      'id': 'mp_3',
      'title': 'Pack 15 Sons Épicos + Stickers 3D',
      'creator': '@KikoGamer',
      'category': 'Sons & GIFs',
      'netPrice': 10.0,
      'desc': 'Efeitos sonoros masterizados em MP3 e ícones 3D para alertas de presentes.',
      'owned': false,
    },
  ];
}

class MarketplacePublicScreen extends StatefulWidget {
  const MarketplacePublicScreen({super.key});

  @override
  State<MarketplacePublicScreen> createState() => _MarketplacePublicScreenState();
}

class _MarketplacePublicScreenState extends State<MarketplacePublicScreen> {
  String _filter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final visible = MarketplaceState.items.where((it) {
      if (_filter == 'Grátis') return (it['netPrice'] as double) == 0.0;
      if (_filter == 'PRO') return (it['netPrice'] as double) > 0.0;
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
            border: Border.all(color: const Color(0xFF38BDF8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🛒 Market Place Oficial HELL Live', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 4),
              const Text('Transfere packs gratuitos ou adquire criações exclusivas feitas pelos criadores PRO da comunidade.', style: TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['Todos', 'Grátis', 'PRO'].map((f) {
                  return ChoiceChip(
                    label: Text(f),
                    selected: _filter == f,
                    selectedColor: const Color(0xFF1E78FF),
                    onSelected: (_) => setState(() => _filter = f),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...visible.map((item) {
          final double net = (item['netPrice'] as num).toDouble();
          final double consumerPrice = net == 0.0 ? 0.0 : (net * 1.30);
          final bool owned = item['owned'] == true;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1636),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: owned ? Colors.greenAccent : const Color(0xFF1E429F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: net == 0.0 ? Colors.green.withOpacity(0.25) : const Color(0xFF1E78FF).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        net == 0.0 ? 'GRÁTIS' : '${consumerPrice.toStringAsFixed(2)} €',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: net == 0.0 ? Colors.greenAccent : const Color(0xFF38BDF8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Por ${item['creator']} · ${item['category']}', style: const TextStyle(fontSize: 11.5, color: Colors.white60)),
                const SizedBox(height: 6),
                Text(item['desc'], style: const TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: owned ? Colors.green : const Color(0xFF1E78FF)),
                    onPressed: () {
                      setState(() => item['owned'] = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(owned ? 'Conteúdo já transferido para a tua biblioteca!' : '✅ "${item['title']}" adquirido e adicionado à tua conta!')),
                      );
                    },
                    icon: Icon(owned ? Icons.check_circle : Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                    label: Text(
                      owned ? 'Instalado na Biblioteca' : (net == 0.0 ? 'Transferir Gratuitamente' : 'Adquirir Agora (${consumerPrice.toStringAsFixed(2)} €)'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class CreatorStudioProScreen extends StatefulWidget {
  final String creatorName;
  const CreatorStudioProScreen({super.key, required this.creatorName});

  @override
  State<CreatorStudioProScreen> createState() => _CreatorStudioProScreenState();
}

class _CreatorStudioProScreenState extends State<CreatorStudioProScreen> {
  bool _isProActive = false;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _netPriceCtrl = TextEditingController(text: '10.00');
  String _category = 'Overlays 3D';
  String? _attachedFileName;

  @override
  Widget build(BuildContext context) {
    final double netVal = double.tryParse(_netPriceCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final double finalConsumerPrice = netVal * 1.30;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF132E73), Color(0xFF08112B)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _isProActive ? Colors.greenAccent : const Color(0xFFF59E0B), width: 1.6),
          ),
          child: Column(
            children: [
              Icon(Icons.workspace_premium, size: 48, color: _isProActive ? Colors.greenAccent : const Color(0xFFF59E0B)),
              const SizedBox(height: 8),
              Text(
                _isProActive ? 'Estúdio de Criador PRO Ativo' : 'Estúdio de Criador PRO · HELL Live',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cria e vende os teus próprios Overlays 3D, Banners animados e Packs de Sons/GIFs no Market Place. Defines o teu valor líquido e a plataforma acrescenta automaticamente a taxa de serviço ao comprador.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              if (!_isProActive) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: () => setState(() => _isProActive = true),
                    child: const Text('Ativar Subscrição Criador PRO (4,99 €/mês)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_isProActive) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1636),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E78FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🛠️ Publicar Novo Pack no Market Place', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                const SizedBox(height: 10),
                TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Título do Pack / Overlay', isDense: true)),
                const SizedBox(height: 8),
                               DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Categoria', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'Overlays 3D', child: Text('Overlays 3D')),
                    DropdownMenuItem(value: 'Banners Perfil', child: Text('Banners de Perfil (Estático / GIF)')),
                    DropdownMenuItem(value: 'Sons & GIFs', child: Text('Packs de Sons & GIFs')),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? 'Overlays 3D'),
                ),
                const SizedBox(height: 8),
                TextField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Descrição detalhada', isDense: true)),
                const SizedBox(height: 8),
                TextField(
                  controller: _netPriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'O Teu Valor Líquido a Receber (€) — 0 para Grátis', isDense: true),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF050B1E), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recebes líquido: ${netVal.toStringAsFixed(2)} €', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Preço final comprador (+30%): ${finalConsumerPrice.toStringAsFixed(2)} €', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final res = await FilePicker.platform.pickFiles();
                    if (res != null) {
                      setState(() => _attachedFileName = res.files.single.name);
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: Text(_attachedFileName ?? 'Anexar Ficheiros do Pack (PNG, GIF, MP3, ZIP)'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: () {
                      if (_titleCtrl.text.trim().isEmpty) return;
                      MarketplaceState.items.insert(0, {
                        'id': 'mp_${DateTime.now().millisecondsSinceEpoch}',
                        'title': _titleCtrl.text.trim(),
                        'creator': '@${widget.creatorName}',
                        'category': _category,
                        'netPrice': netVal,
                        'desc': _descCtrl.text.trim().isEmpty ? 'Criação exclusiva Estúdio PRO HELL Live.' : _descCtrl.text.trim(),
                        'owned': true,
                      });
                      _titleCtrl.clear();
                      _descCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚀 Publicado no Market Place HELL Live com sucesso!'), backgroundColor: Colors.green));
                    },
                    icon: const Icon(Icons.publish, color: Colors.white),
                    label: const Text('Publicar Agora no Market Place', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

