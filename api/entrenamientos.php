<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/validar.php';

$metodo = $_SERVER['REQUEST_METHOD'];

// POST → registra todas las sesiones de entrenamiento de un guardado
// Body: { partida_id, sesiones: [{ pokemon_uid, pokemon_nombre, pe_inicial, pe_gastado,
//         pe_final, xp_ganada, nivel_antes, nivel_despues, cantidad_entrenamientos,
//         stats: [{ stat_nombre, cantidad_entrenada, valor_antes, valor_despues }] }] }
// Los strings pokemon_nombre y stat_nombre se resuelven a IDs aquí
if ($metodo === 'POST') {
    $body = json_decode(file_get_contents('php://input'), true);

    $partidaId = int_opt($body, 'partida_id');
    $sesiones  = arr_req($body, 'sesiones');

    if (empty($sesiones)) {
        echo json_encode(['ok' => true, 'insertadas' => 0]);
        exit;
    }

    $pdo->beginTransaction();
    try {
        // Pre-cargar tablas catálogo (nombre → id)
        $catPokemon = $pdo->query('SELECT nombre, id FROM pokemon_catalogo')
                          ->fetchAll(PDO::FETCH_KEY_PAIR);
        $catStats   = $pdo->query('SELECT nombre, id FROM stat_tipos')
                          ->fetchAll(PDO::FETCH_KEY_PAIR);

        $stmtS = $pdo->prepare(
            'INSERT INTO entrenamiento_sesiones
             (partida_id, pokemon_uid, pokemon_id, pe_inicial, pe_gastado, pe_final,
              xp_ganada, nivel_antes, nivel_despues, cantidad_entrenamientos)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );

        $stmtE = $pdo->prepare(
            'INSERT INTO entrenamiento_stats
             (sesion_id, stat_id, cantidad_entrenada, valor_antes, valor_despues)
             VALUES (?, ?, ?, ?, ?)'
        );

        $stmtLog = $pdo->prepare(
            'INSERT INTO entrenamiento_log (partida_id, pokemon_uid) VALUES (?, ?)'
        );

        foreach ($sesiones as $s) {
            $pokemonId  = $catPokemon[$s['pokemon_nombre']] ?? null;
            if ($pokemonId === null) throw new Exception("Pokemon desconocido: {$s['pokemon_nombre']}");
            $pokemonUid = str_req($s, 'pokemon_uid', 50);

            $stmtS->execute([
                $partidaId,
                $pokemonUid,
                $pokemonId,
                int_req($s, 'pe_inicial'),
                int_req($s, 'pe_gastado'),
                int_req($s, 'pe_final'),
                int_opt($s, 'xp_ganada') ?? 0,
                int_req($s, 'nivel_antes'),
                int_req($s, 'nivel_despues'),
                int_req($s, 'cantidad_entrenamientos'),
            ]);
            $sesionId = (int) $pdo->lastInsertId();

            foreach ($s['stats'] as $stat) {
                $statId = $catStats[$stat['stat_nombre']] ?? null;
                if ($statId === null) throw new Exception("Stat desconocido: {$stat['stat_nombre']}");

                $stmtE->execute([
                    $sesionId,
                    $statId,
                    int_req($stat, 'cantidad_entrenada'),
                    int_req($stat, 'valor_antes'),
                    int_req($stat, 'valor_despues'),
                ]);
            }

            $stmtLog->execute([$partidaId, $pokemonUid]);
        }

        $pdo->commit();
        echo json_encode(['ok' => true, 'insertadas' => count($sesiones)]);

    } catch (Exception $ex) {
        $pdo->rollBack();
        http_response_code(500);
        echo json_encode(['error' => $ex->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['error' => 'Método no permitido']);
}
