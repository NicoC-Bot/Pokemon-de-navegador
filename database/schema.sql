-- =============================================================
--  Practica_2 — Schema de base de datos
--  Motor: MySQL 5.7+ / MariaDB 10.3+
--  Charset: utf8mb4
--
--  Instrucciones de instalación:
--    1. Abrir phpMyAdmin o cliente MySQL
--    2. Ejecutar este archivo completo
--    3. Ajustar credenciales en api/config.php si es necesario
--       (por defecto: host=localhost, user=root, pass='')
-- =============================================================

CREATE DATABASE IF NOT EXISTS practica2
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE practica2;

-- -------------------------------------------------------------
--  Orden de borrado: hijos antes que padres (FK con CASCADE)
-- -------------------------------------------------------------
DROP TABLE IF EXISTS inventario_partida;
DROP TABLE IF EXISTS pokemon_partida;
DROP TABLE IF EXISTS partida_estado;
DROP TABLE IF EXISTS partidas;

-- -------------------------------------------------------------
--  partidas — registro principal de cada guardado
-- -------------------------------------------------------------
CREATE TABLE partidas (
  id                  INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  nombre              VARCHAR(100)    NOT NULL,
  creada_en           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ultima_modificacion DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------
--  partida_estado — estado global del entrenador por partida
--  Los timestamps (ultimo_descanso, descansando_hasta,
--  captura_cooldown_hasta) se almacenan como epoch en ms (BIGINT)
--  para mantener precisión desde el frontend JS.
-- -------------------------------------------------------------
CREATE TABLE partida_estado (
  id                    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  partida_id            INT UNSIGNED  NOT NULL,
  entrenador_nombre     VARCHAR(100)  NOT NULL,
  clase_id              VARCHAR(50)   NOT NULL,
  ultimo_descanso       BIGINT        NULL DEFAULT NULL,
  descansando_hasta     BIGINT        NULL DEFAULT NULL,
  pe_descanso           INT           NOT NULL DEFAULT 0,
  captura_cooldown_hasta BIGINT       NULL DEFAULT NULL,
  capturas_disponibles  TINYINT       NOT NULL DEFAULT 3,
  PRIMARY KEY (id),
  CONSTRAINT fk_estado_partida
    FOREIGN KEY (partida_id) REFERENCES partidas (id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------
--  pokemon_partida — cada Pokémon perteneciente a una partida
-- -------------------------------------------------------------
CREATE TABLE pokemon_partida (
  id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  partida_id      INT UNSIGNED    NOT NULL,
  uid             VARCHAR(64)     NOT NULL,
  nombre          VARCHAR(100)    NOT NULL,
  elemento        VARCHAR(50)     NOT NULL,
  rareza          VARCHAR(20)     NOT NULL,
  nivel           TINYINT         NOT NULL DEFAULT 1,
  nivel_ascension TINYINT         NOT NULL DEFAULT 0,
  hp_actual       INT             NOT NULL,
  pe              INT             NOT NULL DEFAULT 100,
  stats           JSON            NOT NULL,
  en_equipo       TINYINT(1)      NOT NULL DEFAULT 0,
  slot_equipo     TINYINT         NULL DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_pokemon_partida
    FOREIGN KEY (partida_id) REFERENCES partidas (id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -------------------------------------------------------------
--  inventario_partida — materiales almacenados en cada partida
-- -------------------------------------------------------------
CREATE TABLE inventario_partida (
  id          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  partida_id  INT UNSIGNED  NOT NULL,
  material_id VARCHAR(64)   NOT NULL,
  cantidad    INT           NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_partida_material (partida_id, material_id),
  CONSTRAINT fk_inventario_partida
    FOREIGN KEY (partida_id) REFERENCES partidas (id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
