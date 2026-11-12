class AppTranslations {
  static String t(String lang, String key) {
    final map = {
      'pt': {
        'live_status': 'Estado da Live',
        'tap_connect': 'Tocar para Ligar Multiplataforma',
        'alerts': 'Alertas & Regras (Likes / Presentes)',
        'sounds': 'Biblioteca de Sons & GIFs Online',
        'voices': 'Comentários & Vozes Reais',
        'podium_wheel': 'Pódio Oficial & Roleta Interativa',
        'studio': 'Estúdio de Overlays, Metas & Doações',
        'stream_deck': 'Stream Deck & Emparelhamento',
        'community': 'Comunidade Ao Vivo (Mundo)',
        'about': 'Quem Somos Nós (HELL Live)',
        'settings': 'Definições & Idioma',
      },
      'en': {
        'live_status': 'Live Status',
        'tap_connect': 'Tap to Connect Multi-Platform',
        'alerts': 'Alerts & Rules (Likes / Gifts)',
        'sounds': 'Online Sounds & GIFs Library',
        'voices': 'Chat TTS & Real Voices',
        'podium_wheel': 'Official Podium & Interactive Wheel',
        'studio': 'Overlay Studio, Goals & Donations',
        'stream_deck': 'Stream Deck & Device Pairing',
        'community': 'Live Community (World Map)',
        'about': 'About Us (HELL Live)',
        'settings': 'Settings & App Language',
      },
      'es': {
        'live_status': 'Estado del Directo',
        'tap_connect': 'Tocar para Conectar Multiplataforma',
        'alerts': 'Alertas y Reglas (Likes / Regalos)',
        'sounds': 'Biblioteca de Sonidos y GIFs',
        'voices': 'Comentarios y Voces Reales',
        'podium_wheel': 'Podio Oficial y Ruleta Interactiva',
        'studio': 'Estudio de Overlays, Metas y Donaciones',
        'stream_deck': 'Stream Deck y Emparejamiento',
        'community': 'Comunidad en Vivo (Mundo)',
        'about': 'Quiénes Somos (HELL Live)',
        'settings': 'Ajustes e Idioma de la App',
      },
    };
    return map[lang]?[key] ?? map['pt']![key] ?? key;
  }
}

class DefaultMediaLibrary {
  static final List<Map<String, String>> builtInSounds = [
    {'name': 'Aplausos Plateia', 'cat': 'Eventos', 'url': 'https://google.com'},
    {'name': 'Moeda / Vitória', 'cat': 'Presentes', 'url': 'https://google.com'},
    {'name': 'Buzina Épica', 'cat': 'Eventos', 'url': 'https://google.com'},
    {'name': 'Sino de Alerta', 'cat': 'Presentes', 'url': 'https://google.com'},
    {'name': 'Tambor Suspense', 'cat': 'Eventos', 'url': 'https://google.com'},
    {'name': 'Foguetes Festa', 'cat': 'Presentes', 'url': 'https://google.com'},
    {'name': 'Laser Sci-Fi', 'cat': 'Gaming', 'url': 'https://google.com'},
    {'name': 'Level Up / Power', 'cat': 'Gaming', 'url': 'https://google.com'},
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
}
