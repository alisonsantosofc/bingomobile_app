import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

void main() => runApp(const BingoClientApp());

class BingoClientApp extends StatelessWidget {
  const BingoClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BingoCardScreen(),
    );
  }
}

class BingoCardScreen extends StatefulWidget {
  const BingoCardScreen({super.key});

  @override
  State<BingoCardScreen> createState() => _BingoCardScreenState();
}

class _BingoCardScreenState extends State<BingoCardScreen> {
  WebSocket? socket;
  List<int> drawnNumbers = [];
  List<int> myCard = generateCard();
  Set<int> marked = {};
  String serverIp = '';
  final ipController = TextEditingController();

  void connect(String ip) async {
    try {
      final ws = await WebSocket.connect('ws://$ip:3000');
      setState(() {
        socket = ws;
        serverIp = ip;
      });
      ws.listen((data) {
        final decoded = jsonDecode(data);
        if (decoded['type'] == 'DRAW') {
          setState(() {
            drawnNumbers.add(decoded['number']);
          });
        }
      });
    } catch (e) {
      print('Erro ao conectar: $e');
    }
  }

  void callBingo() {
    socket?.add(jsonEncode({"type": "BINGO", "playerId": "Jogador 1"}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Cartela')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ipController,
                      decoration: const InputDecoration(labelText: 'IP da TV'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => connect(ipController.text),
                    child: const Text('Conectar'),
                  )
                ],
              ),
            ),
            Wrap(
              children: myCard.map((n) {
                bool isMarked = marked.contains(n);
                bool isDrawn = drawnNumbers.contains(n);
                return GestureDetector(
                  onTap: isDrawn
                      ? () => setState(() => marked.add(n))
                      : null,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMarked
                          ? Colors.green
                          : isDrawn
                              ? Colors.yellow
                              : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$n'),
                  ),
                );
              }).toList(),
            ),
            ElevatedButton(
              onPressed: callBingo,
              child: const Text('BINGO!'),
            )
          ],
        ),
      ),
    );
  }
}

List<int> generateCard() {
  final set = <int>{};
  while (set.length < 15) {
    set.add(1 + (74 * (DateTime.now().microsecondsSinceEpoch % 1000) ~/ 1000));
  }
  return set.toList();
}