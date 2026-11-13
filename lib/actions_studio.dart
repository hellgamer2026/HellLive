import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:file_picker/file_picker.dart';
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

  // 1. Pré-Visualização Simulada em OFF (Exatamente como aparece na Live)
  void _openOfflinePreview({
    required String title,
    required String mediaUrl,
    required String soundUrl,
    String? customVoicePath,
    String? message,
  }) {
    if (customVoicePath != null) {
      widget.sfxPlayer.play(DeviceFileSource(customVoicePath));
    } else if (soundUrl.isNotEmpty) {
      widget.sfxPlayer.play(UrlSource(soundUrl));
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF04091A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF38BDF8), width: 2)),
        title: const Row(
          children: [
            Icon(Icons.visibility, color: Color(0xFF38BDF8)),
            SizedBox(width: 8),
            Expanded(child: Text('Pré-Visualização em OFF', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const RadialGradient(colors: [Color(0xFF152E6E), Color(0xFF050B1E)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Image.network(mediaUrl, width: 110, height: 110, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.bolt, size: 70, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 12),
                  Text(
                    message ?? 'Apoiante_VIP enviou $title!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text('Simulação local · Sem precisar de estar em live', style: TextStyle(fontSize: 11, color: Color(0xFF7DD3FC))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
              onPressed: () {
                if (customVoicePath != null) {
                  widget.sfxPlayer.play(DeviceFileSource(customVoicePath));
                } else if (soundUrl.isNotEmpty) {
                  widget.sfxPlayer.play(UrlSource(soundUrl));
                }
              },
              icon: const Icon(Icons.replay, color: Colors.white),
              label: const Text('Repetir Som & Animação', style: TextStyle(color: Colors.white)),
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
    );
  }

  // 2. Repositório Online de Sons Gratuitos (Para pesquisar e baixar para a biblioteca)
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
              height: 460,
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
                              tooltip: 'Ouvir em OFF',
                              onPressed: () async {
                                await widget.sfxPlayer.stop();
                                await widget.sfxPlayer.play(UrlSource(snd['url']!));
                              },
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
  // 3. Janela Completa de Personalização (Imagem/GIF + Gravar Voz + 1 Som Único + Pré-Visualização OFF)
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
    String? chosenSound = initialSound.isEmpty ? null : initialSound;
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
                          soundUrl: chosenSound ?? '',
                          customVoicePath: customVoicePath,
                        ),
                        icon: const Icon(Icons.visibility, size: 16, color: Colors.black),
                        label: const Text('Pré-Visualizar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('1. Alterar Imagem PNG ou GIF:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (v) => setModalState(() => mediaFilter = v),
                    decoration: const InputDecoration(hintText: 'Filtrar imagens PNG / GIFs da biblioteca...', prefixIcon: Icon(Icons.search), isDense: true, border: OutlineInputBorder()),
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
                                chosenSound = null;
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
                          onPressed: () => widget.sfxPlayer.play(DeviceFileSource(customVoicePath!)),
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
                      const Text('3. Escolher 1 Som (Toca em OFF):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF38BDF8))),
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
                    leading: Icon(chosenSound == null ? Icons.radio_button_checked : Icons.radio_button_off, color: chosenSound == null ? Colors.redAccent : Colors.white54),
                    title: const Text('Sem Som (Desativar áudio)', style: TextStyle(color: Colors.white70)),
                    onTap: () async {
                      await widget.sfxPlayer.stop();
                      setModalState(() => chosenSound = null);
                    },
                  ),
                  ...widget.sounds.map((s) {
                    final url = s['url']!;
                    final isSelected = chosenSound == url;
                    return ListTile(
                      dense: true,
                      leading: Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? const Color(0xFF38BDF8) : Colors.white54),
                      title: Text(s['name'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.volume_up, size: 18, color: Colors.greenAccent),
                        onPressed: () async {
                          await widget.sfxPlayer.stop();
                          await widget.sfxPlayer.play(UrlSource(url));
                        },
                      ),
                      onTap: () async {
                        setModalState(() {
                          chosenSound = url;
                          customVoicePath = null;
                        });
                        await widget.sfxPlayer.stop();
                        await widget.sfxPlayer.play(UrlSource(url));
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: () {
                      widget.sfxPlayer.stop();
                      onSave(chosenMedia, chosenSound ?? '', customVoicePath, ttsThank);
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

  // 4. Widget Visual das Metas Animadas Estilo TikFinity (Barra Néon, Foguetão, Bomba de Gasolina, Rastilho/Dinamite)
  Widget _buildAnimatedGoalWidget(String style, double pct, String title, int current, int target) {
    final completed = pct >= 1.0;

    if (style == 'Foguetão Espacial') {
      return Container(
        height: 82,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF04081A), Color(0xFF10255E)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🚀 $title', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('${(pct * 100).round()}% ($current/$target)', style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            LayoutBuilder(
              builder: (ctx, c) {
                final maxW = c.maxWidth - 36;
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(height: 6, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
                    Container(
                      height: 6,
                      width: maxW * pct,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.orangeAccent, Color(0xFF38BDF8)]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: (maxW * pct).clamp(0.0, maxW)),
                      child: Text(completed ? '🌌✨' : '🚀🔥', style: const TextStyle(fontSize: 22)),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    }

    if (style == 'Bomba de Gasolina Vintage') {
      return Container(
        height: 82,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1F1209), Color(0xFF3B1D0E)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amberAccent.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amberAccent, width: 1.5),
              ),
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    color: completed ? Colors.greenAccent : Colors.amber,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('⛽ $title', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                  const SizedBox(height: 4),
                  Text(
                    completed ? 'TANQUE CHEIO! META BATIDA!' : 'Depósito a ${(pct * 100).round()}% · $current / $target',
                    style: const TextStyle(fontSize: 11.5, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (style == 'Rastilho & Dinamite') {
      return Container(
        height: 82,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1E0B0B), Color(0xFF3B0D14)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🧨 $title', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(completed ? '🎆 BOOM! META BATIDA! 🎆' : 'Falta ${100 - (pct * 100).round()}%', style: const TextStyle(fontSize: 11, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(height: 5, color: Colors.brown.shade300),
                      FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(height: 5, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                Text(completed ? '💥🎆🎇' : '🔥🧨', style: const TextStyle(fontSize: 24)),
              ],
            ),
          ],
        ),
      );
    }

    // Estilo Padrão: Barra Néon
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('${(pct * 100).round()}% ($current/$target)', style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 11,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
          ),
        ),
      ],
    );
  }

  // 5. Personalizador & Simulador em OFF das Metas Animadas
  void _openGoalCustomizerAndSimulator(Map<String, dynamic> goal) {
    final titleCtrl = TextEditingController(text: goal['title']);
    final targetCtrl = TextEditingController(text: '${goal['target']}');
    final overlayUrlCtrl = TextEditingController(text: goal['overlayUrl'] ?? '');
    String selectedStyle = goal['style'] ?? 'Foguetão Espacial';
    double simulatedPct = ((goal['current'] as int) / ((goal['target'] as int) == 0 ? 1 : (goal['target'] as int))).clamp(0.0, 1.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08112B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final simTarget = int.tryParse(targetCtrl.text.trim()) ?? 1000;
          final simCurrent = (simTarget * simulatedPct).round();

          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎯 Personalizar & Simular Meta em OFF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                  const SizedBox(height: 10),
                  // Pré-visualização animada ao vivo em OFF
                  _buildAnimatedGoalWidget(selectedStyle, simulatedPct, titleCtrl.text, simCurrent, simTarget),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Simular Progresso:', style: TextStyle(fontSize: 11.5, color: Colors.white70)),
                      Expanded(
                        child: Slider(
                          value: simulatedPct,
                          min: 0.0,
                          max: 1.0,
                          activeColor: Colors.amberAccent,
                          onChanged: (v) async {
                            setModalState(() => simulatedPct = v);
                            if (v >= 0.99) {
                              await widget.sfxPlayer.stop();
                              await widget.sfxPlayer.play(UrlSource('https://google.com'));
                            }
                          },
                        ),
                      ),
                      Text('${(simulatedPct * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amberAccent)),
                    ],
                  ),
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
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: ['Barra Néon', 'Foguetão Espacial', 'Bomba de Gasolina Vintage', 'Rastilho & Dinamite'].contains(selectedStyle)
                        ? selectedStyle
                        : 'Foguetão Espacial',
                    dropdownColor: const Color(0xFF050B1E),
                    decoration: const InputDecoration(labelText: 'Tipo de Animação (Estilo TikFinity)', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'Barra Néon', child: Text('Barra Néon (Clássica)')),
                      DropdownMenuItem(value: 'Foguetão Espacial', child: Text('🚀 Foguetão Espacial (Sobe até à Meta)')),
                      DropdownMenuItem(value: 'Bomba de Gasolina Vintage', child: Text('⛽ Bomba de Gasolina Antiga (Enche o Tanque)')),
                      DropdownMenuItem(value: 'Rastilho & Dinamite', child: Text('🧨 Rastilho & Dinamite (Explosão + Fogos)')),
                    ],
                    onChanged: (v) => setModalState(() => selectedStyle = v ?? 'Foguetão Espacial'),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('Overlay Likes App', style: TextStyle(fontSize: 10.5)),
                        onPressed: () => setModalState(() => overlayUrlCtrl.text = 'https://onrender.com'),
                      ),
                      ActionChip(
                        label: const Text('Overlays Grátis Net', style: TextStyle(fontSize: 10.5)),
                        onPressed: () => launchUrl(Uri.parse('https://streamelements.com'), mode: LaunchMode.externalApplication),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: overlayUrlCtrl,
                    decoration: const InputDecoration(labelText: 'URL Overlay da Meta (App ou Net)', isDense: true),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 13)),
                      onPressed: () {
                        setState(() {
                          goal['title'] = titleCtrl.text.trim();
                          goal['target'] = simTarget;
                          goal['style'] = selectedStyle;
                          goal['overlayUrl'] = overlayUrlCtrl.text.trim();
                        });
                        widget.onStateChanged();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Guardar Meta & Estilo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
  // Cartão Visual Uniforme (Usado em Todos os Presentes e Todos os Alertas)
  Widget _buildUniformActionCard({
    required String mediaUrl,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback onDelete,
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
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF050B1E), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
            child: Image.network(mediaUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.bolt, color: Color(0xFF38BDF8))),
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
            tooltip: 'Pré-Visualizar em OFF',
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
                // 1. PRESENTES (Uniforme + PNG + Gravar Voz + Pré-Visualizar OFF + Switch Individual)
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
                      return _buildUniformActionCard(
                        mediaUrl: g['png'],
                        title: g['name'],
                        subtitle: hasVoice ? '🎙️ Voz gravada · ${g['coins']} moedas' : '${g['coins']} moedas',
                        isEnabled: g['enabled'] == true,
                        onDelete: () => setState(() => DefaultMediaLibrary.tiktokGiftsCatalog.removeAt(idx)),
                        onEdit: () => _openRichCustomizer(
                          title: g['name'],
                          initialMedia: g['png'],
                          initialSound: g['sound'] ?? '',
                          initialCustomVoice: g['customVoicePath'],
                          initialTtsThank: g['ttsThank'] ?? true,
                          showTtsOption: true,
                          onSave: (m, s, vPath, tts) => setState(() {
                            g['png'] = m;
                            g['sound'] = s;
                            g['customVoicePath'] = vPath;
                            g['ttsThank'] = tts;
                          }),
                        ),
                        onPlayPreview: () {
                          _openOfflinePreview(
                            title: g['name'],
                            mediaUrl: g['png'],
                            soundUrl: g['sound'] ?? '',
                            customVoicePath: g['customVoicePath'],
                          );
                          if (!hasVoice && g['ttsThank'] == true) {
                            widget.onSpeakVoice('Obrigado Apoiante pelo presente ${g['name']}!');
                          }
                        },
                        onToggleEnabled: (v) => setState(() => g['enabled'] = v),
                      );
                    }),
                  ],
                ),
                // 2. ALERTAS (Mesmo Aspeto Uniforme + Pré-Visualização OFF + Switch Individual)
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
                      return _buildUniformActionCard(
                        mediaUrl: al['media'],
                        title: al['name'],
                        subtitle: 'Gatilho em tempo real',
                        isEnabled: al['enabled'] == true,
                        onDelete: () => setState(() => widget.alertsList.removeAt(idx)),
                        onEdit: () => _openRichCustomizer(
                          title: al['name'],
                          initialMedia: al['media'],
                          initialSound: al['sound'] ?? '',
                          onSave: (m, s, vPath, _) => setState(() {
                            al['media'] = m;
                            al['sound'] = s;
                          }),
                        ),
                        onPlayPreview: () => _openOfflinePreview(
                          title: al['name'],
                          mediaUrl: al['media'],
                          soundUrl: al['sound'] ?? '',
                          message: 'Apoiante ativou: ${al['name']}!',
                        ),
                        onToggleEnabled: (v) => setState(() => al['enabled'] = v),
                      );
                    }),
                  ],
                ),
                // 3. METAS ANIMADAS ESTILO TIKFINITY (Foguetão, Bomba Gasolina, Rastilho/Explosão + Simulador OFF)
                ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF), padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () {
                        setState(() {
                          widget.goalsList.add({
                            'id': 'm_${DateTime.now().millisecondsSinceEpoch}',
                            'title': 'Nova Meta Animada',
                            'target': 1000,
                            'current': 350,
                            'style': 'Foguetão Espacial',
                            'overlayUrl': 'https://onrender.com',
                            'enabled': true,
                          });
                        });
                      },
                      icon: const Icon(Icons.add_chart, color: Colors.white),
                      label: const Text('+ Metas Animadas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    ...widget.goalsList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final goal = entry.value;
                      final pct = ((goal['current'] as int) / ((goal['target'] as int) == 0 ? 1 : (goal['target'] as int))).clamp(0.0, 1.0);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
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
                                  child: Text('Estilo: ${goal['style']}', style: const TextStyle(fontSize: 12, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                                  tooltip: 'Personalizar & Simular em OFF',
                                  onPressed: () => _openGoalCustomizerAndSimulator(goal),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.play_circle_fill, color: Color(0xFF38BDF8), size: 22),
                                  tooltip: 'Simular Meta em OFF',
                                  onPressed: () => _openGoalCustomizerAndSimulator(goal),
                                ),
                                Switch(
                                  activeColor: Colors.white,
                                  activeTrackColor: const Color(0xFF1E78FF),
                                  value: goal['enabled'] == true,
                                  onChanged: (v) => setState(() => goal['enabled'] = v),
                                ),
                              ],
                            ),
                            _buildAnimatedGoalWidget(goal['style'] ?? 'Barra Néon', pct, goal['title'], goal['current'], goal['target']),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                // 4. CHAT TTS (Preservado 100% intacto!)
                widget.chatTtsTabContent,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
