class AppTranslations {
  static String t(String lang, String key) {
    final map = {
      'pt': {
        'actions': 'Ações',
        'donation': 'Donation',
        'music': 'Música & Fundo',
        'interaction': 'Interação & Pódio',
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
        'music': 'Music & Background',
        'interaction': 'Interaction & Podium',
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
        'music': 'Música y Fondo',
        'interaction': 'Interacción y Podio',
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
    {'id': 'g1', 'name': 'Rosa (Rose)', 'coins': 1, 'enabled': true, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'id': 'g2', 'name': 'TikTok / GG', 'coins': 1, 'enabled': true, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'id': 'g3', 'name': 'Coração com Dedos', 'coins': 5, 'enabled': true, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'id': 'g4', 'name': 'Perfume / Rosa Ouro', 'coins': 20, 'enabled': true, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'id': 'g5', 'name': 'Coroa Imperial', 'coins': 99, 'enabled': true, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'id': 'g6', 'name': 'Chuva de Dinheiro', 'coins': 500, 'enabled': true, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'id': 'g7', 'name': 'Foguete Espacial', 'coins': 2000, 'enabled': true, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'id': 'g8', 'name': 'Leão Rei (Lion)', 'coins': 29999, 'enabled': true, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
  ];

  static final List<Map<String, String>> builtInSounds = [
    {'name': 'Aplausos Plateia', 'url': 'https://google.com'},
    {'name': 'Moeda / Vitória', 'url': 'https://google.com'},
    {'name': 'Buzina Épica', 'url': 'https://google.com'},
    {'name': 'Sino de Alerta', 'url': 'https://google.com'},
    {'name': 'Tambor Suspense', 'url': 'https://google.com'},
    {'name': 'Foguetes Festa', 'url': 'https://google.com'},
    {'name': 'Laser Sci-Fi', 'url': 'https://google.com'},
    {'name': 'Level Up / Power', 'url': 'https://google.com'},
  ];

  static final List<Map<String, String>> builtInGifs = [
    {'name': 'Chuva de Moedas', 'url': 'https://giphy.com'},
    {'name': 'Leão Rugindo', 'url': 'https://giphy.com'},
    {'name': 'Rosa Brilhante', 'url': 'https://giphy.com'},
    {'name': 'Festa Néon', 'url': 'https://giphy.com'},
    {'name': 'GG Vitória', 'url': 'https://giphy.com'},
    {'name': 'Novo Seguidor', 'url': 'https://giphy.com'},
    {'name': 'Coração Explodir', 'url': 'https://giphy.com'},
    {'name': 'Fogo Azul', 'url': 'https://giphy.com'},
  ];

  static final List<Map<String, dynamic>> wheelTemplates = [
    {
      'name': 'Desafios Gaming Pro',
      'theme': 'neon',
      'items': ['10 Flexões', 'Sem Mira 1 Ronda', 'Só Pistola', 'Jogar Invertido', 'Sensibilidade Máxima', 'Vitória Obrigatória']
    },
    {
      'name': 'Interação com o Chat',
      'theme': 'fire',
      'items': ['Escolher Música', 'Salve Especial', 'Seguir de Volta', 'Mod por 10 Min', 'Responder Verdade', 'Dupla na Próxima']
    },
    {
      'name': 'Prémios & Sorteios',
      'theme': 'toxic',
      'items': ['VIP no Canal', 'Destaque na Live', 'Escolha o Jogo', 'Desafio Surpresa', 'Roda Novamente', 'Grande Prémio!']
    },
  ];

  static final List<Map<String, dynamic>> tikfinityOverlayCategories = [
    {
      'category': 'Overlays de Meta',
      'items': [
        {'name': 'Meta de Likes (Likes Goal)', 'desc': 'Barra de progresso animada para likes da live', 'scene': 'goal_likes'},
        {'name': 'Meta de Seguidores (Follows Goal)', 'desc': 'Contador visual para novos seguidores', 'scene': 'goal_follows'},
        {'name': 'Meta de Espectadores (Viewer Count)', 'desc': 'Mostra o pico de audiência em tempo real', 'scene': 'goal_viewers'},
        {'name': 'Meta de Moedas (Coins Earned)', 'desc': 'Progresso total de diamantes e moedas', 'scene': 'goal_coins'},
        {'name': 'Meta de Subscritores (New Sub)', 'desc': 'Barra dedicada a novos assinantes', 'scene': 'goal_subs'},
      ]
    },
    {
      'category': 'Overlay de Meta com Contagem Regressiva',
      'items': [
        {'name': 'Countdown Likes', 'desc': 'Meta de likes com relógio decrescente', 'scene': 'cd_likes'},
        {'name': 'Countdown Follows', 'desc': 'Meta de seguidores com cronómetro', 'scene': 'cd_follows'},
        {'name': 'Countdown Viewer Count', 'desc': 'Desafio de audiência contra o relógio', 'scene': 'cd_viewers'},
        {'name': 'Countdown Coins Earned', 'desc': 'Subathon / Desafio de moedas com tempo', 'scene': 'cd_coins'},
        {'name': 'Countdown New Sub', 'desc': 'Contagem regressiva para novos subs', 'scene': 'cd_subs'},
      ]
    },
    {
      'category': 'Widgets Interativos & Sociais',
      'items': [
        {'name': 'Overlay da Roleta (Wheel)', 'desc': 'Exibe a roleta giratória em direto no OBS/Studio', 'scene': 'wheel'},
        {'name': 'Rotador de Redes Sociais', 'desc': 'Alterna automaticamente Instagram, Discord, YouTube e TikTok', 'scene': 'social_rotator'},
        {'name': 'Contagem de Seguidores Ao Vivo', 'desc': 'Contador digital em tempo real com animação', 'scene': 'follower_counter'},
      ]
    },
    {
      'category': 'Overlays de Presentes & Ranking',
      'items': [
        {'name': 'Top Gift (Maior Presente)', 'desc': 'Destaca o utilizador que enviou o presente mais valioso', 'scene': 'top_gift'},
        {'name': 'Top Streak (Mais Presentes)', 'desc': 'Destaca quem enviou a maior sequência de presentes', 'scene': 'top_streak'},
      ]
    },
    {
      'category': 'Overlays Gráficos & Câmara',
      'items': [
        {'name': 'Webcam Frames (Molduras Câmara)', 'desc': 'Moldura néon iluminada para a tua câmara', 'scene': 'cam_frame'},
        {'name': 'Overlays Completos HUD', 'desc': 'Layout completo de ecrã para gaming e conversa', 'scene': 'live'},
        {'name': 'Chat Banners', 'desc': 'Faixa elegante para destacar mensagens do chat na tela', 'scene': 'chat_banner'},
      ]
    },
  ];

  static List<Map<String, dynamic>> generate1119GiftsDatabase() {
    final baseNames = [
      'Rosa', 'TikTok', 'GG', 'Coração', 'Perfume', 'Coroa', 'Chuva de Dinheiro', 'Foguete', 'Leão',
      'Universo', 'Carro Desportivo', 'Fénix', 'Dragão', 'Castelo', 'Iate', 'Planeta', 'Diamante',
      'Troféu', 'Microfone Ouro', 'Panda', 'Gato Ninja', 'Cão Astronauta', 'Fogo Azul', 'Raio Néon',
      'Estrela Cadente', 'Pizza', 'Café', 'Gelado', 'Bolo Festa', 'Balão', 'Confetti', 'Guitarra',
      'Auscultadores', 'Comando Pro', 'Óculos VR', 'Ninja', 'Samurai', 'Cavaleiro', 'Rei', 'Rainha'
    ];
    final gifs = builtInGifs.map((g) => g['url']!).toList();
    return List.generate(1119, (i) {
      final base = baseNames[i % baseNames.length];
      final tier = (i ~/ baseNames.length) + 1;
      final coins = (i == 0) ? 1 : ((i % 50) + 1) * (tier > 5 ? 10 : 1);
      return {
        'id': 'tk_gift_${i + 1}',
        'number': i + 1,
        'name': tier == 1 ? base : '$base Pro #$tier',
        'coins': coins,
        'gif': gifs[i % gifs.length],
      };
    });
  }
}
