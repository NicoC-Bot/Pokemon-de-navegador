<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/validar.php';

$metodo = $_SERVER['REQUEST_METHOD'];

// POST → registra una batalla completa en una sola transacción
// Body: { partida_id, estado, resultado, turnos_totales, participantes[], turnos[] }
// Los campos estado/resultado/equipo/tipo_accion siguen siendo strings — se resuelven a IDs aquí
if ($metodo === 'POST') {
    $body = json_decode(file_get_contents('php://input'), true);

    $pdo->beginTransaction();
    try {
        // Pre-cargar tablas lookup (nombre → id)
        $catEstados     = $pdo->query('SELECT nombre, id FROM batalla_estados')   ->fetchAll(PDO::FETCH_KEY_PAIR);
        $catResultados  = $pdo->query('SELECT nombre, id FROM batalla_resultados')->fetchAll(PDO::FETCH_KEY_PAIR);
        $catEquipos     = $pdo->query('SELECT nombre, id FROM equipos')           ->fetchAll(PDO::FETCH_KEY_PAIR);
        $catTiposAcc    = $pdo->query('SELECT nombre, id FROM tipos_accion')      ->fetchAll(PDO::FETCH_KEY_PAIR);
        $catHabilidades = $pdo->query('SELECT nombre, id FROM habilidades_catalogo')->fetchAll(PDO::FETCH_KEY_PAIR);
        $catPokemon     = $pdo->query('SELECT nombre, id FROM pokemon_catalogo')  ->fetchAll(PDO::FETCH_KEY_PAIR);

        $estadoId    = $catEstados[$body['estado']] ?? null;
        $resultadoId = isset($body['resultado']) ? ($catResultados[$body['resultado']] ?? null) : null;

        if ($estadoId === null) throw new Exception("Estado de batalla desconocido: {$body['estado']}");

        // 1. Insertar cabecera de la batalla
        $stmt = $pdo->prepare(
            'INSERT INTO batallas (partida_id, estado_id, resultado_id, turnos_totales)
             VALUES (?, ?, ?, ?)'
        );
        $stmt->execute([
            int_opt($body, 'partida_id'),
            $estadoId,
            $resultadoId,
            int_opt($body, 'turnos_totales') ?? 0,
        ]);
        $batallaId = (int) $pdo->lastInsertId();

        // 2. Insertar participantes y construir mapa "nombre|equipo" → participante_id
        $stmtP = $pdo->prepare(
            'INSERT INTO batalla_participantes (batalla_id, pokemon_id, pokemon_uid, equipo_id)
             VALUES (?, ?, ?, ?)'
        );
        $mapaId = [];  // "nombre|equipo" → id
        foreach ($body['participantes'] as $p) {
            $pokemonId = $catPokemon[$p['pokemon_nombre']] ?? null;
            $equipoId  = $catEquipos[$p['equipo']]        ?? null;

            if ($pokemonId === null) throw new Exception("Pokemon desconocido: {$p['pokemon_nombre']}");
            if ($equipoId  === null) throw new Exception("Equipo desconocido: {$p['equipo']}");

            $stmtP->execute([
                $batallaId,
                $pokemonId,
                $p['pokemon_uid'] ?? null,
                $equipoId,
            ]);
            $mapaId[$p['pokemon_nombre'] . '|' . $p['equipo']] = (int) $pdo->lastInsertId();
        }

        // 3. Insertar turnos usando el mapa
        $stmtT = $pdo->prepare(
            'INSERT INTO batalla_turnos
             (batalla_id, numero_turno, participante_id, tipo_accion_id, habilidad_id, dano_causado, objetivo_id)
             VALUES (?, ?, ?, ?, ?, ?, ?)'
        );
        foreach ($body['turnos'] as $t) {
            $participanteId = $mapaId[$t['participante'] . '|' . $t['equipo_participante']] ?? null;
            if ($participanteId === null) continue;  // participante desconocido, saltar

            $objetivoId   = null;
            if (!empty($t['objetivo']) && !empty($t['equipo_objetivo'])) {
                $objetivoId = $mapaId[$t['objetivo'] . '|' . $t['equipo_objetivo']] ?? null;
            }

            $tipoAccId  = $catTiposAcc[$t['tipo_accion']] ?? null;
            $habilidadId = isset($t['habilidad_nombre']) ? ($catHabilidades[$t['habilidad_nombre']] ?? null) : null;

            if ($tipoAccId === null) throw new Exception("Tipo de acción desconocido: {$t['tipo_accion']}");

            $stmtT->execute([
                $batallaId,
                int_req($t, 'numero_turno'),
                $participanteId,
                $tipoAccId,
                $habilidadId,
                int_opt($t, 'dano_causado'),
                $objetivoId,
            ]);
        }

        $pdo->commit();
        echo json_encode(['id' => $batallaId]);

    } catch (Exception $ex) {
        $pdo->rollBack();
        http_response_code(500);
        echo json_encode(['error' => $ex->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['error' => 'Método no permitido']);
}
