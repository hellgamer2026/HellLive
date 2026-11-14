import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
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
    required this.onStateChanged,
  });

  @override
  State<ActionsStudioTab> createState() => _ActionsStudioTabState();
}

class _ActionsStudioTabState extends State<ActionsStudioTab> {
  String? _currentlyPlayingUrl;

  BoxDecoration _neonCard() => BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E429F), width: 1.2),
      );

  Future<void> _togglePlayAudio(String url, {bool isLocal = false, VoidCallback? onStateUpdate}) async {
    if (url.isEmpty) return;
    if (_currentlyPlayingUrl == url) {
      await widget.sfxPlayer.stop();
      _currentlyPlayingUrl = null;
      if (mounted) setState(() {});
      onStateUpdate?.call();
      return;
    }
    _currentlyPlayingUrl = url;
    if (mounted) setState(() {});
    onStateUpdate?.call();
    try {
      await widget.sfxPlayer.stop();
      if (isLocal || !url.startsWith('http')) {
        await widget.sfxPlayer.play(DeviceFileSource(url));
      } else {
        await widget.sfxPlayer.play(UrlSource(url));
      }
      widget.sfxPlayer.onPlayerComplete.listen((_) {
        if (_currentlyPlayingUrl == url) {
          _currentlyPlayingUrl = null;
          if (mounted) setState(() {});
          onStateUpdate?.call();
        }
      });
    } catch (_) {
      _currentlyPlayingUrl = null;
      if (mounted) setState(() {});
      onStateUpdate?.call();
    }
  }

  Widget _buildSmartMediaWidget(String mediaPath, {double size = 42}) {
    if (mediaPath.isEmpty) {
      return Icon(Icons.card_giftcard, size: size, color: const Color(0xFF38BDF8));
    }
    if (!mediaPath.startsWith('http')) {
      final f = File(mediaPath);
      if (f.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(f, width: size, height: size, fit: BoxFit.contain),
        );
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        mediaPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.auto_awesome, size: size, color: const Color(0xFF38BDF8)),
      ),
    );
  }
    Future<List<Map<String, String>>> _fetchIconifySearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];
    final results = <Map<String, String>>[];
    try {
      final res = await http.get(Uri.parse('https://api.iconify.design/search?query=${Uri.encodeComponent(clean)}&limit=24'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final icons = List<String>.from(data['icons'] ?? []);
        for (final ic in icons) {
          final parts = ic.split(':');
          if (parts.length == 2) {
            results.add({
              'name': parts[1],
              'url': 'https://api.iconify.design/${parts[0]}/${parts[1]}.png?height=96',
            });
          }
        }
      }
    } catch (_) {}
    return results;
  }

  void _openInstantPreviewDialog({
    required String title,
    required String mediaUrl,
    required String soundUrl,
    String? customVoicePath,
    required String message,
  }) {
    // Dispara o áudio em paralelo sem bloquear a abertura da janela (0 ms de atraso)
    if (customVoicePath != null && customVoicePath.isNotEmpty) {
      widget.sfxPlayer.stop().then((_) => widget.sfxPlayer.play(DeviceFileSource(customVoicePath)));
    } else if (soundUrl.isNotEmpty) {
      widget.sfxPlayer.stop().then((_) {
        if (soundUrl.startsWith('http')) {
          widget.sfxPlayer.play(UrlSource(soundUrl));
        } else {
          widget.sfxPlayer.play(DeviceFileSource(soundUrl));
        }
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF050B1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF38BDF8), width: 2)),
        title: Row(
          children: [
            const Icon(Icons.visibility, color: Color(0xFF38BDF8), size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Pré-visualização · $title', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E78FF)),
              ),
              child: Column(
                children: [
                  _buildSmartMediaWidget(mediaUrl, size: 84),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
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
  void _openQuickImagePicker(String currentMedia, Function(String) onPicked) {
    final searchCtrl = TextEditingController();
    List<Map<String, String>> onlineResults = [];
    bool searching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> runSearch() async {
            final q = searchCtrl.text.trim();
            if (q.isEmpty) return;
            setModalState(() => searching = true);
            final res = await _fetchIconifySearch(q);
            setModalState(() {
              onlineResults = res;
              searching = false;
            });
          }

          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SizedBox(
              height: 460,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🖼️ Escolher Imagem / Ícone HD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          onSubmitted: (_) => runSearch(),
                          decoration: const InputDecoration(
                            hintText: 'Pesquisar na internet (ex: crown, fire, rocket)...',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.all(13)),
                        onPressed: runSearch,
                        child: const Icon(Icons.search, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.folder_open, color: Color(0xFF38BDF8)),
                        tooltip: 'Carregar do Dispositivo',
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(type: FileType.image);
                          if (res != null && res.files.single.path != null) {
                            onPicked(res.files.single.path!);
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (searching)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
                        itemCount: (onlineResults.isNotEmpty ? onlineResults : DefaultMediaLibrary.builtInGifsAndPngs).length,
                        itemBuilder: (ctx, i) {
                          final list = onlineResults.isNotEmpty ? onlineResults : DefaultMediaLibrary.builtInGifsAndPngs;
                          final item = list[i];
                          final url = item['url']!;
                          return InkWell(
                            onTap: () {
                              onPicked(url);
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0E1D47),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: currentMedia == url ? const Color(0xFF38BDF8) : Colors.white12, width: 1.5),
                              ),
                              child: _buildSmartMediaWidget(url, size: 48),
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
    required String? initialCustomVoice,
    required bool initialTtsThank,
    required String? initialCustomMessage,
    required String defaultMessageTemplate,
    required Function(String media, String sound, String? voicePath, bool ttsThank, String customMsg) onSave,
  }) {
    String chosenMedia = initialMedia;
    // Por defeito nenhum som vem pré-selecionado ('') — o utilizador escolhe exatamente 1 som
    String chosenSound = initialSound;
    String? customVoicePath = initialCustomVoice;
    bool ttsThank = initialTtsThank;
    bool isRecording = false;
    final msgCtrl = TextEditingController(text: (initialCustomMessage == null || initialCustomMessage.isEmpty) ? defaultMessageTemplate : initialCustomMessage);
    final soundSearchCtrl = TextEditingController();
    String soundQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final allSounds = [...DefaultMediaLibrary.onlineSoundsRepository, ...widget.sounds];
          final seenUrls = <String>{};
          final uniqueSounds = <Map<String, String>>[];
          for (final s in allSounds) {
            final u = s['url'] ?? '';
            if (u.isNotEmpty && !seenUrls.contains(u)) {
              seenUrls.add(u);
              if (soundQuery.isEmpty || (s['name'] ?? '').toLowerCase().contains(soundQuery.toLowerCase())) {
                uniqueSounds.add(s);
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SizedBox(
              height: 540,
              child: ListView(
                children: [
                  Text('⚙️ Personalizar · $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildSmartMediaWidget(chosenMedia, size: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                          onPressed: () => _openQuickImagePicker(chosenMedia, (newUrl) => setModalState(() => chosenMedia = newUrl)),
                          icon: const Icon(Icons.image, color: Colors.white, size: 18),
                          label: const Text('Alterar Imagem / Ícone', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: msgCtrl,
                    decoration: const InputDecoration(labelText: 'Mensagem do Alerta (usa {user})', isDense: true, border: OutlineInputBorder()),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ler agradecimento por voz (TTS)', style: TextStyle(fontSize: 13)),
                    value: ttsThank,
                    onChanged: (v) => setModalState(() => ttsThank = v),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: isRecording ? Colors.redAccent : const Color(0xFF122B6B)),
                        onPressed: () async {
                          if (!isRecording) {
                            if (await widget.voiceRecorder.hasPermission()) {
                              final path = '${Directory.systemTemp.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
                              await widget.voiceRecorder.start(const RecordConfig(), path: path);
                              setModalState(() => isRecording = true);
                            }
                          } else {
                            final p = await widget.voiceRecorder.stop();
                            setModalState(() {
                              isRecording = false;
                              if (p != null) {
                                customVoicePath = p;
                                chosenSound = '';
                              }
                            });
                          }
                        },
                        icon: Icon(isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 18),
                                                label: Text(isRecording ? 'Parar Gravação' : 'Gravar Voz Própria', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      if (customVoicePath != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent),
                          onPressed: () => _togglePlayAudio(customVoicePath!, isLocal: true, onStateUpdate: () => setModalState(() {})),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => setModalState(() => customVoicePath = null),
                        ),
                      ],
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('🔊 Biblioteca de Sons (Escolhe apenas 1):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF38BDF8))),
                      TextButton.icon(
                        onPressed: () async {
                          final res = await FilePicker.platform.pickFiles(type: FileType.audio);
                          if (res != null && res.files.single.path != null) {
                            setModalState(() {
                              chosenSound = res.files.single.path!;
                              customVoicePath = null;
                              widget.sounds.insert(0, {'name': res.files.single.name, 'url': res.files.single.path!});
                            });
                          }
                        },
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: const Text('+ Ficheiro Áudio', style: TextStyle(fontSize: 11.5)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: soundSearchCtrl,
                          onSubmitted: (v) => setModalState(() => soundQuery = v),
                          decoration: const InputDecoration(hintText: 'Filtrar sons da biblioteca...', isDense: true, border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.search, color: Color(0xFF38BDF8)),
                        onPressed: () => setModalState(() => soundQuery = soundSearchCtrl.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    dense: true,
                    leading: Icon(chosenSound.isEmpty && customVoicePath == null ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: const Color(0xFF38BDF8)),
                    title: const Text('Sem Som (Silencioso)', style: TextStyle(fontSize: 12.5)),
                    onTap: () => setModalState(() {
                      chosenSound = '';
                      customVoicePath = null;
                    }),
                  ),
                  ...uniqueSounds.map((s) {
                    final url = s['url']!;
                    final isSelected = chosenSound == url;
                    final isPlaying = _currentlyPlayingUrl == url;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF122E73) : const Color(0xFF0B1636),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? const Color(0xFF38BDF8) : Colors.white12),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? const Color(0xFF38BDF8) : Colors.white38),
                        title: Text(s['name'] ?? '', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(isPlaying ? Icons.stop_circle : Icons.play_circle_fill, color: isPlaying ? Colors.redAccent : Colors.greenAccent, size: 26),
                              onPressed: () => _togglePlayAudio(url, onStateUpdate: () => setModalState(() {})),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  chosenSound = url;
                                  customVoicePath = null;
                                });
                              },
                              child: Text(isSelected ? 'Selecionado' : 'Usar Som', style: TextStyle(fontSize: 11, color: isSelected ? Colors.greenAccent : const Color(0xFF38BDF8))),
                            ),
                          ],
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

  Widget _buildGoalOverlayGraphic(String type, double pct, String title, int current, int target) {
    final pctInt = (pct * 100).round();

    if (type == 'tiktok_capsule' || type == 'tiktok_heart' || type == 'tiktok_gift') {
      final isHeart = type == 'tiktok_heart';
      final isGift = type == 'tiktok_gift';
      final accent = isHeart ? const Color(0xFFFE2C55) : (isGift ? const Color(0xFFFACC15) : const Color(0xFF25F4EE));
      final icon = isHeart ? Icons.favorite : (isGift ? Icons.card_giftcard : Icons.star_rounded);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0D).withOpacity(0.92),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: accent.withOpacity(0.75), width: 1.5),
          boxShadow: [BoxShadow(color: accent.withOpacity(0.25), blurRadius: 12)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: accent.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Colors.white)),
                      Text('$current / $target', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: accent)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 9,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Estilo TikFinity PRO (Segmentado Néon / Ouro / Subathon)
    final isGold = type == 'tikfinity_gold';
    final isSubathon = type == 'tikfinity_subathon';
    final primary = isGold ? const Color(0xFFFACC15) : (isSubathon ? const Color(0xFFF97316) : const Color(0xFF38BDF8));
    final secondary = isGold ? const Color(0xFFD97706) : (isSubathon ? const Color(0xFFEF4444) : const Color(0xFF1E78FF));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF070F26), Color(0xFF030712)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary, width: 1.6),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.32), blurRadius: 14)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1, color: primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text('$current / $target ($pctInt%)', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
              ),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [secondary, primary]),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: primary.withOpacity(0.6), blurRadius: 8)],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openGoalSimulator(Map<String, dynamic> goal) {
    double simPct = ((goal['current'] ?? 250) / ((goal['target'] ?? 1000) == 0 ? 1000 : goal['target'])).clamp(0.0, 1.0);
    final int target = goal['target'] ?? 1000;
    final String overlayType = goal['overlayType'] ?? 'tiktok_capsule';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSimState) => AlertDialog(
          backgroundColor: const Color(0xFF050B1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
          title: const Text('🎬 Simulação Ao Vivo do Overlay', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGoalOverlayGraphic(overlayType, simPct, goal['title'] ?? 'Meta', (simPct * target).round(), target),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                    onPressed: () {
                      setSimState(() => simPct = (simPct + 0.20).clamp(0.0, 1.0));
                      _togglePlayAudio(DefaultMediaLibrary.builtInSounds.first['url']!);
                    },
                    child: const Text('+20% Progresso', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      setSimState(() => simPct = 1.0);
                      _togglePlayAudio(DefaultMediaLibrary.builtInSounds[3]['url']!);
                    },
                    child: const Text('Simular 100%', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  OutlinedButton(
                    onPressed: () => setSimState(() => simPct = 0.0),
                    child: const Text('Repor 0%', style: TextStyle(fontSize: 12)),
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
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  void _openGoalEditAndGallery(Map<String, dynamic> goal) {
    final titleCtrl = TextEditingController(text: goal['title'] ?? 'Meta da Live');
    final targetCtrl = TextEditingController(text: '${goal['target'] ?? 1000}');
    String selectedOverlay = goal['overlayType'] ?? 'tiktok_capsule';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SizedBox(
            height: 520,
            child: ListView(
              children: [
                const Text('🎯 Galeria de Overlays de Meta (TikFinity & TikTok Studio)', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                const SizedBox(height: 10),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título da Meta', isDense: true, border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Objetivo Numérico', isDense: true, border: OutlineInputBorder())),
                const SizedBox(height: 12),
                ...DefaultMediaLibrary.goalOverlaysCatalog.map((item) {
                  final type = item['type']!;
                  final isSel = selectedOverlay == type;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedOverlay = type),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF122E73) : const Color(0xFF0B1636),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSel ? const Color(0xFF38BDF8) : Colors.white12, width: isSel ? 2 : 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                              Text('${item['name']} · [${item['brand']}]', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF38BDF8))),
                              if (isSel) const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildGoalOverlayGraphic(type, 0.65, titleCtrl.text.trim().isEmpty ? 'Meta da Live' : titleCtrl.text.trim(), 650, 1000),
                        ],
                      ),
                    ),
                  );
                }),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 13)),
                  onPressed: () {
                    setState(() {
                      goal['title'] = titleCtrl.text.trim().isEmpty ? 'Meta da Live' : titleCtrl.text.trim();
                      goal['target'] = int.tryParse(targetCtrl.text.trim()) ?? 1000;
                      goal['overlayType'] = selectedOverlay;
                    });
                    widget.onStateChanged();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Aplicar Overlay à Meta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAddPresentPicker() {
    final searchCtrl = TextEditingController();
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = DefaultMediaLibrary.fullTikTokPngSelectableList.where((item) {
            if (query.isEmpty) return true;
            return item['name'].toString().toLowerCase().contains(query.toLowerCase());
          }).toList();

          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SizedBox(
              height: 480,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎁 Catálogo de Presentes HD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          onSubmitted: (v) => setModalState(() => query = v),
                          decoration: const InputDecoration(hintText: 'Pesquisar presente (ex: Rosa, Leão, Galáxia)...', isDense: true, border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.all(13)),
                        onPressed: () => setModalState(() => query = searchCtrl.text),
                        child: const Icon(Icons.search, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];
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
                                'sound': '',
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
                                _buildSmartMediaWidget(item['png'].toString(), size: 46),
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
    required String title,
    required String subtitle,
    required String mediaUrl,
    required bool isEnabled,
    required VoidCallback onDelete,
    required VoidCallback onTapImage,
    required VoidCallback onEdit,
    required VoidCallback onPlayPreview,
    required Function(bool) onToggleEnabled,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: _neonCard(),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            tooltip: 'Eliminar',
            onPressed: onDelete,
          ),
          GestureDetector(
            onTap: onTapImage,
            child: _buildSmartMediaWidget(mediaUrl, size: 42),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 2),
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
            icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 26),
            tooltip: 'Pré-visualizar Agora',
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
      length: 3,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF38BDF8),
            labelColor: Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: '🎁 Presentes'),
              Tab(text: '🔔 Alertas'),
              Tab(text: '🎯 Metas'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 1. PRESENTES
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
                            onChanged: widget.onToggleAllGifts,
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
                    const SizedBox(height: 12),
                    ...DefaultMediaLibrary.tiktokGiftsCatalog.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final g = entry.value;
                      final hasVoice = g['customVoicePath'] != null;
                      final hasSound = (g['sound'] ?? '').toString().isNotEmpty;
                      final defaultMsg = 'Obrigado {user} pelo presente ${g['name']}!';

                      return _buildUniformActionCard(
                        title: g['name'] ?? 'Presente',
                        subtitle: hasVoice
                            ? '🎙️ Voz gravada · ${g['coins']} moedas'
                            : (hasSound ? '🔊 Som personalizado · ${g['coins']} moedas' : '🔇 Sem som · ${g['coins']} moedas'),
                        mediaUrl: g['png'] ?? '',
                        isEnabled: g['enabled'] == true,
                        onDelete: () => setState(() => DefaultMediaLibrary.tiktokGiftsCatalog.removeAt(idx)),
                        onTapImage: () => _openQuickImagePicker(g['png'] ?? '', (newImg) => setState(() => g['png'] = newImg)),
                        onEdit: () => _openRichCustomizer(
                          title: g['name'] ?? 'Presente',
                          initialMedia: g['png'] ?? '',
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
                          final raw = (g['customMessage'] == null || g['customMessage'].toString().trim().isEmpty) ? defaultMsg : g['customMessage'].toString();
                          final spoken = raw.replaceAll('{user}', 'Apoiante');
                          _openInstantPreviewDialog(
                            title: g['name'] ?? 'Presente',
                            mediaUrl: g['png'] ?? '',
                            soundUrl: g['sound'] ?? '',
                            customVoicePath: g['customVoicePath'],
                            message: spoken,
                          );
                          if (!hasVoice && (g['ttsThank'] ?? true) == true) {
                            widget.onSpeakVoice(spoken);
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
                          widget.alertsList.insert(0, {
                            'id': 'al_${DateTime.now().millisecondsSinceEpoch}',
                            'trigger': 'follow',
                            'name': 'Novo Alerta Personalizado',
                            'enabled': true,
                            'ttsThank': true,
                            'customVoicePath': null,
                            'media': DefaultMediaLibrary.builtInGifsAndPngs.first['url']!,
                            'sound': '',
                          });
                        });
                      },
                      icon: const Icon(Icons.add_alert, color: Colors.white),
                      label: const Text('+ Criar Novo Alerta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    ...widget.alertsList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final al = entry.value;
                      final hasVoice = al['customVoicePath'] != null;
                      final hasSound = (al['sound'] ?? '').toString().isNotEmpty;
                      final defaultMsg = '{user} ativou ${al['name']}!';

                      return _buildUniformActionCard(
                        title: al['name'] ?? 'Alerta',
                        subtitle: hasVoice ? '🎙️ Voz gravada' : (hasSound ? '🔊 Som personalizado' : '🔇 Sem som selecionado'),
                        mediaUrl: al['media'] ?? '',
                        isEnabled: al['enabled'] == true,
                        onDelete: () => setState(() => widget.alertsList.removeAt(idx)),
                        onTapImage: () => _openQuickImagePicker(al['media'] ?? '', (newImg) => setState(() => al['media'] = newImg)),
                        onEdit: () => _openRichCustomizer(
                          title: al['name'] ?? 'Alerta',
                          initialMedia: al['media'] ?? '',
                          initialSound: al['sound'] ?? '',
                          initialCustomVoice: al['customVoicePath'],
                          initialTtsThank: al['ttsThank'] ?? true,
                          initialCustomMessage: al['customMessage'],
                          defaultMessageTemplate: defaultMsg,
                          onSave: (m, s, vPath, tts, msg) => setState(() {
                            al['media'] = m;
                            al['sound'] = s;
                            al['customVoicePath'] = vPath;
                            al['ttsThank'] = tts;
                            al['customMessage'] = msg;
                          }),
                        ),
                        onPlayPreview: () {
                          final raw = (al['customMessage'] == null || al['customMessage'].toString().trim().isEmpty) ? defaultMsg : al['customMessage'].toString();
                          final spoken = raw.replaceAll('{user}', 'Apoiante');
                          _openInstantPreviewDialog(
                            title: al['name'] ?? 'Alerta',
                            mediaUrl: al['media'] ?? '',
                            soundUrl: al['sound'] ?? '',
                            customVoicePath: al['customVoicePath'],
                            message: spoken,
                          );
                          if (!hasVoice && (al['ttsThank'] ?? true) == true) {
                            widget.onSpeakVoice(spoken);
                          }
                        },
                        onToggleEnabled: (v) => setState(() => al['enabled'] = v),
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
                          widget.goalsList.insert(0, {
                            'id': 'goal_${DateTime.now().millisecondsSinceEpoch}',
                            'title': 'Nova Meta da Live',
                            'current': 250,
                            'target': 1000,
                            'overlayType': 'tiktok_capsule',
                          });
                        });
                        widget.onStateChanged();
                      },
                      icon: const Icon(Icons.add_chart, color: Colors.white),
                      label: const Text('+ Criar Nova Meta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    ...widget.goalsList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final goal = entry.value;
                      final int current = goal['current'] ?? 0;
                      final int target = (goal['target'] ?? 1000) == 0 ? 1000 : goal['target'];
                      final double pct = (current / target).clamp(0.0, 1.0);
                      final String overlayType = goal['overlayType'] ?? 'tiktok_capsule';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: _neonCard(),
                        child: Column(
                          children: [
                            _buildGoalOverlayGraphic(overlayType, pct, goal['title'] ?? 'Meta', current, target),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                  onPressed: () => _openGoalEditAndGallery(goal),
                                  icon: const Icon(Icons.style, size: 16, color: Colors.white),
                                  label: const Text('Estilo TikFinity / Studio', style: TextStyle(color: Colors.white, fontSize: 11.5)),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                  onPressed: () => _openGoalSimulator(goal),
                                  icon: const Icon(Icons.play_arrow, size: 18, color: Colors.white),
                                  label: const Text('Simular Ao Vivo', style: TextStyle(color: Colors.white, fontSize: 11.5)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() => widget.goalsList.removeAt(idx));
                                    widget.onStateChanged();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
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
