import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTranslations {
  static String t(String lang, String key) {
    final map = {
      'pt': {
        'actions': 'Ações',
        'donation': 'Donation',
        'music': 'Música',
        'interaction': 'Interações',
        'overlays': 'Galeria de Overlays',
        'stream_deck': 'Stream Deck Pro',
        'community': 'Comunidade Global',
        'faq': 'Dúvidas & Contacto',
        'about': 'Quem Somos Nós',
        'settings': 'Definições & Idioma',
      },
      'en': {
        'actions': 'Actions',
        'donation': 'Donation',
        'music': 'Music',
        'interaction': 'Interactions',
        'overlays': 'Overlays Gallery',
        'stream_deck': 'Stream Deck Pro',
        'community': 'Global Community',
        'faq': 'FAQ & Contact',
        'about': 'About Us',
        'settings': 'Settings & Language',
      },
      'es': {
        'actions': 'Acciones',
        'donation': 'Donation',
        'music': 'Música',
        'interaction': 'Interacciones',
        'overlays': 'Galería de Overlays',
        'stream_deck': 'Stream Deck Pro',
        'community': 'Comunidad Global',
        'faq': 'Dudas y Contacto',
        'about': 'Quiénes Somos',
        'settings': 'Ajustes e Idioma',
      },
    };
    return map[lang]?[key] ?? map['pt']![key] ?? key;
  }
}

class OnlineMediaHubService {
  // Pesquisa infinita em tempo real na API pública Iconify (200.000+ ícones e modelos 3D Fluent/Noto/Twemoji)
  static Future<List<Map<String, String>>> searchOnlineIcons3D(String query) async {
    final q = query.trim().isEmpty ? 'trophy crown fire heart rocket diamond lion gift star' : query.trim();
    try {
      final uri = Uri.parse('https://iconify.design{Uri.encodeComponent(q)}&limit=48');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final icons = List<String>.from(data['icons'] ?? []);
        return icons.map((iconId) {
          final parts = iconId.split(':');
          final prefix = parts.first;
          final name = parts.length > 1 ? parts[1] : iconId;
          final url = 'https://iconify.design';
          final cleanTitle = name.replaceAll('-', ' ').replaceAll('_', ' ');
          return {
            'name': '${cleanTitle[0].toUpperCase()}${cleanTitle.substring(1)} ($prefix)',
            'url': url,
          };
        }).toList();
      }
    } catch (_) {}
    return DefaultMediaLibrary.builtInGifsAndPngs;
  }
  
  // Pesquisa infinita de efeitos sonoros gratuitos em MP3 via Internet Archive Audio API
  static Future<List<Map<String, String>>> searchOnlineSounds(String query) async {
    final q = query.trim().isEmpty ? 'sound effect notification bell explosion applause' : '${query.trim()} sound effect';
    try {
      final uri = Uri.parse(
        'https://archive.org{Uri.encodeComponent('$q AND mediatype:audio AND format:VBR+MP3')}&fl[]=identifier,title&rows=30&page=1&output=json',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 9));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final docs = List<Map<String, dynamic>>.from(data['response']?['docs'] ?? []);
        final List<Map<String, String>> out = [];
        for (final d in docs) {
          final id = (d['identifier'] ?? '').toString();
          final title = (d['title'] ?? id).toString();
          if (id.isNotEmpty) {
            out.add({
              'name': title.length > 42 ? '${title.substring(0, 42)}...' : title,
              'cat': 'Online Archive',
              'url': 'https://archive.org',
            });
          }
        }
        if (out.isNotEmpty) return out;
      }
    } catch (_) {}
    return DefaultMediaLibrary.onlineSoundsRepository;
  }

  // Catálogo online extenso de Overlays de Metas (Estilo TikFinity) + persistência local na galeria
  static Future<List<Map<String, dynamic>>> fetchOnlineGoalOverlays() async {
    final remoteCatalog = List<Map<String, dynamic>>.from(DefaultMediaLibrary.onlineGoalOverlaysGallery);
    try {
      final uri = Uri.parse('https://githubusercontent.com');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic> && !remoteCatalog.any((e) => e['id'] == item['id'])) {
              remoteCatalog.insert(0, item);
            }
          }
        }
      }
    } catch (_) {}
    return remoteCatalog;
  }

  static Future<List<String>> getDownloadedGoalOverlayIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('hell_downloaded_goal_overlays') ?? ['ov_cyber_3d', 'ov_gold_3d', 'ov_rocket_3d'];
  }

  static Future<void> downloadGoalOverlayToGallery(Map<String, dynamic> overlay) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await getDownloadedGoalOverlayIds();
    final id = overlay['id'].toString();
    if (!ids.contains(id)) {
      ids.add(id);
      await prefs.setStringList('hell_downloaded_goal_overlays', ids);
    }
    final lottieUrl = (overlay['lottieUrl'] ?? '').toString();
    if (lottieUrl.startsWith('http')) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final ovDir = Directory('${dir.path}/hell_overlays');
        if (!ovDir.existsSync()) ovDir.createSync(recursive: true);
        final res = await http.get(Uri.parse(lottieUrl)).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final file = File('${ovDir.path}/$id.json');
          await file.writeAsBytes(res.bodyBytes);
        }
      } catch (_) {}
    }
  }
}

class DefaultMediaLibrary {
  // URLs reais em alta definição (Fluent 3D / Iconify CDN) e áudios MP3 reais distintos
  static final List<Map<String, dynamic>> tiktokGiftsCatalog = [
    {
      'id': 'g1',
      'name': 'Rosa 3D (Rose)',
      'coins': 1,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://iconify.design',
      'sound': 'https://google.com',
    },
    {
      'id': 'g2',
      'name': 'Fogo Épico 3D / GG',
      'coins': 1,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://iconify.design',
      'sound': 'https://google.com',
    },
    {
      'id': 'g3',
      'name': 'Coração Brilhante 3D',
      'coins': 5,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://iconify.design',
      'sound': 'https://google.com',
    },
    {
      'id': 'g4',
      'name': 'Troféu Campeão 3D',
      'coins': 99,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://iconify.design',
      'sound': 'https://google.com',
    },
    {
      'id': 'g5',
      'name': 'Coroa Imperial 3D',
      'coins': 199,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://iconify.design',
      'sound': 'https://google.com',
    },
    {
      'id': 'g6',
      'name': 'Chuva de Dinheiro 3D',
      'coins': 500,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://iconify.design',
      'sound': 'https://google.com',
    },
    {
      'id': 'g7',
      'name': 'Foguete Espacial 3D',
      'coins': 2000,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://iconify.design',
      'sound': 'https://google.com',
    },
    {
      'id': 'g8',
      'name': 'Leão Rei 3D (Lion)',
      'coins': 29999,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://iconify.design',
      'sound': 'https://google.com',
    },
  ];

  static final List<Map<String, dynamic>> fullTikTokPngSelectableList = [
    {'name': 'Rosa 3D (Rose)', 'coins': 1, 'png': 'https://iconify.design'},
    {'name': 'Fogo 3D', 'coins': 1, 'png': 'https://iconify.design'},
    {'name': 'GG Controle 3D', 'coins': 1, 'png': 'https://iconify.design'},
    {'name': 'Coração 3D', 'coins': 5, 'png': 'https://iconify.design'},
    {'name': 'Café Espresso 3D', 'coins': 10, 'png': 'https://iconify.design'},
    {'name': 'Pizza Suprema 3D', 'coins': 20, 'png': 'https://iconify.design'},
    {'name': 'Donut Glaceado 3D', 'coins': 30, 'png': 'https://iconify.design'},

