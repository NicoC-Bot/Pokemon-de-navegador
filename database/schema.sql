-- =============================================================
--  Practica_2 — Schema de base de datos (versión actual)
--  Motor:  MySQL 5.7+ / MariaDB 10.3+
--  Charset: utf8mb4
--
--  Instrucciones:
--    1. Abrir phpMyAdmin
--    2. Ejecutar este archivo completo
--    3. Credenciales en api/config.php (por defecto: host=localhost, user=root, pass='')
-- =============================================================

CREATE DATABASE IF NOT EXISTS practica2
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE practica2;

-- =============================================================
--  BORRADO EN ORDEN INVERSO DE DEPENDENCIAS
-- =============================================================

DROP TABLE IF EXISTS entrenamiento_stats;
DROP TABLE IF EXISTS entrenamiento_sesiones;
DROP TABLE IF EXISTS batalla_turnos;
DROP TABLE IF EXISTS batalla_participantes;
DROP TABLE IF EXISTS batallas;
DROP TABLE IF EXISTS inventario_partida;
DROP TABLE IF EXISTS pokemon_partida;
DROP TABLE IF EXISTS partidas;
DROP TABLE IF EXISTS materiales;
DROP TABLE IF EXISTS habilidades_catalogo;
DROP TABLE IF EXISTS pokemon_catalogo;
DROP TABLE IF EXISTS clases_catalogo;
DROP TABLE IF EXISTS stat_tipos;
DROP TABLE IF EXISTS habilidad_tipos;
DROP TABLE IF EXISTS tipos_material;
DROP TABLE IF EXISTS tipos_accion;
DROP TABLE IF EXISTS equipos;
DROP TABLE IF EXISTS batalla_resultados;
DROP TABLE IF EXISTS batalla_estados;
DROP TABLE IF EXISTS rareza_tipos;
DROP TABLE IF EXISTS elementos;

-- =============================================================
--  PARTE 1 — TABLAS LOOKUP
-- =============================================================

CREATE TABLE elementos (
  id     TINYINT UNSIGNED NOT NULL,
  nombre VARCHAR(30)      NOT NULL,
  icono  VARCHAR(10)      NOT NULL,
  color  VARCHAR(20)      NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO elementos VALUES
  (1, 'Fuego',     '🔥', '#e63946'),
  (2, 'Agua',      '💧', '#4895ef'),
  (3, 'Planta',    '🌿', '#2dc653'),
  (4, 'Tierra',    '🪨', '#a0784a'),
  (5, 'Eléctrico', '⚡', '#f4c430'),
  (6, 'Viento',    '🌀', '#48cae4'),
  (7, 'Oscuro',    '🌑', '#5a3e8a'),
  (8, 'Luz',       '✨', '#f7b731');

-- -------------------------------------------------------------

CREATE TABLE rareza_tipos (
  id     TINYINT UNSIGNED NOT NULL,
  nombre VARCHAR(20)      NOT NULL,
  label  VARCHAR(20)      NOT NULL,
  color  VARCHAR(20)      NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO rareza_tipos VALUES
  (1, 'comun',      'Común',      '#888888'),
  (2, 'pocoComun',  'Poco común', '#2d8c4e'),
  (3, 'raro',       'Raro',       '#1a6db5'),
  (4, 'muyRaro',    'Muy raro',   '#7b2fbe'),
  (5, 'legendario', 'Legendario', '#c8970a');

-- -------------------------------------------------------------

CREATE TABLE batalla_estados (
  id     TINYINT UNSIGNED NOT NULL,
  nombre VARCHAR(20)      NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO batalla_estados VALUES (1, 'terminado'), (2, 'abandono');

-- -------------------------------------------------------------

CREATE TABLE batalla_resultados (
  id     TINYINT UNSIGNED NOT NULL,
  nombre VARCHAR(20)      NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO batalla_resultados VALUES (1, 'victoria'), (2, 'derrota');

-- -------------------------------------------------------------

CREATE TABLE equipos (
  id     TINYINT UNSIGNED NOT NULL,
  nombre VARCHAR(20)      NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO equipos VALUES (1, 'jugador'), (2, 'oponente');

-- -------------------------------------------------------------

CREATE TABLE tipos_accion (
  id     TINYINT UNSIGNED NOT NULL,
  nombre VARCHAR(20)      NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO tipos_accion VALUES
  (1, 'ataque'), (2, 'habilidad'), (3, 'defender'), (4, 'relevo');

-- -------------------------------------------------------------

CREATE TABLE tipos_material (
  id     TINYINT UNSIGNED NOT NULL,
  nombre VARCHAR(30)      NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO tipos_material VALUES
  (1, 'curativo'), (2, 'general'), (3, 'ascension'), (4, 'curativo-elemental');

-- -------------------------------------------------------------

CREATE TABLE habilidad_tipos (
  id     TINYINT UNSIGNED NOT NULL,
  nombre VARCHAR(20)      NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO habilidad_tipos VALUES (1, 'fisico'), (2, 'especial'), (3, 'estado');

-- -------------------------------------------------------------

CREATE TABLE stat_tipos (
  id     TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(30)      NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO stat_tipos VALUES
  (1, 'HP'),
  (2, 'Ataque'),
  (3, 'Defensa'),
  (4, 'Ataque Esp.'),
  (5, 'Defensa Esp.'),
  (6, 'Velocidad'),
  (7, 'Daño Físico'),
  (8, 'Daño Elemental'),
  (9, 'Evasión');

-- -------------------------------------------------------------

CREATE TABLE clases_catalogo (
  id            TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  identificador VARCHAR(20)      NOT NULL,
  label         VARCHAR(50)      NOT NULL,
  color         VARCHAR(20)      NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO clases_catalogo VALUES
  (1, 'fuego',    '🔥 Fuego',     '#e63946'),
  (2, 'agua',     '💧 Agua',      '#4895ef'),
  (3, 'planta',   '🌿 Planta',    '#2dc653'),
  (4, 'electro',  '⚡ Eléctrico', '#f4d35e'),
  (5, 'psiquico', '🧠 Psíquico',  '#9b5de5'),
  (6, 'roca',     '🛡️ Roca',      '#8d6e63');

-- =============================================================
--  PARTE 2 — TABLAS CATÁLOGO
-- =============================================================

CREATE TABLE pokemon_catalogo (
  id          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(100)     NOT NULL,
  elemento_id TINYINT UNSIGNED NOT NULL,
  rareza_id   TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_pcatalogo_elemento FOREIGN KEY (elemento_id) REFERENCES elementos    (id),
  CONSTRAINT fk_pcatalogo_rareza   FOREIGN KEY (rareza_id)   REFERENCES rareza_tipos (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO pokemon_catalogo (id, nombre, elemento_id, rareza_id) VALUES
  (1, 'Embrix',  1, 1),
  (2, 'Aquell',  2, 1),
  (3, 'Verdún',  3, 1),
  (4, 'Petrix',  4, 2),
  (5, 'Voltín',  5, 3),
  (6, 'Zéfiro',  6, 3),
  (7, 'Noctis',  7, 4),
  (8, 'Solaris', 8, 5);

-- -------------------------------------------------------------

CREATE TABLE habilidades_catalogo (
  id         INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  pokemon_id INT UNSIGNED     NOT NULL,
  nombre     VARCHAR(100)     NOT NULL,
  tipo_id    TINYINT UNSIGNED NOT NULL,
  potencia   INT              NULL DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_hab_pokemon FOREIGN KEY (pokemon_id) REFERENCES pokemon_catalogo (id),
  CONSTRAINT fk_hab_tipo    FOREIGN KEY (tipo_id)    REFERENCES habilidad_tipos  (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO habilidades_catalogo (id, pokemon_id, nombre, tipo_id, potencia) VALUES
  ( 1, 1, 'Ascua',        1,   30),
  ( 2, 1, 'Llamarada',    1,   65),
  ( 3, 2, 'Burbuja',      2,   25),
  ( 4, 2, 'Torrente',     2,   55),
  ( 5, 3, 'Látigo Cepa',  1,   48),
  ( 6, 3, 'Regeneración', 3, NULL),
  ( 7, 4, 'Golpe Rocoso', 1,   35),
  ( 8, 4, 'Terremoto',    1,   70),
  ( 9, 5, 'Chispazo',     1,   30),
  (10, 5, 'Descarga',     2,   55),
  (11, 6, 'Ráfaga',       2,   30),
  (12, 6, 'Vendaval',     2,   60),
  (13, 7, 'Zarpazo',      1,   35),
  (14, 7, 'Sombra Cruel', 2,   65),
  (15, 8, 'Destello',     2,   35),
  (16, 8, 'Rayo Solar',   2,   80);

-- =============================================================
--  PARTE 3 — MATERIALES (catálogo de ítems del juego)
--  tipo_id    → tipos_material
--  elemento_id → elementos (NULL para ítems sin elemento)
-- =============================================================

CREATE TABLE materiales (
  id            VARCHAR(64)      NOT NULL,
  nombre        VARCHAR(100)     NOT NULL,
  icono         VARCHAR(10)      NOT NULL,
  descripcion   VARCHAR(255)     NOT NULL,
  tipo_id       TINYINT UNSIGNED NOT NULL,
  hp_recuperado INT              NULL DEFAULT NULL,
  elemento_id   TINYINT UNSIGNED NULL DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_material_tipo     FOREIGN KEY (tipo_id)    REFERENCES tipos_material (id),
  CONSTRAINT fk_material_elemento FOREIGN KEY (elemento_id) REFERENCES elementos     (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO materiales (id, nombre, icono, descripcion, tipo_id, hp_recuperado, elemento_id) VALUES
  ('baya',              'Baya Dulce',          '🍓', 'Una baya silvestre. Restaura 15 HP.',                                      1, 15,   NULL),
  ('hierba',            'Hierba Medicinal',    '🌿', 'Hierba con propiedades curativas. Restaura 25 HP.',                         1, 25,   NULL),
  ('nectar',            'Néctar Silvestre',    '🍯', 'Néctar dulce y energizante. Restaura 20 HP.',                              1, 20,   NULL),
  ('frutaMistica',      'Fruta Mística',       '🍇', 'Fruta de propiedades extraordinarias. Restaura 40 HP.',                    1, 40,   NULL),
  ('cristal',           'Cristal de Tierra',   '💎', 'Un cristal opaco extraído del suelo.',                                     2, NULL, NULL),
  ('agua',              'Agua Pura',           '💧', 'Agua cristalina de un manantial cercano.',                                 2, NULL, NULL),
  ('piedra',            'Piedra Brillante',    '🪨', 'Una piedra con un brillo inusual.',                                        2, NULL, NULL),
  ('brasaIgnia',        'Brasa Ígnia',         '🔥', 'Una brasa que arde sin consumirse.',                                       3, NULL, 1),
  ('perlaMarina',       'Perla Marina',        '🫧', 'Perla formada en las profundidades marinas.',                              3, NULL, 2),
  ('semillaAncestral',  'Semilla Ancestral',   '🌱', 'Semilla que irradia vida en su interior.',                                 3, NULL, 3),
  ('rocaArcana',        'Roca Arcana',         '🗿', 'Roca imbuida con energía telúrica.',                                      3, NULL, 4),
  ('chispaEstatica',    'Chispa Estática',     '⚡', 'Chispa atrapada en un cristal eléctrico.',                                3, NULL, 5),
  ('plumaEterea',       'Pluma Etérea',        '🪶', 'Pluma que flota sin ningún apoyo.',                                       3, NULL, 6),
  ('sombraCristalizada','Sombra Cristalizada', '🌑', 'Oscuridad solidificada en forma de cristal.',                              3, NULL, 7),
  ('fragmentoSolar',    'Fragmento Solar',     '☀️', 'Fragmento de luz pura solidificada.',                                     3, NULL, 8),
  ('chileIgnio',        'Chile Ígneo',         '🌶️','Picante y ardiente. Restaura 55 HP solo a Pokémon de Fuego.',              4, 55,   1),
  ('bayaMarina',        'Baya Marina',         '🫐', 'Jugosa baya de las costas. Restaura 55 HP solo a Pokémon de Agua.',        4, 55,   2),
  ('kiwiSilvestre',     'Kiwi Silvestre',      '🥝', 'Fruta de la selva profunda. Restaura 55 HP solo a Pokémon de Planta.',     4, 55,   3),
  ('raizArcana',        'Raíz Arcana',         '🍠', 'Raíz de la tierra profunda. Restaura 55 HP solo a Pokémon de Tierra.',     4, 55,   4),
  ('bayaElectra',       'Baya Electra',        '🍋', 'Baya cargada de electricidad. Restaura 55 HP solo a Pokémon Eléctrico.',  4, 55,   5),
  ('vainaAerea',        'Vaina Aérea',         '🫛', 'Vaina que flota en el viento. Restaura 55 HP solo a Pokémon de Viento.',  4, 55,   6),
  ('frutoSombrio',      'Fruto Sombrío',       '🫒', 'Fruto que crece sin luz. Restaura 55 HP solo a Pokémon de Oscuro.',        4, 55,   7),
  ('frutaAurea',        'Fruta Áurea',         '🍊', 'Fruta dorada que desprende luz propia. Restaura 55 HP solo a Pokémon de Luz.', 4, 55, 8);

-- =============================================================
--  PARTE 4 — PARTIDAS Y DATOS DE JUEGO
-- =============================================================

CREATE TABLE partidas (
  id                     INT              NOT NULL AUTO_INCREMENT,
  nombre                 VARCHAR(100)     NOT NULL,
  creada_en              DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ultima_modificacion    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  entrenador_nombre      VARCHAR(100)     NOT NULL,
  clase_id               TINYINT UNSIGNED NOT NULL,
  ultimo_descanso        BIGINT           NULL DEFAULT NULL,
  descansando_hasta      BIGINT           NULL DEFAULT NULL,
  pe_descanso            INT              NOT NULL DEFAULT 0,
  captura_cooldown_hasta BIGINT           NULL DEFAULT NULL,
  capturas_disponibles   TINYINT          NOT NULL DEFAULT 3,
  PRIMARY KEY (id),
  CONSTRAINT fk_partida_clase FOREIGN KEY (clase_id) REFERENCES clases_catalogo (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------

CREATE TABLE pokemon_partida (
  id              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  partida_id      INT           NOT NULL,
  uid             VARCHAR(64)   NOT NULL,
  pokemon_id      INT UNSIGNED  NOT NULL,
  nivel           TINYINT       NOT NULL DEFAULT 1,
  nivel_ascension TINYINT       NOT NULL DEFAULT 0,
  hp_actual       INT           NOT NULL,
  pe              INT           NOT NULL DEFAULT 100,
  stats           JSON          NOT NULL,
  en_equipo       TINYINT(1)    NOT NULL DEFAULT 0,
  slot_equipo     TINYINT       NULL DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_pokemon_partida FOREIGN KEY (partida_id) REFERENCES partidas        (id) ON DELETE CASCADE,
  CONSTRAINT fk_pp_catalogo     FOREIGN KEY (pokemon_id) REFERENCES pokemon_catalogo(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------

CREATE TABLE inventario_partida (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  partida_id  INT          NOT NULL,
  material_id VARCHAR(64)  NOT NULL,
  cantidad    INT          NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_partida_material (partida_id, material_id),
  CONSTRAINT fk_inventario_partida  FOREIGN KEY (partida_id)  REFERENCES partidas  (id) ON DELETE CASCADE,
  CONSTRAINT fk_inventario_material FOREIGN KEY (material_id) REFERENCES materiales(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================================
--  PARTE 5 — REGISTRO DE BATALLAS
-- =============================================================

CREATE TABLE batallas (
  id             INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  partida_id     INT              NULL DEFAULT NULL,
  fecha          DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado_id      TINYINT UNSIGNED NOT NULL,
  resultado_id   TINYINT UNSIGNED NULL DEFAULT NULL,
  turnos_totales INT              NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  CONSTRAINT fk_batalla_partida    FOREIGN KEY (partida_id)   REFERENCES partidas          (id) ON DELETE SET NULL,
  CONSTRAINT fk_batalla_estado     FOREIGN KEY (estado_id)    REFERENCES batalla_estados   (id),
  CONSTRAINT fk_batalla_resultado  FOREIGN KEY (resultado_id) REFERENCES batalla_resultados(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------

CREATE TABLE batalla_participantes (
  id          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  batalla_id  INT UNSIGNED     NOT NULL,
  pokemon_id  INT UNSIGNED     NOT NULL,
  pokemon_uid VARCHAR(64)      NULL DEFAULT NULL,
  equipo_id   TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_participante_batalla FOREIGN KEY (batalla_id) REFERENCES batallas        (id) ON DELETE CASCADE,
  CONSTRAINT fk_part_pokemon         FOREIGN KEY (pokemon_id) REFERENCES pokemon_catalogo(id),
  CONSTRAINT fk_part_equipo          FOREIGN KEY (equipo_id)  REFERENCES equipos         (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------

CREATE TABLE batalla_turnos (
  id              INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  batalla_id      INT UNSIGNED     NOT NULL,
  numero_turno    INT              NOT NULL,
  participante_id INT UNSIGNED     NOT NULL,
  tipo_accion_id  TINYINT UNSIGNED NOT NULL,
  habilidad_id    INT UNSIGNED     NULL DEFAULT NULL,
  dano_causado    INT              NULL DEFAULT NULL,
  objetivo_id     INT UNSIGNED     NULL DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_turno_batalla      FOREIGN KEY (batalla_id)      REFERENCES batallas             (id) ON DELETE CASCADE,
  CONSTRAINT fk_turno_participante FOREIGN KEY (participante_id) REFERENCES batalla_participantes(id) ON DELETE CASCADE,
  CONSTRAINT fk_turno_objetivo     FOREIGN KEY (objetivo_id)     REFERENCES batalla_participantes(id) ON DELETE SET NULL,
  CONSTRAINT fk_turno_tipo_accion  FOREIGN KEY (tipo_accion_id)  REFERENCES tipos_accion         (id),
  CONSTRAINT fk_turno_habilidad    FOREIGN KEY (habilidad_id)    REFERENCES habilidades_catalogo (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================================
--  PARTE 6 — REGISTRO DE ENTRENAMIENTOS
-- =============================================================

CREATE TABLE entrenamiento_sesiones (
  id                      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  partida_id              INT           NULL DEFAULT NULL,
  pokemon_uid             VARCHAR(64)   NOT NULL,
  pokemon_id              INT UNSIGNED  NOT NULL,
  pe_inicial              INT           NOT NULL,
  pe_gastado              INT           NOT NULL,
  pe_final                INT           NOT NULL,
  xp_ganada               INT           NOT NULL DEFAULT 0,
  nivel_antes             TINYINT       NOT NULL,
  nivel_despues           TINYINT       NOT NULL,
  cantidad_entrenamientos INT           NOT NULL DEFAULT 0,
  registrada_en           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_eseson_partida FOREIGN KEY (partida_id) REFERENCES partidas        (id) ON DELETE SET NULL,
  CONSTRAINT fk_eseson_pokemon FOREIGN KEY (pokemon_id) REFERENCES pokemon_catalogo(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------

CREATE TABLE entrenamiento_stats (
  id                 INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  sesion_id          INT UNSIGNED     NOT NULL,
  stat_id            TINYINT UNSIGNED NOT NULL,
  cantidad_entrenada INT              NOT NULL,
  valor_antes        INT              NOT NULL,
  valor_despues      INT              NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_estat_sesion FOREIGN KEY (sesion_id) REFERENCES entrenamiento_sesiones(id) ON DELETE CASCADE,
  CONSTRAINT fk_estat_tipo   FOREIGN KEY (stat_id)   REFERENCES stat_tipos            (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
