<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/validar.php';

$metodo = $_SERVER['REQUEST_METHOD'];

// GET /api/partidas.php          → lista todas las partidas
// GET /api/partidas.php?id=X     → datos completos de una partida
if ($metodo === 'GET') {

    if (isset($_GET['stats'])) {
        $id = int_get('stats');
        try {
            $stmt = $pdo->prepare(
                'SELECT COUNT(b.id) AS total_batallas,
                        SUM(CASE WHEN br.nombre = ? THEN 1 ELSE 0 END) AS victorias,
                        SUM(CASE WHEN br.nombre = ? THEN 1 ELSE 0 END) AS derrotas,
                        SUM(CASE WHEN be.nombre = \'abandono\' THEN 1 ELSE 0 END) AS huidas,
                        ROUND(AVG(b.turnos_totales), 1) AS turnos_promedio
                 FROM partidas p
                 LEFT JOIN batallas b             ON b.partida_id = p.id
                 LEFT JOIN batalla_resultados br  ON br.id = b.resultado_id
                 LEFT JOIN batalla_estados     be ON be.id = b.estado_id
                 WHERE p.id = ?
                 GROUP BY p.id'
            );
            $stmt->execute(['victoria', 'derrota', $id]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$row) {
                echo json_encode(['total_batallas' => 0, 'victorias' => 0, 'derrotas' => 0, 'huidas' => 0, 'turnos_promedio' => null]);
            } else {
                echo json_encode([
                    'total_batallas'  => (int) $row['total_batallas'],
                    'victorias'       => (int) $row['victorias'],
                    'derrotas'        => (int) $row['derrotas'],
                    'huidas'          => (int) $row['huidas'],
                    'turnos_promedio' => $row['turnos_promedio'] !== null ? (float) $row['turnos_promedio'] : null,
                ]);
            }
        } catch (Exception $ex) {
            http_response_code(500);
            echo json_encode(['error' => $ex->getMessage()]);
        }

    } elseif (isset($_GET['id'])) {
        $id = int_get('id');

        // JOIN para recuperar clase_id como identificador string ('fuego', 'agua', ...) y sus stats
        $stmt = $pdo->prepare(
            'SELECT p.id, p.nombre, p.creada_en, p.ultima_modificacion,
                    e.nombre AS entrenador_nombre, cc.identificador AS clase_id, cc.stats AS clase_stats,
                    p.ultimo_descanso, p.descansando_hasta, p.pe_descanso,
                    p.captura_cooldown_hasta, p.capturas_disponibles
             FROM partidas p
             JOIN clases_catalogo cc ON cc.id = p.clase_id
             JOIN entrenadores e    ON e.id  = p.entrenador_id
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
            'clase_stats'            => json_decode($partida['clase_stats'], true),
            'ultimo_descanso'        => $partida['ultimo_descanso']        !== null ? (int) $partida['ultimo_descanso']        : null,
            'descansando_hasta'      => $partida['descansando_hasta']      !== null ? (int) $partida['descansando_hasta']      : null,
            'pe_descanso'            => (int) $partida['pe_descanso'],
            'captura_cooldown_hasta' => $partida['captura_cooldown_hasta'] !== null ? (int) $partida['captura_cooldown_hasta'] : null,
            'capturas_disponibles'   => (int) $partida['capturas_disponibles'],
        ];

        $stmt = $pdo->prepare(
            'SELECT uid, nombre, elemento, rareza,
                    nivel, nivel_ascension, hp_actual, pe, stats,
                    habilidades_ascension, habilidad_rareza, en_equipo, slot_equipo
             FROM pokemon_partida WHERE partida_id = ?'
        );
        $stmt->execute([$id]);
        $pokemon = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($pokemon as &$p) {
            $p['stats']                 = json_decode($p['stats'], true);
            $p['habilidades_ascension'] = $p['habilidades_ascension'] !== null
                ? json_decode($p['habilidades_ascension'], true) : [];
            $p['en_equipo']             = (bool) $p['en_equipo'];
            $p['slot_equipo']           = $p['slot_equipo'] !== null ? (int) $p['slot_equipo'] : null;
            $p['nivel']                 = (int) $p['nivel'];
            $p['nivel_ascension']       = (int) $p['nivel_ascension'];
            $p['hp_actual']             = (int) $p['hp_actual'];
            $p['pe']                    = (int) $p['pe'];
        }

        $stmt = $pdo->prepare(
            'SELECT m.tipo AS material_id, ip.cantidad
             FROM inventario_partida ip
             JOIN materiales m ON m.id = ip.material_id
             WHERE ip.partida_id = ?'
        );
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
        $limite = 10;
        $pagina = max(1, int_get('pagina') ?? 1);
        $offset = ($pagina - 1) * $limite;

        $total = (int) $pdo->query('SELECT COUNT(*) FROM partidas')->fetchColumn();

        $stmt = $pdo->prepare(
            'SELECT p.id, p.nombre, p.creada_en, e.nombre AS entrenador_nombre, cc.identificador AS clase_id
             FROM partidas p
             JOIN entrenadores e    ON e.id  = p.entrenador_id
             JOIN clases_catalogo cc ON cc.id = p.clase_id
             ORDER BY p.creada_en DESC LIMIT ? OFFSET ?'
        );
        $stmt->bindValue(1, $limite, PDO::PARAM_INT);
        $stmt->bindValue(2, $offset, PDO::PARAM_INT);
        $stmt->execute();

        echo json_encode([
            'partidas' => $stmt->fetchAll(PDO::FETCH_ASSOC),
            'total'    => $total,
            'pagina'   => $pagina,
            'paginas'  => (int) ceil($total / $limite),
        ]);
    }
}

// POST → guarda una partida nueva (todas las tablas en transacción)
elseif ($metodo === 'POST') {
    $body = json_decode(file_get_contents('php://input'), true);

    $pdo->beginTransaction();
    try {
        $e = arr_req($body, 'estado');

        // Resolver clase string → id numérico
        $catClases = $pdo->query('SELECT identificador, id FROM clases_catalogo')
                         ->fetchAll(PDO::FETCH_KEY_PAIR);
        $claseIdStr = str_req($e, 'clase_id', 50);
        $claseId    = $catClases[$claseIdStr] ?? null;
        if ($claseId === null) throw new Exception("Clase desconocida: {$claseIdStr}");

        // Resolver entrenador_nombre → entrenador_id (crear si no existe)
        $entrenadorNombre = str_req($e, 'entrenador_nombre', 100);
        $stmtEnt = $pdo->prepare('SELECT id FROM entrenadores WHERE nombre = ?');
        $stmtEnt->execute([$entrenadorNombre]);
        $entrenadorId = $stmtEnt->fetchColumn();
        if (!$entrenadorId) {
            $pdo->prepare('INSERT INTO entrenadores (nombre) VALUES (?)')->execute([$entrenadorNombre]);
            $entrenadorId = (int) $pdo->lastInsertId();
        }

        $stmt = $pdo->prepare(
            'INSERT INTO partidas
             (nombre, creada_en, ultima_modificacion,
              entrenador_id, clase_id,
              ultimo_descanso, descansando_hasta, pe_descanso,
              captura_cooldown_hasta, capturas_disponibles)
             VALUES (?, NOW(), NOW(), ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            str_req($body, 'nombre', 100),
            $entrenadorId, $claseId,
            int_opt($e, 'ultimo_descanso'), int_opt($e, 'descansando_hasta'), int_opt($e, 'pe_descanso') ?? 0,
            int_opt($e, 'captura_cooldown_hasta'), int_opt($e, 'capturas_disponibles') ?? 3,
        ]);
        $partidaId = (int) $pdo->lastInsertId();

        // Catálogo de pokémon (nombre → id) para resolver la FK
        $catPokemon = $pdo->query('SELECT nombre, id FROM pokemon_catalogo')
                          ->fetchAll(PDO::FETCH_KEY_PAIR);

        $stmt = $pdo->prepare(
            'INSERT INTO pokemon_partida
             (partida_id, uid, nombre, elemento, rareza, pokemon_id,
              nivel, nivel_ascension, hp_actual, pe, stats,
              habilidades_ascension, habilidad_rareza, en_equipo, slot_equipo)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        foreach (arr_req($body, 'pokemon') as $p) {
            $nombre    = str_req($p, 'nombre', 100);
            $pokemonId = $catPokemon[$nombre] ?? null;
            if ($pokemonId === null) throw new InvalidArgumentException("Pokemon no encontrado en catálogo: {$nombre}");
            $stmt->execute([
                $partidaId,
                str_req($p, 'uid', 50),
                $nombre,
                str_req($p, 'elemento', 30),
                str_req($p, 'rareza', 20),
                $pokemonId,
                int_req($p, 'nivel'),
                int_req($p, 'nivel_ascension'),
                int_req($p, 'hp_actual'),
                int_req($p, 'pe'),
                json_encode(arr_req($p, 'stats')),
                json_encode(arr_str($p, 'habilidades_ascension', 40)),
                str_opt($p, 'habilidad_rareza', 40),
                bool_req($p, 'en_equipo') ? 1 : 0,
                int_opt($p, 'slot_equipo'),
            ]);
        }

        $catMateriales = $pdo->query('SELECT tipo, id FROM materiales')->fetchAll(PDO::FETCH_KEY_PAIR);
        $stmt = $pdo->prepare('INSERT INTO inventario_partida (partida_id, material_id, cantidad) VALUES (?, ?, ?)');
        foreach (arr_req($body, 'inventario') as $inv) {
            $materialId = $catMateriales[str_req($inv, 'material_id', 50)] ?? null;
            if ($materialId === null) throw new InvalidArgumentException("Material no encontrado: {$inv['material_id']}");
            $stmt->execute([$partidaId, $materialId, int_req($inv, 'cantidad')]);
        }

        $pdo->commit();
        echo json_encode(['id' => $partidaId]);

    } catch (InvalidArgumentException $ex) {
        $pdo->rollBack();
        http_response_code(400);
        echo json_encode(['error' => $ex->getMessage()]);
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
        $e = arr_req($body, 'estado');

        $catClases  = $pdo->query('SELECT identificador, id FROM clases_catalogo')
                          ->fetchAll(PDO::FETCH_KEY_PAIR);
        $claseIdStr = str_req($e, 'clase_id', 50);
        $claseId    = $catClases[$claseIdStr] ?? null;
        if ($claseId === null) throw new Exception("Clase desconocida: {$claseIdStr}");

        // Resolver entrenador_nombre → entrenador_id (crear si no existe)
        $entrenadorNombre = str_req($e, 'entrenador_nombre', 100);
        $stmtEnt = $pdo->prepare('SELECT id FROM entrenadores WHERE nombre = ?');
        $stmtEnt->execute([$entrenadorNombre]);
        $entrenadorId = $stmtEnt->fetchColumn();
        if (!$entrenadorId) {
            $pdo->prepare('INSERT INTO entrenadores (nombre) VALUES (?)')->execute([$entrenadorNombre]);
            $entrenadorId = (int) $pdo->lastInsertId();
        }

        $stmt = $pdo->prepare(
            'UPDATE partidas
             SET nombre = ?, ultima_modificacion = NOW(),
                 entrenador_id = ?, clase_id = ?,
                 ultimo_descanso = ?, descansando_hasta = ?, pe_descanso = ?,
                 captura_cooldown_hasta = ?, capturas_disponibles = ?
             WHERE id = ?'
        );
        $stmt->execute([
            str_req($body, 'nombre', 100),
            $entrenadorId, $claseId,
            int_opt($e, 'ultimo_descanso'), int_opt($e, 'descansando_hasta'), int_opt($e, 'pe_descanso') ?? 0,
            int_opt($e, 'captura_cooldown_hasta'), int_opt($e, 'capturas_disponibles') ?? 3,
            $id,
        ]);

        $stmt = $pdo->prepare('DELETE FROM pokemon_partida WHERE partida_id = ?');
        $stmt->execute([$id]);

        $catPokemon = $pdo->query('SELECT nombre, id FROM pokemon_catalogo')
                          ->fetchAll(PDO::FETCH_KEY_PAIR);

        $stmt = $pdo->prepare(
            'INSERT INTO pokemon_partida
             (partida_id, uid, nombre, elemento, rareza, pokemon_id,
              nivel, nivel_ascension, hp_actual, pe, stats,
              habilidades_ascension, habilidad_rareza, en_equipo, slot_equipo)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        foreach (arr_req($body, 'pokemon') as $p) {
            $nombre    = str_req($p, 'nombre', 100);
            $pokemonId = $catPokemon[$nombre] ?? null;
            if ($pokemonId === null) throw new InvalidArgumentException("Pokemon no encontrado en catálogo: {$nombre}");
            $stmt->execute([
                $id,
                str_req($p, 'uid', 50),
                $nombre,
                str_req($p, 'elemento', 30),
                str_req($p, 'rareza', 20),
                $pokemonId,
                int_req($p, 'nivel'),
                int_req($p, 'nivel_ascension'),
                int_req($p, 'hp_actual'),
                int_req($p, 'pe'),
                json_encode(arr_req($p, 'stats')),
                json_encode(arr_str($p, 'habilidades_ascension', 40)),
                str_opt($p, 'habilidad_rareza', 40),
                bool_req($p, 'en_equipo') ? 1 : 0,
                int_opt($p, 'slot_equipo'),
            ]);
        }

        $stmt = $pdo->prepare('DELETE FROM inventario_partida WHERE partida_id = ?');
        $stmt->execute([$id]);

        $catMateriales = $pdo->query('SELECT tipo, id FROM materiales')->fetchAll(PDO::FETCH_KEY_PAIR);
        $stmt = $pdo->prepare('INSERT INTO inventario_partida (partida_id, material_id, cantidad) VALUES (?, ?, ?)');
        foreach (arr_req($body, 'inventario') as $inv) {
            $materialId = $catMateriales[str_req($inv, 'material_id', 50)] ?? null;
            if ($materialId === null) throw new InvalidArgumentException("Material no encontrado: {$inv['material_id']}");
            $stmt->execute([$id, $materialId, int_req($inv, 'cantidad')]);
        }

        $pdo->commit();
        echo json_encode(['ok' => true]);

    } catch (InvalidArgumentException $ex) {
        $pdo->rollBack();
        http_response_code(400);
        echo json_encode(['error' => $ex->getMessage()]);
    } catch (Exception $ex) {
        $pdo->rollBack();
        http_response_code(500);
        echo json_encode(['error' => $ex->getMessage()]);
    }
}

// DELETE → elimina una partida y todo su historial asociado
elseif ($metodo === 'DELETE') {
    $body = json_decode(file_get_contents('php://input'), true);
    $id   = int_req($body, 'id');

    try {
        $pdo->prepare('CALL sp_eliminar_partida(?)')->execute([$id]);
        echo json_encode(['ok' => true]);
    } catch (Exception $ex) {
        http_response_code(500);
        echo json_encode(['error' => $ex->getMessage()]);
    }
}
