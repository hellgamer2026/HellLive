import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_data.dart';
import 'live_connectors.dart';

class DonationHubScreen extends StatefulWidget {
  final AudioPlayer sfxPlayer;
  final Function(String) onSpeakVoice;

  const DonationHubScreen({
    super.key,
    required this.sfxPlayer,
    required this.onSpeakVoice,
  });

  @override
  State<DonationHubScreen> createState() => _DonationHubScreenState();
}

class _DonationHubScreenState extends State<DonationHubScreen> {
  final _mbwayCtrl = TextEditingController();
  final _paypalCtrl = TextEditingController();
  final _revolutCtrl = TextEditingController();
  final _pixCtrl = TextEditingController();
  final _minAmountCtrl = TextEditingController(text: '1.00');
  final _thankTemplateCtrl = TextEditingController(text: 'Muito obrigado {user} pela doação de {amount} euros! {message}');

  String _selectedMedia = DefaultMediaLibrary.builtInGifsAndPngs.first['url']!;
  String _selectedSound = '';
  bool _readTtsThank = true;
  String? _playingUrl;

  BoxDecoration _neonCard() => BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E429F), width: 1.2),
      );

  Future<void> _toggleSound(String url, {VoidCallback? onModalUpdate}) async {
    if (url.isEmpty) return;
    if (_playingUrl == url) {
      await widget.sfxPlayer.stop();
      _playingUrl = null;
      if (mounted) setState(() {});
      onModalUpdate?.call();
      return;
    }
    _playingUrl = url;
    if (mounted) setState(() {});
    onModalUpdate?.call();
    await widget.sfxPlayer.stop();
    if (url.startsWith('http')) {
      await widget.sfxPlayer.play(UrlSource(url));
    } else {
      await widget.sfxPlayer.play(DeviceFileSource(url));
    }
  }

  void _triggerDonationPreview() {
    final minVal = _minAmountCtrl.text.trim().isEmpty ? '2.00' : _minAmountCtrl.text.trim();
    final spoken = _thankTemplateCtrl.text
        .replaceAll('{user}', 'Apoiante VIP')
        .replaceAll('{amount}', minVal)
        .replaceAll('{message}', 'Continua com a excelente transmissão!');

    if (_selectedSound.isNotEmpty) {
      widget.sfxPlayer.stop().then((_) {
        if (_selectedSound.startsWith('http')) {
          widget.sfxPlayer.play(UrlSource(_selectedSound));
        } else {
          widget.sfxPlayer.play(DeviceFileSource(_selectedSound));
        }
      });
    }
    if (_readTtsThank) {
      widget.onSpeakVoice(spoken);
    }
    LocalObsServer.pushAlert('Apoiante VIP · $minVal €', spoken, _selectedMedia);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF050B1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.greenAccent, width: 2)),
        title: const Text('💸 Pré-visualização de Donation Ao Vivo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _selectedMedia.startsWith('http')
                ? Image.network(_selectedMedia, width: 84, height: 84, fit: BoxFit.contain)
                : Image.file(File(_selectedMedia), width: 84, height: 84, fit: BoxFit.contain),
            const SizedBox(height: 10),
            Text('Apoiante VIP doou $minVal €', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.greenAccent)),
            const SizedBox(height: 6),
            Text(spoken, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: Colors.white)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
            onPressed: () {
              widget.sfxPlayer.stop();
              Navigator.pop(ctx);
            },
            child: const Text('Fechar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  void _openDonationMediaAndSoundPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 500,
            child: ListView(
              children: [
                const Text('🖼️ Imagem / GIF da Doação (Biblioteca HD)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 68,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final res = await FilePicker.platform.pickFiles(type: FileType.image);
                          if (res != null && res.files.single.path != null) {
                            setState(() => _selectedMedia = res.files.single.path!);
                            setModalState(() {});
                          }
                        },
                        child: Container(
                          width: 64,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(color: const Color(0xFF1E78FF), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.add_photo_alternate, color: Colors.white),
                        ),
                      ),
                      ...DefaultMediaLibrary.builtInGifsAndPngs.map((g) {
                        final u = g['url']!;
                        final sel = _selectedMedia == u;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedMedia = u);
                            setModalState(() {});
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E1D47),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: sel ? Colors.greenAccent : Colors.white12, width: 2),
                            ),
                            child: Image.network(u, width: 52, height: 52, fit: BoxFit.contain),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 22),
                const Text('🔊 Escolher Som Único da Doação (Desmarcado por defeito):', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                ListTile(
                  dense: true,
                  leading: Icon(_selectedSound.isEmpty ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: const Color(0xFF38BDF8)),
                  title: const Text('Sem Som (Silencioso)'),
                  onTap: () {
                    setState(() => _selectedSound = '');
                    setModalState(() {});
                  },
                ),
                ...DefaultMediaLibrary.onlineSoundsRepository.map((s) {
                  final u = s['url']!;
                  final sel = _selectedSound == u;
                  final playing = _playingUrl == u;
                  return ListTile(
                    dense: true,
                    leading: Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: sel ? Colors.greenAccent : Colors.white38),
                    title: Text(s['name'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(playing ? Icons.stop_circle : Icons.play_circle_fill, color: playing ? Colors.redAccent : Colors.greenAccent),
                          onPressed: () => _toggleSound(u, onModalUpdate: () => setModalState(() {})),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedSound = u);
                            setModalState(() {});
                          },
                          child: Text(sel ? 'Selecionado' : 'Usar Som', style: TextStyle(color: sel ? Colors.greenAccent : const Color(0xFF38BDF8), fontSize: 11.5)),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() => _selectedSound = u);
                      setModalState(() {});
                    },
                  );
                }),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                  onPressed: () {
                    widget.sfxPlayer.stop();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Concluir Seleção', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeDonationLink = _paypalCtrl.text.trim().isNotEmpty
        ? _paypalCtrl.text.trim()
        : (_revolutCtrl.text.trim().isNotEmpty ? _revolutCtrl.text.trim() : 'http://${LocalObsServer.localIp}:${LocalObsServer.port}/overlay?widget=donate');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _neonCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('💸 Central Donation 100% Real', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                    onPressed: _triggerDonationPreview,
                    icon: const Icon(Icons.play_arrow, size: 18, color: Colors.white),
                    label: const Text('Pré-visualizar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _selectedMedia.startsWith('http')
                      ? Image.network(_selectedMedia, width: 48, height: 48, fit: BoxFit.contain)
                      : Image.file(File(_selectedMedia), width: 48, height: 48, fit: BoxFit.contain),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openDonationMediaAndSoundPicker,
                      icon: const Icon(Icons.tune),
                      label: Text(_selectedSound.isEmpty ? 'Imagem & Som (Sem som)' : 'Imagem & Som Ativos'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _minAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor Mínimo de Doação (€)', prefixIcon: Icon(Icons.euro), isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _thankTemplateCtrl,
                decoration: const InputDecoration(labelText: 'Gatilho Voz TTS ({user}, {amount}, {message})', prefixIcon: Icon(Icons.record_voice_over), isDense: true),
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Ler agradecimento e mensagem do doador por voz TTS'),
                value: _readTtsThank,
                onChanged: (v) => setState(() => _readTtsThank = v),
              ),
              const Divider(color: Colors.white12),
              const Text('💳 Métodos de Recebimento Personalizados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF38BDF8))),
              const SizedBox(height: 8),
              TextField(controller: _mbwayCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telemóvel MB WAY (Portugal)', prefixIcon: Icon(Icons.phone_android), isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _paypalCtrl, decoration: const InputDecoration(labelText: 'Link PayPal.me (ex: https://paypal.me)', prefixIcon: Icon(Icons.account_balance_wallet_outlined), isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: _revolutCtrl, decoration: const InputDecoration(labelText: 'Link Revolut.me / Cartão', prefixIcon: Icon(Icons.credit_card), isDense: true)),
              const SizedBox(height: 8),
               TextField(controller: _pixCtrl, decoration: const InputDecoration(labelText: 'Chave PIX (Opcional)', prefixIcon: Icon(Icons.qr_code), isDense: true)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF050B1E), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🛡️ Acesso Rápido Seguro para Seguidores (Sem violações na Live):', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                    const SizedBox(height: 4),
                    const Text('Coloca este link na Bio do teu perfil e fixa no chat para os espectadores apoiarem em 1 clique:', style: TextStyle(fontSize: 11, color: Colors.white70)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: Text(safeDonationLink, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12))),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18, color: Colors.white),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: safeDonationLink));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link seguro de apoio copiado!')));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MusicDeckController {
  static AudioPlayer? sharedPlayer;
  static bool isPlaying = false;
  static int currentIndex = 0;
  static List<Map<String, String>> activeTracks = List<Map<String, String>>.from(DefaultMediaLibrary.royaltyFreeMusicRepo);

  static Future<void> togglePlayPause() async {
    final player = sharedPlayer;
    if (player == null || activeTracks.isEmpty) return;
    if (isPlaying) {
      await player.pause();
      isPlaying = false;
    } else {
      final track = activeTracks[currentIndex % activeTracks.length];
      final src = track['url'] ?? track['source'] ?? '';
      if (src.startsWith('http')) {
        await player.play(UrlSource(src));
      } else if (src.isNotEmpty) {
        await player.play(DeviceFileSource(src));
      }
      isPlaying = true;
    }
  }

  static Future<void> nextTrack() async {
    final player = sharedPlayer;
    if (player == null || activeTracks.isEmpty) return;
    currentIndex = (currentIndex + 1) % activeTracks.length;
    final track = activeTracks[currentIndex];
    final src = track['url'] ?? track['source'] ?? '';
    await player.stop();
    if (src.startsWith('http')) {
      await player.play(UrlSource(src));
    } else if (src.isNotEmpty) {
      await player.play(DeviceFileSource(src));
    }
    isPlaying = true;
  }
}

class MusicBackgroundScreen extends StatefulWidget {
  final AudioPlayer bgPlayer;
  const MusicBackgroundScreen({super.key, required this.bgPlayer});

  @override
  State<MusicBackgroundScreen> createState() => _MusicBackgroundScreenState();
}

class _MusicBackgroundScreenState extends State<MusicBackgroundScreen> {
  final TextEditingController _playlistUrlCtrl = TextEditingController();
  double _volume = 0.35;

  @override
  void initState() {
    super.initState();
    MusicDeckController.sharedPlayer = widget.bgPlayer;
  }

  Future<void> _playIndex(int index) async {
    if (MusicDeckController.activeTracks.isEmpty) return;
    MusicDeckController.currentIndex = index % MusicDeckController.activeTracks.length;
    final track = MusicDeckController.activeTracks[MusicDeckController.currentIndex];
    final src = track['url'] ?? track['source'] ?? '';
    await widget.bgPlayer.setVolume(_volume);
    await widget.bgPlayer.setReleaseMode(ReleaseMode.loop);
    await widget.bgPlayer.stop();
    if (src.startsWith('http')) {
      await widget.bgPlayer.play(UrlSource(src));
    } else if (src.isNotEmpty) {
      await widget.bgPlayer.play(DeviceFileSource(src));
    }
    setState(() => MusicDeckController.isPlaying = true);
  }

  Future<void> _pickLocalTracks() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
    if (res != null && res.files.isNotEmpty) {
      setState(() {
        for (final f in res.files) {
          if (f.path != null) {
            MusicDeckController.activeTracks.insert(0, {
              'title': f.name,
              'artist': 'Ficheiro Local',
              'url': f.path!,
            });
          }
        }
      });
      await _playIndex(0);
    }
  }

  void _addCustomStreamOrPlaylist() {
    final raw = _playlistUrlCtrl.text.trim();
    if (raw.isEmpty) return;
    if (raw.endsWith('.mp3') || raw.endsWith('.aac') || raw.endsWith('.ogg')) {
      setState(() {
        MusicDeckController.activeTracks.insert(0, {
          'title': 'Stream / Faixa Externa',
          'artist': raw,
          'url': raw,
        });
        _playlistUrlCtrl.clear();
      });
      _playIndex(0);
    } else {
      final uri = Uri.tryParse(raw.startsWith('http') ? raw : 'https://$raw');
      if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracks = MusicDeckController.activeTracks;
    final activeTitle = tracks.isNotEmpty
        ? tracks[MusicDeckController.currentIndex % tracks.length]['title']!
        : 'Nenhuma faixa selecionada';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF38BDF8), width: 1.4),
          ),
          child: Column(
            children: [
              const Text('🎵 LEITOR INTEGRADO (SINCRONIZADO COM STREAM DECK)', style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: Color(0xFF38BDF8), fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(activeTitle, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 40,
                    color: Colors.greenAccent,
                    icon: Icon(MusicDeckController.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                    onPressed: () async {
                      await MusicDeckController.togglePlayPause();
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    iconSize: 38,
                    color: Colors.redAccent,
                    icon: const Icon(Icons.stop_circle),
                    onPressed: () async {
                      await widget.bgPlayer.stop();
                      setState(() => MusicDeckController.isPlaying = false);
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    iconSize: 36,
                    color: const Color(0xFF38BDF8),
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () async {
                      await MusicDeckController.nextTrack();
                      setState(() {});
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.volume_down, size: 20, color: Colors.white70),
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
                  Text('${(_volume * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF38BDF8))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954)),
                      onPressed: () => launchUrl(Uri.parse('https://spotify.com'), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.music_note, color: Colors.white, size: 18),
                      label: const Text('Spotify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF0000)),
                      onPressed: () => launchUrl(Uri.parse('https://youtube.com'), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
                      label: const Text('YouTube Music', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      decoration: const InputDecoration(hintText: 'Colar link MP3 direto, rádio ou playlist...', isDense: true, border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                    onPressed: _addCustomStreamOrPlaylist,
                    child: const Text('Tocar / Abrir', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('🎧 Playlist da Transmissão (Sem Direitos Autorais)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
            TextButton.icon(
              onPressed: _pickLocalTracks,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('+ MP3 Local'),
            ),
          ],
        ),
        ...tracks.asMap().entries.map((e) {
          final isCurrent = (MusicDeckController.currentIndex % tracks.length) == e.key && MusicDeckController.isPlaying;
          return Card(
            color: isCurrent ? const Color(0xFF122E73) : const Color(0xFF0B1636),
            child: ListTile(
              dense: true,
              leading: Icon(isCurrent ? Icons.equalizer : Icons.library_music, color: isCurrent ? Colors.greenAccent : const Color(0xFF38BDF8)),
              title: Text(e.value['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(e.value['artist'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.white60)),
              trailing: IconButton(
                icon: Icon(isCurrent ? Icons.pause : Icons.play_arrow, color: Colors.greenAccent),
                onPressed: () => _playIndex(e.key),
              ),
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
    {'user': '@KikoGamer', 'msg': 'O Stream Deck no tablet ficou excelente!'},
  ];

  final List<Map<String, dynamic>> _creators = [
    {'nick': '@SofiaLive', 'bio': 'FPS & Just Chatting · Portugal', 'status': 'online', 'following': false},
    {'nick': '@KikoGamer', 'bio': 'Torneios e Desafios ao vivo', 'status': 'dnd', 'following': true},
    {'nick': '@TugaStream', 'bio': 'Criador de Overlays PRO', 'status': 'online', 'following': false},
  ];

  Color _dotColor(String st) {
    if (st == 'dnd') return Colors.orange;
    if (st == 'invisible') return Colors.white;
    if (st == 'offline') return Colors.redAccent;
    return Colors.green;
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
            tabs: [Tab(text: '👥 Perfis Públicos'), Tab(text: '💬 Chat da Comunidade')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: _creators.map((c) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF1E429F)),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                const CircleAvatar(backgroundColor: Color(0xFF1E78FF), child: Icon(Icons.person, color: Colors.white)),
                                Container(width: 11, height: 11, decoration: BoxDecoration(color: _dotColor(c['status']), shape: BoxShape.circle)),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['nick'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                                  Text(c['bio'], style: const TextStyle(fontSize: 11.5, color: Colors.white60)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: c['following'] ? Colors.white12 : const Color(0xFF1E78FF)),
                              onPressed: () => setState(() => c['following'] = !c['following']),
                              child: Text(c['following'] ? 'A Seguir' : 'Seguir', style: const TextStyle(color: Colors.white, fontSize: 11.5)),
                            ),
                          ],
                        ),
                      )).toList(),
                ),
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
                          Expanded(child: TextField(controller: _chatCtrl, decoration: const InputDecoration(hintText: 'Escrever para a comunidade...', border: OutlineInputBorder(), isDense: true))),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF38BDF8)),
                            onPressed: () {
                              if (_chatCtrl.text.trim().isNotEmpty) {
                                setState(() {
                                  _communityMessages.add({'user': '@${widget.currentUser['nickname'] ?? 'Criador'}', 'msg': _chatCtrl.text.trim()});
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

class AboutAndSupportScreen extends StatefulWidget {
  const AboutAndSupportScreen({super.key});

  @override
  State<AboutAndSupportScreen> createState() => _AboutAndSupportScreenState();
}

class _AboutAndSupportScreenState extends State<AboutAndSupportScreen> {
  final TextEditingController _aiInputCtrl = TextEditingController();
  final List<Map<String, String>> _aiChat = [
    {'role': 'ai', 'text': 'Olá! Sou o Assistente IA da HELL Live. Pergunta-me como ligar o OBS, configurar alertas de presentes, usar o Stream Deck ou publicar no Market Place!'},
  ];

  final List<Map<String, String>> _faqTopics = [
    {
      'title': '1. Como ligar os Overlays no OBS Studio / TikTok Live Studio?',
      'example': 'Vai a "Galeria de Overlays", copia o Link Principal Browser Source (ex: http://192.168.x.x:8765/overlay), abre o OBS Studio > Fontes > Adicionar Browser e cola o endereço com largura 1920 e altura 1080.',
    },
    {
      'title': '2. Como ativar sons e voz nos Presentes e Alertas?',
      'example': 'Entra em "Ações", toca no ícone de lápis junto a qualquer presente ou alerta, escolhe 1 único som da biblioteca (ou grava a tua própria voz) e toca no botão verde Play para pré-visualizar.',
    },
    {
      'title': '3. Como transferir vozes masculinas e femininas para o Chat TTS?',
      'example': 'No Menu Principal abre "Chat TTS & Vozes", filtra por Masculinas ou Femininas, toca no ícone de transferência para guardar a voz dentro da app e ativa o interruptor principal.',
    },
    {
      'title': '4. Como vender Overlays e Packs no Market Place?',
      'example': 'Entra em "Estúdio Criador PRO", ativa a tua subscrição PRO, define o valor líquido que queres receber e publica o teu pack. O comprador vê o preço final já com a taxa da plataforma incluída.',
    },
  ];

  String _generateSmartAiReply(String question) {
    final q = question.toLowerCase();
    if (q.contains('obs') || q.contains('overlay') || q.contains('link')) {
      return 'Para ligar ao OBS ou TikTok Live Studio, vai a "Galeria de Overlays", copia o URL Browser Source local e adiciona-o como Fonte de Navegador (Browser Source) no teu programa de transmissão.';
    }
    if (q.contains('voz') || q.contains('tts') || q.contains('som')) {
      return 'Podes transferir vozes masculinas e femininas diretamente na secção "Chat TTS & Vozes" do Menu Principal, sem precisar de abrir as definições do telemóvel.';
    }
    if (q.contains('doar') || q.contains('donation') || q.contains('mbway') || q.contains('paypal')) {
      return 'Na aba "Donation", preenche o teu MB WAY, PayPal.me ou Revolut, define o valor mínimo e copia o link seguro para colocares na bio da tua live.';
    }
    if (q.contains('vender') || q.contains('pro') || q.contains('market')) {
      return 'Com o "Estúdio Criador PRO", defines o valor líquido que desejas ganhar por cada venda e o Market Place calcula automaticamente o preço final (+30%) para os compradores.';
    }
    return 'Podes explorar os exemplos práticos acima ou contactar a nossa equipa oficial através do e-mail hellgamer2026@gmail.com!';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(child: Image.asset('icon.png', height: 85, errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, size: 70, color: Color(0xFF38BDF8)))),
        const SizedBox(height: 10),
        const Center(child: Text('HELL Live', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2))),
        const Center(child: Text('A tua live, no teu comando. · LIVE · PLAY · CONNECT', style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: Color(0xFF38BDF8)))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E78FF)),
          ),
          child: const Text(
            'O HELL Live foi criado para dar a todos os criadores — do telemóvel ao estúdio completo no PC — ferramentas profissionais de transmissão, alertas em tempo real, Stream Deck em vidro 3D e um Market Place justo.',
            style: TextStyle(fontSize: 13.5, height: 1.5, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 16),
        const Text('📚 Tópicos Rápidos & Exemplos Práticos', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
        const SizedBox(height: 8),
        ..._faqTopics.map((f) => Card(
              color: const Color(0xFF0B1636),
              child: ExpansionTile(
                title: Text(f['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(f['example']!, style: const TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.45)),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1636),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF38BDF8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.smart_toy, color: Color(0xFF38BDF8)),
                  SizedBox(width: 8),
                  Text('Assistente IA · Dúvidas & Suporte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF38BDF8))),
                ],
              ),
              const SizedBox(height: 10),
              ..._aiChat.map((m) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: m['role'] == 'ai' ? const Color(0xFF122E73) : const Color(0xFF1E78FF).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(m['text']!, style: const TextStyle(fontSize: 12.5)),
                  )),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _aiInputCtrl,
                      decoration: const InputDecoration(hintText: 'Escreve a tua dúvida aqui...', isDense: true, border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF38BDF8)),
                    onPressed: () {
                      final q = _aiInputCtrl.text.trim();
                      if (q.isEmpty) return;
                      setState(() {
                        _aiChat.add({'role': 'user', 'text': q});
                        _aiChat.add({'role': 'ai', 'text': _generateSmartAiReply(q)});
                        _aiInputCtrl.clear();
                      });
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 22),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined, color: Color(0xFF38BDF8)),
                title: const Text('Contacto Oficial da Marca', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: const Text('hellgamer2026@gmail.com', style: TextStyle(color: Colors.cyanAccent)),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  onPressed: () => launchUrl(Uri.parse('mailto:hellgamer2026@gmail.com')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

