<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

require_once __DIR__ . '/config.php';

$metodo = $_SERVER['REQUEST_METHOD'];

// GET /api/partidas.php          → lista todas las partidas
// GET /api/partidas.php?id=X     → datos completos de una partida
if ($metodo === 'GET') {

    if (isset($_GET['id'])) {
        $id = (int) $_GET['id'];

        $stmt = $pdo->prepare('SELECT id, nombre, creada_en FROM partidas WHERE id = ?');
        $stmt->execute([$id]);
        $partida = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$partida) {
            http_response_code(404);
            echo json_encode(['error' => 'Partida no encontrada']);
            exit;
        }

        $stmt = $pdo->prepare('SELECT * FROM partida_estado WHERE partida_id = ?');
        $stmt->execute([$id]);
        $estado = $stmt->fetch(PDO::FETCH_ASSOC);
        $estado['ultimo_descanso']        = $estado['ultimo_descanso']        !== null ? (int) $estado['ultimo_descanso']        : null;
        $estado['descansando_hasta']      = $estado['descansando_hasta']      !== null ? (int) $estado['descansando_hasta']      : null;
        $estado['captura_cooldown_hasta'] = $estado['captura_cooldown_hasta'] !== null ? (int) $estado['captura_cooldown_hasta'] : null;
        $estado['capturas_disponibles']   = (int) $estado['capturas_disponibles'];
        $estado['pe_descanso']            = (int) $estado['pe_descanso'];

        $stmt = $pdo->prepare('SELECT * FROM pokemon_partida WHERE partida_id = ?');
        $stmt->execute([$id]);
        $pokemon = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($pokemon as &$p) {
            $p['stats']           = json_decode($p['stats'], true);
            $p['en_equipo']       = (bool) $p['en_equipo'];
            $p['slot_equipo']     = $p['slot_equipo'] !== null ? (int) $p['slot_equipo'] : null;
            $p['nivel']           = (int) $p['nivel'];
            $p['nivel_ascension'] = (int) $p['nivel_ascension'];
            $p['hp_actual']       = (int) $p['hp_actual'];
            $p['pe']              = (int) $p['pe'];
        }

        $stmt = $pdo->prepare('SELECT material_id, cantidad FROM inventario_partida WHERE partida_id = ?');
        $stmt->execute([$id]);
        $inventario = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($inventario as &$inv) {
            $inv['cantidad'] = (int) $inv['cantidad'];
        }

        echo json_encode([
            'id'         => (int) $partida['id'],
            'nombre'     => $partida['nombre'],
            'creada_en'  => $partida['creada_en'],
            'estado'     => $estado,
            'pokemon'    => $pokemon,
            'inventario' => $inventario,
        ]);

    } else {
        $stmt = $pdo->query('SELECT id, nombre, creada_en FROM partidas ORDER BY creada_en DESC');
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }
}

// POST → guarda una partida nueva (todas las tablas en transacción)
elseif ($metodo === 'POST') {
    $body = json_decode(file_get_contents('php://input'), true);

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare('INSERT INTO partidas (nombre, creada_en, ultima_modificacion) VALUES (?, NOW(), NOW())');
        $stmt->execute([$body['nombre']]);
        $partidaId = (int) $pdo->lastInsertId();

        $e = $body['estado'];
        $stmt = $pdo->prepare(
            'INSERT INTO partida_estado
             (partida_id, entrenador_nombre, clase_id, ultimo_descanso, descansando_hasta, pe_descanso, captura_cooldown_hasta, capturas_disponibles)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $partidaId, $e['entrenador_nombre'], $e['clase_id'],
            $e['ultimo_descanso'], $e['descansando_hasta'], $e['pe_descanso'],
            $e['captura_cooldown_hasta'], $e['capturas_disponibles'],
        ]);

        $stmt = $pdo->prepare(
            'INSERT INTO pokemon_partida
             (partida_id, uid, nombre, elemento, rareza, nivel, nivel_ascension, hp_actual, pe, stats, en_equipo, slot_equipo)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        foreach ($body['pokemon'] as $p) {
            $stmt->execute([
                $partidaId, $p['uid'], $p['nombre'], $p['elemento'], $p['rareza'],
                $p['nivel'], $p['nivel_ascension'], $p['hp_actual'], $p['pe'],
                json_encode($p['stats']), $p['en_equipo'] ? 1 : 0, $p['slot_equipo'],
            ]);
        }

        $stmt = $pdo->prepare('INSERT INTO inventario_partida (partida_id, material_id, cantidad) VALUES (?, ?, ?)');
        foreach ($body['inventario'] as $inv) {
            $stmt->execute([$partidaId, $inv['material_id'], $inv['cantidad']]);
        }

        $pdo->commit();
        echo json_encode(['id' => $partidaId]);

    } catch (Exception $ex) {
        $pdo->rollBack();
        http_response_code(500);
        echo json_encode(['error' => $ex->getMessage()]);
    }
}

// PUT → sobreescribe una partida existente (todas las tablas en transacción)
elseif ($metodo === 'PUT') {
    $body = json_decode(file_get_contents('php://input'), true);
    $id   = (int) $body['id'];

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare('UPDATE partidas SET nombre = ?, ultima_modificacion = NOW() WHERE id = ?');
        $stmt->execute([$body['nombre'], $id]);

        $stmt = $pdo->prepare('DELETE FROM partida_estado WHERE partida_id = ?');
        $stmt->execute([$id]);

        $e = $body['estado'];
        $stmt = $pdo->prepare(
            'INSERT INTO partida_estado
             (partida_id, entrenador_nombre, clase_id, ultimo_descanso, descansando_hasta, pe_descanso, captura_cooldown_hasta, capturas_disponibles)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $id, $e['entrenador_nombre'], $e['clase_id'],
            $e['ultimo_descanso'], $e['descansando_hasta'], $e['pe_descanso'],
            $e['captura_cooldown_hasta'], $e['capturas_disponibles'],
        ]);

        $stmt = $pdo->prepare('DELETE FROM pokemon_partida WHERE partida_id = ?');
        $stmt->execute([$id]);

        $stmt = $pdo->prepare(
            'INSERT INTO pokemon_partida
             (partida_id, uid, nombre, elemento, rareza, nivel, nivel_ascension, hp_actual, pe, stats, en_equipo, slot_equipo)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        foreach ($body['pokemon'] as $p) {
            $stmt->execute([
                $id, $p['uid'], $p['nombre'], $p['elemento'], $p['rareza'],
                $p['nivel'], $p['nivel_ascension'], $p['hp_actual'], $p['pe'],
                json_encode($p['stats']), $p['en_equipo'] ? 1 : 0, $p['slot_equipo'],
            ]);
        }

        $stmt = $pdo->prepare('DELETE FROM inventario_partida WHERE partida_id = ?');
        $stmt->execute([$id]);

        $stmt = $pdo->prepare('INSERT INTO inventario_partida (partida_id, material_id, cantidad) VALUES (?, ?, ?)');
        foreach ($body['inventario'] as $inv) {
            $stmt->execute([$id, $inv['material_id'], $inv['cantidad']]);
        }

        $pdo->commit();
        echo json_encode(['ok' => true]);

    } catch (Exception $ex) {
        $pdo->rollBack();
        http_response_code(500);
        echo json_encode(['error' => $ex->getMessage()]);
    }
}

// DELETE → elimina una partida (CASCADE borra el resto)
elseif ($metodo === 'DELETE') {
    $body = json_decode(file_get_contents('php://input'), true);
    $stmt = $pdo->prepare('DELETE FROM partidas WHERE id = ?');
    $stmt->execute([$body['id']]);
    echo json_encode(['ok' => true]);
}
