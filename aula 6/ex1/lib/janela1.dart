import 'package:flutter/material.dart';

class Janela1 extends StatelessWidget {
  // receber a função
  const Janela1(
    this.muda, {
    super.key,
  });

  final Function() muda;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/imagens/palhaco.png',
                //color: const Color.fromARGB(40, 244, 67, 54),
              ),
            ),
          ),
          const Text('Aperte o botão para começar:'),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton.icon(
            icon: Icon(
              Icons.arrow_right_alt,
            ),
            onPressed: () {
              print('Iniciando...');
              muda(); // agora pode
            },
            label: const Text('Iniciar'),
          ),
        ],
      ),
    );
  }
}
