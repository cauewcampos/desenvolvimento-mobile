<?php
header('Content-Type: application/json; charset=utf-8');

try {
    $pdo = new PDO(
        'mysql:dbname=bdx;host=127.0.0.1;charset=utf8mb4',
        'root',
        '',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'ok' => false,
        'mensagem' => 'Nao foi possivel conectar ao banco de dados.'
    ]);
    exit;
}

$rawBody = file_get_contents('php://input');
$data = json_decode($rawBody, true);
if (!is_array($data)) {
    http_response_code(400);
    echo json_encode([
        'ok' => false,
        'mensagem' => 'Dados invalidos.'
    ]);
    exit;
}

$action = strtolower(trim((string) ($data['action'] ?? '')));

if ($action === 'register') {
    $nome = trim((string) ($data['nome'] ?? ''));
    $email = strtolower(trim((string) ($data['email'] ?? '')));
    $senha = (string) ($data['senha'] ?? '');

    if ($nome === '' || $email === '' || $senha === '') {
        http_response_code(400);
        echo json_encode([
            'ok' => false,
            'mensagem' => 'Preencha nome, e-mail e senha.'
        ]);
        exit;
    }

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode([
            'ok' => false,
            'mensagem' => 'E-mail invalido.'
        ]);
        exit;
    }

    $verifica = $pdo->prepare('SELECT id FROM usuarios WHERE email = :email LIMIT 1');
    $verifica->execute(['email' => $email]);
    if ($verifica->fetch()) {
        http_response_code(409);
        echo json_encode([
            'ok' => false,
            'mensagem' => 'Este e-mail ja esta cadastrado.'
        ]);
        exit;
    }

    $senhaHash = password_hash($senha, PASSWORD_DEFAULT);
    $stmt = $pdo->prepare(
        'INSERT INTO usuarios (nome, email, senha) VALUES (:nome, :email, :senha)'
    );
    $stmt->execute([
        'nome' => $nome,
        'email' => $email,
        'senha' => $senhaHash,
    ]);

    echo json_encode([
        'ok' => true,
        'mensagem' => 'Cadastro realizado com sucesso.',
        'user' => [
            'id' => $pdo->lastInsertId(),
            'nome' => $nome,
            'email' => $email,
        ],
    ]);
    exit;
}

if ($action === 'login') {
    $email = strtolower(trim((string) ($data['email'] ?? '')));
    $senha = (string) ($data['senha'] ?? '');

    if ($email === '' || $senha === '') {
        http_response_code(400);
        echo json_encode([
            'ok' => false,
            'mensagem' => 'Informe e-mail e senha.'
        ]);
        exit;
    }

    $stmt = $pdo->prepare('SELECT id, nome, email, senha FROM usuarios WHERE email = :email LIMIT 1');
    $stmt->execute(['email' => $email]);
    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$usuario || !password_verify($senha, $usuario['senha'])) {
        http_response_code(401);
        echo json_encode([
            'ok' => false,
            'mensagem' => 'E-mail ou senha incorretos.'
        ]);
        exit;
    }

    echo json_encode([
        'ok' => true,
        'mensagem' => 'Login realizado com sucesso.',
        'user' => [
            'id' => (int) $usuario['id'],
            'nome' => $usuario['nome'],
            'email' => $usuario['email'],
        ],
    ]);
    exit;
}

http_response_code(400);
echo json_encode([
    'ok' => false,
    'mensagem' => 'Ação invalida.'
]);
