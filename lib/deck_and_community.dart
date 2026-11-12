import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class StreamDeckScreen extends StatefulWidget {
  final IO.Socket socket;
  final String activeRoom;
  final String? generatedCode;
  final String? pairedRoom;
  final VoidCallback onGenerateCode;
  final Function(String) onJoinWithCode;
  final Function(String, dynamic) onSendCommand;

  const StreamDeckScreen({
    super.key,
    required this.socket,
    required this.activeRoom,
    required this.generatedCode,
    required this.pairedRoom,
    required this.onGenerateCode,
    required this.onJoinWithCode,
    required this.onSendCommand,
  });

  @override
  State<StreamDeckScreen> createState() => _StreamDeckScreenState();
}

class _StreamDeckScreenState extends State<StreamDeckScreen> {
  final TextEditingController _codeCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final targetRoom = widget.pairedRoom ?? widget.activeRoom;
    final buttons = [
      {'label': 'Aplausos', 'icon': Icons.celebration, 'color': const Color(0xFF1E78FF), 'cmd': 'sound', 'val': 'https://google.com'},
      {'label': 'Buzina Épica', 'icon': Icons.campaign, 'color': const Color(0xFFF59E0B), 'cmd': 'sound', 'val': 'https://google.com'},
      {'label': 'Moeda / Win', 'icon': Icons.monetization_on, 'color': const Color(0xFF10B981), 'cmd': 'sound', 'val': 'https://google.com'},
      {'label': 'Suspense', 'icon': Icons.music_note, 'color': const Color(0xFF8B5CF6), 'cmd': 'sound', 'val': 'https://google.com'},
      {'label': 'Girar Roleta', 'icon': Icons.casino, 'color': const Color(0xFF06B6D4), 'cmd': 'wheel', 'val': null},
      {'label': 'Cena Início', 'icon': Icons.play_circle_fill, 'color': const Color(0xFF3B82F6), 'cmd': 'scene', 'val': 'starting'},
      {'label': 'Cena Pausa', 'icon': Icons.pause_circle_filled, 'color': const Color(0xFFF97316), 'cmd': 'scene', 'val': 'brb'},
      {'label': 'SILENCIAR TUDO', 'icon': Icons.volume_off, 'color': const Color(0xFFEF4444), 'cmd': 'panic', 'val': null},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E429F)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🔗 Emparelhar 2.º Aparelho', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  if (widget.pairedRoom != null)
                    const Chip(label: Text('Ligado', style: TextStyle(fontSize: 11)), backgroundColor: Colors.green),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                    onPressed: widget.onGenerateCode,
                    child: const Text('Gerar Código (Tablet/PC)', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  if (widget.generatedCode != null)
                    SelectableText(widget.generatedCode!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.cyanAccent)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Inserir código de 6 dígitos...', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      if (_codeCtrl.text.trim().length == 6) {
                        widget.onJoinWithCode(_codeCtrl.text.trim());
                      }
                    },
                    child: const Text('Ligar'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          targetRoom.isEmpty ? 'Painel Local (Liga uma live para controlar)' : 'Controlando Sala: $targetRoom',
          style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: buttons.length,
          itemBuilder: (ctx, i) {
            final b = buttons[i];
            return InkWell(
              onTap: () => widget.onSendCommand(b['cmd'] as String, b['val']),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: (b['color'] as Color).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: b['color'] as Color, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(b['icon'] as IconData, color: b['color'] as Color, size: 32),
                    const SizedBox(height: 8),
                    Text(b['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
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
    _globeCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
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
          height: 210,
          decoration: BoxDecoration(
            gradient: const RadialGradient(colors: [Color(0xFF132E73), Color(0xFF050B1E)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E78FF)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _globeCtrl,
                builder: (_, __) => CustomPaint(
                  size: const Size(170, 170),
                  painter: _GlobePainter(_globeCtrl.value * 2 * pi),
                ),
              ),
              const Positioned(
                bottom: 10,
                child: Text('🌍 REDE GLOBAL HELL LIVE', style: TextStyle(fontSize: 11, letterSpacing: 2, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
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
            child: const Text('Nenhum criador transmitindo neste instante. Liga a tua live para seres o primeiro em destaque!', style: TextStyle(color: Colors.white70)),
          )
        else
          ..._liveStreamers.map((s) => Card(
                color: const Color(0xFF0B1636),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF1E78FF), child: Icon(Icons.live_tv, color: Colors.white)),
                  title: Text(s['user'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Em direto no ${s['platform']}'),
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

class _GlobePainter extends CustomPainter {
  final double rotation;
  _GlobePainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paintLine = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, radius, paintLine);
    for (int i = -2; i <= 2; i++) {
      final y = center.dy + i * (radius / 3);
      final w = sqrt(max(0, radius * radius - pow(y - center.dy, 2)));
      canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, y), width: w * 2, height: w * 0.35), paintLine);
    }
    for (int i = 0; i < 4; i++) {
      final angle = rotation + (i * pi / 4);
      canvas.drawOval(Rect.fromCenter(center: center, width: radius * 2 * cos(angle).abs(), height: radius * 2), paintLine);
    }
    final dotPaint = Paint()..color = Colors.cyanAccent;
    canvas.drawCircle(Offset(center.dx + cos(rotation) * 35, center.dy - 20), 4, dotPaint);
    canvas.drawCircle(Offset(center.dx - sin(rotation) * 45, center.dy + 25), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _GlobePainter oldDelegate) => true;
}

class AboutHellLiveScreen extends StatelessWidget {
  const AboutHellLiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Image.asset('icon.png', height: 95, errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, size: 80, color: Color(0xFF38BDF8))),
        ),
        const SizedBox(height: 16),
        const Center(child: Text('HELL Live', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2))),
        const Center(child: Text('LIVE · PLAY · CONNECT', style: TextStyle(fontSize: 11, letterSpacing: 3, color: Color(0xFF38BDF8)))),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1636),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E78FF)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A Nossa Missão', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              SizedBox(height: 10),
              Text(
                'O HELL Live nasceu com um propósito claro: democratizar as transmissões ao vivo para todos os gamers e criadores de conteúdo.\n\nAcreditamos que ninguém deve ser impedido de interagir com a sua comunidade por não poder pagar mensalidades caras pelas ferramentas básicas.\n\nAqui tens leitura de chat por voz real, alertas personalizados, pódio competitivo, roleta interativa, estúdio de overlays e stream deck numa única plataforma leve e acessível.',
                style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
