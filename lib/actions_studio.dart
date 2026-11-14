import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_data.dart';

class ActionsStudioTab extends StatefulWidget {
  final List<Map<String, dynamic>> alertsList;
  final List<Map<String, dynamic>> goalsList;
  final List<Map<String, String>> sounds;
  final AudioPlayer sfxPlayer;
  final AudioRecorder voiceRecorder;
  final bool allGiftsEnabled;
  final Function(bool) onToggleAllGifts;
  final Function(String) onSpeakVoice;
  final Widget chatTtsTabContent;
  final VoidCallback onStateChanged;

  const ActionsStudioTab({
    super.key,
    required this.alertsList,
    required this.goalsList,
    required this.sounds,
    required this.sfxPlayer,
    required this.voiceRecorder,
    required this.allGiftsEnabled,
    required this.onToggleAllGifts,
    required this.onSpeakVoice,
    required this.chatTtsTabContent,
    required this.onStateChanged,
  });

  @override
  State<ActionsStudioTab> createState() => _ActionsStudioTabState();
}

class _ActionsStudioTabState extends State<ActionsStudioTab> {
  String? _currentlyPlayingUrl;
  StreamSubscription? _playerCompleteSub;

  @override
  void initState() {
    super.initState();
    _playerCompleteSub = widget.sfxPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _currentlyPlayingUrl = null);
    });
  }

  @override
  void dispose() {
    _playerCompleteSub?.cancel();
    super.dispose();
  }

  BoxDecoration _neonCard() => BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E429F), width: 1.2),
      );

  Future<void> _togglePlayAudio(String url, {String? filePath, VoidCallback? onStateUpdate}) async {
    try {
      if (_currentlyPlayingUrl == url && url.isNotEmpty) {
        await widget.sfxPlayer.stop();
        if (mounted) setState(() => _currentlyPlayingUrl = null);
        onStateUpdate?.call();
        return;
      }

      await widget.sfxPlayer.stop();
      await widget.sfxPlayer.setVolume(1.0);
      if (filePath != null && filePath.isNotEmpty) {
        await widget.sfxPlayer.play(DeviceFileSource(filePath));
        if (mounted) setState(() => _currentlyPlayingUrl = filePath);
      } else if (url.isNotEmpty) {
        await widget.sfxPlayer.play(UrlSource(url));
        if (mounted) setState(() => _currentlyPlayingUrl = url);
      }
      onStateUpdate?.call();
    } catch (_) {
      if (mounted) setState(() => _currentlyPlayingUrl = null);
      onStateUpdate?.call();
    }
  }

  Future<List<Map<String, String>>> _searchOnlineImages(String query) async {
    final q = query.trim().isEmpty ? 'trophy crown fire rocket diamond' : query.trim();
    try {
      final uri = Uri.parse('https://iconify.design{Uri.encodeComponent(q)}&limit=36');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final icons = List<String>.from(data['icons'] ?? []);
        return icons.map((iconId) {
          final parts = iconId.split(':');
          final prefix = parts.first;
          final name = parts.length > 1 ? parts[1] : iconId;
          return {
            'name': name.replaceAll('-', ' ').toUpperCase(),
            'url': 'https://iconify.design',
          };
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, String>>> _searchOnlineAudioEffects(String query) async {
    final q = query.trim().isEmpty ? 'applause bell explosion laser horn' : query.trim();
    try {
      final uri = Uri.parse(
        'https://wikimedia.org{Uri.encodeComponent("$q filetype:audio")}&gsrnamespace=6&gsrlimit=20&prop=imageinfo&iiprop=url&format=json&origin=*',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 7));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final pages = (data['query']?['pages'] as Map<String, dynamic>?) ?? {};
        final list = <Map<String, String>>[];
        for (final entry in pages.values) {
          final title = (entry['title'] ?? '').toString().replaceFirst('File:', '').replaceAll('_', ' ');
          final info = (entry['imageinfo'] as List?)?.first;
          final url = (info?['url'] ?? '').toString();
          if (url.endsWith('.ogg') || url.endsWith('.mp3') || url.endsWith('.wav')) {
            list.add({'name': title, 'cat': 'Online Cloud', 'url': url});
          }
        }
        return list;
      }
    } catch (_) {}
    return [];
  }
  void _openOfflinePreview({
    required String title,
    required String mediaUrl,
    required String soundUrl,
    String? customVoicePath,
    String? message,
  }) {
    _togglePlayAudio(soundUrl, filePath: customVoicePath);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF04091A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF38BDF8), width: 2)),
        title: const Row(
          children: [
            Icon(Icons.live_tv_rounded, color: Color(0xFF38BDF8)),
            SizedBox(width: 8),
            Expanded(child: Text('Simulação de Live (Modo OFF)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          ],
        ),
        content: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.4, end: 1.0),
          duration: const Duration(milliseconds: 550),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const RadialGradient(colors: [Color(0xFF15347A), Color(0xFF050B1E)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
              boxShadow: [BoxShadow(color: const Color(0xFF38BDF8).withOpacity(0.28), blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  mediaUrl,
                  width: 115,
                  height: 115,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.celebration, size: 70, color: Color(0xFF38BDF8)),
                ),
                const SizedBox(height: 12),
                Text(
                  message ?? 'Apoiante_VIP enviou $title!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('● Som & Animação Ativos', style: TextStyle(fontSize: 11, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
            onPressed: () {
              _currentlyPlayingUrl = null;
              _togglePlayAudio(soundUrl, filePath: customVoicePath);
            },
            icon: const Icon(Icons.replay, size: 17, color: Colors.white),
            label: const Text('Repetir', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              widget.sfxPlayer.stop();
              setState(() => _currentlyPlayingUrl = null);
              Navigator.pop(ctx);
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _openQuickImagePicker(String currentMedia, Function(String newMedia) onPicked) {
    final searchCtrl = TextEditingController();
    List<Map<String, String>> onlineResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final baseImages = [
            ...DefaultMediaLibrary.fullTikTokPngSelectableList.map((p) => {'name': p['name'].toString(), 'url': p['png'].toString()}),
            ...DefaultMediaLibrary.builtInGifsAndPngs,
          ];
          final displayList = onlineResults.isNotEmpty ? onlineResults : baseImages;

          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SizedBox(
              height: 490,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🖼️ Biblioteca Online de Imagens 3D & Stickers HD', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          onSubmitted: (v) async {
                            setModalState(() => isSearching = true);
                            final res = await _searchOnlineImages(v);
                            setModalState(() {
                              onlineResults = res;
                              isSearching = false;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Pesquisar milhares de imagens online (ex: lion, car, crown, fire)...',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13)),
                        onPressed: () async {
                          setModalState(() => isSearching = true);
                          final res = await _searchOnlineImages(searchCtrl.text);
                          setModalState(() {
                            onlineResults = res;
                            isSearching = false;
                          });
                        },
                        child: const Text('Buscar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (isSearching)
                    const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))))
                  else
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
                        itemCount: displayList.length,
                        itemBuilder: (ctx, i) {
                          final img = displayList[i];
                          final sel = currentMedia == img['url'];
                          return GestureDetector(
                            onTap: () {
                              onPicked(img['url']!);
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0E1D47),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: sel ? Colors.cyanAccent : Colors.white12, width: 2),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Image.network(
                                      img['url']!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white38),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(img['name']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: Colors.white70)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  void _openOnlineSoundsRepo(Function(String soundUrl) onSoundPicked) {
    final searchCtrl = TextEditingController();
    String query = '';
    List<Map<String, String>> cloudResults = [];
    bool loadingCloud = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final localFiltered = DefaultMediaLibrary.onlineSoundsRepository
              .where((s) => query.isEmpty || s['name']!.toLowerCase().contains(query.toLowerCase()) || s['cat']!.toLowerCase().contains(query.toLowerCase()))
              .toList();
          final results = [...cloudResults, ...localFiltered];

          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SizedBox(
              height: 490,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌐 Biblioteca Online de Sons & Alertas (Estilo TikFinity)', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          onChanged: (v) => setModalState(() => query = v),
                          onSubmitted: (v) async {
                            setModalState(() => loadingCloud = true);
                            final fetched = await _searchOnlineAudioEffects(v);
                            setModalState(() {
                              cloudResults = fetched;
                              loadingCloud = false;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Pesquisar efeitos (ex: explosion, applause, horn, bell)...',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13)),
                        onPressed: () async {
                          setModalState(() => loadingCloud = true);
                          final fetched = await _searchOnlineAudioEffects(searchCtrl.text);
                          setModalState(() {
                            cloudResults = fetched;
                            loadingCloud = false;
                          });
                        },
                        child: const Text('Pesquisar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (loadingCloud)
                    const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (ctx, i) {
                          final snd = results[i];
                          final url = snd['url']!;
                          final isPlaying = _currentlyPlayingUrl == url;
                          return Card(
                            color: const Color(0xFF0E1D47),
                            child: ListTile(
                              dense: true,
                              leading: IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                                  color: isPlaying ? Colors.redAccent : Colors.greenAccent,
                                  size: 30,
                                ),
                                onPressed: () => _togglePlayAudio(url, onStateUpdate: () => setModalState(() {})),
                              ),
                              title: Text(snd['name']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('Categoria: ${snd['cat']}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(horizontal: 10)),
                                onPressed: () async {
                                  await widget.sfxPlayer.stop();
                                  setState(() {
                                    _currentlyPlayingUrl = null;
                                    if (!widget.sounds.any((x) => x['url'] == url)) {
                                      widget.sounds.insert(0, {'name': snd['name']!, 'url': url});
                                    }
                                  });
                                  onSoundPicked(url);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                                child: const Text('Usar Som', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openRichCustomizer({
    required String title,
    required String initialMedia,
    required String initialSound,
    String? initialCustomVoice,
    bool initialTtsThank = true,
    String? initialCustomMessage,
    required String defaultMessageTemplate,
    required Function(String media, String sound, String? voicePath, bool ttsThank, String customMessage) onSave,
  }) {
    String chosenMedia = initialMedia;
    String chosenSound = initialSound;
    String? customVoicePath = initialCustomVoice;
    bool ttsThank = initialTtsThank;
    bool isRecording = false;
    String mediaFilter = '';
    List<Map<String, String>> remoteImages = [];
    final msgCtrl = TextEditingController(
      text: (initialCustomMessage == null || initialCustomMessage.trim().isEmpty) ? defaultMessageTemplate : initialCustomMessage,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final baseMedia = [
            ...DefaultMediaLibrary.fullTikTokPngSelectableList.map((p) => {'name': p['name'].toString(), 'url': p['png'].toString()}),
            ...DefaultMediaLibrary.builtInGifsAndPngs,
          ];
          final allMedia = (remoteImages.isNotEmpty ? remoteImages : baseMedia)
              .where((m) => mediaFilter.isEmpty || m['name']!.toLowerCase().contains(mediaFilter.toLowerCase()))
              .toList();

          final sampleUser = 'Hélder';
          final renderedPreviewText = msgCtrl.text.replaceAll('{user}', sampleUser).replaceAll('{nome}', sampleUser);

          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SizedBox(
              height: 590,
              child: ListView(
                children: [
                  Row(
                    children: [
                      Image.network(chosenMedia, width: 46, height: 46, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40)),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Personalizar · $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)))),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        onPressed: () {
                          _openOfflinePreview(
                            title: title,
                            mediaUrl: chosenMedia,
                            soundUrl: chosenSound,
                            customVoicePath: customVoicePath,
                            message: renderedPreviewText,
                          );
                          if (customVoicePath == null && ttsThank && renderedPreviewText.trim().isNotEmpty) {
                            widget.onSpeakVoice(renderedPreviewText);
                          }
                        },
                        icon: const Icon(Icons.visibility, size: 16, color: Colors.black),
                        label: const Text('Pré-Visualizar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('1. Alterar Imagem 3D / Sticker Online:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: _neonCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('2. Mensagem Falada de Agradecimento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF38BDF8))),
                            Switch(
                              activeColor: Colors.white,
                              activeTrackColor: const Color(0xFF1E78FF),
                              value: ttsThank,
                              onChanged: (v) => setModalState(() => ttsThank = v),
                            ),
                          ],
                        ),
                        if (ttsThank) ...[
                          TextField(
                            controller: msgCtrl,
                            onChanged: (_) => setModalState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Texto que será lido na live (usa {user} para o nome)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: [
                              ActionChip(
                                label: const Text('+ Inserir {user}', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  msgCtrl.text = '${msgCtrl.text} {user}';
                                  setModalState(() {});
                                },
                              ),
                              ActionChip(
                                label: const Text('Redefinir Padrão', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  msgCtrl.text = defaultMessageTemplate;
                                  setModalState(() {});
                                },
                              ),
                              ActionChip(
                                label: const Text('🔊 Ouvir Exemplo', style: TextStyle(fontSize: 11)),
                                onPressed: () => widget.onSpeakVoice(renderedPreviewText),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Exemplo lido na live: "$renderedPreviewText"', style: const TextStyle(fontSize: 11, color: Colors.greenAccent)),
                        ],
                        const Divider(color: Colors.white12),
                        const Text('Ou Gravar a Tua Própria Voz (Substitui o Som):', style: TextStyle(fontSize: 11.5, color: Colors.white70)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: isRecording ? Colors.redAccent : const Color(0xFF122B6B)),
                              onPressed: () async {
                                if (!isRecording) {
                                  if (await widget.voiceRecorder.hasPermission()) {
                                    final path = '${Directory.systemTemp.path}/act_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
                                    await widget.voiceRecorder.start(const RecordConfig(), path: path);
                                    setModalState(() => isRecording = true);
                                  }
                                } else {
                                  final recorded = await widget.voiceRecorder.stop();
                                  setModalState(() {
                                    isRecording = false;
                                    if (recorded != null) {
                                      customVoicePath = recorded;
                                      chosenSound = '';
                                    }
                                  });
                                }
                              },
                              icon: Icon(isRecording ? Icons.stop : Icons.mic, size: 17, color: Colors.white),
                              label: Text(isRecording ? 'Parar Gravação' : 'Gravar Minha Voz', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                            if (customVoicePath != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent),
                                onPressed: () => _togglePlayAudio(customVoicePath!, filePath: customVoicePath, onStateUpdate: () => setModalState(() {})),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => setModalState(() => customVoicePath = null),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text('3. Escolher 1 Som Único:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF38BDF8))),
                      ),
                      TextButton.icon(
                        onPressed: () => _openOnlineSoundsRepo((url) {
                          setModalState(() {
                            chosenSound = url;
                            customVoicePath = null;
                          });
                        }),
                        icon: const Icon(Icons.cloud_download, size: 16),
                        label: const Text('Biblioteca Online de Sons', style: TextStyle(fontSize: 11.5)),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: (chosenSound.isEmpty && customVoicePath == null) ? Colors.redAccent.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        (chosenSound.isEmpty && customVoicePath == null) ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: (chosenSound.isEmpty && customVoicePath == null) ? Colors.redAccent : Colors.white54,
                      ),
                      title: const Text('Sem Som (Silencioso)', style: TextStyle(color: Colors.white70)),
                      onTap: () async {
                        await widget.sfxPlayer.stop();
                        setModalState(() {
                          _currentlyPlayingUrl = null;
                          chosenSound = '';
                          customVoicePath = null;
                        });
                      },
                    ),
                  ),
                  ...widget.sounds.asMap().entries.map((entry) {
                    final s = entry.value;
                    final url = (s['url'] ?? '').trim();
                    final isSelected = customVoicePath == null && chosenSound.isNotEmpty && chosenSound == url;
                    final isPlaying = _currentlyPlayingUrl == url;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1E78FF).withOpacity(0.22) : const Color(0xFF0E1D47).withOpacity(0.45),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isSelected ? const Color(0xFF38BDF8) : Colors.white54,
                        ),
                        title: Text(
                          s['name'] ?? 'Áudio',
                          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF38BDF8) : Colors.white),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                            size: 26,
                            color: isPlaying ? Colors.redAccent : Colors.greenAccent,
                          ),
                          tooltip: isPlaying ? 'Parar' : 'Testar Áudio',
                         onPressed: () => _togglePlayAudio(url, onStateUpdate: () => setModalState(() {})),
                      ),
                      onTap: () {
                        setModalState(() {
                          chosenSound = url;
                          customVoicePath = null;
                        });
                      },
                    ),
                  );
                }),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 13)),
                  onPressed: () async {
                    await widget.sfxPlayer.stop();
                    setState(() => _currentlyPlayingUrl = null);
                    onSave(chosenMedia, chosenSound, customVoicePath, ttsThank, msgCtrl.text.trim());
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Guardar Alterações', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildSelectedGoalOverlayGraphic(String overlayType, double pct, String title, int current, int target) {

    final completed = pct >= 1.0;

    Color primaryGlow = const Color(0xFF38BDF8);
    Color secondaryGlow = const Color(0xFF1E78FF);
    Color surfaceTop = const Color(0xFF0E1D47);
    Color surfaceBottom = const Color(0xFF04091A);
    String badgeLabel = 'CYBER REACTOR 3D';
    IconData emblem = Icons.bolt_rounded;

    if (overlayType == 'gold_3d' || overlayType == 'gold_vip') {
      primaryGlow = const Color(0xFFFACC15);
      secondaryGlow = const Color(0xFFD97706);
      surfaceTop = const Color(0xFF2B2108);
      surfaceBottom = const Color(0xFF0D0A03);
      badgeLabel = 'CARBON GOLD VIP 3D';
      emblem = Icons.workspace_premium_rounded;
    } else if (overlayType == 'rocket_3d' || overlayType == 'rocket') {
      primaryGlow = const Color(0xFF60A5FA);
      secondaryGlow = const Color(0xFF818CF8);
      surfaceTop = const Color(0xFF131C4A);
      surfaceBottom = const Color(0xFF05081C);
      badgeLabel = 'ORBITAL TELEMETRY 3D';
      emblem = Icons.rocket_launch_rounded;
    } else if (overlayType == 'plasma_3d' || overlayType == 'fuse' || overlayType == 'gas') {
      primaryGlow = const Color(0xFFFB7185);
      secondaryGlow = const Color(0xFFEA580C);
      surfaceTop = const Color(0xFF380D16);
      surfaceBottom = const Color(0xFF120306);
      badgeLabel = 'PLASMA CORE 3D';
      emblem = Icons.local_fire_department_rounded;
    } else if (overlayType == 'subathon_3d' || overlayType == 'subathon') {
      primaryGlow = const Color(0xFFC084FC);
      secondaryGlow = const Color(0xFF7C3AED);
      surfaceTop = const Color(0xFF251047);
      surfaceBottom = const Color(0xFF0B0417);
      badgeLabel = 'SUBATHON CHRONO 3D';
      emblem = Icons.timer_rounded;
    } else if (overlayType == 'emerald_3d') {
      primaryGlow = const Color(0xFF34D399);
      secondaryGlow = const Color(0xFF059669);
      surfaceTop = const Color(0xFF092E22);
      surfaceBottom = const Color(0xFF03120D);
      badgeLabel = 'EMERALD PRISM 3D';
      emblem = Icons.diamond_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [surfaceTop, surfaceBottom]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGlow.withOpacity(0.85), width: 1.6),
        boxShadow: [
          BoxShadow(color: primaryGlow.withOpacity(0.24), blurRadius: 18, offset: const Offset(0, 6)),
          const BoxShadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryGlow.withOpacity(0.35), secondaryGlow.withOpacity(0.15)]),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryGlow.withOpacity(0.6)),
                ),
                child: Icon(emblem, color: primaryGlow, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.4)),
                    Text(badgeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryGlow.withOpacity(0.9), letterSpacing: 1.1)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryGlow.withOpacity(0.5)),
                ),
                child: Text(
                  '${(pct * 100).round()}%',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: completed ? Colors.greenAccent : primaryGlow),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth * pct.clamp(0.0, 1.0);
              return Container(
                height: 22,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: Colors.white12, width: 1.2),
                ),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      width: barWidth,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white.withOpacity(0.85), primaryGlow, secondaryGlow],
                          stops: const [0.0, 0.32, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: primaryGlow.withOpacity(0.75), blurRadius: 12)],
                      ),
                    ),
                    Center(
                      child: Text(
                        completed ? 'OBJETIVO CONCLUÍDO · $current / $target' : '$current / $target',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1))],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openGoalExclusiveSimulationWindow(Map<String, dynamic> goal) {
    final String overlayType = goal['overlayType'] ?? 'cyber_3d';
    final String title = goal['title'] ?? 'Meta da Live';
    final int target = (goal['target'] as int) == 0 ? 1000 : (goal['target'] as int);
    double simulatedPct = ((goal['current'] as int) / target).clamp(0.0, 1.0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSimState) {
          final simCurrent = (target * simulatedPct).round();
          return AlertDialog(
            backgroundColor: const Color(0xFF04091A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF38BDF8), width: 2)),
            title: const Row(
              children: [
                Icon(Icons.play_circle_filled, color: Color(0xFF38BDF8)),
                SizedBox(width: 8),
                Expanded(child: Text('Simulador de Meta 3D (OFF)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSelectedGoalOverlayGraphic(overlayType, simulatedPct, title, simCurrent, target),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('Progresso:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    Expanded(
                      child: Slider(
                        value: simulatedPct,
                        min: 0.0,
                        max: 1.0,
                        activeColor: const Color(0xFF38BDF8),
                        onChanged: (v) async {
                          setSimState(() => simulatedPct = v);
                          if (v >= 0.99) {
                            await _togglePlayAudio('https://google.com');
                          }
                        },
                      ),
                    ),
                    Text('${(simulatedPct * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                      onPressed: () async {
                        final next = (simulatedPct + 0.15).clamp(0.0, 1.0);
                        setSimState(() => simulatedPct = next);
                        await _togglePlayAudio('https://wikimedia.org');
                      },
                      child: const Text('+15% Ação', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                            onPressed: () async {
                        setSimState(() => simulatedPct = 1.0);
                        await _togglePlayAudio('https://wikimedia.org');
                      },
                      child: const Text('Simular 100% Concluído', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    OutlinedButton(
                      onPressed: () => setSimState(() => simulatedPct = 0.0),
                      child: const Text('Zerar (0%)', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  widget.sfxPlayer.stop();
                  Navigator.pop(ctx);
                },
                child: const Text('Fechar Simulador'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openGoalEditAndOverlayPicker(Map<String, dynamic> goal) {
    final titleCtrl = TextEditingController(text: goal['title']);
    final targetCtrl = TextEditingController(text: '${goal['target']}');
    String chosenOverlayType = goal['overlayType'] ?? 'cyber_3d';
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final previewTarget = int.tryParse(targetCtrl.text.trim()) ?? 1000;
          final previewCurrent = (previewTarget * 0.68).round();
          final filteredOverlays = DefaultMediaLibrary.goalOverlaysCatalog
              .where((ov) => searchQuery.isEmpty || ov['name']!.toLowerCase().contains(searchQuery.toLowerCase()) || ov['desc']!.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎯 Biblioteca Online de Overlays 3D para Metas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 10),
                  _buildSelectedGoalOverlayGraphic(chosenOverlayType, 0.68, titleCtrl.text, previewCurrent, previewTarget),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: titleCtrl,
                          onChanged: (_) => setModalState(() {}),
                          decoration: const InputDecoration(labelText: 'Título da Meta', isDense: true, border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: targetCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setModalState(() {}),
                          decoration: const InputDecoration(labelText: 'Objetivo', isDense: true, border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setModalState(() => searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar overlays 3D (ex: cyber, gold, orbital, plasma, subathon)...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...filteredOverlays.map((ov) {
                    final sel = chosenOverlayType == ov['type'];
                    return Card(
                      color: sel ? const Color(0xFF122E73) : const Color(0xFF0B1636),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: sel ? const Color(0xFF38BDF8) : Colors.white12, width: sel ? 1.8 : 1),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(sel ? Icons.check_circle : Icons.view_in_ar_rounded, color: sel ? const Color(0xFF38BDF8) : Colors.white54),
                        title: Text(ov['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(ov['desc']!, style: const TextStyle(fontSize: 11, color: Colors.white60)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: sel ? Colors.green : const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(horizontal: 10)),
                          onPressed: () => setModalState(() => chosenOverlayType = ov['type']!),
                          child: Text(sel ? 'Selecionado' : 'Baixar & Usar', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                        onTap: () => setModalState(() => chosenOverlayType = ov['type']!),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 13)),
                      onPressed: () {
                        setState(() {
                          goal['title'] = titleCtrl.text.trim();
                          goal['target'] = previewTarget;
                          goal['overlayType'] = chosenOverlayType;
                        });
                        widget.onStateChanged();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Aplicar Overlay 3D à Meta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAddPresentPicker() {
    final searchCtrl = TextEditingController();
    List<Map<String, String>> cloudResults = [];
    bool searching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final items = cloudResults.isNotEmpty
              ? cloudResults.map((e) => {'name': e['name']!, 'coins': 10, 'png': e['url']!}).toList()
              : DefaultMediaLibrary.fullTikTokPngSelectableList;

          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SizedBox(
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎁 Adicionar Presente (Biblioteca Online 3D)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          onSubmitted: (v) async {
                            setModalState(() => searching = true);
                            final res = await _searchOnlineImages(v);
                            setModalState(() {
                              cloudResults = res;
                              searching = false;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Pesquisar milhares de presentes online...',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13)),
                        onPressed: () async {
                          setModalState(() => searching = true);
                          final res = await _searchOnlineImages(searchCtrl.text);
                          setModalState(() {
                            cloudResults = res;
                            searching = false;
                          });
                        },
                        child: const Text('Buscar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (searching)
                    const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8))))
                  else
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final item = items[i];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                DefaultMediaLibrary.tiktokGiftsCatalog.insert(0, {
                                  'id': 'tk_${DateTime.now().millisecondsSinceEpoch}_$i',
                                  'name': item['name'],
                                  'coins': item['coins'],
                                  'enabled': true,
                                  'ttsThank': true,
                                  'customVoicePath': null,
                                  'png': item['png'],
                                  'sound': DefaultMediaLibrary.builtInSounds.first['url'],
                                });
                              });
                              widget.onStateChanged();
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: _neonCard(),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    item['png'].toString(),
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard, size: 40, color: Color(0xFF38BDF8)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(item['name'].toString(), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text('${item['coins']} moedas', style: const TextStyle(fontSize: 10, color: Color(0xFF38BDF8))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUniformActionCard({
    required String mediaUrl,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback onDelete,
    required VoidCallback onTapImage,
    required VoidCallback onEdit,
    required VoidCallback onPlayPreview,
    required Function(bool) onToggleEnabled,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: _neonCard(),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
            tooltip: 'Eliminar',
            onPressed: onDelete,
          ),
          GestureDetector(
            onTap: onTapImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: const Color(0xFF050B1E), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5))),
                  child: Image.network(mediaUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.celebration, color: Color(0xFF38BDF8))),
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Color(0xFF1E78FF), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library, size: 10, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
            tooltip: 'Personalizar',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: Color(0xFF38BDF8), size: 24),
            tooltip: 'Simular em OFF',
            onPressed: onPlayPreview,
          ),
          Switch(
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF1E78FF),
            value: isEnabled,
            onChanged: onToggleEnabled,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFF38BDF8),
            labelColor: Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: '🎁 Presentes'),
              Tab(text: '🔔 Alertas'),
              Tab(text: '🎯 Metas'),
              Tab(text: '🗣️ Chat TTS'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: _neonCard(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ativar Todos os Presentes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          Switch(
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF1E78FF),
                            value: widget.allGiftsEnabled,
                            onChanged: (v) {
                              widget.onToggleAllGifts(v);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: _openAddPresentPicker,
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                      label: const Text('+ Adicionar Presente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    ...DefaultMediaLibrary.tiktokGiftsCatalog.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final g = entry.value;
                      final hasVoice = g['customVoicePath'] != null;
                      final defaultMsg = 'Obrigado pelo presente ${g['name']}, {user}!';
                      return _buildUniformActionCard(
                        mediaUrl: g['png'],
                        title: g['name'],
                        subtitle: hasVoice ? '🎙️ Voz gravada · ${g['coins']} moedas' : '${g['coins']} moedas · Toca na img para mudar',
                        isEnabled: g['enabled'] == true,
                        onDelete: () => setState(() => DefaultMediaLibrary.tiktokGiftsCatalog.removeAt(idx)),
                        onTapImage: () => _openQuickImagePicker(g['png'], (newImg) => setState(() => g['png'] = newImg)),
                        onEdit: () => _openRichCustomizer(
                          title: g['name'],
                          initialMedia: g['png'],
                          initialSound: g['sound'] ?? '',
                          initialCustomVoice: g['customVoicePath'],
                          initialTtsThank: g['ttsThank'] ?? true,
                          initialCustomMessage: g['customMessage'],
                          defaultMessageTemplate: defaultMsg,
                          onSave: (m, s, vPath, tts, msg) => setState(() {
                            g['png'] = m;
                            g['sound'] = s;
                            g['customVoicePath'] = vPath;
                            g['ttsThank'] = tts;
                            g['customMessage'] = msg;
                          }),
                        ),
                        onPlayPreview: () {
                          final rawMsg = (g['customMessage'] == null || g['customMessage'].toString().trim().isEmpty) ? defaultMsg : g['customMessage'].toString();
                          final spokenMsg = rawMsg.replaceAll('{user}', 'Hélder').replaceAll('{nome}', 'Hélder');
                          _openOfflinePreview(
                            title: g['name'],
                            mediaUrl: g['png'],
                            soundUrl: g['sound'] ?? '',
                            customVoicePath: g['customVoicePath'],
                            message: spokenMsg,
                          );
                          if (!hasVoice && (g['ttsThank'] ?? true) == true) {
                            widget.onSpeakVoice(spokenMsg);
                          }
                        },
                        onToggleEnabled: (v) => setState(() => g['enabled'] = v),
                      );
                    }),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () {
                        setState(() {
                          widget.alertsList.add({
                            'id': 'a_${DateTime.now().millisecondsSinceEpoch}',
                            'trigger': 'chat',
                            'name': 'Novo Alerta Personalizado',
                            'enabled': true,
                            'ttsThank': true,
                            'customMessage': 'Obrigado pelo apoio na live, {user}!',
                            'media': DefaultMediaLibrary.builtInGifsAndPngs.first['url']!,
                            'sound': DefaultMediaLibrary.builtInSounds.first['url']!,
                          });
                        });
                      },
                      icon: const Icon(Icons.add_alert, color: Colors.white),
                      label: const Text('+ Criar Novo Alerta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    ...widget.alertsList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final al = entry.value;
                      final hasVoice = al['customVoicePath'] != null;
                      final defaultMsg = 'Obrigado pelo apoio no ${al['name']}, {user}!';
                      return _buildUniformActionCard(
                        mediaUrl: al['media'],
                        title: al['name'],
                        subtitle: 'Toca na imagem ou no lápis para personalizar',
                        isEnabled: al['enabled'] == true,
