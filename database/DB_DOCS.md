# Base de datos — Practica_2

## Índice

- [Tablas](#tablas) — línea 21
- [Normalizaciones aplicadas](#normalizaciones-aplicadas) — línea 74
- [Índices](#índices) — línea 83
- [Vistas](#vistas) — línea 100
- [Stored Procedures](#stored-procedures) — línea 113
- [Triggers](#triggers) — línea 124
- [Consultar logs](#consultar-logs) — línea 144
- [Backups](#backups) — línea 154
- [Queries de reporte](#queries-de-reporte) — línea 172
- [Migración a PostgreSQL](#migración-a-postgresql) — línea 206
- [Transacciones — niveles de aislamiento](#transacciones--niveles-de-aislamiento) — línea 246
- [Slow Query Log](#slow-query-log) — línea 282
- [Seguridad en la API](#seguridad-en-la-api) — línea 317

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
| Tabla | Descripción | Poblada por |
|-------|-------------|-------------|
| `partidas_log` | Registra cuándo se creó o eliminó una partida | `after_partida_insert`, `after_partida_delete` |
| `pokemon_nivel_log` | Registra cada subida de nivel con el valor anterior y nuevo | `after_pokemon_nivel` |
| `batallas_log` | Registra la fecha de cada batalla al completarse | `after_batalla_insert` |

---

## Normalizaciones aplicadas

- `partidas.entrenador_nombre` → tabla `entrenadores` con FK `entrenador_id`
- `materiales.id` cambió de `VARCHAR(64)` a `INT AUTO_INCREMENT`; el identificador string pasó a la columna `tipo`
- `inventario_partida.material_id` actualizado de string a `INT` con FK numérica
- Tabla `equipos` renombrada a `participante_tipos`
- `clases_catalogo.stats` — columna JSON agregada con los modificadores de stat de cada clase; elimina la duplicación que existía entre `src/data/clases.js` y `TrainerCreate.vue`

### `clases_catalogo.stats`
Cada clase de entrenador (fuego, agua, planta, etc.) tiene bonos y penalizaciones a los stats del pokémon. Antes esos valores vivían solo en el frontend (`src/data/clases.js`). Ahora están en la DB como JSON, y `api/partidas.php` los devuelve junto con la partida para que el juego los aplique sin depender de un archivo separado.

- Definición de columna: `database/schema.sql` línea 173
- Query que la lee: `api/partidas.php` línea 54
- Decodificación JSON: `api/partidas.php` línea 74

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

### `sp_eliminar_partida(p_id)`
Elimina una partida y todo su historial asociado en una sola llamada atómica — reemplaza los 5 DELETE secuenciales que antes hacía PHP. Incluye transacción interna con rollback automático si algo falla.

```sql
CALL sp_eliminar_partida(1);
```

- Definición: `database/schema.sql` línea 423
- Usado en: `api/partidas.php` línea 312

---

## Triggers

| Trigger | Evento | Acción |
|---------|--------|--------|
| `after_partida_insert` | AFTER INSERT en `partidas` | Inserta fila en `partidas_log` con acción "creada" y fecha actual |
| `after_partida_delete` | AFTER DELETE en `partidas` | Inserta fila en `partidas_log` con acción "eliminada" y fecha actual |
| `before_pokemon_equipo` | BEFORE INSERT en `pokemon_partida` | Cuenta pokémon con `en_equipo = 1` en la partida; lanza error si llega a 6 |
| `after_pokemon_nivel` | AFTER UPDATE en `pokemon_partida` | Si `nivel` aumentó, inserta fila en `pokemon_nivel_log` con nivel anterior y nuevo |
| `after_batalla_insert` | AFTER INSERT en `batallas` | Inserta fila en `batallas_log` con el id de la batalla y fecha actual |

---

## Consultar logs

```sql
SELECT * FROM partidas_log;
SELECT * FROM pokemon_nivel_log;
SELECT * FROM batallas_log;
```

---

## Backups

### Crear backup
Genera un archivo `.sql` con toda la estructura y datos de la DB.

```bash
mysqldump -u root -p practica2 > C:\xampp\htdocs\Practica_2\database\backup.sql
```

### Restaurar backup
Vuelve la DB al estado exacto en que estaba cuando se hizo el backup.

```bash
mysql -u root -p practica2 < C:\xampp\htdocs\Practica_2\database\backup.sql
```

---

## Queries de reporte

### Pokémon agrupados por partida
Devuelve una fila por partida con todos sus pokémon como array JSON. Útil para revisión y exportación desde phpMyAdmin.
Query manual — no está integrada al código, solo para usar en phpMyAdmin.

```sql
SELECT
  p.nombre AS partida,
  CONCAT('[', GROUP_CONCAT(
    JSON_OBJECT('nombre', pc.nombre, 'nivel', pp.nivel, 'elemento', e.nombre)
    SEPARATOR ','
  ), ']') AS pokemon
FROM partidas p
JOIN pokemon_partida pp  ON pp.partida_id = p.id
JOIN pokemon_catalogo pc ON pc.id = pp.pokemon_id
JOIN elementos e         ON e.id  = pc.elemento_id
GROUP BY p.id, p.nombre
ORDER BY p.id;
```

---

## Migración a PostgreSQL

### Pasos

**1. Exportar la DB actual**
```bash
mysqldump -u root -p practica2 > C:\xampp\htdocs\Practica_2\database\backup.sql
```

**2. Ajustar la sintaxis del archivo exportado**
PostgreSQL no comparte toda la sintaxis de MySQL. Cambios necesarios en el `.sql`:

| MySQL | PostgreSQL |
|-------|------------|
| `AUTO_INCREMENT` | `SERIAL` o `GENERATED ALWAYS AS IDENTITY` |
| `TINYINT(1)` | `BOOLEAN` |
| `ENGINE=InnoDB` | eliminar, no existe |
| `UNSIGNED` | eliminar, no existe |
| Backticks `` ` `` | comillas dobles `"` o eliminar |
| `DEFAULT CHARSET=utf8mb4` | eliminar |

**3. Crear la DB en PostgreSQL**
```sql
CREATE DATABASE practica2;
```

**4. Importar el archivo ajustado**
```bash
psql -U postgres -d practica2 -f backup_postgres.sql
```

### Alternativa automática con pgloader
`pgloader` migra directamente de MySQL a PostgreSQL sin editar el archivo manualmente:
```bash
pgloader mysql://root@localhost/practica2 postgresql://postgres@localhost/practica2
```

---

## Transacciones — niveles de aislamiento

Controlan cuánto se aísla una transacción de lo que hacen otras transacciones al mismo tiempo. A mayor nivel, más seguro pero más lento.

### Los 3 problemas que resuelven

| Problema | Qué ocurre |
|----------|-----------|
| **Dirty read** | Lees datos que otro escribió pero aún no confirmó — pueden desaparecer |
| **Non-repeatable read** | Lees un dato, otro lo modifica, vuelves a leerlo y cambió |
| **Phantom read** | Ejecutas la misma query dos veces y aparecen filas nuevas insertadas por otro |

### Los 4 niveles

| Nivel | Dirty read | Non-repeatable | Phantom |
|-------|-----------|----------------|---------|
| `READ UNCOMMITTED` | ✅ posible | ✅ posible | ✅ posible |
| `READ COMMITTED` | ❌ evitado | ✅ posible | ✅ posible |
| `REPEATABLE READ` | ❌ evitado | ❌ evitado | ✅ posible |
| `SERIALIZABLE` | ❌ evitado | ❌ evitado | ❌ evitado |

MySQL usa **REPEATABLE READ** por defecto — no es necesario configurarlo salvo casos especiales.

### Cómo aplicarlo en PHP

```php
// Una línea antes de beginTransaction(), solo si necesitas cambiar el nivel
$pdo->exec('SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED'); // ningún problema resuelto
$pdo->exec('SET TRANSACTION ISOLATION LEVEL READ COMMITTED');   // resuelve dirty read
$pdo->exec('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ');  // resuelve dirty + non-repeatable (default MySQL)
$pdo->exec('SET TRANSACTION ISOLATION LEVEL SERIALIZABLE');     // resuelve los 3 problemas

$pdo->beginTransaction();
// ... operaciones ...
$pdo->commit();
```

---

## Slow Query Log

Archivo donde MySQL registra automáticamente las queries que tardan más de un tiempo definido. Útil para detectar problemas de rendimiento sin correr EXPLAIN manualmente.

### Activar en XAMPP

Editar `C:\xampp\mysql\bin\my.ini`, sección `[mysqld]`:

```ini
slow_query_log = 1
slow_query_log_file = C:/xampp/mysql/logs/slow_queries.log
long_query_time = 2
```

- `slow_query_log = 1` — activa el log
- `slow_query_log_file` — ruta donde se guarda el archivo
- `long_query_time = 2` — registra queries que tarden más de 2 segundos

Reiniciar MySQL desde el panel de XAMPP para aplicar.

### Formato del log

```
# Query_time: 3.45  Lock_time: 0.01  Rows_examined: 50000
SELECT * FROM pokemon_partida WHERE nivel > 5;
```

Muestra el tiempo que tardó, cuántas filas revisó y la query exacta.

---

## Seguridad en la API

### SQL Injection
El ataque más común en apps con DB. El atacante mete código SQL en un campo de texto para manipular la base de datos.

**Ejemplo de código vulnerable:**
```php
$query = "SELECT * FROM partidas WHERE id = " . $_GET['id'];
// Si el usuario envía: 1; DROP TABLE partidas; -- → borra la tabla
```

**Solución — PDO con `?`:**
```php
$stmt = $pdo->prepare('SELECT * FROM partidas WHERE id = ?');
$stmt->execute([$id]);
```
El `?` le dice a MySQL que el valor es un dato, nunca código. Ya aplicado en `api/partidas.php`.

---

### Validación de tipos
PDO protege el SQL, pero no valida que el dato tenga sentido. Hay que validar según lo que se espera recibir.

| Caso | Validación |
|------|-----------|
| Esperas un número entero | `$id = (int) $_GET['id']` |
| Esperas texto | `trim($valor)` para limpiar espacios |
| Esperas un email | `filter_var($email, FILTER_VALIDATE_EMAIL)` |
| Esperas longitud limitada | `strlen($valor) <= 100` |

Ya aplicado en `api/partidas.php` con `(int)` en todos los IDs.

---

### XSS (Cross-Site Scripting)
Un atacante guarda código JavaScript malicioso en la DB. Cuando otro usuario carga la página, el navegador lo ejecuta como si fuera código legítimo — puede robar cookies, redirigir a otra página o enviar datos a servidores externos.

**Datos externos** (siempre sanitizar):
- `$_GET` — datos de la URL
- `$_POST` — datos de un formulario
- Cualquier valor leído de la DB con `fetch()`

**Solución en PHP** — usar `htmlspecialchars()` al mostrar datos externos con `echo`:
```php
echo htmlspecialchars($dato); // convierte <script> en &lt;script&gt; — se muestra como texto, no se ejecuta
```
Regla: **si viene de fuera, escápalo**. Si tienes dudas, aplícalo siempre — no hace daño en datos seguros.

**Solución en Vue:**
Vue escapa automáticamente los valores en `{{ }}` — no necesitas hacer nada extra.
Solo es peligroso si usas `v-html`, que ejecuta HTML/JS directamente:
```vue
{{ partida.nombre }}              <!-- seguro -->
<div v-html="partida.nombre">    <!-- peligroso, evitar con datos externos -->
```

**En este proyecto:** todo pasa por Vue con `{{ }}`, así que XSS está cubierto. `htmlspecialchars()` solo sería necesario si se usara PHP para generar HTML directamente con `echo`.

---

### CSRF (Cross-Site Request Forgery)
Engañar al usuario para que ejecute una acción en la app sin saberlo. Un sitio malicioso hace una petición a tu app usando las cookies activas del usuario — el servidor la recibe como si fuera legítima.

**Cuándo es necesario:**
- Apps con login y sesiones
- Formularios que ejecutan acciones importantes (transferencias, eliminar cuenta, cambiar contraseña)
- Paneles de administración

**Cuándo no es crítico:**
- Apps sin login
- APIs que usan tokens JWT en headers
- Apps locales como este proyecto

**Solución — token CSRF:**
Un valor secreto único por sesión que el servidor verifica en cada petición. Un sitio externo no puede conocerlo, por lo que no puede falsificar la petición.

**1. Generar el token:**
```php
session_start();
$_SESSION['csrf_token'] = bin2hex(random_bytes(32));
```

**2. Incluirlo en el formulario:**
```php
<input type="hidden" name="csrf_token" value="<?= $_SESSION['csrf_token'] ?>">
```

**3. Verificarlo al recibir la petición:**
```php
if ($_POST['csrf_token'] !== $_SESSION['csrf_token']) {
    http_response_code(403);
    die('Token inválido');
}
```

**En Vue con API JSON** — el token va en los headers en vez del formulario:
```javascript
fetch('/api/partidas.php', {
    method: 'POST',
    headers: {
        'X-CSRF-Token': csrfToken
    }
})
```

**En este proyecto:** no es necesario por ahora — no hay login ni sesiones. Sería obligatorio si se agrega autenticación de usuarios en el futuro.

---

### CORS (Cross-Origin Resource Sharing)
Controla qué dominios pueden hacer peticiones a la API. Por defecto el navegador bloquea peticiones entre dominios distintos — CORS le dice al navegador qué dominios tienen permiso.

**Lo que tiene el proyecto actualmente:**
```php
header('Access-Control-Allow-Origin: *');
```
El `*` permite peticiones desde **cualquier dominio** — útil en desarrollo local, peligroso en producción.

**En producción reemplazar por el dominio específico:**
```php
header('Access-Control-Allow-Origin: https://tudominio.com');
```
Así solo ese dominio puede consumir la API.

**En este proyecto:** el `*` es suficiente por ser local. Cambiarlo sería obligatorio al subir la app a un servidor público.

---

### JWT (JSON Web Token)
Sistema de autenticación para APIs. Identifica al usuario sin guardar sesiones en el servidor — el token viaja en cada petición.

**Flujo:**
1. Usuario hace login con usuario y contraseña
2. Servidor verifica credenciales y genera un token
3. Usuario guarda el token (normalmente en `localStorage`)
4. Cada petición siguiente envía el token en el header
5. Servidor verifica el token y sabe quién es el usuario

**Estructura del token** — 3 partes separadas por puntos:
```
eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxfQ.abc123
     Header                  Payload           Firma
```
- **Header** — algoritmo usado para firmar
- **Payload** — datos del usuario (id, rol, expiración)
- **Firma** — verifica que el token no fue modificado

**Generar token en PHP:**
```php
$payload = ['user_id' => 1, 'exp' => time() + 3600]; // expira en 1 hora
$token = base64_encode(json_encode($payload)) . '.' . hash_hmac('sha256', json_encode($payload), 'clave_secreta');
```

**Enviar token en Vue:**
```javascript
fetch('/api/partidas.php', {
    headers: {
        'Authorization': 'Bearer ' + token
    }
})
```

**En este proyecto:** no hay login, por lo que JWT no es necesario. Sería el sistema a implementar si se agrega autenticación de usuarios en el futuro.

---

### Variables de entorno
Valores de configuración sensibles (contraseñas, claves, nombres de DB) que viven fuera del código en un archivo separado que nunca se sube a Git.

**El problema — credenciales en el código:**
```php
$pdo = new PDO('mysql:host=localhost;dbname=practica2', 'root', '');
// Si se sube a GitHub, cualquiera puede ver estos valores
```

**La solución — archivo `.env` en la raíz del proyecto:**
```
DB_HOST=localhost
DB_NAME=practica2
DB_USER=root
DB_PASS=
```

**Leer los valores en `config.php`:**
```php
$host = getenv('DB_HOST');
$name = getenv('DB_NAME');
$user = getenv('DB_USER');
$pass = getenv('DB_PASS');

$pdo = new PDO("mysql:host=$host;dbname=$name", $user, $pass);
```

**Agregar `.env` al `.gitignore`** para que nunca se suba a Git:
```
.env
```

**En este proyecto:** no es crítico por ser local, pero es un hábito obligatorio en proyectos reales o con credenciales sensibles.
