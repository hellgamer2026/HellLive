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

class DefaultMediaLibrary {
  static final List<Map<String, dynamic>> tiktokGiftsCatalog = [
    {
      'id': 'g1',
      'name': 'Rosa (Rose)',
      'coins': 1,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://flaticon.com',
      'sound': 'https://google.com',
    },
    {
      'id': 'g2',
      'name': 'TikTok / GG',
      'coins': 1,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://flaticon.com',
      'sound': 'https://google.com',
    },
    {
      'id': 'g3',
      'name': 'Coração com Dedos',
      'coins': 5,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://flaticon.com',
      'sound': 'https://google.com',
    },
    {
      'id': 'g4',
      'name': 'Perfume',
      'coins': 20,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://flaticon.com',
      'sound': 'https://google.com',
    },
    {
      'id': 'g5',
      'name': 'Coroa Imperial',
      'coins': 99,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://flaticon.com',
      'sound': 'https://google.com',
    },
    {
      'id': 'g6',
      'name': 'Chuva de Dinheiro',
      'coins': 500,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://flaticon.com',
      'sound': 'https://google.com',
    },
    {
      'id': 'g7',
      'name': 'Foguete Espacial',
      'coins': 2000,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://flaticon.com',
      'sound': 'https://google.com',
    },
    {
      'id': 'g8',
      'name': 'Leão Rei (Lion)',
      'coins': 29999,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': 'https://flaticon.com',
      'sound': 'https://google.com',
    },
  ];

  static final List<Map<String, dynamic>> fullTikTokPngSelectableList = [
    {'name': 'Rosa (Rose)', 'coins': 1, 'png': 'https://flaticon.com'},
    {'name': 'TikTok', 'coins': 1, 'png': 'https://flaticon.com'},
    {'name': 'GG', 'coins': 1, 'png': 'https://flaticon.com'},
    {'name': 'Coração', 'coins': 5, 'png': 'https://flaticon.com'},
    {'name': 'Café Espresso', 'coins': 10, 'png': 'https://flaticon.com'},
    {'name': 'Perfume', 'coins': 20, 'png': 'https://flaticon.com'},
    {'name': 'Doughnut', 'coins': 30, 'png': 'https://flaticon.com'},
    {'name': 'Coroa', 'coins': 99, 'png': 'https://flaticon.com'},
    {'name': 'Chapéu Cowboy', 'coins': 100, 'png': 'https://flaticon.com'},
    {'name': 'Óculos Sol VIP', 'coins': 199, 'png': 'https://flaticon.com'},
    {'name': 'Troféu Campeão', 'coins': 299, 'png': 'https://flaticon.com'},
    {'name': 'Chuva de Dinheiro', 'coins': 500, 'png': 'https://flaticon.com'},
    {'name': 'Diamante Azul', 'coins': 1000, 'png': 'https://flaticon.com'},
    {'name': 'Foguete Espacial', 'coins': 2000, 'png': 'https://flaticon.com'},
    {'name': 'Carro Desportivo', 'coins': 5000, 'png': 'https://flaticon.com'},
    {'name': 'Castelo Real', 'coins': 10000, 'png': 'https://flaticon.com'},
    {'name': 'Leão Rei (Lion)', 'coins': 29999, 'png': 'https://flaticon.com'},
    {'name': 'Universo TikTok', 'coins': 34999, 'png': 'https://flaticon.com'},
  ];

  static final List<Map<String, String>> builtInSounds = [
    {'name': 'Aplausos Plateia', 'url': 'https://google.com'},
    {'name': 'Moeda / Vitória', 'url': 'https://google.com'},
    {'name': 'Buzina Épica', 'url': 'https://google.com'},
    {'name': 'Sino de Alerta', 'url': 'https://google.com'},
    {'name': 'Tambor Suspense', 'url': 'https://google.com'},
    {'name': 'Foguetes Festa', 'url': 'https://google.com'},
    {'name': 'Laser Sci-Fi', 'url': 'https://google.com'},
    {'name': 'Level Up / Pop', 'url': 'https://google.com'},
  ];

  static final List<Map<String, String>> builtInGifsAndPngs = [
    {'name': 'Chuva de Moedas (GIF)', 'url': 'https://giphy.com'},
    {'name': 'Leão Rugindo (GIF)', 'url': 'https://giphy.com'},
    {'name': 'Rosa Brilhante (GIF)', 'url': 'https://giphy.com'},
    {'name': 'Festa Néon (GIF)', 'url': 'https://giphy.com'},
    {'name': 'GG Vitória (GIF)', 'url': 'https://giphy.com'},
    {'name': 'Novo Seguidor (GIF)', 'url': 'https://giphy.com'},
    {'name': 'Coroa Dourada (PNG)', 'url': 'https://flaticon.com'},
    {'name': 'Troféu VIP (PNG)', 'url': 'https://flaticon.com'},
    {'name': 'Diamante Azul (PNG)', 'url': 'https://flaticon.com'},
    {'name': 'Fogo Épico (PNG)', 'url': 'https://flaticon.com'},
  ];

  static final List<Map<String, String>> royaltyFreeMusicRepo = [
    {'title': 'Lo-Fi Chill Café (Sem Copyright)', 'artist': 'HELL Beats', 'url': 'https://google.com'},
    {'title': 'Cyberpunk Synth Wave', 'artist': 'Néon Studio', 'url': 'https://google.com'},
    {'title': 'Arena Gaming Bass', 'artist': 'Pro Stream Audio', 'url': 'https://google.com'},
    {'title': 'Night Rain Relax', 'artist': 'Ambient Free', 'url': 'https://google.com'},
    {'title': 'Victory Celebration Loop', 'artist': 'Streamers Hub', 'url': 'https://google.com'},
  ];

  static final List<Map<String, dynamic>> tikfinityOverlayCategories = [
    {
      'category': 'Overlays de Meta',
      'items': [
        {'name': 'Meta de Likes (Likes Goal)', 'desc': 'Barra de progresso animada para likes da live', 'scene': 'goal_likes', 'previewType': 'bar'},
        {'name': 'Meta de Seguidores (Follows Goal)', 'desc': 'Contador visual para novos seguidores', 'scene': 'goal_follows', 'previewType': 'bar'},
        {'name': 'Meta de Espectadores (Viewer Count)', 'desc': 'Mostra o pico de audiência em tempo real', 'scene': 'goal_viewers', 'previewType': 'bar'},
        {'name': 'Meta de Moedas (Coins Earned)', 'desc': 'Progresso total de diamantes e moedas', 'scene': 'goal_coins', 'previewType': 'bar'},
        {'name': 'Meta de Subscritores (New Sub)', 'desc': 'Barra dedicada a novos assinantes', 'scene': 'goal_subs', 'previewType': 'bar'},
      ]
    },
    {
      'category': 'Overlay de Meta com Contagem Regressiva',
      'items': [
        {'name': 'Countdown Likes', 'desc': 'Meta de likes com relógio decrescente', 'scene': 'cd_likes', 'previewType': 'timer'},
        {'name': 'Countdown Follows', 'desc': 'Meta de seguidores com cronómetro', 'scene': 'cd_follows', 'previewType': 'timer'},
        {'name': 'Countdown Viewer Count', 'desc': 'Desafio de audiência contra o relógio', 'scene': 'cd_viewers', 'previewType': 'timer'},
        {'name': 'Countdown Coins Earned', 'desc': 'Subathon / Desafio de moedas com tempo', 'scene': 'cd_coins', 'previewType': 'timer'},
        {'name': 'Countdown New Sub', 'desc': 'Contagem regressiva para novos subs', 'scene': 'cd_subs', 'previewType': 'timer'},
      ]
    },
    {
      'category': 'Widgets Interativos & Sociais',
      'items': [
        {'name': 'Overlay da Roleta (Wheel)', 'desc': 'Exibe a roleta giratória em direto no OBS/Studio', 'scene': 'wheel', 'previewType': 'wheel'},
        {'name': 'Rotador de Redes Sociais', 'desc': 'Alterna automaticamente Instagram, Discord, YouTube e TikTok', 'scene': 'social_rotator', 'previewType': 'social'},
        {'name': 'Contagem de Seguidores Ao Vivo', 'desc': 'Contador digital em tempo real com animação', 'scene': 'follower_counter', 'previewType': 'counter'},
      ]
    },
    {
      'category': 'Overlays de Presentes & Ranking',
      'items': [
        {'name': 'Top Gift (Maior Presente)', 'desc': 'Destaca o utilizador que enviou o presente mais valioso', 'scene': 'top_gift', 'previewType': 'podium'},
        {'name': 'Top Streak (Mais Presentes)', 'desc': 'Destaca quem enviou a maior sequência de presentes', 'scene': 'top_streak', 'previewType': 'podium'},
      ]
    },
    {
      'category': 'Overlays Gráficos & Câmara',
      'items': [
        {'name': 'Webcam Frames (Molduras Câmara)', 'desc': 'Moldura néon iluminada para a tua câmara', 'scene': 'cam_frame', 'previewType': 'frame'},
        {'name': 'Overlays Completos HUD', 'desc': 'Layout completo de ecrã para gaming e conversa', 'scene': 'live', 'previewType': 'frame'},
        {'name': 'Chat Banners', 'desc': 'Faixa elegante para destacar mensagens do chat na tela', 'scene': 'chat_banner', 'previewType': 'banner'},
      ]
    },
  ];
}
