<?php
header('Content-Type: application/json; charset=utf-8');

function getDb(): PDO
{
    return new PDO(
        'mysql:dbname=bdx;host=127.0.0.1;charset=utf8mb4',
        'root',
        '',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
}

function statusAmizade(PDO $pdo, int $userId, int $otherId): string
{
    if ($userId === $otherId) {
        return 'self';
    }

    $stmt = $pdo->prepare(
        'SELECT status FROM amigos
         WHERE ((requester_id = :a AND target_id = :b) OR (requester_id = :b AND target_id = :a))
         ORDER BY id DESC
         LIMIT 1'
    );
    $stmt->execute(['a' => $userId, 'b' => $otherId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    return $row['status'] ?? 'none';
}

function podeComentar(PDO $pdo, int $userId, int $authorId): bool
{
    if ($userId === $authorId) {
        return true;
    }

    return statusAmizade($pdo, $userId, $authorId) === 'aceita';
}

function hydratePosts(PDO $pdo, array $posts, int $userId): array
{
    foreach ($posts as &$post) {
        $post['autor_id'] = (int) ($post['autor_id'] ?? 0);
        $countLikes = $pdo->prepare('SELECT COUNT(*) FROM likes WHERE post_id = :post_id');
        $countLikes->execute(['post_id' => $post['id']]);
        $post['curtidas'] = (int) $countLikes->fetchColumn();

        $likedStmt = $pdo->prepare('SELECT 1 FROM likes WHERE post_id = :post_id AND user_id = :user_id LIMIT 1');
        $likedStmt->execute(['post_id' => $post['id'], 'user_id' => $userId]);
        $post['curtido_por_mim'] = (bool) $likedStmt->fetchColumn();

        $commentsStmt = $pdo->prepare(
            'SELECT c.id, c.texto, c.user_id, u.nome AS autor_nome
             FROM comentarios c
             INNER JOIN usuarios u ON u.id = c.user_id
             WHERE c.post_id = :post_id
             ORDER BY c.id ASC'
        );
        $commentsStmt->execute(['post_id' => $post['id']]);
        $post['comentarios'] = $commentsStmt->fetchAll(PDO::FETCH_ASSOC);

        $post['status_amizade'] = $userId > 0 ? statusAmizade($pdo, $userId, (int) $post['autor_id']) : 'none';
        $post['pode_comentar'] = $userId > 0 ? podeComentar($pdo, $userId, (int) $post['autor_id']) : false;
    }

    return $posts;
}

$method = $_SERVER['REQUEST_METHOD'];
$pdo = getDb();

if ($method === 'GET') {
    $action = $_GET['action'] ?? 'feed';
    $userId = isset($_GET['user_id']) ? (int) $_GET['user_id'] : 0;

    if ($action === 'pending_requests') {
        $stmt = $pdo->prepare(
            'SELECT a.id, a.requester_id, u.nome AS requester_nome
             FROM amigos a
             INNER JOIN usuarios u ON u.id = a.requester_id
             WHERE a.target_id = :user_id AND a.status = "pendente"
             ORDER BY a.id DESC'
        );
        $stmt->execute(['user_id' => $userId]);
        echo json_encode(['dados' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
        exit;
    }

    $stmt = $pdo->query(
        'SELECT t.id,
                COALESCE(t.user_id, 0) AS autor_id,
                t.foto,
                t.descricao,
                t.created_at,
                COALESCE(u.nome, "Usuario") AS autor_nome
         FROM textos t
         LEFT JOIN usuarios u ON u.id = t.user_id
         ORDER BY t.id DESC'
    );
    $posts = hydratePosts($pdo, $stmt->fetchAll(PDO::FETCH_ASSOC), $userId);

    echo json_encode(['dados' => $posts]);
    exit;
}

if ($action === 'search') {
    $query = trim((string) ($_GET['query'] ?? ''));
    if ($query === '') {
        echo json_encode(['dados' => []]);
        exit;
    }

    $like = '%' . str_replace(['\\', '%', '_'], ['\\\\', '\\%', '\\_'], $query) . '%';
    $stmt = $pdo->prepare(
        'SELECT t.id,
                COALESCE(t.user_id, 0) AS autor_id,
                t.foto,
                t.descricao,
                t.created_at,
                COALESCE(u.nome, "Usuario") AS autor_nome
         FROM textos t
         LEFT JOIN usuarios u ON u.id = t.user_id
         WHERE LOWER(COALESCE(u.nome, "")) LIKE LOWER(:query)
            OR LOWER(COALESCE(t.descricao, "")) LIKE LOWER(:query)
            OR LOWER(COALESCE(t.texto, "")) LIKE LOWER(:query)
         ORDER BY t.id DESC'
    );
    $stmt->execute(['query' => $like]);
    $posts = hydratePosts($pdo, $stmt->fetchAll(PDO::FETCH_ASSOC), $userId);

    echo json_encode(['dados' => $posts]);
    exit;
}

if ($method === 'POST') {
    $raw = file_get_contents('php://input');
    $payload = json_decode($raw, true);
    $formAction = $_POST['action'] ?? ($payload['action'] ?? null);

    if ($formAction === 'publish' || $formAction === null && isset($_FILES['foto'])) {
        if (!isset($_FILES['foto']) || $_FILES['foto']['error'] !== UPLOAD_ERR_OK) {
            http_response_code(400);
            echo json_encode(['mensagem' => 'Nenhuma foto foi recebida.']);
            exit;
        }

        $foto = $_FILES['foto'];
        $descricao = trim((string) ($_POST['descricao'] ?? ''));
        $userId = (int) ($_POST['user_id'] ?? 0);

        if ($userId <= 0) {
            http_response_code(400);
            echo json_encode(['mensagem' => 'Usuario nao identificado.']);
            exit;
        }

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

        $stmt = $pdo->prepare(
            'INSERT INTO textos (user_id, foto, descricao) VALUES (:user_id, :foto, :descricao)'
        );
        $stmt->execute([
            'user_id' => $userId,
            'foto' => $nome,
            'descricao' => $descricao,
        ]);

        echo json_encode([
            'mensagem' => 'Foto enviada com sucesso.',
            'arquivo' => $nome,
        ]);
        exit;
    }

    if ($formAction === 'like') {
        $userId = (int) ($payload['user_id'] ?? $_POST['user_id'] ?? 0);
        $postId = (int) ($payload['post_id'] ?? $_POST['post_id'] ?? 0);

        if ($userId <= 0 || $postId <= 0) {
            http_response_code(400);
            echo json_encode(['mensagem' => 'Dados invalidos.']);
            exit;
        }

        $check = $pdo->prepare('SELECT id FROM likes WHERE user_id = :user_id AND post_id = :post_id LIMIT 1');
        $check->execute(['user_id' => $userId, 'post_id' => $postId]);

        if ($check->fetch()) {
            $remove = $pdo->prepare('DELETE FROM likes WHERE user_id = :user_id AND post_id = :post_id');
            $remove->execute(['user_id' => $userId, 'post_id' => $postId]);
            echo json_encode(['liked' => false, 'mensagem' => 'Curtida removida.']);
            exit;
        }

        $insert = $pdo->prepare('INSERT INTO likes (user_id, post_id) VALUES (:user_id, :post_id)');
        $insert->execute(['user_id' => $userId, 'post_id' => $postId]);

        echo json_encode(['liked' => true, 'mensagem' => 'Curtida registrada.']);
        exit;
    }

    if ($formAction === 'comment') {
        $userId = (int) ($payload['user_id'] ?? $_POST['user_id'] ?? 0);
        $postId = (int) ($payload['post_id'] ?? $_POST['post_id'] ?? 0);
        $texto = trim((string) ($payload['texto'] ?? $_POST['texto'] ?? ''));

        if ($userId <= 0 || $postId <= 0 || $texto === '') {
            http_response_code(400);
            echo json_encode(['mensagem' => 'Comentario invalido.']);
            exit;
        }

        $post = $pdo->prepare('SELECT user_id FROM textos WHERE id = :id LIMIT 1');
        $post->execute(['id' => $postId]);
        $postData = $post->fetch(PDO::FETCH_ASSOC);

        if (!$postData) {
            http_response_code(404);
            echo json_encode(['mensagem' => 'Postagem nao encontrada.']);
            exit;
        }

        if (!podeComentar($pdo, $userId, (int) $postData['user_id'])) {
            http_response_code(403);
            echo json_encode(['mensagem' => 'Você só pode comentar em postagens de amigos.']);
            exit;
        }

        $insert = $pdo->prepare('INSERT INTO comentarios (post_id, user_id, texto) VALUES (:post_id, :user_id, :texto)');
        $insert->execute(['post_id' => $postId, 'user_id' => $userId, 'texto' => $texto]);

        $user = $pdo->prepare('SELECT nome FROM usuarios WHERE id = :id LIMIT 1');
        $user->execute(['id' => $userId]);
        $nome = $user->fetchColumn();

        echo json_encode([
            'mensagem' => 'Comentario enviado.',
            'comentario' => [
                'id' => (int) $pdo->lastInsertId(),
                'texto' => $texto,
                'user_id' => $userId,
                'autor_nome' => $nome,
            ],
        ]);
        exit;
    }

    if ($formAction === 'friend_request') {
        $userId = (int) ($payload['user_id'] ?? $_POST['user_id'] ?? 0);
        $authorId = (int) ($payload['author_id'] ?? $_POST['author_id'] ?? 0);

        if ($userId <= 0 || $authorId <= 0 || $userId === $authorId) {
            http_response_code(400);
            echo json_encode(['mensagem' => 'Solicitacao invalida.']);
            exit;
        }

        $check = $pdo->prepare(
            'SELECT * FROM amigos
             WHERE ((requester_id = :a AND target_id = :b) OR (requester_id = :b AND target_id = :a))
             ORDER BY id DESC LIMIT 1'
        );
        $check->execute(['a' => $userId, 'b' => $authorId]);
        $row = $check->fetch(PDO::FETCH_ASSOC);

        if ($row) {
            echo json_encode(['mensagem' => 'Solicitacao ja existe.', 'status' => $row['status']]);
            exit;
        }

        $stmt = $pdo->prepare(
            'INSERT INTO amigos (requester_id, target_id, status) VALUES (:requester_id, :target_id, "pendente")'
        );
        $stmt->execute(['requester_id' => $userId, 'target_id' => $authorId]);

        echo json_encode(['mensagem' => 'Solicitacao enviada.', 'status' => 'pendente']);
        exit;
    }

    if ($formAction === 'friend_response') {
        $userId = (int) ($payload['user_id'] ?? $_POST['user_id'] ?? 0);
        $friendId = (int) ($payload['friend_id'] ?? $_POST['friend_id'] ?? 0);
        $status = strtolower((string) ($payload['status'] ?? $_POST['status'] ?? ''));

        if ($userId <= 0 || $friendId <= 0 || !in_array($status, ['aceita', 'recusada'], true)) {
            http_response_code(400);
            echo json_encode(['mensagem' => 'Resposta invalida.']);
            exit;
        }

        $stmt = $pdo->prepare(
            'UPDATE amigos
             SET status = :status
             WHERE requester_id = :friend_id AND target_id = :user_id AND status = "pendente"'
        );
        $stmt->execute(['status' => $status, 'friend_id' => $friendId, 'user_id' => $userId]);

        if ($stmt->rowCount() === 0) {
            http_response_code(404);
            echo json_encode(['mensagem' => 'Solicitacao nao encontrada.']);
            exit;
        }

        echo json_encode(['mensagem' => 'Resposta registrada.', 'status' => $status]);
        exit;
    }
}

http_response_code(405);
echo json_encode(['mensagem' => 'Metodo nao permitido.']);
