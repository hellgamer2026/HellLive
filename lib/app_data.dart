class AppTranslations {
  static String t(String lang, String key) {
    final map = {
      'pt': {
        'alerts': 'Alertas, Metas & Doações',
        'comments': 'Comentários & Vozes',
        'podium': 'Pódio Oficial',
        'interaction': 'Interação & Roleta',
        'studio': 'Estúdio & Marketplace',
        'stream_deck': 'Stream Deck Pro',
        'community': 'Comunidade Ao Vivo',
        'about': 'Quem Somos Nós',
        'settings': 'Definições & Idioma',
      },
      'en': {
        'alerts': 'Alerts, Goals & Donations',
        'comments': 'Comments & Voices',
        'podium': 'Official Podium',
        'interaction': 'Interaction & Wheel',
        'studio': 'Studio & Marketplace',
        'stream_deck': 'Stream Deck Pro',
        'community': 'Live Community',
        'about': 'About Us',
        'settings': 'Settings & Language',
      },
      'es': {
        'alerts': 'Alertas, Metas y Donaciones',
        'comments': 'Comentarios y Voces',
        'podium': 'Podio Oficial',
        'interaction': 'Interacción y Ruleta',
        'studio': 'Estudio y Marketplace',
        'stream_deck': 'Stream Deck Pro',
        'community': 'Comunidad en Vivo',
        'about': 'Quiénes Somos',
        'settings': 'Ajustes e Idioma',
      },
    };
    return map[lang]?[key] ?? map['pt']![key] ?? key;
  }
}

class DefaultMediaLibrary {
  static final List<Map<String, dynamic>> tiktokGiftsCatalog = [
    {'name': 'Rosa (Rose)', 'coins': 1, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'name': 'TikTok / GG', 'coins': 1, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'name': 'Coração com Dedos', 'coins': 5, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'name': 'Perfume / Rosa Ouro', 'coins': 20, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'name': 'Coroa Imperial', 'coins': 99, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'name': 'Chuva de Dinheiro', 'coins': 500, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'name': 'Foguete Espacial', 'coins': 2000, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
    {'name': 'Leão Rei (Lion)', 'coins': 29999, 'gif': 'https://giphy.com', 'sound': 'https://google.com'},
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

  static final List<Map<String, String>> overlayPresets = [
    {'name': 'Azul Néon Pro (Completo)', 'desc': 'Alertas + Pódio + Contador Likes + Barra Meta', 'scene': 'live'},
    {'name': 'Moldura Câmara Gaming', 'desc': 'Recorte iluminado azul ciano para webcam', 'scene': 'cam_frame'},
    {'name': 'Ecrã Início de Live', 'desc': 'Ecrã animado "A Live Vai Começar"', 'scene': 'starting'},
    {'name': 'Ecrã Pausa (Já Voltamos)', 'desc': 'Ideal para intervalos durante a transmissão', 'scene': 'brb'},
    {'name': 'Ecrã Fim de Transmissão', 'desc': 'Agradecimento final aos espectadores', 'scene': 'ending'},
  ];
}
