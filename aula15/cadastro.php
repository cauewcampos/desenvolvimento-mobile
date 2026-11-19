<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cadastro</title>
</head>
<body>
    <form action="salva_usuario.php">
        <!-- $_GET['nome'] -->
        <label for="">Nome:</label>
        <input type="text" name="nome"><br>
        <label for="">Senha:</label>
        <input type="password" name="senha"><br>
        <label for="">E-mail:</label>
        <input type="email" name="email"><br>
        <input type="submit">
    </form>
</body>
</html>