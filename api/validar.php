<?php
function str_req(array $d, string $campo, int $max = 255): string {
    $v = trim((string) ($d[$campo] ?? ''));
    if ($v === '') throw new InvalidArgumentException("Campo requerido: {$campo}");
    if (strlen($v) > $max) throw new InvalidArgumentException("'{$campo}' supera {$max} caracteres");
    return $v;
}

function int_req(array $d, string $campo): int {
    $v = $d[$campo] ?? null;
    if ($v === null || !is_numeric($v)) throw new InvalidArgumentException("Se esperaba entero en: {$campo}");
    return (int) $v;
}

function int_opt(array $d, string $campo): ?int {
    $v = $d[$campo] ?? null;
    if ($v === null) return null;
    if (!is_numeric($v)) throw new InvalidArgumentException("Se esperaba entero o null en: {$campo}");
    return (int) $v;
}

function bool_req(array $d, string $campo): bool {
    return !empty($d[$campo]);
}

function arr_req(array $d, string $campo): array {
    $v = $d[$campo] ?? null;
    if (!is_array($v)) throw new InvalidArgumentException("Se esperaba arreglo en: {$campo}");
    return $v;
}

function int_get(string $param): ?int {
    if (!isset($_GET[$param])) return null;
    if (!ctype_digit((string) $_GET[$param])) throw new InvalidArgumentException("Parámetro GET inválido: {$param}");
    return (int) $_GET[$param];
}
