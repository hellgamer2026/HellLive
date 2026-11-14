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


 
