void main() {
  var nome = 'Camiseta ADS';
  var quantidade = 3;
  var preco = 49.90;
  var disponivel = true;
  const imposto = 5.0;

  var precoTotal = (quantidade * preco) * (1 + imposto / 100);

  print("Produto: " + nome);
  print("Disponível em estoque: " + disponivel.toString());
  print("Produto: " + quantidade.toString());
  print("Preço unitário: " + preco.toString());
  print("Valor total: R\$ " + precoTotal.toString());
}
