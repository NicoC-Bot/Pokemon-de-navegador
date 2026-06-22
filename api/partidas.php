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

        // JOIN para recuperar clase_id como identificador string ('fuego', 'agua', ...)
        $stmt = $pdo->prepare(
            'SELECT p.id, p.nombre, p.creada_en, p.ultima_modificacion,
                    p.entrenador_nombre, cc.identificador AS clase_id,
                    p.ultimo_descanso, p.descansando_hasta, p.pe_descanso,
                    p.captura_cooldown_hasta, p.capturas_disponibles
             FROM partidas p
             JOIN clases_catalogo cc ON cc.id = p.clase_id
             WHERE p.id = ?'
        );
        $stmt->execute([$id]);
        $partida = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$partida) {
            http_response_code(404);
            echo json_encode(['error' => 'Partida no encontrada']);
            exit;
        }

        $estado = [
            'entrenador_nombre'      => $partida['entrenador_nombre'],
            'clase_id'               => $partida['clase_id'],
            'ultimo_descanso'        => $partida['ultimo_descanso']        !== null ? (int) $partida['ultimo_descanso']        : null,
            'descansando_hasta'      => $partida['descansando_hasta']      !== null ? (int) $partida['descansando_hasta']      : null,
            'pe_descanso'            => (int) $partida['pe_descanso'],
            'captura_cooldown_hasta' => $partida['captura_cooldown_hasta'] !== null ? (int) $partida['captura_cooldown_hasta'] : null,
            'capturas_disponibles'   => (int) $partida['capturas_disponibles'],
        ];

        // JOIN para recuperar nombre, elemento y rareza del catálogo
        $stmt = $pdo->prepare(
            'SELECT pp.uid, pc.nombre, e.nombre AS elemento, rt.nombre AS rareza,
                    pp.nivel, pp.nivel_ascension, pp.hp_actual, pp.pe, pp.stats,
                    pp.en_equipo, pp.slot_equipo
             FROM pokemon_partida pp
             JOIN pokemon_catalogo pc ON pc.id = pp.pokemon_id
             JOIN elementos        e  ON e.id  = pc.elemento_id
             JOIN rareza_tipos     rt ON rt.id = pc.rareza_id
             WHERE pp.partida_id = ?'
        );
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
        $e = $body['estado'];

        // Resolver clase string → id numérico
        $catClases = $pdo->query('SELECT identificador, id FROM clases_catalogo')
                         ->fetchAll(PDO::FETCH_KEY_PAIR);
        $claseId = $catClases[$e['clase_id']] ?? null;
        if ($claseId === null) throw new Exception("Clase desconocida: {$e['clase_id']}");

        $stmt = $pdo->prepare(
            'INSERT INTO partidas
             (nombre, creada_en, ultima_modificacion,
              entrenador_nombre, clase_id,
              ultimo_descanso, descansando_hasta, pe_descanso,
              captura_cooldown_hasta, capturas_disponibles)
             VALUES (?, NOW(), NOW(), ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $body['nombre'],
            $e['entrenador_nombre'], $claseId,
            $e['ultimo_descanso'], $e['descansando_hasta'], $e['pe_descanso'] ?? 0,
            $e['captura_cooldown_hasta'], $e['capturas_disponibles'] ?? 3,
        ]);
        $partidaId = (int) $pdo->lastInsertId();

        // Catálogo de pokémon (nombre → id) para resolver la FK
        $catPokemon = $pdo->query('SELECT nombre, id FROM pokemon_catalogo')
                          ->fetchAll(PDO::FETCH_KEY_PAIR);

        $stmt = $pdo->prepare(
            'INSERT INTO pokemon_partida
             (partida_id, uid, pokemon_id, nivel, nivel_ascension, hp_actual, pe, stats, en_equipo, slot_equipo)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        foreach ($body['pokemon'] as $p) {
            $pokemonId = $catPokemon[$p['nombre']] ?? null;
            if ($pokemonId === null) throw new Exception("Pokemon no encontrado en catálogo: {$p['nombre']}");
            $stmt->execute([
                $partidaId, $p['uid'], $pokemonId,
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
        $e = $body['estado'];

        $catClases = $pdo->query('SELECT identificador, id FROM clases_catalogo')
                         ->fetchAll(PDO::FETCH_KEY_PAIR);
        $claseId = $catClases[$e['clase_id']] ?? null;
        if ($claseId === null) throw new Exception("Clase desconocida: {$e['clase_id']}");

        $stmt = $pdo->prepare(
            'UPDATE partidas
             SET nombre = ?, ultima_modificacion = NOW(),
                 entrenador_nombre = ?, clase_id = ?,
                 ultimo_descanso = ?, descansando_hasta = ?, pe_descanso = ?,
                 captura_cooldown_hasta = ?, capturas_disponibles = ?
             WHERE id = ?'
        );
        $stmt->execute([
            $body['nombre'],
            $e['entrenador_nombre'], $claseId,
            $e['ultimo_descanso'], $e['descansando_hasta'], $e['pe_descanso'] ?? 0,
            $e['captura_cooldown_hasta'], $e['capturas_disponibles'] ?? 3,
            $id,
        ]);

        $stmt = $pdo->prepare('DELETE FROM pokemon_partida WHERE partida_id = ?');
        $stmt->execute([$id]);

        $catPokemon = $pdo->query('SELECT nombre, id FROM pokemon_catalogo')
                          ->fetchAll(PDO::FETCH_KEY_PAIR);

        $stmt = $pdo->prepare(
            'INSERT INTO pokemon_partida
             (partida_id, uid, pokemon_id, nivel, nivel_ascension, hp_actual, pe, stats, en_equipo, slot_equipo)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        foreach ($body['pokemon'] as $p) {
            $pokemonId = $catPokemon[$p['nombre']] ?? null;
            if ($pokemonId === null) throw new Exception("Pokemon no encontrado en catálogo: {$p['nombre']}");
            $stmt->execute([
                $id, $p['uid'], $pokemonId,
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

// DELETE → elimina una partida y todo su historial asociado
elseif ($metodo === 'DELETE') {
    $body = json_decode(file_get_contents('php://input'), true);
    $id   = (int) $body['id'];

    $pdo->beginTransaction();
    try {
        $pdo->prepare('DELETE FROM entrenamiento_sesiones WHERE partida_id = ?')->execute([$id]);
        $pdo->prepare('DELETE FROM batallas              WHERE partida_id = ?')->execute([$id]);
        $pdo->prepare('DELETE FROM inventario_partida    WHERE partida_id = ?')->execute([$id]);
        $pdo->prepare('DELETE FROM pokemon_partida       WHERE partida_id = ?')->execute([$id]);
        $pdo->prepare('DELETE FROM partidas              WHERE id         = ?')->execute([$id]);
        $pdo->commit();
        echo json_encode(['ok' => true]);
    } catch (Exception $ex) {
        $pdo->rollBack();
        http_response_code(500);
        echo json_encode(['error' => $ex->getMessage()]);
    }
}
