class AppTranslations {
  static String t(String lang, String key) {
    final map = {
      'pt': {
        'actions': 'Ações',
        'chat_tts': 'Chat TTS & Vozes',
        'donation': 'Donation',
        'music': 'Música & Playlists',
        'interaction': 'Interações',
        'overlays': 'Galeria de Overlays',
        'marketplace': 'Market Place',
        'creator_pro': 'Estúdio Criador PRO',
        'stream_deck': 'Stream Deck Pro',
        'community': 'Comunidade Global',
        'profile': 'Perfil, Privacidade & Segurança',
        'about': 'Quem Somos Nós & Ajuda',
        'settings': 'Definições & Idiomas',
      },
      'en': {
        'actions': 'Actions',
        'chat_tts': 'Chat TTS & Voices',
        'donation': 'Donations',
        'music': 'Music & Playlists',
        'interaction': 'Interactions',
        'overlays': 'Overlay Gallery',
        'marketplace': 'Market Place',
        'creator_pro': 'PRO Creator Studio',
        'stream_deck': 'Stream Deck Pro',
        'community': 'Global Community',
        'profile': 'Profile, Privacy & Security',
        'about': 'About Us & Support',
        'settings': 'Settings & Languages',
      },
      'es': {
        'actions': 'Acciones',
        'chat_tts': 'Chat TTS y Voces',
        'donation': 'Donaciones',
        'music': 'Música y Playlists',
        'interaction': 'Interacciones',
        'overlays': 'Galería de Overlays',
        'marketplace': 'Market Place',
        'creator_pro': 'Estudio Creador PRO',
        'stream_deck': 'Stream Deck Pro',
        'community': 'Comunidad Global',
        'profile': 'Perfil, Privacidad y Seguridad',
        'about': 'Quiénes Somos y Ayuda',
        'settings': 'Ajustes e Idiomas',
      },
    };
    return map[lang]?[key] ?? map['pt']![key] ?? key;
  }
}

class DefaultMediaLibrary {
  static const String _cdn = 'https://jsdelivr.net';

  static final List<Map<String, dynamic>> fullTikTokPngSelectableList = [
    {'name': 'Rosa', 'coins': 1, 'png': '$_cdn/1f339.png'},
    {'name': 'Coração TikTok', 'coins': 1, 'png': '$_cdn/2764.png'},
    {'name': 'GG', 'coins': 1, 'png': '$_cdn/1f3ae.png'},
    {'name': 'Fogo', 'coins': 5, 'png': '$_cdn/1f525.png'},
    {'name': 'Microfone', 'coins': 5, 'png': '$_cdn/1f3a4.png'},
    {'name': 'Panda', 'coins': 5, 'png': '$_cdn/1f43c.png'},
    {'name': 'Café Expresso', 'coins': 10, 'png': '$_cdn/2615.png'},
    {'name': 'Gelado', 'coins': 10, 'png': '$_cdn/1f366.png'},
    {'name': 'Óculos Escuros', 'coins': 15, 'png': '$_cdn/1f60e.png'},
    {'name': 'Perfume', 'coins': 20, 'png': '$_cdn/1f48e.png'},
    {'name': 'Donut', 'coins': 30, 'png': '$_cdn/1f369.png'},
    {'name': 'Coroa Real', 'coins': 99, 'png': '$_cdn/1f451.png'},
    {'name': 'Confetes Festa', 'coins': 100, 'png': '$_cdn/1f389.png'},
    {'name': 'Coração Mãos', 'coins': 100, 'png': '$_cdn/1f496.png'},
    {'name': 'Corgi Fofo', 'coins': 299, 'png': '$_cdn/1f436.png'},
    {'name': 'Luvas de Boxe', 'coins': 299, 'png': '$_cdn/1f94a.png'},
    {'name': 'Troféu Ouro', 'coins': 500, 'png': '$_cdn/1f3c6.png'},
    {'name': 'Diamante Azul', 'coins': 1000, 'png': '$_cdn/1f48e.png'},
    {'name': 'Galáxia', 'coins': 1000, 'png': '$_cdn/1f30c.png'},
    {'name': 'Foguetão Espacial', 'coins': 2000, 'png': '$_cdn/1f680.png'},
    {'name': 'Carro Desportivo', 'coins': 7000, 'png': '$_cdn/1f3ce.png'},
    {'name': 'Iate de Luxo', 'coins': 9888, 'png': '$_cdn/1f6e5.png'},
    {'name': 'Castelo Real', 'coins': 20000, 'png': '$_cdn/1f3f0.png'},
    {'name': 'Leão Rei', 'coins': 29999, 'png': '$_cdn/1f981.png'},
    {'name': 'Universo TikTok', 'coins': 34999, 'png': '$_cdn/1fa90.png'},
  ];

  static final List<Map<String, dynamic>> tiktokGiftsCatalog = [
    {'id': 'tk_rosa', 'name': 'Rosa', 'coins': 1, 'enabled': true, 'ttsThank': true, 'customVoicePath': null, 'png': '$_cdn/1f339.png', 'sound': ''},
    {'id': 'tk_gg', 'name': 'GG', 'coins': 1, 'enabled': true, 'ttsThank': true, 'customVoicePath': null, 'png': '$_cdn/1f3ae.png', 'sound': ''},
    {'id': 'tk_fogo', 'name': 'Fogo', 'coins': 5, 'enabled': true, 'ttsThank': true, 'customVoicePath': null, 'png': '$_cdn/1f525.png', 'sound': ''},
    {'id': 'tk_coroa', 'name': 'Coroa Real', 'coins': 99, 'enabled': true, 'ttsThank': true, 'customVoicePath': null, 'png': '$_cdn/1f451.png', 'sound': ''},
    {'id': 'tk_galaxia', 'name': 'Galáxia', 'coins': 1000, 'enabled': true, 'ttsThank': true, 'customVoicePath': null, 'png': '$_cdn/1f30c.png', 'sound': ''},
    {'id': 'tk_leao', 'name': 'Leão Rei', 'coins': 29999, 'enabled': true, 'ttsThank': true, 'customVoicePath': null, 'png': '$_cdn/1f981.png', 'sound': ''},
  ];

  static final List<Map<String, String>> builtInGifsAndPngs = [
    {'name': 'Festa & Confetes', 'url': '$_cdn/1f389.png'},
    {'name': 'Troféu Campeão', 'url': '$_cdn/1f3c6.png'},
    {'name': 'Estrela Brilhante', 'url': '$_cdn/1f31f.png'},
    {'name': 'Chama Néon', 'url': '$_cdn/1f525.png'},
    {'name': 'Coração Pulsante', 'url': '$_cdn/1f496.png'},
    {'name': 'Foguetão', 'url': '$_cdn/1f680.png'},
    {'name': 'Diamante', 'url': '$_cdn/1f48e.png'},
    {'name': 'Coroa VIP', 'url': '$_cdn/1f451.png'},
    {'name': 'Raio Elétrico', 'url': '$_cdn/26a1.png'},
    {'name': 'Mão a Acenar', 'url': '$_cdn/1f44b.png'},
    {'name': 'Sino de Alerta', 'url': '$_cdn/1f514.png'},
    {'name': 'Dinheiro / Apoio', 'url': '$_cdn/1f4b8.png'},
  ];
  static final List<Map<String, String>> builtInSounds = [
    {'name': 'Moeda & Brilho (Clássico)', 'url': 'https://pixabay.com'},
    {'name': 'Notificação Cristalina', 'url': 'https://pixabay.com'},
    {'name': 'Aplausos da Plateia', 'url': 'https://pixabay.com'},
    {'name': 'Vitória Épica (Level Up)', 'url': 'https://pixabay.com'},
    {'name': 'Sino de Caixa Registadora', 'url': 'https://pixabay.com'},
    {'name': 'Buzina de Festa (Airhorn)', 'url': 'https://pixabay.com'},
  ];

  static final List<Map<String, String>> onlineSoundsRepository = [
    {'name': 'Moeda & Brilho (Clássico)', 'cat': 'Presentes', 'url': 'https://pixabay.com'},
    {'name': 'Notificação Cristalina', 'cat': 'Alertas', 'url': 'https://pixabay.com'},
    {'name': 'Aplausos da Plateia', 'cat': 'Festa', 'url': 'https://pixabay.com'},
    {'name': 'Vitória Épica (Level Up)', 'cat': 'Metas', 'url': 'https://pixabay.com'},
    {'name': 'Sino de Caixa Registadora', 'cat': 'Donation', 'url': 'https://pixabay.com'},
    {'name': 'Buzina de Festa (Airhorn)', 'cat': 'Efeitos', 'url': 'https://pixabay.com'},
    {'name': 'Explosão Cinemática', 'cat': 'Ação', 'url': 'https://pixabay.com'},
    {'name': 'Tambor de Suspense (Drumroll)', 'cat': 'Roleta', 'url': 'https://pixabay.com'},
  ];

  static final List<Map<String, String>> goalOverlaysCatalog = [
    {'type': 'tiktok_capsule', 'brand': 'TikTok Live Studio', 'name': 'Cápsula Oficial TikTok Studio', 'desc': 'Barra transparente com ícone à esquerda e contador limpo.'},
    {'type': 'tiktok_heart', 'brand': 'TikTok Live Studio', 'name': 'Barra Coração & Likes Studio', 'desc': 'Design nativo rosa/ciano com progresso arredondado.'},
    {'type': 'tiktok_gift', 'brand': 'TikTok Live Studio', 'name': 'Barra Presentes & Diamantes', 'desc': 'Widget compacto estilo TikTok Live Studio.'},
    {'type': 'tikfinity_neon', 'brand': 'TikFinity PRO', 'name': 'Barra Néon Cyber Segmentada', 'desc': 'Blocos luminosos 3D com brilho azul elétrico.'},
    {'type': 'tikfinity_gold', 'brand': 'TikFinity PRO', 'name': 'Barra Ouro VIP 3D', 'desc': 'Acabamento dourado metálico para metas de apoios.'},
    {'type': 'tikfinity_subathon', 'brand': 'TikFinity PRO', 'name': 'Barra Subathon & Fogo', 'desc': 'Gradiente plasma dinâmico para desafios ao vivo.'},
  ];
  static final List<Map<String, String>> royaltyFreeMusicRepo = [
    {'title': 'Cyberpunk Night Drive (Lo-Fi)', 'artist': 'HELL Beats · Sem Direitos Autorais', 'url': 'https://pixabay.com'},
    {'title': 'Synthwave Stream Energy', 'artist': 'Neon Pulse · Livre para Lives', 'url': 'https://pixabay.com'},
    {'title': 'Chill Gaming Vibes', 'artist': 'Studio Flow · Sem Copyright', 'url': 'https://pixabay.com'},
    {'title': 'Epic Arena Intro', 'artist': 'Pro Stream Audio · Grátis', 'url': 'https://pixabay.com'},
  ];

  static final List<Map<String, String>> profileBannersCatalog = [
    {'id': 'bn_cyber', 'name': 'Néon Cyber Azul 3D', 'type': 'Estático HD', 'primary': '0xFF0EA5E9', 'secondary': '0xFF1E3A8A'},
    {'id': 'bn_fire', 'name': 'Chama Épica Streamer', 'type': 'Animado', 'primary': '0xFFF97316', 'secondary': '0xFF7F1D1D'},
    {'id': 'bn_gold', 'name': 'Ouro VIP Exclusivo', 'type': 'Estático HD', 'primary': '0xFFFACC15', 'secondary': '0xFF422006'},
    {'id': 'bn_matrix', 'name': 'Matrix Esmeralda PRO', 'type': 'Animado', 'primary': '0xFF10B981', 'secondary': '0xFF064E3B'},
    {'id': 'bn_purple', 'name': 'Galáxia Twitch & TikTok', 'type': 'Animado', 'primary': '0xFFA855F7', 'secondary': '0xFF3B0764'},
  ];

  static final List<Map<String, dynamic>> tikfinityOverlayCategories = [
    {
      'category': '🎨 Overlays HUD & Molduras 3D',
      'items': [
        {'name': 'HUD Câmara Néon 3D', 'desc': 'Moldura transparente com brilho azul elétrico para OBS.', 'scene': 'hud_cam', 'previewType': 'frame', 'price': 0.0},
        {'name': 'Barra de Metas TikTok Studio', 'desc': 'Cápsula oficial transparente com progresso ao vivo.', 'scene': 'goal_bar', 'previewType': 'bar', 'price': 0.0},
        {'name': 'Temporizador Subathon Sem Fundo', 'desc': 'Contagem regressiva transparente ("Tu controlas o tempo!").', 'scene': 'timer_hud', 'previewType': 'timer', 'price': 0.0},
        {'name': 'Roleta 3D Interativa', 'desc': 'Roda giratória 3D com prémios e efeitos sonoros.', 'scene': 'wheel_3d', 'previewType': 'wheel', 'price': 0.0},
        {'name': 'Pódio Top Apoiantes (Foto + Nome)', 'desc': 'Classificação em tempo real dos maiores apoiantes.', 'scene': 'podium_top', 'previewType': 'podium', 'price': 0.0},
      ],
    },
  ];
}
