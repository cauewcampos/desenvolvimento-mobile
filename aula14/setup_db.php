<?php
header('Content-Type: application/json; charset=utf-8');

try {
    $pdo = new PDO(
        'mysql:host=127.0.0.1;charset=utf8mb4',
        'root',
        '',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $pdo->exec('CREATE DATABASE IF NOT EXISTS bdx CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');

    $pdo = new PDO(
        'mysql:dbname=bdx;host=127.0.0.1;charset=utf8mb4',
        'root',
        '',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS usuarios (
            id INT AUTO_INCREMENT PRIMARY KEY,
            nome VARCHAR(120) NOT NULL,
            email VARCHAR(180) NOT NULL UNIQUE,
            senha VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
    );

    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS textos (
            id INT AUTO_INCREMENT PRIMARY KEY,
            foto VARCHAR(255) NULL,
            descricao TEXT NULL,
            texto VARCHAR(200) NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
    );

    $columnsTextos = $pdo->query('SHOW COLUMNS FROM textos')->fetchAll(PDO::FETCH_COLUMN);
    if (!in_array('user_id', $columnsTextos, true)) {
        $pdo->exec('ALTER TABLE textos ADD COLUMN user_id INT NULL AFTER id');
    }

    if (!in_array('foto', $columnsTextos, true)) {
        $pdo->exec('ALTER TABLE textos ADD COLUMN foto VARCHAR(255) NULL AFTER user_id');
    }

    if (!in_array('descricao', $columnsTextos, true)) {
        $pdo->exec('ALTER TABLE textos ADD COLUMN descricao TEXT NULL AFTER foto');
    }

    if (!in_array('texto', $columnsTextos, true)) {
        $pdo->exec('ALTER TABLE textos ADD COLUMN texto VARCHAR(200) NULL AFTER descricao');
    }

    if (!in_array('created_at', $columnsTextos, true)) {
        $pdo->exec('ALTER TABLE textos ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP AFTER texto');
    }

    $hasFk = false;
    try {
        $fkCheck = $pdo->query(
            "SELECT 1 FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA = 'bdx' AND TABLE_NAME = 'textos' AND COLUMN_NAME = 'user_id' AND REFERENCED_TABLE_NAME = 'usuarios' LIMIT 1"
        )->fetchColumn();
        $hasFk = $fkCheck !== false;
    } catch (Exception $e) {
        $hasFk = false;
    }

    if (!$hasFk) {
        try {
            $pdo->exec('ALTER TABLE textos ADD CONSTRAINT fk_textos_user FOREIGN KEY (user_id) REFERENCES usuarios(id) ON DELETE CASCADE');
        } catch (Exception $e) {
            // Mantém a app funcionando mesmo que haja registros antigos sem relação estrangeira definida.
        }
    }

    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS amigos (
            id INT AUTO_INCREMENT PRIMARY KEY,
            requester_id INT NOT NULL,
            target_id INT NOT NULL,
            status ENUM("pendente","aceita","recusada") DEFAULT "pendente",
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_friendship (requester_id, target_id),
            FOREIGN KEY (requester_id) REFERENCES usuarios(id) ON DELETE CASCADE,
            FOREIGN KEY (target_id) REFERENCES usuarios(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
    );

    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS likes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            post_id INT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_like (user_id, post_id),
            FOREIGN KEY (user_id) REFERENCES usuarios(id) ON DELETE CASCADE,
            FOREIGN KEY (post_id) REFERENCES textos(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
    );

    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS comentarios (
            id INT AUTO_INCREMENT PRIMARY KEY,
            post_id INT NOT NULL,
            user_id INT NOT NULL,
            texto TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (post_id) REFERENCES textos(id) ON DELETE CASCADE,
            FOREIGN KEY (user_id) REFERENCES usuarios(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
    );

    echo json_encode([
        'ok' => true,
        'mensagem' => 'Banco e tabelas prontos.'
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'ok' => false,
        'mensagem' => 'Erro ao preparar o banco: ' . $e->getMessage()
    ]);
}
