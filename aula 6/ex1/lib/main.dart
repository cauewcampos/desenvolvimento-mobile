import 'package:flutter/material.dart';
import 'package:flutter_application_2/janela1.dart';
import 'package:flutter_application_2/janela2.dart';

void main() {
  runApp(
    const Controle(),
  );
}

class Controle extends StatefulWidget {
  const Controle({super.key});

  @override
  State<Controle> createState() => _ControleState();
}

class _ControleState extends State<Controle> {
  // Widget? atual;
  String atual = 'um';

  // criação de muda
  void muda() {
    setState(() {
      atual = 'dois';
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget? usar;

    if (atual == 'um') {
      usar = Janela1(muda);
    } else {
      usar = const Janela2();
    }

    return MaterialApp(
      home: usar,
    );
  }
}
