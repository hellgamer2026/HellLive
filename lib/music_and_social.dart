class CommunitySocialScreen extends StatefulWidget {
  final String serverUrl;
  final Map<String, dynamic> currentUser;
  const CommunitySocialScreen({super.key, required this.serverUrl, required this.currentUser});

  @override
  State<CommunitySocialScreen> createState() => _CommunitySocialScreenState();
}

class _CommunitySocialScreenState extends State<CommunitySocialScreen> {
  final TextEditingController _chatCtrl = TextEditingController();
  final List<Map<String, String>> _communityMessages = [
    {'user': '@SofiaLive', 'msg': 'Alguém a testar os novos overlays néon hoje?'},
    {'user': '@KikoGamer', 'msg': 'O Stream Deck no tablet ficou brutal!'},
  ];

  final List<Map<String, dynamic>> _creators = [
    {'nick': '@SofiaLive', 'bio': 'FPS & Just Chatting · Portugal', 'status': 'online', 'following': false, 'discord': 'discord.gg/sofia', 'whatsapp': ''},
    {'nick': '@KikoGamer', 'bio': 'Torneios e Desafios ao vivo', 'status': 'dnd', 'following': true, 'discord': '', 'whatsapp': '://whatsapp.com'},
    {'nick': '@TugaStream', 'bio': 'Criador de Overlays PRO', 'status': 'online', 'following': false, 'discord': 'discord.gg/tuga', 'whatsapp': ''},
  ];

  Color _dotColor(String st) {
    if (st == 'dnd') return Colors.orange;
    if (st == 'invisible') return Colors.white;
    if (st == 'offline') return Colors.redAccent;
    return Colors.green;
  }

  void _openDirectMessage(Map<String, dynamic> target) {
    if (target['status'] == 'dnd') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${target['nick']} está em modo Não Incomodar.')));
      return;
    }
    final dmCtrl = TextEditingController();
    final List<String> history = ['Olá ${target['nick']}! Tudo bem?'];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF0B1636),
          title: Row(
            children: [
              Icon(Icons.circle, size: 11, color: _dotColor(target['status'])),
              const SizedBox(width: 8),
              Text('Mensagem Privada · ${target['nick']}', style: const TextStyle(fontSize: 15)),
            ],
          ),
          content: SizedBox(
            width: 360,
            height: 240,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: history.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFF1E78FF).withOpacity(0.22), borderRadius: BorderRadius.circular(10)),
                            child: Text(m, style: const TextStyle(fontSize: 13)),
                          ),
                        )).toList(),
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: TextField(controller: dmCtrl, decoration: const InputDecoration(hintText: 'Escrever mensagem...', isDense: true))),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF38BDF8)),
                      onPressed: () {
                        if (dmCtrl.text.trim().isNotEmpty) {
                          setModalState(() {
                            history.add('${widget.currentUser['nickname'] ?? 'Eu'}: ${dmCtrl.text.trim()}');
                            dmCtrl.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF38BDF8),
            labelColor: Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: '👥 Criadores & Seguidores'),
              Tab(text: '💬 Chat da Comunidade'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 1. Perfis, Seguidores & Mensagens Privadas
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ..._creators.map((c) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF0E1D47), Color(0xFF08112B)]),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1E429F)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      const CircleAvatar(backgroundColor: Color(0xFF1E78FF), child: Icon(Icons.person, color: Colors.white)),
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(color: _dotColor(c['status']), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF050B1E), width: 2)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c['nick'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text(c['bio'], style: const TextStyle(fontSize: 11.5, color: Colors.white60)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.mail_outline, color: Color(0xFF38BDF8)),
                                    tooltip: 'Mensagem Privada',
                                    onPressed: () => _openDirectMessage(c),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: c['following'] ? Colors.white12 : const Color(0xFF1E78FF)),
                                    onPressed: () => setState(() => c['following'] = !c['following']),
                                    child: Text(c['following'] ? 'A Seguir' : 'Seguir', style: const TextStyle(color: Colors.white, fontSize: 11.5)),
                                  ),
                                ],
                              ),
                              if ((c['discord'] as String).isNotEmpty || (c['whatsapp'] as String).isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if ((c['discord'] as String).isNotEmpty)
                                      Chip(label: Text('Discord: ${c['discord']}', style: const TextStyle(fontSize: 10.5)), backgroundColor: const Color(0xFF5865F2).withOpacity(0.25)),
                                    if ((c['whatsapp'] as String).isNotEmpty)
                                      Chip(label: Text('WhatsApp: ${c['whatsapp']}', style: const TextStyle(fontSize: 10.5)), backgroundColor: Colors.green.withOpacity(0.25)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        )),
                  ],
                ),
                // 2. Chat Geral da Comunidade
                Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: _communityMessages.map((m) => Card(
                              color: const Color(0xFF0B1636),
                              child: ListTile(
                                dense: true,
                                title: Text(m['user']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 12.5)),
                                subtitle: Text(m['msg']!),
                              ),
                            )).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(child: TextField(controller: _chatCtrl, decoration: const InputDecoration(hintText: 'Mensagem para a comunidade...', border: OutlineInputBorder(), isDense: true))),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF38BDF8)),
                            onPressed: () {
                              if (_chatCtrl.text.trim().isNotEmpty) {
                                setState(() {
                                  _communityMessages.add({
                                    'user': '@${widget.currentUser['nickname'] ?? 'Criador'}',
                                    'msg': _chatCtrl.text.trim(),
                                  });
                                  _chatCtrl.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
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
