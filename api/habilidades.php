<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
require_once __DIR__ . '/config.php';

try {
    $rows = $pdo->query(
        'SELECT identificador, elemento, rareza, nombre, tipo, potencia, `precision`, descripcion, efecto, escala
         FROM habilidades_ascension_catalogo
         ORDER BY elemento, rareza, identificador'
    )->fetchAll(PDO::FETCH_ASSOC);

    foreach ($rows as &$r) {
        $r['potencia']    = $r['potencia']  !== null ? (int) $r['potencia']  : null;
        $r['precision']   = $r['precision'] !== null ? (int) $r['precision'] : null;
        $r['descripcion'] = json_decode($r['descripcion'], true);
        $r['efecto']      = $r['efecto']    !== null ? json_decode($r['efecto'], true) : null;
    }

    echo json_encode($rows);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Error al cargar catálogo de habilidades']);
}
