import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
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
  BoxDecoration _neonCard() => BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E429F), width: 1.2),
      );

  Future<void> _playAudioSafe(String url, {String? filePath}) async {
    try {
      await widget.sfxPlayer.stop();
      await widget.sfxPlayer.setVolume(1.0);
      if (filePath != null && filePath.isNotEmpty) {
        await widget.sfxPlayer.play(DeviceFileSource(filePath));
      } else if (url.isNotEmpty) {
        await widget.sfxPlayer.play(UrlSource(url));
      }
    } catch (_) {}
  }

  // 1. Pré-Visualização Operacional em OFF (Com Animação Real + Som Real)
  void _openOfflinePreview({
    required String title,
    required String mediaUrl,
    required String soundUrl,
    String? customVoicePath,
    String? message,
  }) {
    _playAudioSafe(soundUrl, filePath: customVoicePath);

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
            onPressed: () => _playAudioSafe(soundUrl, filePath: customVoicePath),
            icon: const Icon(Icons.replay, size: 17, color: Colors.white),
            label: const Text('Repetir', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              widget.sfxPlayer.stop();
              Navigator.pop(ctx);
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // 2. Seletor Rápido ao Tocar Diretamente na Imagem
  void _openQuickImagePicker(String currentMedia, Function(String newMedia) onPicked) {
    final allImages = [
      ...DefaultMediaLibrary.fullTikTokPngSelectableList.map((p) => {'name': p['name'].toString(), 'url': p['png'].toString()}),
      ...DefaultMediaLibrary.builtInGifsAndPngs,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🖼️ Escolher Imagem PNG / 3D da Biblioteca', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
                  itemCount: allImages.length,
                  itemBuilder: (ctx, i) {
                    final img = allImages[i];
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
                        child: Image.network(img['url']!, fit: BoxFit.contain),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Repositório Online de Sons Gratuitos
  void _openOnlineSoundsRepo(Function(String soundUrl) onSoundPicked) {
    final searchCtrl = TextEditingController();
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final results = DefaultMediaLibrary.onlineSoundsRepository
              .where((s) => query.isEmpty || s['name']!.toLowerCase().contains(query.toLowerCase()) || s['cat']!.toLowerCase().contains(query.toLowerCase()))
              .toList();

          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SizedBox(
              height: 450,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌐 Repositório Online de Sons Gratuitos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (v) => setModalState(() => query = v),
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar sons (ex: explosão, meme, sino, aplausos)...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (ctx, i) {
                        final snd = results[i];
                        return Card(
                          color: const Color(0xFF0E1D47),
                          child: ListTile(
                            dense: true,
                            leading: IconButton(
                              icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 28),
                              onPressed: () => _playAudioSafe(snd['url']!),
                            ),
                            title: Text(snd['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('Categoria: ${snd['cat']}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(horizontal: 10)),
                              onPressed: () {
                                setState(() {
                                  if (!widget.sounds.any((x) => x['url'] == snd['url'])) {
                                    widget.sounds.insert(0, {'name': snd['name']!, 'url': snd['url']!});
                                  }
                                });
                                onSoundPicked(snd['url']!);
                                Navigator.pop(ctx);
                              },
                              child: const Text('Baixar & Usar', style: TextStyle(color: Colors.white, fontSize: 11)),
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

  // 4. Janela Completa de Personalização (Seleção Única de Som Real + Trocar Imagem + Voz Própria)
  void _openRichCustomizer({
    required String title,
    required String initialMedia,
    required String initialSound,
    String? initialCustomVoice,
    bool initialTtsThank = true,
    bool showTtsOption = false,
    required Function(String media, String sound, String? voicePath, bool ttsThank) onSave,
  }) {
    String chosenMedia = initialMedia;
    String chosenSound = initialSound;
    String? customVoicePath = initialCustomVoice;
    bool ttsThank = initialTtsThank;
    bool isRecording = false;
    String mediaFilter = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final allMedia = [
            ...DefaultMediaLibrary.fullTikTokPngSelectableList.map((p) => {'name': p['name'].toString(), 'url': p['png'].toString()}),
            ...DefaultMediaLibrary.builtInGifsAndPngs,
          ].where((m) => mediaFilter.isEmpty || m['name']!.toLowerCase().contains(mediaFilter.toLowerCase())).toList();

          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SizedBox(
              height: 560,
              child: ListView(
                children: [
                  Row(
                    children: [
                      Image.network(chosenMedia, width: 46, height: 46, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40)),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Personalizar · $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)))),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        onPressed: () => _openOfflinePreview(
                          title: title,
                          mediaUrl: chosenMedia,
                          soundUrl: chosenSound,
                          customVoicePath: customVoicePath,
                        ),
                        icon: const Icon(Icons.visibility, size: 16, color: Colors.black),
                        label: const Text('Pré-Visualizar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('1. Alterar Imagem PNG / 3D:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (v) => setModalState(() => mediaFilter = v),
                    decoration: const InputDecoration(hintText: 'Pesquisar imagens PNG / 3D...', prefixIcon: Icon(Icons.search), isDense: true, border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 76,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: allMedia.length,
                      itemBuilder: (ctx, i) {
                        final item = allMedia[i];
                        final sel = chosenMedia == item['url'];
                        return GestureDetector(
                          onTap: () => setModalState(() => chosenMedia = item['url']!),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              border: Border.all(color: sel ? Colors.cyanAccent : Colors.white12, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Image.network(item['url']!, width: 58, height: 58, fit: BoxFit.contain),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('2. Gravar Voz Própria ou TTS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF38BDF8))),
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
                        icon: Icon(isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 18),
                        label: Text(isRecording ? 'Parar Gravação' : 'Gravar Minha Voz', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      if (customVoicePath != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 28),
                          onPressed: () => _playAudioSafe('', filePath: customVoicePath),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => setModalState(() => customVoicePath = null),
                        ),
                      ],
                    ],
                  ),
                  if (showTtsOption)
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Agradecimento Falado Automático (TTS)', style: TextStyle(fontSize: 12.5)),
                      value: ttsThank,
                      onChanged: (v) => setModalState(() => ttsThank = v),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('3. Escolher 1 Som Único (Toca ao clicar):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF38BDF8))),
                      TextButton.icon(
                        onPressed: () => _openOnlineSoundsRepo((url) {
                          setModalState(() {
                            chosenSound = url;
                            customVoicePath = null;
                          });
                        }),
                        icon: const Icon(Icons.cloud_download, size: 16),
                        label: const Text('Pesquisar Sons Online', style: TextStyle(fontSize: 11.5)),
                      ),
                    ],
                  ),
                  ListTile(
                    dense: true,
                    leading: Icon(chosenSound.isEmpty && customVoicePath == null ? Icons.check_circle : Icons.radio_button_unchecked, color: chosenSound.isEmpty && customVoicePath == null ? Colors.redAccent : Colors.white54),
                    title: const Text('Sem Som (Silencioso)', style: TextStyle(color: Colors.white70)),
                    onTap: () async {
                      await widget.sfxPlayer.stop();
                      setModalState(() {
                        chosenSound = '';
                        customVoicePath = null;
                      });
                    },
                  ),
                  ...widget.sounds.asMap().entries.map((entry) {
                    final s = entry.value;
                    final url = s['url']!;
                    final isSelected = chosenSound == url && customVoicePath == null;
                    return ListTile(
                      dense: true,
                      leading: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? const Color(0xFF38BDF8) : Colors.white54),
                      title: Text(s['name'] ?? '', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF38BDF8) : Colors.white)),
                      trailing: IconButton(
                        icon: const Icon(Icons.volume_up, size: 20, color: Colors.greenAccent),
                        onPressed: () => _playAudioSafe(url),
                      ),
                      onTap: () async {
                        setModalState(() {
                          chosenSound = url;
                          customVoicePath = null;
                        });
                        await _playAudioSafe(url);
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: () {
                      widget.sfxPlayer.stop();
                      onSave(chosenMedia, chosenSound, customVoicePath, ttsThank);
                      Navigator.pop(ctx);
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

  // 5. Desenho Gráfico Real do Overlay Escolhido para a Meta (Sem Barras Genéricas)
  Widget _buildSelectedGoalOverlayGraphic(String overlayType, double pct, String title, int current, int target) {
    final completed = pct >= 1.0;

    if (overlayType == 'rocket') {
      return Container(
        height: 105,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.bottomLeft, end: Alignment.topRight, colors: [Color(0xFF04091E), Color(0xFF0F2B6B)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 80,
              child: CustomPaint(painter: _RocketGoalPainter(pct)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🚀 $title', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    completed ? 'ÓRBITA ATINGIDA! 100% COMPLETO!' : 'Altitude: ${(pct * 100).round()}% · $current / $target',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: completed ? Colors.greenAccent : const Color(0xFF38BDF8)),
                  ),
                  const SizedBox(height: 4),
                  const Text('Overlay: Foguetão Espacial', style: TextStyle(fontSize: 10.5, color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (overlayType == 'gas') {
      return Container(
        height: 105,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF241208), Color(0xFF45210E)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amberAccent, width: 1.5),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 80,
              child: CustomPaint(painter: _VintageGasPumpPainter(pct)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('⛽ $title', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.amberAccent)),
                  const SizedBox(height: 4),
                  Text(
                    completed ? 'DEPÓSITO CHEIO! META BATIDA!' : 'Combustível: ${(pct * 100).round()}% · $current / $target',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text('Overlay: Bomba de Gasolina Vintage', style: TextStyle(fontSize: 10.5, color: Colors.white60)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (overlayType == 'fuse') {
      return Container(
        height: 105,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF260A0A), Color(0xFF4A0E17)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🧨 $title', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                Text(
                  completed ? '🎆 BOOM! FOGOS DE ARTIFÍCIO! 🎆' : 'Rastilho: ${(pct * 100).round()}% ($current/$target)',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: completed ? Colors.amberAccent : Colors.orangeAccent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: CustomPaint(painter: _FuseDynamitePainter(pct)),
            ),
          ],
        ),
      );
    }

    if (overlayType == 'subathon') {
      return Container(
        height: 98,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF1A1047)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.purpleAccent, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('⏱️ $title', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.25), borderRadius: BorderRadius.circular(8)),
                  child: const Text('01:45:00', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.amberAccent, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: pct, minHeight: 12, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation(Colors.purpleAccent)),
            ),
            const SizedBox(height: 4),
            Text('$current / $target (${(pct * 100).round()}%) · Overlay Subathon', style: const TextStyle(fontSize: 10.5, color: Colors.white70)),
          ],
        ),
      );
    }

    // Overlay Néon / Coroa Ouro VIP
    final isGold = overlayType == 'gold_vip';
    final accent = isGold ? const Color(0xFFFACC15) : const Color(0xFF38BDF8);
    return Container(
      height: 95,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isGold ? [const Color(0xFF261D06), const Color(0xFF3D2E0A)] : [const Color(0xFF09183D), const Color(0xFF102A66)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${isGold ? '👑' : '⚡'} $title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accent)),
              Text('$current / $target (${(pct * 100).round()}%)', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: pct, minHeight: 12, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(accent)),
          ),
        ],
      ),
    );
  }

  // 6A. Janela Exclusiva de Simulação Ao Vivo em OFF (Botão PLAY ▶️ na Meta)
  void _openGoalExclusiveSimulationWindow(Map<String, dynamic> goal) {
    final String overlayType = goal['overlayType'] ?? 'rocket';
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
                Expanded(child: Text('Simulador de Meta Ao Vivo (OFF)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
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
                        activeColor: Colors.amberAccent,
                        onChanged: (v) async {
                          setSimState(() => simulatedPct = v);
                          if (v >= 0.99) {
                            await _playAudioSafe('https://google.com');
                          }
                        },
                      ),
                    ),
                    Text('${(simulatedPct * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
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
                        await _playAudioSafe('https://google.com');
                        if (next >= 1.0) {
                          await _playAudioSafe('https://google.com');
                        }
                      },
                      child: const Text('+15% Ação', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () async {
                        setSimState(() => simulatedPct = 1.0);
                        await _playAudioSafe('https://google.com');
                      },
                      child: const Text('🎆 Simular 100% Meta Batida!', style: TextStyle(color: Colors.white, fontSize: 12)),
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

  // 6B. Janela de Personalização da Meta & Escolha Visual do Overlay (Botão LÁPIS ✏️)
  void _openGoalEditAndOverlayPicker(Map<String, dynamic> goal) {
    final titleCtrl = TextEditingController(text: goal['title']);
    final targetCtrl = TextEditingController(text: '${goal['target']}');
    String chosenOverlayType = goal['overlayType'] ?? 'rocket';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final previewTarget = int.tryParse(targetCtrl.text.trim()) ?? 1000;
          final previewCurrent = (previewTarget * 0.65).round();

          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✏️ Configurar Meta & Escolher Overlay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 10),
                  // Pré-visualização imediata do overlay escolhido
                  _buildSelectedGoalOverlayGraphic(chosenOverlayType, 0.65, titleCtrl.text, previewCurrent, previewTarget),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    onChanged: (_) => setModalState(() {}),
                    decoration: const InputDecoration(labelText: 'Título da Meta', isDense: true),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setModalState(() {}),
                    decoration: const InputDecoration(labelText: 'Objetivo Numérico', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  const Text('Escolhe o Overlay Exclusivo para esta Meta:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 6),
                  ...DefaultMediaLibrary.goalOverlaysCatalog.map((ov) {
                    final sel = chosenOverlayType == ov['type'];
                    return Card(
                      color: sel ? const Color(0xFF122E73) : const Color(0xFF0B1636),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: sel ? const Color(0xFF38BDF8) : Colors.white12, width: sel ? 1.8 : 1),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(sel ? Icons.check_circle : Icons.radio_button_unchecked, color: sel ? const Color(0xFF38BDF8) : Colors.white54),
                        title: Text(ov['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(ov['desc']!, style: const TextStyle(fontSize: 11, color: Colors.white60)),
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
                      child: const Text('Aplicar Overlay à Meta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
  void _openAddPresentPngPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎁 Adicionar Presente TikTok (PNG)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85),
                  itemCount: DefaultMediaLibrary.fullTikTokPngSelectableList.length,
                  itemBuilder: (ctx, i) {
                    final item = DefaultMediaLibrary.fullTikTokPngSelectableList[i];
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
                            'sound': 'https://google.com',
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
                            Image.network(item['png'], width: 46, height: 46, fit: BoxFit.contain),
                            const SizedBox(height: 6),
                            Text(item['name'], textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  // Cartão Visual Uniforme (Tocar na Imagem abre logo a Biblioteca de Imagens!)
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
                             // 1. PRESENTES (Com Mensagem Personalizada {user} + Som + Voz Própria)
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
                      onPressed: _openAddPresentPngPicker,
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                      label: const Text('+ Adicionar Presente (PNG TikTok)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                // 2. ALERTAS (Com Mensagem Personalizada {user} + Som + Voz Própria)
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
                        onDelete: () => setState(() => widget.alertsList.removeAt(idx)),
                        onTapImage: () => _openQuickImagePicker(al['media'], (newImg) => setState(() => al['media'] = newImg)),
                        onEdit: () => _openRichCustomizer(
                          title: al['name'],
                          initialMedia: al['media'],
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
                          final rawMsg = (al['customMessage'] == null || al['customMessage'].toString().trim().isEmpty) ? defaultMsg : al['customMessage'].toString();
                          final spokenMsg = rawMsg.replaceAll('{user}', 'Hélder').replaceAll('{nome}', 'Hélder');
                          _openOfflinePreview(
                            title: al['name'],
                            mediaUrl: al['media'],
                            soundUrl: al['sound'] ?? '',
                            customVoicePath: al['customVoicePath'],
                            message: spokenMsg,
                          );
                          if (!hasVoice && (al['ttsThank'] ?? true) == true) {
                            widget.onSpeakVoice(spokenMsg);
                          }
                        },
                        onToggleEnabled: (v) => setState(() => al['enabled'] = v),
                      );
                    }),
                  ],
                ),
                // 3. METAS COM OVERLAY ESCOLHIDO DESENHADO NO CARTÃO + PLAY EXCLUSIVO
                ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () {
                        setState(() {
                          widget.goalsList.add({
                            'id': 'm_${DateTime.now().millisecondsSinceEpoch}',
                            'title': 'Nova Meta da Live',
                            'target': 1000,
                            'current': 450,
                            'overlayType': 'rocket',
                            'enabled': true,
                          });
                        });
                      },
                      icon: const Icon(Icons.add_chart, color: Colors.white),
                      label: const Text('+ Adicionar Meta com Overlay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    ...widget.goalsList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final goal = entry.value;
                      final pct = ((goal['current'] as int) / ((goal['target'] as int) == 0 ? 1 : (goal['target'] as int))).clamp(0.0, 1.0);
                      final ovType = goal['overlayType'] ?? 'rocket';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: _neonCard(),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => setState(() => widget.goalsList.removeAt(idx)),
                                ),
                                Expanded(
                                  child: Text(
                                    DefaultMediaLibrary.goalOverlaysCatalog.firstWhere((e) => e['type'] == ovType, orElse: () => {'name': 'Overlay Meta'})['name']!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                                  tooltip: 'Escolher Overlay & Editar',
                                  onPressed: () => _openGoalEditAndOverlayPicker(goal),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 24),
                                  tooltip: 'Simular Meta Ao Vivo (OFF)',
                                  onPressed: () => _openGoalExclusiveSimulationWindow(goal),
                                ),
                                Switch(
                                  activeColor: Colors.white,
                                  activeTrackColor: const Color(0xFF1E78FF),
                                  value: goal['enabled'] == true,
                                  onChanged: (v) => setState(() => goal['enabled'] = v),
                                ),
                              ],
                            ),
                            _buildSelectedGoalOverlayGraphic(ovType, pct, goal['title'], goal['current'], goal['target']),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                // 4. CHAT TTS
                widget.chatTtsTabContent,
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _RocketGoalPainter extends CustomPainter {
  final double progress;
  _RocketGoalPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white54;
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 1.5, starPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.15), 2.0, starPaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.55), 1.5, starPaint);
    canvas.drawCircle(Offset(size.width * 0.5, 10), 8, Paint()..color = const Color(0xFFFDE047));

    final rocketY = (size.height - 22) - ((size.height - 36) * progress);
    final cx = size.width * 0.5;

    if (progress > 0.02) {
      final flamePath = Path()
        ..moveTo(cx - 5, rocketY + 14)
        ..lineTo(cx + 5, rocketY + 14)
        ..lineTo(cx, rocketY + 24 + (sin(progress * 20) * 3))
        ..close();
      canvas.drawPath(flamePath, Paint()..color = Colors.orangeAccent);
    }

    final bodyPath = Path()
      ..moveTo(cx, rocketY - 12)
      ..lineTo(cx + 8, rocketY + 6)
      ..lineTo(cx + 8, rocketY + 14)
      ..lineTo(cx - 8, rocketY + 14)
      ..lineTo(cx - 8, rocketY + 6)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = Colors.white);

    final nosePath = Path()
      ..moveTo(cx, rocketY - 12)
      ..lineTo(cx + 5, rocketY - 3)
      ..lineTo(cx - 5, rocketY - 3)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = Colors.redAccent);
    canvas.drawCircle(Offset(cx, rocketY + 4), 3, Paint()..color = const Color(0xFF38BDF8));
  }

  @override
  bool shouldRepaint(covariant _RocketGoalPainter oldDelegate) => oldDelegate.progress != progress;
}

class _VintageGasPumpPainter extends CustomPainter {
  final double progress;
  _VintageGasPumpPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final bodyRect = RRect.fromRectAndRadius(Rect.fromLTWH(8, 12, size.width - 16, size.height - 14), const Radius.circular(8));
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFFDC2626));
    canvas.drawRRect(bodyRect, Paint()..color = Colors.amberAccent..style = PaintingStyle.stroke..strokeWidth = 1.8);
    canvas.drawCircle(Offset(size.width * 0.5, 9), 7, Paint()..color = Colors.amberAccent);

    final tankRect = Rect.fromLTWH(14, 22, size.width - 28, size.height - 32);
    canvas.drawRect(tankRect, Paint()..color = const Color(0xFF1E1B18));

    final fillHeight = tankRect.height * progress;
    final fuelRect = Rect.fromLTWH(tankRect.left, tankRect.bottom - fillHeight, tankRect.width, fillHeight);
    canvas.drawRect(fuelRect, Paint()..color = progress >= 1.0 ? Colors.greenAccent : Colors.amber);
  }

  @override
  bool shouldRepaint(covariant _VintageGasPumpPainter oldDelegate) => oldDelegate.progress != progress;
}

class _FuseDynamitePainter extends CustomPainter {
  final double progress;
  _FuseDynamitePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final dynamiteX = size.width - 42;
    final cy = size.height * 0.55;

    final dynRect = RRect.fromRectAndRadius(Rect.fromLTWH(dynamiteX, cy - 11, 34, 22), const Radius.circular(5));
    canvas.drawRRect(dynRect, Paint()..color = Colors.redAccent);
    canvas.drawLine(Offset(dynamiteX + 10, cy - 11), Offset(dynamiteX + 10, cy + 11), Paint()..color = Colors.black..strokeWidth = 2);
    canvas.drawLine(Offset(dynamiteX + 24, cy - 11), Offset(dynamiteX + 24, cy + 11), Paint()..color = Colors.black..strokeWidth = 2);

    final burnX = 8 + ((dynamiteX - 12) * progress);
    canvas.drawLine(Offset(8, cy), Offset(dynamiteX, cy), Paint()..color = Colors.white24..strokeWidth = 3);
    canvas.drawLine(Offset(burnX, cy), Offset(dynamiteX, cy), Paint()..color = Colors.amber.shade200..strokeWidth = 3);

    if (progress >= 1.0) {
      canvas.drawCircle(Offset(dynamiteX + 16, cy), 20, Paint()..color = Colors.orangeAccent.withOpacity(0.5));
      canvas.drawCircle(Offset(dynamiteX + 16, cy), 12, Paint()..color = Colors.yellowAccent);
      final sparkPaint = Paint()..color = Colors.cyanAccent..strokeWidth = 2;
      canvas.drawLine(Offset(dynamiteX, cy - 18), Offset(dynamiteX - 10, cy - 26), sparkPaint);
      canvas.drawLine(Offset(dynamiteX + 28, cy - 16), Offset(dynamiteX + 36, cy - 25), sparkPaint);
    } else {
      canvas.drawCircle(Offset(burnX, cy), 5, Paint()..color = Colors.orangeAccent);
      canvas.drawCircle(Offset(burnX, cy), 2.5, Paint()..color = Colors.yellow);
    }
  }

  @override
  bool shouldRepaint(covariant _FuseDynamitePainter oldDelegate) => oldDelegate.progress != progress;
}
