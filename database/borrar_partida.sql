-- =============================================================
--  borrar_partida.sql
--  Elimina una partida y todos sus datos asociados.
--
--  INSTRUCCIONES:
--    1. Cambia el valor de @id por el id de la partida a borrar.
--    2. Ejecuta el script completo en phpMyAdmin o en la terminal.
--
--  QUÉ SE BORRA (CASCADE automático):
--    - pokemon_partida   → borrado automático por ON DELETE CASCADE
--    - inventario_partida → borrado automático por ON DELETE CASCADE
--
--  QUÉ SE LIMPIA MANUALMENTE ANTES:
--    - entrenamiento_sesiones → ON DELETE SET NULL, se borran aquí
--    - entrenamiento_stats    → borrado por FK CASCADE desde sesiones
--    - batallas               → ON DELETE SET NULL, se borran aquí
--    - batalla_participantes  → borrado por FK CASCADE desde batallas
--    - batalla_turnos         → borrado por FK CASCADE desde batallas
-- =============================================================

USE practica2;

SET @id = 1;  -- ← cambia este valor por el id de la partida

START TRANSACTION;

  -- Historial de entrenamiento (sesiones + stats vía CASCADE)
  DELETE FROM entrenamiento_sesiones WHERE partida_id = @id;

  -- Historial de batallas (participantes + turnos vía CASCADE)
  DELETE FROM batallas WHERE partida_id = @id;

  -- Partida principal (pokemon_partida + inventario_partida vía CASCADE)
  DELETE FROM partidas WHERE id = @id;

COMMIT;
