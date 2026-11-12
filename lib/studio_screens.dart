import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'app_data.dart';

BoxDecoration _studioCardDeco() => BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF1E429F), width: 1.2),
    );

class PodiumScreen extends StatefulWidget {
  final IO.Socket socket;
  final String roomName;
  final List<Map<String, dynamic>> topGifts;
  final List<Map<String, dynamic>> topLikes;

  const PodiumScreen({
    super.key,
    required this.socket,
    required this.roomName,
    required this.topGifts,
    required this.topLikes,
  });

  @override
  State<PodiumScreen> createState() => _PodiumScreenState();
}

class _PodiumScreenState extends State<PodiumScreen> {
  String _selectedStyle = 'neon';

  final List<Map<String, dynamic>> _podiumLibrary = [
    {'id': 'neon', 'name': 'Néon Cyber (Clássico)', 'tag': 'Grátis', 'color': const Color(0xFF1E78FF)},
    {'id': 'gold', 'name': 'Ouro Imperial VIP', 'tag': 'Destaque Semana', 'color': const Color(0xFFF59E0B)},
    {'id': 'minimal', 'name': 'Cristal Minimalista', 'tag': 'Novo', 'color': Colors.cyanAccent},
    {'id': 'emerald', 'name': 'Esmeralda Arena', 'tag': 'Comunidade', 'color': const Color(0xFF10B981)},
    {'id': 'fire', 'name': 'Fogo Competitivo', 'tag': 'Novo', 'color': const Color(0xFFEF4444)},
  ];

  void _applyStyle(String style, String label) {
    setState(() => _selectedStyle = style);
    final clean = widget.roomName.toLowerCase().replaceAll('@', '');
    if (clean.isNotEmpty) {
      widget.socket.emit('set_podium_style', {'room': clean, 'style': style});
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Overlay de Pódio "$label" aplicado!')));
  }

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _studioCardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🏆 Biblioteca de Overlays de Pódio', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF1E78FF), borderRadius: BorderRadius.circular(8)),
                    child: const Text('ATUALIZADO SEMANALMENTE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ..._podiumLibrary.map((item) {
                final active = _selectedStyle == item['id'];
                final Color c = item['color'] as Color;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: active ? c.withOpacity(0.18) : const Color(0xFF050B1E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: active ? c : Colors.white12),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.emoji_events, color: c),
                    title: Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Tema gratuito · ${item['tag']}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: active ? c : const Color(0xFF122B6B)),
                      onPressed: () => _applyStyle(item['id'] as String, item['name'] as String),
                      child: Text(active ? 'Ativo' : 'Usar', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _studioCardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💎 TOP PRESENTES (Moedas × Qtd)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 10),
              if (widget.topGifts.isEmpty)
                const Text('Ainda sem presentes nesta live.', style: TextStyle(color: Colors.white54))
              else
                ...widget.topGifts.take(5).toList().asMap().entries.map((e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(e.key < 3 ? medals[e.key] : '#${e.key + 1}', style: const TextStyle(fontSize: 20)),
                      title: Text(e.value['user'] ?? ''),
                      trailing: Text('${e.value['score']} moedas', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                    )),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _studioCardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('❤️ TOP LIKES (1 Toque = 1 Ponto)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF43F5E))),
              const SizedBox(height: 10),
              if (widget.topLikes.isEmpty)
                const Text('Ainda sem likes nesta live.', style: TextStyle(color: Colors.white54))
              else
                ...widget.topLikes.take(5).toList().asMap().entries.map((e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(e.key < 3 ? medals[e.key] : '#${e.key + 1}', style: const TextStyle(fontSize: 20)),
                      title: Text(e.value['user'] ?? ''),
                      trailing: Text('${e.value['score']} likes', style: const TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold)),
                    )),
            ],
          ),
        ),
      ],
    );
  }
}
class InteractionScreen extends StatefulWidget {
  final IO.Socket socket;
  final String roomName;

  const InteractionScreen({super.key, required this.socket, required this.roomName});

  @override
  State<InteractionScreen> createState() => _InteractionScreenState();
}

class _InteractionScreenState extends State<InteractionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _wheelCtrl;
  double _currentAngle = 0;
  String _lastWinner = 'Toca em Girar!';
  String _wheelTheme = 'neon';
  bool _chatJoinActive = false;

  final TextEditingController _optionCtrl = TextEditingController();
  final TextEditingController _pollQuestionCtrl = TextEditingController(text: 'Jogo a próxima partida de sniper?');
  bool _pollActive = false;

  List<String> _options = [
    '10 Flexões',
    'Escolher Música',
    'Sem Mira 1 Ronda',
    'Salve Especial',
    'Desafio do Chat',
    'Sorte Grande!',
  ];

  @override
  void initState() {
    super.initState();
    _wheelCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _wheelCtrl.dispose();
    _optionCtrl.dispose();
    _pollQuestionCtrl.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_options.isEmpty) return;
    final rnd = Random();
    final end = _currentAngle + (4 + rnd.nextInt(4)) * 2 * pi + rnd.nextDouble() * 2 * pi;
    final anim = Tween<double>(begin: _currentAngle, end: end).animate(CurvedAnimation(parent: _wheelCtrl, curve: Curves.easeOutCubic));
    anim.addListener(() => setState(() => _currentAngle = anim.value));
    _wheelCtrl.forward(from: 0).then((_) {
      final winner = _options[rnd.nextInt(_options.length)];
      setState(() => _lastWinner = '🎉 $winner');
      final clean = widget.roomName.toLowerCase().replaceAll('@', '');
      if (clean.isNotEmpty) {
        widget.socket.emit('remote_command', {'room': clean, 'command': 'wheel', 'payload': _options});
      }
    });
  }

  List<Color> _wheelColors() {
    if (_wheelTheme == 'fire') return [const Color(0xFFEF4444), const Color(0xFFF97316), const Color(0xFFFACC15), const Color(0xFFDC2626)];
    if (_wheelTheme == 'toxic') return [const Color(0xFF22C55E), const Color(0xFF10B981), const Color(0xFF84CC16), const Color(0xFF059669)];
    return [const Color(0xFF1E78FF), const Color(0xFF38BDF8), const Color(0xFF6366F1), const Color(0xFF0EA5E9)];
  }

  @override
  Widget build(BuildContext context) {
    final cleanRoom = widget.roomName.toLowerCase().replaceAll('@', '');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _studioCardDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('📊 Votação Ao Vivo pelo Chat', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 15)),
                  Switch(
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF1E78FF),
                    value: _pollActive,
                    onChanged: (v) {
                      setState(() => _pollActive = v);
                      if (cleanRoom.isNotEmpty) {
                        widget.socket.emit('update_poll', {
                          'room': cleanRoom,
                          'poll': {
                            'active': v,
                            'question': _pollQuestionCtrl.text.trim(),
                            'opt1Label': 'SIM (!sim)',
                            'opt2Label': 'NÃO (!nao)',
                            'opt1Key': '!sim',
                            'opt2Key': '!nao',
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              const Text('O chat vota escrevendo !sim ou !nao e as barras sobem na tela:', style: TextStyle(fontSize: 12, color: Colors.white60)),
              const SizedBox(height: 8),
              TextField(controller: _pollQuestionCtrl, decoration: const InputDecoration(labelText: 'Pergunta para a Live')),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _studioCardDeco(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🎡 Roleta Interativa', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 15)),
                  DropdownButton<String>(
                    value: _wheelTheme,
                    dropdownColor: const Color(0xFF0B1636),
                    items: const [
                      DropdownMenuItem(value: 'neon', child: Text('Estilo Néon')),
                      DropdownMenuItem(value: 'fire', child: Text('Estilo Fogo')),
                      DropdownMenuItem(value: 'toxic', child: Text('Estilo Tóxico')),
                    ],
                    onChanged: (v) => setState(() => _wheelTheme = v ?? 'neon'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: _currentAngle,
                    child: Container(
                      width: 165,
                      height: 165,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(colors: _wheelColors()),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: const Color(0xFF38BDF8).withOpacity(0.45), blurRadius: 18)],
                      ),
                    ),
                  ),
                  Container(
                    width: 62,
                    height: 62,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF050B1E),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                    ),
                    child: Image.asset('icon.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.local_fire_department, color: Color(0xFF38BDF8))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_lastWinner, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                  onPressed: _spinWheel,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('GIRAR ROLETA (App + Tela)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              const Align(alignment: Alignment.centerLeft, child: Text('Biblioteca de Modelos de Roleta:', style: TextStyle(fontSize: 12, color: Colors.white70))),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: DefaultMediaLibrary.wheelTemplates.map((tpl) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(tpl['name'], style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setState(() {
                              _wheelTheme = tpl['theme'];
                              _options = List<String>.from(tpl['items']);
                            });
                          },
                        ),
                      )).toList(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sorteio do Chat (!entrar)', style: TextStyle(fontSize: 13)),
                subtitle: const Text('Quem escrever !entrar no chat entra na roleta', style: TextStyle(fontSize: 11, color: Colors.white54)),
                value: _chatJoinActive,
                onChanged: (v) {
                  setState(() => _chatJoinActive = v);
                  if (cleanRoom.isNotEmpty) {
                    widget.socket.emit('toggle_chat_wheel_join', {'room': cleanRoom, 'open': v, 'keyword': '!entrar'});
                  }
                },
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: _optionCtrl, decoration: const InputDecoration(hintText: 'Adicionar opção...', isDense: true))),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF38BDF8)),
                    onPressed: () {
                      if (_optionCtrl.text.trim().isNotEmpty) {
                        setState(() {
                          _options.add(_optionCtrl.text.trim());
                          _optionCtrl.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                children: _options.map((o) => Chip(label: Text(o, style: const TextStyle(fontSize: 11)), onDeleted: () => setState(() => _options.remove(o)))).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OverlayStudioScreen extends StatefulWidget {
  final IO.Socket socket;
  final String serverUrl;
  final String roomName;

  const OverlayStudioScreen({super.key, required this.socket, required this.serverUrl, required this.roomName});

  @override
  State<OverlayStudioScreen> createState() => _OverlayStudioScreenState();
}

class _OverlayStudioScreenState extends State<OverlayStudioScreen> {
  bool _isProMember = false;
  String _selectedMarketCat = 'Todos';
  final TextEditingController _packNameCtrl = TextEditingController();
  final TextEditingController _creatorNetCtrl = TextEditingController(text: '3.50');
  String _packType = 'Overlay';

  final List<Map<String, String>> _marketplaceItems = [
    {'title': 'Pack Cyber Arena FPS', 'type': 'Overlay', 'author': 'HELL Originals', 'price': 'Grátis', 'scene': 'live'},
    {'title': 'Roleta Castigos Extremos', 'type': 'Roleta', 'author': '@KikoGamer', 'price': '2.89 €', 'scene': 'live'},
    {'title': 'Alertas Explosão Ouro', 'type': 'Alertas', 'author': '@SofiaLive', 'price': '3.49 €', 'scene': 'live'},
    {'title': 'Pack Sons Meme PT/BR', 'type': 'Sons', 'author': '@TugaStream', 'price': '2.19 €', 'scene': 'live'},
    {'title': 'Moldura Câmara Néon Minimal', 'type': 'Overlay', 'author': 'HELL Originals', 'price': 'Grátis', 'scene': 'cam_frame'},
  ];

  String _calcFinalPrice(String rawNet) {
    final net = double.tryParse(rawNet.replaceAll(',', '.')) ?? 0.0;
    if (net <= 0) return 'Grátis';
    final total = (net * 1.30) + 0.35;
    return '${total.toStringAsFixed(2)} €';
  }

  void _openProUpgradeModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1636),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 28),
            SizedBox(width: 8),
            Text('HELL Live PRO', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Desbloqueia o Estúdio Criador Completo e monetiza o teu talento:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('✅ Criação ilimitada de Overlays, Roletas, Alertas e Packs de Sons'),
            SizedBox(height: 6),
            Text('✅ Publicação direta no Marketplace Oficial HELL Live'),
            SizedBox(height: 6),
            Text('✅ Recebes 100% do valor líquido que definires (taxa aplicada ao comprador)'),
            SizedBox(height: 6),
            Text('✅ Selo Criador PRO verificado no teu perfil da Comunidade'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Agora Não')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
            onPressed: () {
              setState(() => _isProMember = true);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Modo Criador PRO ativado!')));
            },
            child: const Text('Ativar Plano PRO (4.99 €/mês)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _publishToMarketplace() {
    if (_packNameCtrl.text.trim().isEmpty) return;
    final finalPrice = _calcFinalPrice(_creatorNetCtrl.text);
    setState(() {
      _marketplaceItems.insert(0, {
        'title': _packNameCtrl.text.trim(),
        'type': _packType,
        'author': widget.roomName.isEmpty ? '@CriadorPRO' : '@${widget.roomName.replaceAll('@', '')}',
        'price': finalPrice,
        'scene': 'live',
      });
      _packNameCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🚀 Publicado no Marketplace por $finalPrice!')));
  }

  @override
  Widget build(BuildContext context) {
    final cleanRoom = (widget.roomName.isEmpty ? 'teu_canal' : widget.roomName).toLowerCase().replaceAll('@', '');
    final studioUrl = '${widget.serverUrl}/overlay/$cleanRoom';
    final filteredMarket = _selectedMarketCat == 'Todos'
        ? _marketplaceItems
        : _marketplaceItems.where((m) => m['type'] == _selectedMarketCat).toList();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF38BDF8),
            labelColor: Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: '🛒 Marketplace'),
              Tab(text: '✨ Criador PRO'),
              Tab(text: '📦 Grátis & Link'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Todos', 'Overlay', 'Roleta', 'Alertas', 'Sons'].map((cat) {
                          final sel = _selectedMarketCat == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: sel,
                              selectedColor: const Color(0xFF1E78FF),
                              onSelected: (_) => setState(() => _selectedMarketCat = cat),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...filteredMarket.map((item) {
                      final isFree = item['price'] == 'Grátis';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: _studioCardDeco(),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isFree ? const Color(0xFF1E78FF).withOpacity(0.2) : const Color(0xFFF59E0B).withOpacity(0.2),
                            child: Icon(
                              item['type'] == 'Roleta' ? Icons.casino : (item['type'] == 'Sons' ? Icons.music_note : Icons.layers),
                              color: isFree ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B),
                            ),
                          ),
                          title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${item['type']} · Por ${item['author']}', style: const TextStyle(fontSize: 11.5, color: Colors.white60)),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: isFree ? const Color(0xFF1E78FF) : const Color(0xFFF59E0B)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(isFree ? '✅ "${item['title']}" transferido e aplicado!' : '💳 "${item['title']}" (${item['price']}) desbloqueado!'),
                              ));
                            },
                            child: Text(item['price']!, style: TextStyle(color: isFree ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (!_isProMember)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF0B1636)]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 52),
                            const SizedBox(height: 10),
                            const Text('Estúdio Criador & Loja PRO', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 8),
                            const Text(
                              'Cria os teus próprios Overlays, Roletas, Alertas e Packs de Sons sem limites e coloca-os à venda no Marketplace da comunidade!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 13.5),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), padding: const EdgeInsets.symmetric(vertical: 14)),
                                onPressed: _openProUpgradeModal,
                                icon: const Icon(Icons.lock_open, color: Colors.black),
                                label: const Text('Desbloquear Plano PRO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _studioCardDeco(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified, color: Color(0xFFF59E0B)),
                                SizedBox(width: 8),
                                Text('Publicar Nova Criação no Marketplace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFF59E0B))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _packType,
                              dropdownColor: const Color(0xFF0B1636),
                              decoration: const InputDecoration(labelText: 'Tipo de Criação'),
                              items: const [
                                DropdownMenuItem(value: 'Overlay', child: Text('Overlay de Live')),
                                DropdownMenuItem(value: 'Roleta', child: Text('Roleta Interativa')),
                                DropdownMenuItem(value: 'Alertas', child: Text('Pack de Alertas')),
                                DropdownMenuItem(value: 'Sons', child: Text('Pack de Sons / Efeitos')),
                              ],
                              onChanged: (v) => setState(() => _packType = v ?? 'Overlay'),
                            ),
                            const SizedBox(height: 10),
                            TextField(controller: _packNameCtrl, decoration: const InputDecoration(labelText: 'Nome do Teu Pack / Overlay')),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _creatorNetCtrl,
                              onChanged: (_) => setState(() {}),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Valor Líquido que Queres Receber (€)'),
                            ),
                            const SizedBox(height: 6),
                            Text('Preço final na loja (c/ taxa comprador): ${_calcFinalPrice(_creatorNetCtrl.text)}', style: const TextStyle(fontSize: 12, color: Colors.cyanAccent)),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), padding: const EdgeInsets.symmetric(vertical: 13)),
                                onPressed: _publishToMarketplace,
                                icon: const Icon(Icons.storefront, color: Colors.black),
                                label: const Text('Publicar à Venda no Marketplace', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: _studioCardDeco(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🔗 Link de Navegador (OBS / Streamlabs / TikTok Studio)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 13)),
                          const SizedBox(height: 6),
                          SelectableText(studioUrl, style: const TextStyle(fontSize: 11.5, color: Colors.cyanAccent)),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E78FF)),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: studioUrl));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copiado!')));
                              },
                              icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                              label: const Text('Copiar Link', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...DefaultMediaLibrary.overlayPresets.map((preset) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: _studioCardDeco(),
                          child: ListTile(
                            leading: const Icon(Icons.layers, color: Color(0xFF38BDF8)),
                            title: Text(preset['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(preset['desc']!, style: const TextStyle(fontSize: 11.5, color: Colors.white60)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF122B6B)),
                              onPressed: () {
                                if (widget.roomName.isNotEmpty) {
                                  widget.socket.emit('remote_command', {'room': cleanRoom, 'command': 'scene', 'payload': preset['scene']});
                                }
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Overlay "${preset['name']}" ativado!')));
                              },
                              child: const Text('Usar', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
