import 'package:flutter/material.dart';

import 'janela1.dart';
import 'janela2.dart';

void main() {
  runApp(
    Controle(),
  );
}

class Controle extends StatefulWidget {
  const Controle({super.key});

  @override
  State<Controle> createState() => _ControleState();
}

class _ControleState extends State<Controle> {
  var janela = 'um';

  // criação de muda
  void muda() {
    setState(() {
      janela = 'dois';
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget atual = Janela1(muda);

    if (janela == 'um') {
      atual = Janela1(muda);
    } else {
      atual = const Janela2();
    }

    return MaterialApp(
      home: atual,
    );
  }
}
