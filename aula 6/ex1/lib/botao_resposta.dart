import 'package:flutter/material.dart';

class BotaoReposta extends StatelessWidget {
  BotaoReposta({
    super.key,
    required this.textoResposta,
    required this.callResposta, // nomeada
    required this.cor,
  });

  final String textoResposta;
  final void Function() callResposta;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: cor,
        foregroundColor: Colors.white, // texto
      ),
      onPressed: callResposta, // será chamada no click
      child: Text(textoResposta),
    );
  }
}
