import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class MusicBackgroundScreen extends StatefulWidget {
  final AudioPlayer bgPlayer;
  const MusicBackgroundScreen({super.key, required this.bgPlayer});

  @override
  State<MusicBackgroundScreen> createState() => _MusicBackgroundScreenState();
}

class _MusicBackgroundScreenState extends State<MusicBackgroundScreen> {
  final TextEditingController _playlistUrlCtrl = TextEditingController();
  double _volume = 0.35;
  bool _isPlaying = false;
  int _currentIndex = 0;

  final List<Map<String, String>> _playlist = [
    {'title': 'Chill Lo-Fi Stream (Sem Copyright)', 'source': 'https://google.com', 'type': 'url'},
    {'title': 'Synthwave Cyber Arena', 'source': 'https://google.com', 'type': 'url'},
  ];

  Future<void> _playCurrent() async {
    if (_playlist.isEmpty) return;
    final track = _playlist[_currentIndex];
    await widget.bgPlayer.setVolume(_volume);
    await widget.bgPlayer.setReleaseMode(ReleaseMode.loop);
    if (track['type'] == 'file') {
      await widget.bgPlayer.play(DeviceFileSource(track['source']!));
    } else {
      await widget.bgPlayer.play(UrlSource(track['source']!));
    }
    setState(() => _isPlaying = true);
  }

  Future<void> _pauseMusic() async {
    await widget.bgPlayer.pause();
    setState(() => _isPlaying = false);
  }

  Future<void> _stopMusic() async {
    await widget.bgPlayer.stop();
    setState(() => _isPlaying = false);
  }

  Future<void> _nextTrack() async {
    if (_playlist.isEmpty) return;
    setState(() => _currentIndex = (_currentIndex + 1) % _playlist.length);
    await _playCurrent();
  }

  Future<void> _pickLocalTracks() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
    if (res != null && res.files.isNotEmpty) {
      setState(() {
        for (final f in res.files) {
          if (f.path != null) {
            _playlist.add({'title': f.name, 'source': f.path!, 'type': 'file'});
          }
        }
      });
      if (!_isPlaying) {
        _currentIndex = _playlist.length - res.files.length;
        await _playCurrent();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTitle = _playlist.isEmpty ? 'Nenhuma faixa selecionada' : _playlist[_currentIndex]['title']!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E429F)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎵 Serviços de Streaming Conectados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF38BDF8))),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954), padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () => launchUrl(Uri.parse('https://spotify.com'), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.music_note, color: Colors.white),
                      label: const Text('Spotify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF0000), padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () => launchUrl(Uri.parse('https://youtube.com'), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                      label: const Text('YT Music', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _playlistUrlCtrl,
                      decoration: const InputDecoration(hintText: 'Colar link de playlist Spotify / YT Music...', isDense: true, border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.open_in_new, color: Color(0xFF38BDF8)),
                    tooltip: 'Abrir Playlist',
                    onPressed: () {
                      final uri = Uri.tryParse(_playlistUrlCtrl.text.trim());
                      if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF38BDF8), width: 1.3),
          ),
          child: Column(
            children: [
              const Text('MÚSICA DE FUNDO NA TRANSMISSÃO', style: TextStyle(fontSize: 10.5, letterSpacing: 2, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(currentTitle, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(iconSize: 38, color: Colors.greenAccent, tooltip: 'Iniciar Música', icon: const Icon(Icons.play_circle_filled), onPressed: _playCurrent),
                  const SizedBox(width: 10),
                  IconButton(iconSize: 38, color: Colors.amberAccent, tooltip: 'Pausar', icon: const Icon(Icons.pause_circle_filled), onPressed: _pauseMusic),
                  const SizedBox(width: 10),
                  IconButton(iconSize: 38, color: Colors.redAccent, tooltip: 'Encerrar Música', icon: const Icon(Icons.stop_circle), onPressed: _stopMusic),
                  const SizedBox(width: 10),
                  IconButton(iconSize: 34, color: const Color(0xFF38BDF8), tooltip: 'Próxima Faixa', icon: const Icon(Icons.skip_next_rounded), onPressed: _nextTrack),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.volume_down, color: Colors.white70),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFF38BDF8),
                      onChanged: (v) async {
                        setState(() => _volume = v);
                        await widget.bgPlayer.setVolume(v);
                      },
                    ),
                  ),
                  Text('${(_volume * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('📂 Minhas Músicas & Playlists Locais', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
              onPressed: _pickLocalTracks,
              icon: const Icon(Icons.library_music, size: 18, color: Colors.white),
              label: const Text('+ Carregar MP3', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._playlist.asMap().entries.map((e) {
          final active = e.key == _currentIndex && _isPlaying;
          return Card(
            color: active ? const Color(0xFF122B6B) : const Color(0xFF0B1636),
            child: ListTile(
              dense: true,
              leading: Icon(active ? Icons.graphic_eq : Icons.music_note, color: active ? Colors.greenAccent : const Color(0xFF38BDF8)),
              title: Text(e.value['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () async {
                setState(() => _currentIndex = e.key);
                await _playCurrent();
              },
            ),
          );
        }),
      ],
    );
  }
}

class CommunitySocialScreen extends StatefulWidget {
  final String serverUrl;
  final Map<String, dynamic> currentUser;
  const CommunitySocialScreen({super.key, required this.serverUrl, required this.currentUser});

  @override
  State<CommunitySocialScreen> createState() => _CommunitySocialScreenState();
}

class _CommunitySocialScreenState extends State<CommunitySocialScreen> {
  final TextEditingController _chatCtrl = TextEditingController();
  final List<Map<String, String>> _communityMessages = [
    {'user': '@SofiaLive', 'msg': 'Alguém a testar os novos overlays néon hoje?'},
    {'user': '@KikoGamer', 'msg': 'O Stream Deck no tablet ficou brutal!'},
  ];

  final List<Map<String, dynamic>> _creators = [
    {'nick': '@SofiaLive', 'bio': 'FPS & Just Chatting · Portugal', 'status': 'online', 'following': false, 'discord': 'discord.gg/sofia', 'whatsapp': ''},
    {'nick': '@KikoGamer', 'bio': 'Torneios e Desafios ao vivo', 'status': 'dnd', 'following': true, 'discord': '', 'whatsapp': '://whatsapp.com'},
    {'nick': '@TugaStream', 'bio': 'Criador de Overlays PRO', 'status': 'online', 'following': false, 'discord': 'discord.gg/tuga', 'whatsapp': ''},
  ];

  Color _dotColor(String st) {
    if (st == 'dnd') return Colors.orange;
    if (st == 'invisible') return Colors.white;
    if (st == 'offline') return Colors.redAccent;
    return Colors.green;
  }

  void _openDirectMessage(Map<String, dynamic> target) {
    if (target['status'] == 'dnd') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${target['nick']} está em modo Não Incomodar.')));
      return;
    }
    final dmCtrl = TextEditingController();
    final List<String> history = ['Olá ${target['nick']}! Tudo bem?'];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF0B1636),
          title: Row(
            children: [
              Icon(Icons.circle, size: 11, color: _dotColor(target['status'])),
              const SizedBox(width: 8),
              Text('Mensagem Privada · ${target['nick']}', style: const TextStyle(fontSize: 15)),
            ],
          ),
          content: SizedBox(
            width: 360,
            height: 240,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: history.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFF1E78FF).withOpacity(0.22), borderRadius: BorderRadius.circular(10)),
                            child: Text(m, style: const TextStyle(fontSize: 13)),
                          ),
                        )).toList(),
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: TextField(controller: dmCtrl, decoration: const InputDecoration(hintText: 'Escrever mensagem...', isDense: true))),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF38BDF8)),
                      onPressed: () {
                        if (dmCtrl.text.trim().isNotEmpty) {
                          setModalState(() {
                            history.add('${widget.currentUser['nickname'] ?? 'Eu'}: ${dmCtrl.text.trim()}');
                            dmCtrl.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF38BDF8),
            labelColor: Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: '👥 Criadores & Seguidores'),
              Tab(text: '💬 Chat da Comunidade'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 1. Perfis, Seguidores & Mensagens Privadas
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ..._creators.map((c) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1E429F)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      const CircleAvatar(backgroundColor: Color(0xFF1E78FF), child: Icon(Icons.person, color: Colors.white)),
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(color: _dotColor(c['status']), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF050B1E), width: 2)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c['nick'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text(c['bio'], style: const TextStyle(fontSize: 11.5, color: Colors.white60)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.mail_outline, color: Color(0xFF38BDF8)),
                                    tooltip: 'Mensagem Privada',
                                    onPressed: () => _openDirectMessage(c),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: c['following'] ? Colors.white12 : const Color(0xFF1E78FF)),
                                    onPressed: () => setState(() => c['following'] = !c['following']),
                                    child: Text(c['following'] ? 'A Seguir' : 'Seguir', style: const TextStyle(color: Colors.white, fontSize: 11.5)),
                                  ),
                                ],
                              ),
                              if ((c['discord'] as String).isNotEmpty || (c['whatsapp'] as String).isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if ((c['discord'] as String).isNotEmpty)
                                      Chip(label: Text('Discord: ${c['discord']}', style: const TextStyle(fontSize: 10.5)), backgroundColor: const Color(0xFF5865F2).withOpacity(0.25)),
                                    if ((c['whatsapp'] as String).isNotEmpty)
                                      Chip(label: Text('WhatsApp: ${c['whatsapp']}', style: const TextStyle(fontSize: 10.5)), backgroundColor: Colors.green.withOpacity(0.25)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        )),
                  ],
                ),
                // 2. Chat Geral da Comunidade
                Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: _communityMessages.map((m) => Card(
                              color: const Color(0xFF0B1636),
                              child: ListTile(
                                dense: true,
                                title: Text(m['user']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 12.5)),
                                subtitle: Text(m['msg']!),
                              ),
                            )).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(child: TextField(controller: _chatCtrl, decoration: const InputDecoration(hintText: 'Mensagem para a comunidade...', border: OutlineInputBorder(), isDense: true))),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF38BDF8)),
                            onPressed: () {
                              if (_chatCtrl.text.trim().isNotEmpty) {
                                setState(() {
                                  _communityMessages.add({
                                    'user': '@${widget.currentUser['nickname'] ?? 'Criador'}',
                                    'msg': _chatCtrl.text.trim(),
                                  });
                                  _chatCtrl.clear();
                                });
                              }
                            },
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
