<?php
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $dbh = new PDO(
        'mysql:dbname=bdx;host=127.0.0.1;charset=utf8mb4',
        'root',
        '',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    $consulta = $dbh->query(
        'SELECT id, foto, descricao, texto FROM textos ORDER BY id DESC'
    );
    echo json_encode(['dados' => $consulta->fetchAll(PDO::FETCH_ASSOC)]);
    exit;
}

if (!isset($_FILES['foto']) || $_FILES['foto']['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(['mensagem' => 'Nenhuma foto foi recebida.']);
    exit;
}

$foto = $_FILES['foto'];
$descricao = trim((string) ($_POST['descricao'] ?? ''));
$tiposPermitidos = [
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'image/webp' => 'webp',
];

$tipo = mime_content_type($foto['tmp_name']);
if (!isset($tiposPermitidos[$tipo])) {
    http_response_code(415);
    echo json_encode(['mensagem' => 'Formato de foto nao permitido.']);
    exit;
}

$diretorio = __DIR__ . DIRECTORY_SEPARATOR . 'uploads';
if (!is_dir($diretorio)) {
    mkdir($diretorio, 0755, true);
}

$nome = bin2hex(random_bytes(16)) . '.' . $tiposPermitidos[$tipo];
$caminho = $diretorio . DIRECTORY_SEPARATOR . $nome;

if (!move_uploaded_file($foto['tmp_name'], $caminho)) {
    http_response_code(500);
    echo json_encode(['mensagem' => 'Nao foi possivel salvar a foto.']);
    exit;
}

$dbh = new PDO(
    'mysql:dbname=bdx;host=127.0.0.1;charset=utf8mb4',
    'root',
    '',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);
$comando = $dbh->prepare(
    'INSERT INTO textos (foto, descricao) VALUES (:foto, :descricao)'
);
$comando->execute([
    'foto' => $nome,
    'descricao' => $descricao,
]);

$url = 'http://' . $_SERVER['HTTP_HOST'] . '/uploads/' . $nome;
echo json_encode([
    'mensagem' => 'Foto enviada com sucesso.',
    'arquivo' => $nome,
    'url' => $url,
]);
