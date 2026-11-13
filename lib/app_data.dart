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
    {'name': 'Aplausos Plateia', 'cat': 'Vitória', 'url': 'https://google.com'},
    {'name': 'Moeda / Vitória', 'cat': 'Gaming', 'url': 'https://google.com'},
    {'name': 'Buzina Épica', 'cat': 'Meme', 'url': 'https://google.com'},
    {'name': 'Sino de Alerta', 'cat': 'Notificação', 'url': 'https://google.com'},
    {'name': 'Tambor Suspense', 'cat': 'Meme', 'url': 'https://google.com'},
    {'name': 'Foguetes Festa', 'cat': 'Vitória', 'url': 'https://google.com'},
    {'name': 'Laser Sci-Fi', 'cat': 'Sci-Fi', 'url': 'https://google.com'},
    {'name': 'Level Up / Pop', 'cat': 'Gaming', 'url': 'https://google.com'},
  ];

  // Repositório Online Extenso de Sons Gratuitos (Estilo TikFinity Soundboard)
  static final List<Map<String, String>> onlineSoundsRepository = [
    {'name': 'Explosão Épica Dinamite', 'cat': 'Ação', 'url': 'https://google.com'},
    {'name': 'Fogos de Artifício Final', 'cat': 'Vitória', 'url': 'https://google.com'},
    {'name': 'Multidão a Vibrar Estádio', 'cat': 'Vitória', 'url': 'https://google.com'},
    {'name': 'Buzina de Caminhão Meme', 'cat': 'Meme', 'url': 'https://google.com'},
    {'name': 'Sirene Alerta Vermelho', 'cat': 'Alerta', 'url': 'https://google.com'},
    {'name': 'Boing Cartoon Engraçado', 'cat': 'Meme', 'url': 'https://google.com'},
    {'name': 'Cowbell Ritmo', 'cat': 'Meme', 'url': 'https://google.com'},
    {'name': 'Sino de Boxe Round', 'cat': 'Gaming', 'url': 'https://google.com'},
    {'name': 'Nave Espacial Descolar', 'cat': 'Sci-Fi', 'url': 'https://google.com'},
    {'name': 'Trovão Tempestade', 'cat': 'Ação', 'url': 'https://google.com'},
    {'name': 'Pop Bolha Rápido', 'cat': 'Notificação', 'url': 'https://google.com'},
    {'name': 'Rufar de Tambores', 'cat': 'Suspense', 'url': 'https://google.com'},
  ];

  static final List<Map<String, String>> builtInGifsAndPngs = [
    {'name': 'Chuva de Moedas (GIF)', 'url': 'https://giphy.com'},
    {'name': 'Leão Rugindo (GIF)', 'url': 'https://giphy.com'},
    {'name': 'Rosa Brilhante (GIF)', 'url': 'https://giphy.com'},
    {'name': 'Festa Néon (GIF)', 'url': 'https://giphy.com'},
    {'name': 'GG Vitória (GIF)', 'url': 'https://giphy.com'},
    {'name': 'Novo Seguidor (GIF)', 'url': 'https://giphy.com'},
    {'name': 'Foguetão Espacial (PNG)', 'url': 'https://flaticon.com'},
    {'name': 'Coroa Dourada (PNG)', 'url': 'https://flaticon.com'},
    {'name': 'Troféu VIP (PNG)', 'url': 'https://flaticon.com'},
    {'name': 'Diamante Azul (PNG)', 'url': 'https://flaticon.com'},
    {'name': 'Fogo Épico (PNG)', 'url': 'https://flaticon.com'},
    {'name': 'Dinamite & Bomba (PNG)', 'url': 'https://flaticon.com'},
  ];
 
  static final List<Map<String, String>> goalOverlaysCatalog = [
    {'id': 'ov_rocket', 'name': 'Foguetão Espacial (Sobe até à Lua)', 'type': 'rocket', 'desc': 'Foguetão animado que descola consoante a meta avança'},
    {'id': 'ov_gas', 'name': 'Bomba de Gasolina Vintage (Tanque)', 'type': 'gas', 'desc': 'Visor clássico de combustível que sobe até 100%'},
    {'id': 'ov_fuse', 'name': 'Rastilho & Dinamite (Explosão + Fogos)', 'type': 'fuse', 'desc': 'Pavio a arder até rebentar e lançar fogos de artifício'},
    {'id': 'ov_neon_bar', 'name': 'Barra Néon Cyber (Progresso Clássico)', 'type': 'neon_bar', 'desc': 'Barra iluminada néon azul com contador em tempo real'},
    {'id': 'ov_subathon', 'name': 'Subathon Countdown (Barra + Relógio)', 'type': 'subathon', 'desc': 'Meta combinada com contagem regressiva para maratonas'},
    {'id': 'ov_gold_vip', 'name': 'Coroa Ouro VIP (Meta de Apoios)', 'type': 'gold_vip', 'desc': 'Design dourado de luxo com coroa animada'},
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
