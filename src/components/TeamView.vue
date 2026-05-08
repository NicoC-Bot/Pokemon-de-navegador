<script setup>
import { rarezas } from '../data/pokemonesExploracion.js'

const props = defineProps({
  equipo:     Array,
  capturados: Array,
})

const emit = defineEmits(['actualizar-equipo', 'volver'])

function obtenerRareza(id) {
  return rarezas.find(r => r.id === id) ?? rarezas[0]
}

function estaEnEquipo(pokemon) {
  return props.equipo.some(p => p.uid === pokemon.uid)
}

function agregarAlEquipo(pokemon) {
  if (props.equipo.length >= 6 || estaEnEquipo(pokemon)) return
  emit('actualizar-equipo', [...props.equipo, pokemon])
}

function quitarDelEquipo(pokemon) {
  if (props.equipo.length <= 1) return
  emit('actualizar-equipo', props.equipo.filter(p => p.uid !== pokemon.uid))
}
</script>

<template>
  <div class="team-view">

    <h2>Equipo</h2>
    <p class="subtitulo">Gestiona los Pokémon de tu equipo activo.</p>

    <div class="columnas">

      <!-- Capturados -->
      <div class="columna-capturados">
        <h3 class="col-titulo">
          Capturados
          <span class="contador">{{ capturados.length }}</span>
        </h3>

        <div v-if="capturados.length === 0" class="sin-capturados">
          Aún no has capturado ningún Pokémon.
        </div>

        <div class="capturados-grid">
          <div
            v-for="pokemon in capturados"
            :key="pokemon.uid"
            class="cap-card"
            :style="{ borderColor: pokemon.colorElemento }"
          >
            <div class="cap-header" :style="{ backgroundColor: pokemon.colorElemento }">
              <div class="cap-info">
                <span class="cap-nombre">{{ pokemon.nombre }}</span>
                <span class="cap-elemento">{{ pokemon.elemento }}</span>
              </div>
              <div class="cap-badges">
                <span class="nivel-badge">Nv. {{ pokemon.nivel }}</span>
                <span class="rareza-badge" :style="{ backgroundColor: obtenerRareza(pokemon.rareza).color }">
                  {{ obtenerRareza(pokemon.rareza).label }}
                </span>
              </div>
            </div>

            <div class="cap-stats">
              <div v-for="(valor, nombre) in pokemon.stats" class="stat-fila">
                <span class="stat-nombre">{{ nombre }}</span>
                <span class="stat-valor">{{ valor }}</span>
              </div>
            </div>

            <div class="cap-botones">
              <div v-if="estaEnEquipo(pokemon)" class="agregado-aviso">
                ✓ Agregado al equipo
              </div>
              <button
                v-else
                class="btn-agregar"
                :disabled="equipo.length >= 6"
                :style="equipo.length < 6 ? { backgroundColor: pokemon.colorElemento } : {}"
                @click="agregarAlEquipo(pokemon)"
              >
                Agregar
              </button>
              <button
                class="btn-eliminar"
                :disabled="!estaEnEquipo(pokemon) || equipo.length <= 1"
                @click="quitarDelEquipo(pokemon)"
              >
                Eliminar
              </button>
            </div>
          </div>
        </div>
      </div>

    </div>

    <button class="btn-volver" @click="emit('volver')">← Volver</button>

  </div>
</template>

<style scoped>
.team-view {
  padding: 28px 32px;
  font-family: sans-serif;
}

h2 {
  font-size: 1.4rem;
  margin-bottom: 4px;
}

.subtitulo {
  color: #666;
  font-size: 0.9rem;
  margin-bottom: 20px;
}

.columnas {
  margin-bottom: 24px;
}

.col-titulo {
  font-size: 0.9rem;
  font-weight: bold;
  color: #333;
  margin-bottom: 10px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.contador {
  font-size: 0.78rem;
  background: #f0f0f0;
  color: #666;
  padding: 2px 8px;
  border-radius: 20px;
  font-weight: normal;
}

/* Capturados */
.sin-capturados {
  color: #aaa;
  font-size: 0.88rem;
  padding: 24px;
  text-align: center;
}

.capturados-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.cap-card {
  border: 2px solid #ccc;
  border-radius: 10px;
  overflow: hidden;
}

.cap-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 10px 12px;
  color: white;
  gap: 6px;
}

.cap-info {
  display: flex;
  flex-direction: column;
  gap: 1px;
  min-width: 0;
}

.cap-nombre { font-weight: bold; font-size: 0.9rem; }
.cap-elemento { font-size: 0.75rem; opacity: 0.85; }

.cap-badges {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
  flex-shrink: 0;
}

.nivel-badge {
  font-size: 0.68rem;
  font-weight: bold;
  padding: 3px 7px;
  border-radius: 20px;
  background: rgba(0,0,0,0.25);
  color: white;
  white-space: nowrap;
}

.rareza-badge {
  font-size: 0.68rem;
  font-weight: bold;
  padding: 3px 7px;
  border-radius: 20px;
  color: white;
  white-space: nowrap;
}

.cap-stats {
  display: flex;
  flex-direction: column;
  gap: 3px;
  padding: 8px 10px;
}

.stat-fila {
  display: flex;
  justify-content: space-between;
  font-size: 0.78rem;
  padding: 2px 5px;
  background: #f9f9f9;
  border-radius: 4px;
}

.stat-nombre { color: #444; }
.stat-valor  { font-weight: bold; color: #222; }

.cap-botones {
  display: flex;
  flex-direction: column;
  border-top: 1px solid #eee;
}

.btn-agregar,
.btn-eliminar {
  padding: 7px;
  font-size: 0.78rem;
  font-weight: bold;
  border: none;
  cursor: pointer;
  transition: filter 0.2s;
  color: white;
}

.agregado-aviso {
  text-align: center;
  padding: 7px;
  background: #edfff3;
  border-bottom: 1px solid #eee;
  color: #1a9e3f;
  font-weight: bold;
  font-size: 0.78rem;
  border-bottom: 2px solid #2dc653;
}

.btn-agregar {
  background: #ccc;
  border-bottom: 1px solid #eee;
}

.btn-eliminar {
  background: #e63946;
}

.btn-agregar:not(:disabled):hover,
.btn-eliminar:not(:disabled):hover { filter: brightness(0.9); }

.btn-agregar:disabled,
.btn-eliminar:disabled {
  cursor: not-allowed;
  opacity: 0.35;
  background: #ddd;
  color: #999;
}

/* Volver */
.btn-volver {
  padding: 8px 18px;
  background: white;
  border: 2px solid #ccc;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.88rem;
  color: #555;
  transition: border-color 0.2s;
}

.btn-volver:hover { border-color: #888; color: #222; }
</style>
