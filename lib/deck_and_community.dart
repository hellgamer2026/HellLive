import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
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
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  int _cols = 5;
  int _rows = 3;
  Color _deckBgColor = const Color(0xFF050B1E);

  static final List<Color> _deckBgOptions = [
    const Color(0xFF050B1E),
    const Color(0xFF07090E),
    const Color(0xFF140A26),
    const Color(0xFF061A14),
    const Color(0xFF18181B),
  ];

  static final List<IconData> _iconLibrary = [
    Icons.celebration_outlined,
    Icons.campaign_outlined,
    Icons.emoji_events_outlined,
    Icons.graphic_eq,
    Icons.rocket_launch_outlined,
    Icons.bolt,
    Icons.casino_outlined,
    Icons.play_arrow_rounded,
    Icons.videocam_outlined,
    Icons.sports_esports_outlined,
    Icons.pause_rounded,
    Icons.stop_rounded,
    Icons.notifications_active_outlined,
    Icons.local_fire_department_outlined,
    Icons.favorite_border,
    Icons.star_border_rounded,
    Icons.mic_none_rounded,
    Icons.headset_mic_outlined,
    Icons.monetization_on_outlined,
    Icons.shield_outlined,
    Icons.flash_on_outlined,
    Icons.music_note_outlined,
    Icons.auto_awesome_outlined,
    Icons.whatshot_outlined,
  ];

  static final List<Color> _accentColors = [
    const Color(0xFF38BDF8),
    const Color(0xFF22C55E),
    const Color(0xFFFBBF24),
    const Color(0xFFEF4444),
    const Color(0xFFA78BFA),
    const Color(0xFFF472B6),
  ];

  late List<List<Map<String, dynamic>>> _pages;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pages = [
      [
        {'label': 'Aplausos', 'icon': Icons.celebration_outlined, 'pngPath': null, 'color': const Color(0xFF38BDF8), 'cmd': 'sound', 'val': 'https://google.com'},
        {'label': 'Buzina', 'icon': Icons.campaign_outlined, 'pngPath': null, 'color': const Color(0xFFFBBF24), 'cmd': 'sound', 'val': 'https://google.com'},
        {'label': 'Vitória', 'icon': Icons.emoji_events_outlined, 'pngPath': null, 'color': const Color(0xFF22C55E), 'cmd': 'sound', 'val': 'https://google.com'},
        {'label': 'Suspense', 'icon': Icons.graphic_eq, 'pngPath': null, 'color': const Color(0xFFA78BFA), 'cmd': 'sound', 'val': 'https://google.com'},
        {'label': 'Foguetes', 'icon': Icons.rocket_launch_outlined, 'pngPath': null, 'color': const Color(0xFFF472B6), 'cmd': 'sound', 'val': 'https://google.com'},
        {'label': 'Laser', 'icon': Icons.bolt, 'pngPath': null, 'color': const Color(0xFF38BDF8), 'cmd': 'sound', 'val': 'https://google.com'},
        {'label': 'Roleta', 'icon': Icons.casino_outlined, 'pngPath': null, 'color': const Color(0xFF38BDF8), 'cmd': 'wheel', 'val': null},
        {'label': 'Início Live', 'icon': Icons.play_arrow_rounded, 'pngPath': null, 'color': const Color(0xFF38BDF8), 'cmd': 'scene', 'val': 'starting'},
        {'label': 'Câmara', 'icon': Icons.videocam_outlined, 'pngPath': null, 'color': const Color(0xFFA78BFA), 'cmd': 'scene', 'val': 'cam_frame'},
        {'label': 'Em Jogo', 'icon': Icons.sports_esports_outlined, 'pngPath': null, 'color': const Color(0xFF22C55E), 'cmd': 'scene', 'val': 'live'},
        {'label': 'Pausa', 'icon': Icons.pause_rounded, 'pngPath': null, 'color': const Color(0xFFFBBF24), 'cmd': 'scene', 'val': 'brb'},
        {'label': 'Fim Live', 'icon': Icons.stop_rounded, 'pngPath': null, 'color': const Color(0xFFEF4444), 'cmd': 'scene', 'val': 'ending'},
        {'label': 'Alerta Teste', 'icon': Icons.notifications_active_outlined, 'pngPath': null, 'color': const Color(0xFFFBBF24), 'cmd': 'test_alert', 'val': null},
        {'label': 'Sino', 'icon': Icons.notifications_none, 'pngPath': null, 'color': const Color(0xFF38BDF8), 'cmd': 'sound', 'val': 'https://google.com'},
        {'label': 'ÁUDIO', 'icon': Icons.power_settings_new, 'pngPath': null, 'color': const Color(0xFF22C55E), 'cmd': 'toggle_mute', 'val': null},
      ],
      List.generate(15, (i) => {'label': 'Livre ${i + 1}', 'icon': Icons.add, 'pngPath': null, 'color': Colors.white24, 'cmd': 'custom', 'val': ''}),
    ];
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageCtrl.dispose();
    super.dispose();
  }

  void _openDeckThemePicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1636),
        title: const Text('Cor de Fundo da Consola', style: TextStyle(fontSize: 16)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _deckBgOptions.map((c) {
            return GestureDetector(
              onTap: () {
                setState(() => _deckBgColor = c);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: _deckBgColor == c ? const Color(0xFF38BDF8) : Colors.white38, width: 2.5),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  void _openPairModal() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1636),
        title: const Text('Emparelhar Dispositivo', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onGenerateCode();
                  Navigator.pop(ctx);
                },
                child: const Text('Gerar Código neste Ecrã'),
              ),
            ),
            if (widget.generatedCode != null) ...[
              const SizedBox(height: 10),
              SelectableText(widget.generatedCode!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 4, color: Color(0xFF38BDF8))),
            ],
            const SizedBox(height: 12),
            TextField(controller: codeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Código de 6 dígitos...')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
          ElevatedButton(
            onPressed: () {
              if (codeCtrl.text.trim().length == 6) {
                widget.onJoinWithCode(codeCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ligar'),
          ),
        ],
      ),
    );
  }

  void _editButton(int pageIdx, int btnIdx) {
    final btn = _pages[pageIdx][btnIdx];
    final nameCtrl = TextEditingController(text: btn['label']);
    final urlCtrl = TextEditingController(text: btn['val']?.toString() ?? '');
    IconData selectedIcon = btn['icon'] as IconData;
    String? selectedPng = btn['pngPath'] as String?;
    Color selectedColor = (btn['color'] == Colors.white24) ? const Color(0xFF38BDF8) : (btn['color'] as Color);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF0B1636),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Personalizar Tecla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  if (btnIdx > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 18),
                      tooltip: 'Mover Esquerda',
                      onPressed: () {
                        setState(() {
                          final tmp = _pages[pageIdx][btnIdx - 1];
                          _pages[pageIdx][btnIdx - 1] = _pages[pageIdx][btnIdx];
                          _pages[pageIdx][btnIdx] = tmp;
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  if (btnIdx < _pages[pageIdx].length - 1)
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      tooltip: 'Mover Direita',
                      onPressed: () {
                        setState(() {
                          final tmp = _pages[pageIdx][btnIdx + 1];
                          _pages[pageIdx][btnIdx + 1] = _pages[pageIdx][btnIdx];
                          _pages[pageIdx][btnIdx] = tmp;
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ],
          ),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome da Tecla', isDense: true))),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(type: FileType.image);
                          if (res != null && res.files.single.path != null) {
                            setModalState(() => selectedPng = res.files.single.path);
                          }
                        },
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: Text(selectedPng != null ? 'PNG Ativo' : 'Carregar PNG', style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _accentColors.map((c) {
                      final isSel = selectedColor.value == c.value;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = c),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: isSel ? Border.all(color: Colors.white, width: 2) : null),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 105,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, crossAxisSpacing: 6, mainAxisSpacing: 6),
                      itemCount: _iconLibrary.length,
                      itemBuilder: (_, i) {
                        final ic = _iconLibrary[i];
                        final active = selectedPng == null && selectedIcon == ic;
                        return InkWell(
                          onTap: () => setModalState(() {
                            selectedPng = null;
                            selectedIcon = ic;
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: active ? selectedColor.withOpacity(0.25) : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: active ? selectedColor : Colors.transparent),
                            ),
                            child: Icon(ic, size: 18, color: active ? selectedColor : Colors.white70),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Som (.MP3 / Link)', isDense: true))),
                      IconButton(
                        icon: const Icon(Icons.audio_file_outlined),
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(type: FileType.audio);
                          if (res != null && res.files.single.path != null) {
                            setModalState(() => urlCtrl.text = res.files.single.path!);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _pages[pageIdx][btnIdx]['label'] = nameCtrl.text.trim().isEmpty ? 'Tecla' : nameCtrl.text.trim();
                  _pages[pageIdx][btnIdx]['icon'] = selectedIcon;
                  _pages[pageIdx][btnIdx]['pngPath'] = selectedPng;
                  _pages[pageIdx][btnIdx]['color'] = selectedColor;
                  if (urlCtrl.text.trim().isNotEmpty) {
                    _pages[pageIdx][btnIdx]['cmd'] = 'sound';
                    _pages[pageIdx][btnIdx]['val'] = urlCtrl.text.trim();
                  } else if (_pages[pageIdx][btnIdx]['cmd'] == 'custom') {
                    _pages[pageIdx][btnIdx]['cmd'] = 'configured';
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final keySurface = Color.lerp(_deckBgColor, Colors.white, 0.06)!;
    final itemsPerPage = (_cols * _rows).clamp(1, 15);

    return Scaffold(
      backgroundColor: _deckBgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            children: [
              Row(
                children: [
                  DropdownButton<String>(
                    value: '${_cols}x$_rows',
                    underline: const SizedBox(),
                    dropdownColor: keySurface,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                    items: const [
                      DropdownMenuItem(value: '5x3', child: Text('5 × 3')),
                      DropdownMenuItem(value: '4x3', child: Text('4 × 3')),
                      DropdownMenuItem(value: '4x2', child: Text('4 × 2')),
                      DropdownMenuItem(value: '3x2', child: Text('3 × 2')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        final parts = val.split('x');
                        setState(() {
                         _cols = int.parse(parts.first);
                          _rows = int.parse(parts.last);
                        });
                      }
                    },
                  ),
                  IconButton(icon: const Icon(Icons.palette_outlined, size: 19), tooltip: 'Cor de Fundo', onPressed: _openDeckThemePicker),
                  IconButton(icon: const Icon(Icons.link_rounded, size: 19), tooltip: 'Emparelhar', onPressed: _openPairModal),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 20),
                    tooltip: 'Adicionar Página',
                    onPressed: () => setState(() => _pages.add(List.generate(15, (i) => {'label': 'Livre ${i + 1}', 'icon': Icons.add, 'pngPath': null, 'color': Colors.white24, 'cmd': 'custom', 'val': ''}))),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('icon.png', height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, color: Color(0xFF38BDF8), size: 18)),
                      const SizedBox(width: 4),
                      const Text('ELL ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 3, color: Colors.white)),
                      const Text('LIVE', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, letterSpacing: 3, color: Color(0xFF38BDF8))),
                    ],
                  ),
                  const Spacer(),
                  if (widget.generatedCode != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(widget.generatedCode!, style: const TextStyle(fontSize: 12, letterSpacing: 2, color: Color(0xFF38BDF8), fontWeight: FontWeight.w700)),
                    ),
                  GestureDetector(
                    onTap: widget.onToggleMute,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (widget.isMuted ? const Color(0xFFEF4444) : const Color(0xFF22C55E)).withOpacity(0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.isMuted ? const Color(0xFFEF4444) : const Color(0xFF22C55E), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(widget.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: widget.isMuted ? const Color(0xFFEF4444) : const Color(0xFF22C55E), size: 15),
                          const SizedBox(width: 5),
                          Text(
                            widget.isMuted ? 'MUDO' : 'ATIVO',
                            style: TextStyle(color: widget.isMuted ? const Color(0xFFEF4444) : const Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.minimize_rounded, size: 20), tooltip: 'Minimizar', onPressed: widget.onMinimizeDeck),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  onPageChanged: (p) => setState(() => _currentPage = p),
                  itemCount: _pages.length,
                  itemBuilder: (ctx, pageIdx) {
                    final btns = _pages[pageIdx].take(itemsPerPage).toList();
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final itemW = (constraints.maxWidth - (_cols - 1) * 10) / _cols;
                        final itemH = (constraints.maxHeight - (_rows - 1) * 10) / _rows;
                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _cols,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: itemW / itemH,
                          ),
                          itemCount: btns.length,
                          itemBuilder: (ctx, i) {
                            final b = btns[i];
                            final isMuteBtn = b['cmd'] == 'toggle_mute';
                            final isCustomEmpty = b['cmd'] == 'custom' && b['pngPath'] == null;
                            final String? pngPath = b['pngPath'] as String?;
                            final Color accent = isMuteBtn
                                ? (widget.isMuted ? const Color(0xFFEF4444) : const Color(0xFF22C55E))
                                : (b['color'] as Color);

                            return Material(
                              color: keySurface,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () {
                                  if (isMuteBtn) {
                                    widget.onToggleMute();
                                  } else {
                                    widget.onSendCommand(b['cmd'] as String, b['val']);
                                  }
                                },
                                onLongPress: () => _editButton(pageIdx, i),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: isCustomEmpty ? Colors.white10 : accent.withOpacity(0.38), width: 1),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (isCustomEmpty)
                                        Text('HELL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 3, color: Colors.white.withOpacity(0.08)))
                                      else
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (pngPath != null)
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: Image.file(File(pngPath), width: _rows == 2 ? 34 : 26, height: _rows == 2 ? 34 : 26, fit: BoxFit.cover),
                                              )
                                            else
                                              Icon(
                                                isMuteBtn ? (widget.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded) : (b['icon'] as IconData),
                                                color: accent,
                                                size: _rows == 2 ? 26 : 21,
                                              ),
                                            const SizedBox(height: 5),
                                                                                        Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                              child: Text(
                                                isMuteBtn ? (widget.isMuted ? 'CORTADO' : 'SOM ATIVO') : (b['label'] as String),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: _rows == 2 ? 11.5 : 10.5, letterSpacing: 0.3),
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (!isCustomEmpty)
                                        Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: 24,
                                            height: 2.5,
                                            decoration: BoxDecoration(
                                              color: accent.withOpacity(0.85),

                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final active = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF38BDF8) : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
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

