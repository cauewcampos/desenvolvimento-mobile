<?php
header('Content-Type: application/json');
$nome = $_GET['nome'];

$comandoSQL = "INSERT INTO `usuarios` (`id`, `nome`, `senha`, `email`) VALUES (NULL, '$nome', '{$_GET['senha']}', '{$_GET['email']}')";

$dsn = 'mysql:dbname=site_trufa;host=127.0.0.1';
$user = 'root';
$password = '';

$conexao = new PDO($dsn, $user, $password);

if($conexao->query($comandoSQL)) {
    echo json_encode(["sucesso" => "Usuário $nome cadastrado com sucesso!"]);
} else {
    echo json_encode(["erro" =>"Erro ao cadastrar!"]);
}

?>