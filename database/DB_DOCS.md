# Base de datos — Practica_2

## Índice

- [Tablas](#tablas) — línea 21
- [Normalizaciones aplicadas](#normalizaciones-aplicadas) — línea 74
- [Índices](#índices) — línea 83
- [Vistas](#vistas) — línea 100
- [Stored Procedures](#stored-procedures) — línea 113
- [Triggers](#triggers) — línea 124
- [Consultar logs](#consultar-logs) — línea 136

---

Motor: MySQL / MariaDB  
Charset: utf8mb4  
Schema oficial: `database/schema.sql`

---

## Tablas

### Lookup (datos fijos)
| Tabla | Descripción |
|-------|-------------|
| `elementos` | Tipos de elemento (Fuego, Agua, Planta, etc.) |
| `rareza_tipos` | Niveles de rareza (comun, raro, legendario, etc.) |
| `batalla_estados` | Estados de batalla (terminado, abandono) |
| `batalla_resultados` | Resultados de batalla (victoria, derrota) |
| `participante_tipos` | Tipo de participante en batalla (jugador, oponente) |
| `tipos_accion` | Acciones en batalla (ataque, habilidad, defender, relevo) |
| `tipos_material` | Categorías de material (curativo, ascension, etc.) |
| `habilidad_tipos` | Tipos de habilidad (fisico, especial, estado) |
| `stat_tipos` | Tipos de stat (HP, Ataque, Defensa, etc.) |
| `clases_catalogo` | Clases de entrenador (fuego, agua, planta, etc.) |

### Catálogo
| Tabla | Descripción |
|-------|-------------|
| `pokemon_catalogo` | 28 pokémon disponibles con elemento y rareza |
| `habilidades_catalogo` | 56 habilidades (2 por pokémon) |
| `materiales` | Ítems del juego con tipo numérico y columna `tipo` (identificador string) |

### Datos de partida
| Tabla | Descripción |
|-------|-------------|
| `entrenadores` | Nombres únicos de entrenadores |
| `partidas` | Partidas guardadas, vinculadas a entrenador y clase |
| `pokemon_partida` | Pokémon capturados por partida |
| `inventario_partida` | Materiales por partida |

### Batallas
| Tabla | Descripción |
|-------|-------------|
| `batallas` | Registro de cada batalla |
| `batalla_participantes` | Pokémon participantes por batalla |
| `batalla_turnos` | Acciones turno a turno |

### Entrenamientos
| Tabla | Descripción |
|-------|-------------|
| `entrenamiento_sesiones` | Sesiones de entrenamiento por pokémon |
| `entrenamiento_stats` | Stats entrenados por sesión |

### Log (auditoría)
| Tabla | Descripción |
|-------|-------------|
| `partidas_log` | Registro de creación y eliminación de partidas |
| `pokemon_nivel_log` | Registro de subidas de nivel de pokémon |
| `batallas_log` | Registro de fecha de cada batalla completada |

---

## Normalizaciones aplicadas

- `partidas.entrenador_nombre` → tabla `entrenadores` con FK `entrenador_id`
- `materiales.id` cambió de `VARCHAR(64)` a `INT AUTO_INCREMENT`; el identificador string pasó a la columna `tipo`
- `inventario_partida.material_id` actualizado de string a `INT` con FK numérica
- Tabla `equipos` renombrada a `participante_tipos`

---

## Índices

| Índice | Tabla | Columna |
|--------|-------|---------|
| `idx_pp_partida_id` | `pokemon_partida` | `partida_id` |
| `idx_pp_pokemon_id` | `pokemon_partida` | `pokemon_id` |
| `idx_pp_en_equipo` | `pokemon_partida` | `en_equipo` |
| `idx_inv_partida_id` | `inventario_partida` | `partida_id` |
| `idx_bat_partida_id` | `batallas` | `partida_id` |
| `idx_part_batalla_id` | `batalla_participantes` | `batalla_id` |
| `idx_turno_batalla_id` | `batalla_turnos` | `batalla_id` |
| `idx_ent_partida_id` | `entrenamiento_sesiones` | `partida_id` |
| `idx_partidas_entrenador` | `partidas` | `entrenador_id` |
| `idx_materiales_tipo` | `materiales` | `tipo` |

---

## Vistas

### `vista_entrenadores_pokemon`
Muestra cada partida con su entrenador y la cantidad de pokémon en posesión.

```sql
SELECT * FROM vista_entrenadores_pokemon;
```

Columnas: `partida_id`, `partida`, `entrenador`, `total_pokemon`

---

## Stored Procedures

### `crear_tabla(nombre_tabla)`
Crea una tabla nueva con 3 columnas placeholder listas para renombrar.

```sql
CALL crear_tabla('nombre_de_tu_tabla');
```

---

## Triggers

| Trigger | Evento | Acción |
|---------|--------|--------|
| `after_partida_insert` | AFTER INSERT en `partidas` | Registra "creada" en `partidas_log` |
| `after_partida_delete` | AFTER DELETE en `partidas` | Registra "eliminada" en `partidas_log` |
| `before_pokemon_equipo` | BEFORE INSERT en `pokemon_partida` | Bloquea si el equipo ya tiene 6 pokémon |
| `after_pokemon_nivel` | AFTER UPDATE en `pokemon_partida` | Registra subida de nivel en `pokemon_nivel_log` |
| `after_batalla_insert` | AFTER INSERT en `batallas` | Registra fecha en `batallas_log` |

---

## Consultar logs

```sql
SELECT * FROM partidas_log;
SELECT * FROM pokemon_nivel_log;
SELECT * FROM batallas_log;
```
