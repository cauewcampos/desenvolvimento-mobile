class Pergunta {
  const Pergunta(this.texto, this.respostas);

  final String texto;
  final List<String> respostas;

  List<String> Embaralha() {
    var novaLista = List.of(respostas);
    novaLista.shuffle();
    return novaLista;
  }
}
