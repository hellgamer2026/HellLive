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
  static const String _f3d = 'https://githubusercontent.com';

  static final List<Map<String, dynamic>> tiktokGiftsCatalog = [
    {
      'id': 'g1',
      'name': 'Rosa (Rose)',
      'coins': 1,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': '$_f3d/Animals%20and%20Nature/Rose.png',
      'sound': 'https://google.com',
    },
    {
      'id': 'g2',
      'name': 'TikTok / GG',
      'coins': 1,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': '$_f3d/Activities/Video%20Game.png',
      'sound': 'https://google.com',
    },
    {
      'id': 'g3',
      'name': 'Coração com Dedos',
      'coins': 5,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': '$_f3d/Smilies/Sparkling%20Heart.png',
      'sound': 'https://google.com',
    },
    {
      'id': 'g4',
      'name': 'Perfume VIP',
      'coins': 20,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': '$_f3d/Objects/Gem%20Stone.png',
      'sound': 'https://google.com',
    },
    {
      'id': 'g5',
      'name': 'Coroa Imperial',
      'coins': 99,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': '$_f3d/Objects/Crown.png',
      'sound': 'https://google.com',
    },
    {
      'id': 'g6',
      'name': 'Chuva de Dinheiro',
      'coins': 500,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': '$_f3d/Objects/Money%20with%20Wings.png',
      'sound': 'https://google.com',
    },
    {
    
      'id': 'g7',
      'name': 'Foguete Espacial',
      'coins': 2000,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': '$_f3d/Travel%20and%20places/Rocket.png',
      'sound': 'https://google.com',
    },
    {
      'id': 'g8',
      'name': 'Leão Rei (Lion)',
      'coins': 29999,
      'enabled': true,
      'ttsThank': true,
      'customVoicePath': null,
      'png': '$_f3d/Animals%20and%20Nature/Lion.png',
      'sound': 'https://google.com',
    },
  ];

  static final List<Map<String, dynamic>> fullTikTokPngSelectableList = [
    {'name': 'Rosa (Rose)', 'coins': 1, 'png': '$_f3d/Animals%20and%20Nature/Rose.png'},
    {'name': 'GG Gaming', 'coins': 1, 'png': '$_f3d/Activities/Video%20Game.png'},
    {'name': 'Fogo Épico', 'coins': 1, 'png': '$_f3d/Travel%20and%20places/Fire.png'},
    {'name': 'Coração Brilhante', 'coins': 5, 'png': '$_f3d/Smilies/Sparkling%20Heart.png'},
    {'name': 'Café Espresso', 'coins': 10, 'png': '$_f3d/Food/Hot%20Beverage.png'},
    {'name': 'Doughnut', 'coins': 30, 'png': '$_f3d/Food/Doughnut.png'},
    {'name': 'Coroa Imperial', 'coins': 99, 'png': '$_f3d/Objects/Crown.png'},
    {'name': 'Chapéu Cowboy', 'coins': 100, 'png': '$_f3d/Smilies/Cowboy%20Hat%20Face.png'},
    {'name': 'Óculos Sol VIP', 'coins': 199, 'png': '$_f3d/Smilies/Smiling%20Face%20with%20Sunglasses.png'},
    {'name': 'Troféu Campeão', 'coins': 299, 'png': '$_f3d/Activities/Trophy.png'},
    {'name': 'Chuva de Dinheiro', 'coins': 500, 'png': '$_f3d/Objects/Money%20with%20Wings.png'},
    {'name': 'Diamante Azul', 'coins': 1000, 'png': '$_f3d/Objects/Gem%20Stone.png'},
    {'name': 'Foguete Espacial', 'coins': 2000, 'png': '$_f3d/Travel%20and%20places/Rocket.png'},
    {'name': 'Carro Desportivo', 'coins': 5000, 'png': '$_f3d/Travel%20and%20places/Racing%20Car.png'},
    {'name': 'Castelo Real', 'coins': 10000, 'png': '$_f3d/Travel%20and%20places/Castle.png'},
    {'name': 'Leão Rei (Lion)', 'coins': 29999, 'png': '$_f3d/Animals%20and%20Nature/Lion.png'},
    {'name': 'Dragão Mítico', 'coins': 34999, 'png': '$_f3d/Animals%20and%20Nature/Dragon.png'},
    {'name': 'Unicórnio Mágico', 'coins': 15000, 'png': '$_f3d/Animals%20and%20Nature/Unicorn.png'},
  ];

  static final List<Map<String, String>> builtInSounds = [
    {'name': 'Pop Bolha Rápido', 'cat': 'Notificação', 'url': 'https://google.com'},
    {'name': 'Aplausos & Celebração', 'cat': 'Vitória', 'url': 'https://google.com'},
    {'name': 'Rugido de Leão', 'cat': 'Épico', 'url': 'https://google.com'},
    {'name': 'Laser Sci-Fi', 'cat': 'Sci-Fi', 'url': 'https://google.com'},
    {'name': 'Sino Digital Alerta', 'cat': 'Notificação', 'url': 'https://google.com'},
    {'name': 'Buzina Cartoon', 'cat': 'Meme', 'url': 'https://google.com'},
    {'name': 'Apito & Tambor', 'cat': 'Meme', 'url': 'https://google.com'},
    {'name': 'Toque Madeira', 'cat': 'Gaming', 'url': 'https://google.com'},
  ];

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
    {'name': 'Moeda & Magia', 'cat': 'Gaming', 'url': 'https://google.com'},
    {'name': 'Rufar de Tambores', 'cat': 'Suspense', 'url': 'https://google.com'},
  ];

  static final List<Map<String, String>> builtInGifsAndPngs = [
    {'name': 'Festa & Confetis 3D', 'url': '$_f3d/Activities/Party%20Popper.png'},
    {'name': 'Leão Rugindo 3D', 'url': '$_f3d/Animals%20and%20Nature/Lion.png'},
    {'name': 'Rosa Brilhante 3D', 'url': '$_f3d/Animals%20and%20Nature/Rose.png'},
    {'name': 'Fogo Néon 3D', 'url': '$_f3d/Travel%20and%20places/Fire.png'},
    {'name': 'Comando Gaming 3D', 'url': '$_f3d/Activities/Video%20Game.png'},
    {'name': 'Estrela Dourada 3D', 'url': '$_f3d/Travel%20and%20places/Glowing%20Star.png'},
    {'name': 'Foguetão Espacial 3D', 'url': '$_f3d/Travel%20and%20places/Rocket.png'},
    {'name': 'Coroa Dourada 3D', 'url': '$_f3d/Objects/Crown.png'},
    {'name': 'Troféu VIP 3D', 'url': '$_f3d/Activities/Trophy.png'},
    {'name': 'Diamante Azul 3D', 'url': '$_f3d/Objects/Gem%20Stone.png'},
    {'name': 'Dinamite & Bomba 3D', 'url': '$_f3d/Objects/Bomb.png'},
    {'name': 'Sino de Alerta 3D', 'url': '$_f3d/Objects/Bell.png'},
  ];

   static final List<Map<String, String>> goalOverlaysCatalog = [
    {'id': 'ov_cyber_3d', 'name': 'Cyberpunk Reactor 3D (Néon Volumétrico)', 'type': 'cyber_3d', 'cat': 'Gaming / Sci-Fi', 'desc': 'Núcleo energético 3D com reflexos metálicos e pulso néon dinâmico'},
    {'id': 'ov_gold_3d', 'name': 'Ouro & Carbono VIP 3D (Luxo)', 'type': 'gold_3d', 'cat': 'VIP / Doações', 'desc': 'Barra chanfrada 3D em fibra de carbono e ouro polido com brilho especular'},
    {'id': 'ov_rocket_3d', 'name': 'Lançamento Orbital 3D (Foguetão Pro)', 'type': 'rocket_3d', 'cat': 'Interativo', 'desc': 'Telemetria espacial 3D com propulsão a plasma e altitude em tempo real'},
