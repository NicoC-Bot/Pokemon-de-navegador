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

DROP VIEW  IF EXISTS vista_entrenadores_pokemon;
DROP TABLE IF EXISTS entrenamiento_log;
DROP TABLE IF EXISTS entrenamiento_stats;
DROP TABLE IF EXISTS entrenamiento_sesiones;
DROP TABLE IF EXISTS batalla_turnos;
DROP TABLE IF EXISTS batalla_participantes;
DROP TABLE IF EXISTS batallas;
DROP TABLE IF EXISTS inventario_partida;
DROP TABLE IF EXISTS pokemon_partida;
DROP TABLE IF EXISTS partidas;
DROP TABLE IF EXISTS entrenadores;
DROP TABLE IF EXISTS materiales;
DROP TABLE IF EXISTS habilidades_ascension_catalogo;
DROP TABLE IF EXISTS habilidades_catalogo;
DROP TABLE IF EXISTS pokemon_catalogo;
DROP TABLE IF EXISTS clases_catalogo;
DROP TABLE IF EXISTS stat_tipos;
DROP TABLE IF EXISTS habilidad_tipos;
DROP TABLE IF EXISTS tipos_material;
DROP TABLE IF EXISTS tipos_accion;
DROP TABLE IF EXISTS participante_tipos;
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

CREATE TABLE participante_tipos (
  id     TINYINT UNSIGNED NOT NULL,
  nombre VARCHAR(20)      NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO participante_tipos VALUES (1, 'jugador'), (2, 'oponente');

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
  stats         LONGTEXT         CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`stats`)),
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO clases_catalogo VALUES
  (1, 'fuego',    '🔥 Fuego',     '#e63946', '[{"nombre":"Ataque","valor":20},{"nombre":"Velocidad","valor":5},{"nombre":"Daño Físico","valor":20},{"nombre":"Ataque Esp.","valor":-10},{"nombre":"Defensa","valor":-15},{"nombre":"Daño Elemental","valor":-10},{"nombre":"Evasión","valor":-5},{"nombre":"HP","valor":0},{"nombre":"Defensa Esp.","valor":0}]'),
  (2, 'agua',     '💧 Agua',      '#4895ef', '[{"nombre":"HP","valor":20},{"nombre":"Defensa Esp.","valor":10},{"nombre":"Daño Elemental","valor":15},{"nombre":"Evasión","valor":10},{"nombre":"Ataque","valor":-10},{"nombre":"Daño Físico","valor":-5},{"nombre":"Velocidad","valor":-5},{"nombre":"Defensa","valor":0},{"nombre":"Ataque Esp.","valor":0}]'),
  (3, 'planta',   '🌿 Planta',    '#2dc653', '[{"nombre":"Defensa","valor":25},{"nombre":"Daño Elemental","valor":5},{"nombre":"Velocidad","valor":-15},{"nombre":"Ataque Esp.","valor":-5},{"nombre":"Evasión","valor":-5},{"nombre":"HP","valor":0},{"nombre":"Ataque","valor":0},{"nombre":"Daño Físico","valor":0},{"nombre":"Defensa Esp.","valor":0}]'),
  (4, 'electro',  '⚡ Eléctrico', '#f4d35e', '[{"nombre":"Velocidad","valor":25},{"nombre":"Ataque","valor":5},{"nombre":"Daño Físico","valor":15},{"nombre":"Evasión","valor":25},{"nombre":"Defensa","valor":-15},{"nombre":"HP","valor":-10},{"nombre":"Ataque Esp.","valor":0},{"nombre":"Daño Elemental","valor":0},{"nombre":"Defensa Esp.","valor":0}]'),
  (5, 'psiquico', '🧠 Psíquico',  '#9b5de5', '[{"nombre":"Ataque Esp.","valor":20},{"nombre":"Defensa Esp.","valor":10},{"nombre":"Daño Elemental","valor":25},{"nombre":"Evasión","valor":15},{"nombre":"Ataque","valor":-15},{"nombre":"Defensa","valor":-5},{"nombre":"Daño Físico","valor":-20},{"nombre":"HP","valor":0},{"nombre":"Velocidad","valor":0}]'),
  (6, 'roca',     '🛡️ Roca',      '#8d6e63', '[{"nombre":"Defensa","valor":25},{"nombre":"HP","valor":10},{"nombre":"Daño Físico","valor":10},{"nombre":"Velocidad","valor":-20},{"nombre":"Ataque Esp.","valor":-15},{"nombre":"Daño Elemental","valor":-15},{"nombre":"Evasión","valor":-20},{"nombre":"Ataque","valor":0},{"nombre":"Defensa Esp.","valor":0}]');

-- =============================================================
--  PARTE 2 — TABLAS CATÁLOGO
-- =============================================================

CREATE TABLE habilidades_ascension_catalogo (
  id            SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  identificador VARCHAR(40)       NOT NULL,
  elemento      VARCHAR(30)       NULL DEFAULT NULL,
  rareza        VARCHAR(20)       NULL DEFAULT NULL,
  nombre        VARCHAR(100)      NOT NULL,
  tipo          VARCHAR(20)       NOT NULL,
  potencia      TINYINT UNSIGNED  NULL DEFAULT NULL,
  `precision`   TINYINT UNSIGNED  NULL DEFAULT NULL,
  descripcion   JSON              NOT NULL,
  efecto        JSON              NULL DEFAULT NULL,
  escala        VARCHAR(20)       NULL DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_identificador (identificador)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO habilidades_ascension_catalogo
  (identificador, elemento, rareza, nombre, tipo, potencia, `precision`, descripcion, efecto)
VALUES
-- 🔥 Fuego
('golpe-abrasador',   '🔥 Fuego', NULL, 'Golpe Abrasador',   'fisico',   55, 90,
 '{"base":"Impacto cargado de fuego.","efecto":"30% de reducir la Defensa rival −20% por 2 turnos."}',
 '{"tipo":"debuff","stat":"Defensa","reduccion":20,"turnos":2,"probabilidad":30,"acumulable":false}'),
('frenesi-igneo',     '🔥 Fuego', NULL, 'Frenesí Ígneo',     'fisico',   40, 100,
 '{"base":"Golpe veloz en llamas.","efecto":"50% de quemar al rival, reduciendo su Ataque 15% por 2 turnos."}',
 '{"tipo":"quemadura","stat":"Ataque","reduccion":15,"turnos":2,"probabilidad":50,"acumulable":false}'),
('brasa-impetuosa',   '🔥 Fuego', NULL, 'Brasa Impetuosa',   'fisico',   45, 100,
 '{"base":"Golpe explosivo desde las brasas.","efecto":"Si el usuario tiene ≤50% HP, la potencia sube a 65."}',
 '{"tipo":"condicion-hp","umbral":0.5,"potenciaBonus":20}'),
-- ⚡ Eléctrico
('sobrecarga',        '⚡ Eléctrico',NULL,'Sobrecarga',       'especial', 55, 90,
 '{"base":"Explosión eléctrica masiva.","efecto":"40% de paralizar al rival, reduciendo su Velocidad −30% por 2 turnos."}',
 '{"tipo":"paralisis","stat":"Velocidad","reduccion":30,"turnos":2,"probabilidad":40,"acumulable":false}'),
('impulso-voltaico',  '⚡ Eléctrico',NULL,'Impulso Voltaico', 'fisico',   45, 100,
 '{"base":"Golpe eléctrico que interrumpe.","efecto":"35% de reducir el Ataque rival −15% por 2 turnos."}',
 '{"tipo":"debuff","stat":"Ataque","reduccion":15,"turnos":2,"probabilidad":35,"acumulable":false}'),
('carga-estatica',    '⚡ Eléctrico',NULL,'Carga Estática',   'fisico',   35, 100,
 '{"base":"Descarga rápida.","efecto":"50% de reducir la Velocidad rival −20% por 2 turnos."}',
 '{"tipo":"paralisis","stat":"Velocidad","reduccion":20,"turnos":2,"probabilidad":50,"acumulable":false}'),
-- 🌀 Viento
('corte-aereo',       '🌀 Viento',NULL, 'Corte Aéreo',       'especial', 50, 90,
 '{"base":"Hoja de viento cortante.","efecto":"30% de reducir la Velocidad rival −20% por 2 turnos."}',
 '{"tipo":"debuff","stat":"Velocidad","reduccion":20,"turnos":2,"probabilidad":30,"acumulable":false}'),
('ventisca-esquiva',  '🌀 Viento',NULL, 'Ventisca Esquiva',  'especial', 45, 100,
 '{"base":"Ráfaga defensiva.","efecto":"40% de esquivar el siguiente ataque recibido."}',
 '{"tipo":"esquiva","probabilidad":40}'),
('rafaga-precisa',    '🌀 Viento',NULL, 'Ráfaga Precisa',    'especial', 35, 100,
 '{"base":"Viento concentrado.","efecto":"50% de esquivar el siguiente ataque recibido."}',
 '{"tipo":"esquiva","probabilidad":50}'),
-- 🌑 Oscuro
('garra-umbral',      '🌑 Oscuro',NULL, 'Garra Umbral',      'fisico',   50, 90,
 '{"base":"Zarpazo desde las sombras.","efecto":"35% de reducir la Defensa rival −15% por 2 turnos."}',
 '{"tipo":"debuff","stat":"Defensa","reduccion":15,"turnos":2,"probabilidad":35,"acumulable":false}'),
('pulso-oscuro',      '🌑 Oscuro',NULL, 'Pulso Oscuro',      'especial', 55, 85,
 '{"base":"Onda de energía sombría.","efecto":"25% de reducir el Ataque Esp. rival −15% por 2 turnos."}',
 '{"tipo":"debuff","stat":"Ataque Esp.","reduccion":15,"turnos":2,"probabilidad":25,"acumulable":false}'),
('maldicion-sombria', '🌑 Oscuro',NULL, 'Maldición Sombría', 'estado',   NULL,NULL,
 '{"base":"Corrupción mental.","efecto":"Debuff acumulable en Ataque Esp. rival (−5%/stack, máx 3, 2 turnos)."}',
 '{"tipo":"debuff","stat":"Ataque Esp.","reduccion":5,"turnos":2,"probabilidad":100,"acumulable":true,"stacksMax":3}'),
-- ✨ Luz
('destello-sagrado',  '✨ Luz',   NULL, 'Destello Sagrado',  'especial', 55, 90,
 '{"base":"Explosión de luz sagrada.","efecto":"30% de reducir la Defensa Esp. rival −20% por 2 turnos."}',
 '{"tipo":"debuff","stat":"Defensa Esp.","reduccion":20,"turnos":2,"probabilidad":30,"acumulable":false}'),
('halo-protector',    '✨ Luz',   NULL, 'Halo Protector',    'especial', 35, 100,
 '{"base":"Destello sanador.","efecto":"Recupera el 25% del HP máximo propio."}',
 '{"tipo":"regeneracion","porcentaje":25,"cooldown":0}'),
('rayo-cenital',      '✨ Luz',   NULL, 'Rayo Cenital',      'especial', 50, 100,
 '{"base":"Rayo de luz pura.","efecto":"Si el usuario tiene ≤50% HP, la potencia sube a 80."}',
 '{"tipo":"condicion-hp","umbral":0.5,"potenciaBonus":30}'),
-- Por rareza (elemento = NULL)
('golpe-fiel',        NULL, 'comun',      'Golpe Fiel',         'fisico',   30, 100,
 '{"base":"Un golpe básico pero confiable. Sin efectos adicionales."}',
 NULL),
('tenacidad',         NULL, 'pocoComun',  'Tenacidad',          'fisico',   35, 100,
 '{"base":"Golpe resistente.","efecto":"Si el usuario tiene ≤50% HP, la potencia sube a 60."}',
 '{"tipo":"condicion-hp","umbral":0.5,"potenciaBonus":25}'),
('fuerza-interior',   NULL, 'raro',       'Fuerza Interior',    'especial', 45, 100,
 '{"base":"Golpe que libera energía interior.","efecto":"Recupera el 20% del HP máximo propio."}',
 '{"tipo":"regeneracion","porcentaje":20,"cooldown":0}'),
('dominio',           NULL, 'muyRaro',    'Dominio',            'especial', 55, 90,
 '{"base":"Ataque de presencia imponente.","efecto":"30% de debuff acumulable en Defensa Esp. rival (−5%/stack, máx 3, 2 turnos)."}',
 '{"tipo":"debuff","stat":"Defensa Esp.","reduccion":5,"turnos":2,"probabilidad":30,"acumulable":true,"stacksMax":3}'),
('presencia-absoluta',NULL, 'legendario', 'Presencia Absoluta', 'especial', 65, 85,
 '{"base":"El poder de una leyenda condensado en un golpe.","efecto":"40% de reducir la Defensa Esp. rival −25% por 2 turnos."}',
 '{"tipo":"debuff","stat":"Defensa Esp.","reduccion":25,"turnos":2,"probabilidad":40,"acumulable":false}');

-- 💧 Agua / 🌿 Planta / 🪨 Tierra — habilidades con escala en Defensa
INSERT INTO habilidades_ascension_catalogo
  (identificador, elemento, rareza, nombre, tipo, potencia, `precision`, descripcion, efecto, escala)
VALUES
-- 💧 Agua (Aquell)
('coraza-liquida',    '💧 Agua',   NULL, 'Coraza Líquida',    'fisico', 40, 90,
 '{"base":"Golpe que usa la Defensa como fuerza de impacto.","efecto":"30% de reducir el Ataque rival −15% por 2 turnos."}',
 '{"tipo":"debuff","stat":"Ataque","reduccion":15,"turnos":2,"probabilidad":30,"acumulable":false}',
 'Defensa'),
('marea-vital',       '💧 Agua',   NULL, 'Marea Vital',       'estado', NULL, NULL,
 '{"base":"Oleada de energía acuática restauradora.","efecto":"Recupera el 25% del HP máximo propio. Cooldown: 2 turnos."}',
 '{"tipo":"regeneracion","porcentaje":25,"cooldown":2}',
 NULL),
('chorro-resistente', '💧 Agua',   NULL, 'Chorro Resistente', 'fisico', 38, 100,
 '{"base":"Disparo concentrado que aprovecha la solidez del cuerpo. Sin efectos adicionales."}',
 NULL,
 'Defensa'),
-- 🌿 Planta (Verdún)
('parapeto-vegetal',  '🌿 Planta', NULL, 'Parapeto Vegetal',  'fisico', 35, 90,
 '{"base":"Golpe defensivo que usa la propia resistencia.","efecto":"30% de reducir la Defensa rival −15% por 2 turnos."}',
 '{"tipo":"debuff","stat":"Defensa","reduccion":15,"turnos":2,"probabilidad":30,"acumulable":false}',
 'Defensa'),
('drenaje-raiz',      '🌿 Planta', NULL, 'Drenaje Raíz',      'fisico', 40, 100,
 '{"base":"Golpe que drena energía usando la solidez propia. Sin efectos adicionales."}',
 NULL,
 'Defensa'),
('verdor-restaurador','🌿 Planta', NULL, 'Verdor Restaurador','estado', NULL, NULL,
 '{"base":"El Pokémon canaliza energía vital.","efecto":"Recupera el 20% del HP máximo propio. Cooldown: 2 turnos."}',
 '{"tipo":"regeneracion","porcentaje":20,"cooldown":2}',
 NULL),
-- 🪨 Tierra (Petrix)
('golpe-petreo',      '🪨 Tierra', NULL, 'Golpe Pétreo',      'fisico', 35, 90,
 '{"base":"Impacto telúrico que usa la Defensa como fuerza.","efecto":"25% de reducir la Defensa rival −15% por 2 turnos."}',
 '{"tipo":"debuff","stat":"Defensa","reduccion":15,"turnos":2,"probabilidad":25,"acumulable":false}',
 'Defensa'),
('sismo-defensivo',   '🪨 Tierra', NULL, 'Sismo Defensivo',   'fisico', 40, 85,
 '{"base":"Sacudida del suelo usando la propia masa corporal.","efecto":"30% de reducir la Velocidad rival −20% por 2 turnos."}',
 '{"tipo":"debuff","stat":"Velocidad","reduccion":20,"turnos":2,"probabilidad":30,"acumulable":false}',
 'Defensa'),
('muro-vivo',         '🪨 Tierra', NULL, 'Muro Vivo',         'estado', NULL, NULL,
 '{"base":"El Pokémon canaliza su resistencia como escudo vital.","efecto":"Recupera el 25% del HP máximo propio. Cooldown: 2 turnos."}',
 '{"tipo":"regeneracion","porcentaje":25,"cooldown":2}',
 NULL);

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
  nombre        VARCHAR(100)     NOT NULL,
  icono         VARCHAR(10)      NOT NULL,
  descripcion   VARCHAR(255)     NOT NULL,
  hp_recuperado INT              NULL DEFAULT NULL,
  tipo_id       TINYINT UNSIGNED NOT NULL,
  elemento_id   TINYINT UNSIGNED NULL DEFAULT NULL,
  tipo          VARCHAR(64)      NOT NULL DEFAULT '',
  id            INT              NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (id),
  KEY idx_materiales_tipo (tipo),
  CONSTRAINT fk_material_tipo     FOREIGN KEY (tipo_id)    REFERENCES tipos_material (id),
  CONSTRAINT fk_material_elemento FOREIGN KEY (elemento_id) REFERENCES elementos     (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO materiales (nombre, icono, descripcion, hp_recuperado, tipo_id, elemento_id, tipo) VALUES
  ('Baya Dulce',          '🍓', 'Una baya silvestre. Restaura 15 HP.',                                           15,   1, NULL, 'baya'),
  ('Hierba Medicinal',    '🌿', 'Hierba con propiedades curativas. Restaura 25 HP.',                             25,   1, NULL, 'hierba'),
  ('Néctar Silvestre',    '🍯', 'Néctar dulce y energizante. Restaura 20 HP.',                                   20,   1, NULL, 'nectar'),
  ('Fruta Mística',       '🍇', 'Fruta de propiedades extraordinarias. Restaura 40 HP.',                         40,   1, NULL, 'frutaMistica'),
  ('Cristal de Tierra',   '💎', 'Un cristal opaco extraído del suelo.',                                          NULL, 2, NULL, 'cristal'),
  ('Agua Pura',           '💧', 'Agua cristalina de un manantial cercano.',                                      NULL, 2, NULL, 'agua'),
  ('Piedra Brillante',    '🪨', 'Una piedra con un brillo inusual.',                                             NULL, 2, NULL, 'piedra'),
  ('Brasa Ígnia',         '🔥', 'Una brasa que arde sin consumirse.',                                            NULL, 3, 1,    'brasaIgnia'),
  ('Perla Marina',        '🫧', 'Perla formada en las profundidades marinas.',                                   NULL, 3, 2,    'perlaMarina'),
  ('Semilla Ancestral',   '🌱', 'Semilla que irradia vida en su interior.',                                      NULL, 3, 3,    'semillaAncestral'),
  ('Roca Arcana',         '🗿', 'Roca imbuida con energía telúrica.',                                           NULL, 3, 4,    'rocaArcana'),
  ('Chispa Estática',     '⚡', 'Chispa atrapada en un cristal eléctrico.',                                     NULL, 3, 5,    'chispaEstatica'),
  ('Pluma Etérea',        '🪶', 'Pluma que flota sin ningún apoyo.',                                            NULL, 3, 6,    'plumaEterea'),
  ('Sombra Cristalizada', '🌑', 'Oscuridad solidificada en forma de cristal.',                                   NULL, 3, 7,    'sombraCristalizada'),
  ('Fragmento Solar',     '☀️', 'Fragmento de luz pura solidificada.',                                          NULL, 3, 8,    'fragmentoSolar'),
  ('Chile Ígneo',         '🌶️','Picante y ardiente. Restaura 55 HP solo a Pokémon de Fuego.',                  55,   4, 1,    'chileIgnio'),
  ('Baya Marina',         '🫐', 'Jugosa baya de las costas. Restaura 55 HP solo a Pokémon de Agua.',            55,   4, 2,    'bayaMarina'),
  ('Kiwi Silvestre',      '🥝', 'Fruta de la selva profunda. Restaura 55 HP solo a Pokémon de Planta.',         55,   4, 3,    'kiwiSilvestre'),
  ('Raíz Arcana',         '🍠', 'Raíz de la tierra profunda. Restaura 55 HP solo a Pokémon de Tierra.',         55,   4, 4,    'raizArcana'),
  ('Baya Electra',        '🍋', 'Baya cargada de electricidad. Restaura 55 HP solo a Pokémon Eléctrico.',       55,   4, 5,    'bayaElectra'),
  ('Vaina Aérea',         '🫛', 'Vaina que flota en el viento. Restaura 55 HP solo a Pokémon de Viento.',       55,   4, 6,    'vainaAerea'),
  ('Fruto Sombrío',       '🫒', 'Fruto que crece sin luz. Restaura 55 HP solo a Pokémon de Oscuro.',            55,   4, 7,    'frutoSombrio'),
  ('Fruta Áurea',         '🍊', 'Fruta dorada que desprende luz propia. Restaura 55 HP solo a Pokémon de Luz.', 55,   4, 8,    'frutaAurea');

-- =============================================================
--  PARTE 4 — PARTIDAS Y DATOS DE JUEGO
-- =============================================================

CREATE TABLE entrenadores (
  id     INT          NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE partidas (
  id                     INT              NOT NULL AUTO_INCREMENT,
  nombre                 VARCHAR(100)     NOT NULL,
  creada_en              DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ultima_modificacion    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  entrenador_id          INT              NOT NULL,
  clase_id               TINYINT UNSIGNED NOT NULL,
  ultimo_descanso        BIGINT           NULL DEFAULT NULL,
  descansando_hasta      BIGINT           NULL DEFAULT NULL,
  pe_descanso            INT              NOT NULL DEFAULT 0,
  captura_cooldown_hasta BIGINT           NULL DEFAULT NULL,
  capturas_disponibles   TINYINT          NOT NULL DEFAULT 3,
  PRIMARY KEY (id),
  CONSTRAINT fk_partida_entrenador FOREIGN KEY (entrenador_id) REFERENCES entrenadores    (id),
  CONSTRAINT fk_partida_clase      FOREIGN KEY (clase_id)      REFERENCES clases_catalogo (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------

CREATE TABLE pokemon_partida (
  id                    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  partida_id            INT           NOT NULL,
  uid                   VARCHAR(64)   NOT NULL,
  nombre                VARCHAR(100)  NOT NULL DEFAULT '',
  elemento              VARCHAR(30)   NOT NULL DEFAULT '',
  rareza                VARCHAR(20)   NOT NULL DEFAULT '',
  pokemon_id            INT UNSIGNED  NOT NULL,
  nivel                 TINYINT       NOT NULL DEFAULT 1,
  nivel_ascension       TINYINT       NOT NULL DEFAULT 0,
  hp_actual             INT           NOT NULL,
  pe                    INT           NOT NULL DEFAULT 100,
  stats                 LONGTEXT      CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`stats`)),
  habilidades_ascension LONGTEXT      CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL DEFAULT NULL CHECK (json_valid(`habilidades_ascension`)),
  habilidad_rareza      VARCHAR(40)   NULL DEFAULT NULL,
  en_equipo             TINYINT(1)    NOT NULL DEFAULT 0,
  slot_equipo           TINYINT       NULL DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_pokemon_partida FOREIGN KEY (partida_id) REFERENCES partidas        (id) ON DELETE CASCADE,
  CONSTRAINT fk_pp_catalogo     FOREIGN KEY (pokemon_id) REFERENCES pokemon_catalogo(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------

CREATE TABLE inventario_partida (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  partida_id  INT          NOT NULL,
  material_id INT          NOT NULL,
  cantidad    INT          NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_partida_material (partida_id, material_id),
  CONSTRAINT fk_inventario_partida  FOREIGN KEY (partida_id)  REFERENCES partidas  (id) ON DELETE CASCADE,
  CONSTRAINT fk_inventario_material FOREIGN KEY (material_id) REFERENCES materiales (id)
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
  CONSTRAINT fk_part_equipo          FOREIGN KEY (equipo_id)  REFERENCES participante_tipos (id)
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

-- =============================================================
--  PARTE 7 — STORED PROCEDURES
-- =============================================================

DELIMITER //
CREATE PROCEDURE sp_eliminar_partida(IN p_id INT)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
    DELETE FROM entrenamiento_sesiones WHERE partida_id = p_id;
    DELETE FROM batallas               WHERE partida_id = p_id;
    DELETE FROM inventario_partida     WHERE partida_id = p_id;
    DELETE FROM pokemon_partida        WHERE partida_id = p_id;
    DELETE FROM partidas               WHERE id         = p_id;
  COMMIT;
END //
DELIMITER ;

-- =============================================================
--  PARTE 8 — ÍNDICES
-- =============================================================

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

-- =============================================================
--  PARTE 8 — TABLAS DE LOG Y TRIGGERS
-- =============================================================

CREATE TABLE partidas_log (
  id         INT         NOT NULL AUTO_INCREMENT,
  partida_id INT         NOT NULL,
  accion     VARCHAR(20) NOT NULL,
  fecha      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE pokemon_nivel_log (
  id            INT         NOT NULL AUTO_INCREMENT,
  partida_id    INT         NOT NULL,
  pokemon_uid   VARCHAR(64) NOT NULL,
  nivel_antes   TINYINT     NOT NULL,
  nivel_despues TINYINT     NOT NULL,
  fecha         DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE batallas_log (
  id         INT      NOT NULL AUTO_INCREMENT,
  batalla_id INT      NOT NULL,
  fecha      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================================
--  PARTE 9 — ENTRENAMIENTOS
-- =============================================================

CREATE TABLE entrenamiento_log (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  partida_id  INT UNSIGNED NOT NULL,
  pokemon_uid VARCHAR(50)  NOT NULL,
  fecha       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
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
