# Implementaciones del Proyecto — Practica 2

Resumen técnico de las implementaciones presentes en el proyecto.

---

## Seguridad

### SQL Injection
- **Protección:** PDO con prepared statements y placeholders `?` en todas las consultas.
- **Archivos:** `api/partidas.php`, `api/batallas.php`, `api/entrenamientos.php`
- **Ejemplo:**
  ```php
  $stmt = $pdo->prepare('SELECT * FROM partidas WHERE id = ?');
  $stmt->execute([$id]);
  ```

### Validación de tipos
- Centralizada en `api/validar.php` con funciones helper reutilizables.
- **Archivo:** `api/validar.php` — requerido en `partidas.php`, `batallas.php` y `entrenamientos.php`.

#### Funciones disponibles

**`str_req($d, $campo, $max)`**
Extrae un string. Aplica `trim()` para eliminar espacios al inicio y al final, luego verifica que no quede vacío y que no supere el largo máximo. Si falla alguna condición, lanza una excepción.
```php
str_req($body, 'nombre', 100)
// $body['nombre'] = "  Ash  "  →  retorna "Ash"
// $body['nombre'] = ""         →  lanza error
```

**`int_req($d, $campo)`**
Extrae un entero obligatorio. Usa `is_numeric()` para verificar que el valor sea un número antes de castearlo. Si el campo no existe o no es numérico, lanza una excepción.
```php
int_req($p, 'nivel')
// $p['nivel'] = 5      →  retorna 5
// $p['nivel'] = "abc"  →  lanza error
```

**`int_opt($d, $campo)`**
Igual que `int_req` pero acepta `null`. Si el campo no existe o su valor es `null`, retorna `null` sin error.
```php
int_opt($p, 'slot_equipo')
// $p['slot_equipo'] = 2     →  retorna 2
// $p['slot_equipo'] = null  →  retorna null
// $p['slot_equipo'] = "x"   →  lanza error
```

**`bool_req($d, $campo)`**
Extrae un booleano usando `!empty()`. Valores truthy (`true`, `1`) retornan `true`; valores falsy (`false`, `0`, `null`) retornan `false`. No lanza excepciones.
```php
bool_req($p, 'en_equipo')
// $p['en_equipo'] = true   →  retorna true
// $p['en_equipo'] = false  →  retorna false
```

**`arr_req($d, $campo)`**
Verifica que el campo sea un array antes de usarlo en un `foreach`. Si no existe o no es array, lanza excepción.
```php
arr_req($body, 'pokemon')
// $body['pokemon'] = [{...}]  →  retorna el array
// $body['pokemon'] = null     →  lanza error
```

**`int_get($param)`**
Lee directamente de `$_GET`. Usa `ctype_digit()` — solo acepta strings de dígitos puros. Si el parámetro no está en la URL retorna `null`; si está pero no es numérico, lanza excepción.
```php
int_get('id')
// URL: ?id=5    →  retorna 5
// URL: sin ?id  →  retorna null
// URL: ?id=abc  →  lanza error
```

> **Nota:** `ctype_digit` (usado en `int_get`) solo acepta dígitos positivos (`"5"`). `is_numeric` (usado en `int_req`/`int_opt`) también acepta decimales y negativos. Para IDs de URL se usa el más estricto.

### XSS
- Vue usa `{{ }}` que escapa HTML automáticamente en todos los templates.
- No se usa `v-html` en ningún componente.

### CORS
- Headers configurados en cada archivo PHP de la API:
  ```php
  header('Access-Control-Allow-Origin: *');
  ```
- Permite peticiones locales desde Vue (puerto 5173) hacia XAMPP (puerto 80).

---

## Base de Datos

### Normalización
- **22 tablas** en total, organizadas en tres categorías:
  - **Lookup (10):** `batalla_estados`, `batalla_resultados`, `equipos`, `tipos_accion`, `tipos_material`, `habilidad_tipos`, `stat_tipos`, `elementos`, `rareza_tipos`, `clases_catalogo`
  - **Catálogo (2):** `pokemon_catalogo`, `habilidades_catalogo`
  - **Datos (10):** `partidas`, `pokemon_partida`, `inventario_partida`, `batallas`, `batalla_participantes`, `batalla_turnos`, `materiales`, `entrenamiento_sesiones`, `entrenamiento_stats`, `entrenamiento_log`
- Sin ENUMs ni strings repetidos — todo referenciado por FK a tablas lookup.

### Foreign Keys
- Relaciones definidas con `CONSTRAINT ... FOREIGN KEY ... REFERENCES`.
- Borrado en cascada donde corresponde (`ON DELETE CASCADE`) y `ON DELETE SET NULL` en batallas al eliminar partida.

### Índices
- 10 índices creados sobre columnas de búsqueda frecuente:
  ```sql
  CREATE INDEX idx_pp_partida_id       ON pokemon_partida        (partida_id);
  CREATE INDEX idx_pp_pokemon_id       ON pokemon_partida        (pokemon_id);
  CREATE INDEX idx_pp_en_equipo        ON pokemon_partida        (en_equipo);
  CREATE INDEX idx_inv_partida_id      ON inventario_partida     (partida_id);
  CREATE INDEX idx_bat_partida_id      ON batallas               (partida_id);
  CREATE INDEX idx_part_batalla_id     ON batalla_participantes  (batalla_id);
  CREATE INDEX idx_turno_batalla_id    ON batalla_turnos         (batalla_id);
  CREATE INDEX idx_ent_partida_id      ON entrenamiento_sesiones (partida_id);
  CREATE INDEX idx_partidas_entrenador ON partidas               (entrenador_id);
  CREATE INDEX idx_materiales_tipo     ON materiales             (tipo);
  ```

### Transacciones
- Usadas en `api/batallas.php` para registrar una batalla completa de forma atómica.
- Usadas en el stored procedure `sp_eliminar_partida`.
- Si cualquier operación falla, se hace `ROLLBACK` y no queda estado inconsistente.

### Stored Procedure
- `sp_eliminar_partida(p_id INT)` — elimina una partida y todos sus datos relacionados dentro de una transacción.
- **Archivo:** `database/schema.sql` línea 423.

### Tablas de Log
- `partidas_log` — registra acciones sobre partidas (crear, modificar, eliminar).
- `pokemon_nivel_log` — registra cambios de nivel por pokemon.
- `batallas_log` — registra registro de cada batalla.
- `entrenamiento_log` — registra qué pokemon de cuál partida recibió un entrenamiento y en qué fecha. Sin detalle de stats; solo auditoría de acción. Campos: `id`, `partida_id`, `pokemon_uid`, `fecha` (DATETIME DEFAULT CURRENT_TIMESTAMP).

### Columna JSON
- `clases_catalogo.stats` almacena los bonos de stat de cada clase como JSON.
- **Archivo:** `database/schema.sql` línea 173.

### Backup
- Backup manual disponible en `database/backup.sql` generado con `mysqldump`.

---

## API REST (PHP)

| Archivo | Métodos | Descripción |
|---|---|---|
| `api/partidas.php` | GET, POST, PUT, DELETE | CRUD completo de partidas, pokemon e inventario |
| `api/batallas.php` | POST | Registra una batalla completa con participantes y turnos |
| `api/entrenamientos.php` | POST | Registra sesiones de entrenamiento por pokemon |

- Todas las respuestas en JSON (`Content-Type: application/json`).
- Códigos HTTP correctos (`200`, `201`, `400`, `404`, `500`).
- PDO con `ERRMODE_EXCEPTION` para captura de errores.

---

## Frontend (Vue 3)

### HP Persistente entre combates
- `hpActual` se mantiene entre sesiones de combate.
- Al salir de `CombateView`, se emite el HP final de cada pokemon hacia `App.vue` via `MainHub`.
- `App.vue` actualiza `equipo` y `capturados` con los HP reales.

### Items curativos
- Items de tipo `curativo` restauran HP a cualquier pokemon.
- Items de tipo `curativo-elemental` están diseñados para un elemento específico.
- La curación no supera el HP máximo del pokemon (`Math.min`).

### Sistema de batallas
- Cada combate se registra automáticamente al terminar en la base de datos.
- Se registran: estado, resultado, turnos totales, participantes y detalle de cada turno.

### Sidebar colapsable
- El sidebar de `MainHub` se puede colapsar/expandir con un botón fijo.
- Muestra: info del entrenador, bonos de clase por stat, conteo de pokemon capturados y en equipo.

### Pantalla de carga
- Al cargar una partida guardada se muestra un spinner animado hasta que los datos estén listos.

### Sistema de entrenamiento

#### `src/utils/bonos.js`
Utilidades de cálculo extraídas de `TrainView` para mantener la lógica separada del componente.

**`aplicarBono(valor, bono)`**
Aplica un porcentaje de bono a un valor base. Usa `Math.round` para no acumular decimales y `Math.max(1, ...)` para garantizar mínimo 1 punto de ganancia.
```js
aplicarBono(5, 20)   // → 6   (5 × 1.20 = 6)
aplicarBono(5, -10)  // → 5   (5 × 0.90 = 4.5 → redondeado a 5; mínimo 1)
```

**`calcularGananciaTotal(valorBase, totalEntrenamiento, bono)`**
Calcula la ganancia total de una sesión de entrenamiento aplicando el bono correctamente. Divide el total entrenado en puntos individuales (cada punto = `valorBase`) y aplica el bono a cada uno, evitando el error de aplicar el bono solo una vez sobre el total.
```js
calcularGananciaTotal(5, 15, 20)
// 3 puntos de entrenamiento (15 / 5), cada uno vale aplicarBono(5, 20) = 6 → total: 18
```

**`subirStatNivel(valorStat)`**
Sube un stat +2 al subir de nivel. Si ya está en 150 no lo modifica; si el resultado supera 150 lo tapa en ese tope.
```js
subirStatNivel(100)  // → 102
subirStatNivel(149)  // → 150
subirStatNivel(150)  // → 150 (sin cambio)
```

#### TrainView — mejoras
- **Bono de clase en entrenamiento:** cada punto de entrenamiento aplica `aplicarBono(ganancia(), bonoStat)`, lo que significa que una clase con bono positivo gana más por entrenamiento y con bono negativo gana menos. El botón disminuir usa la misma función para garantizar simetría.
- **Barra fantasma de XP:** muestra con color semitransparente hasta dónde llegará la XP al confirmar el entrenamiento actual. Se calcula como `(xp + xpPendiente) / xpNecesaria * 100`, renderizado con `position: absolute` detrás de la barra real (`z-index: 1`).
- **Indicador `+X xp`:** texto a la derecha de la etiqueta de XP que aparece solo cuando hay entrenamientos pendientes por confirmar.
- **`subirStatNivel` en subida de nivel:** al confirmar y subir de nivel, cada stat aumenta +2 con tope en 150 usando la función utilitaria.
