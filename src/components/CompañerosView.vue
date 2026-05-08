<script setup>
import { rarezas } from '../data/pokemonesExploracion.js'

const props = defineProps({
  equipo:     Array,
  capturados: Array,
  inventario: Object,
})

const emit = defineEmits(['volver'])

function obtenerRareza(id) {
  return rarezas.find(r => r.id === id) ?? rarezas[0]
}

function estaEnEquipo(pokemon) {
  return props.equipo.some(p => p.uid === pokemon.uid)
}
</script>

<template>
  <div class="compañeros-view">

    <h2>Compañeros</h2>
    <p class="subtitulo">Cuida y usa materiales con tus Pokémon.</p>

    <div v-if="capturados.length === 0" class="vacio">
      Aún no tienes ningún compañero.
    </div>

    <div class="grid">
      <div
        v-for="pokemon in capturados"
        :key="pokemon.uid"
        class="pokemon-card"
        :style="{ borderColor: pokemon.colorElemento }"
      >
        <div class="card-header" :style="{ backgroundColor: pokemon.colorElemento }">
          <div class="card-info">
            <span class="card-nombre">{{ pokemon.nombre }}</span>
            <span class="card-elemento">{{ pokemon.elemento }}</span>
          </div>
          <div class="card-badges">
            <span class="nivel-badge">Nv. {{ pokemon.nivel }}</span>
            <span class="rareza-badge" :style="{ backgroundColor: obtenerRareza(pokemon.rareza).color }">
              {{ obtenerRareza(pokemon.rareza).label }}
            </span>
          </div>
        </div>

        <div class="card-body">
          <div class="pe-wrap">
            <div class="pe-labels">
              <span>PE</span>
              <span :class="{ 'pe-bajo': pokemon.pe <= 20 }">{{ pokemon.pe }} / 100</span>
            </div>
            <div class="pe-barra-fondo">
              <div
                class="pe-barra-relleno"
                :style="{ width: pokemon.pe + '%', backgroundColor: pokemon.colorElemento }"
              ></div>
            </div>
          </div>

          <div class="stats">
            <div v-for="(valor, nombre) in pokemon.stats" :key="nombre" class="stat-fila">
              <span class="stat-nombre">{{ nombre }}</span>
              <span class="stat-valor">{{ valor }}</span>
            </div>
          </div>

        </div>

      </div>
    </div>

    <button class="btn-volver" @click="emit('volver')">← Volver</button>

  </div>
</template>

<style scoped>
.compañeros-view {
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

.vacio {
  color: #aaa;
  font-size: 0.88rem;
  text-align: center;
  padding: 32px 0;
}

.grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
  margin-bottom: 24px;
}

.pokemon-card {
  border: 2px solid #ccc;
  border-radius: 12px;
  overflow: hidden;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 10px 12px;
  color: white;
  gap: 6px;
}

.card-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.card-nombre  { font-weight: bold; font-size: 0.95rem; }
.card-elemento { font-size: 0.75rem; opacity: 0.85; }

.card-badges {
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

.card-body {
  padding: 10px 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

/* Barra PE */
.pe-wrap { display: flex; flex-direction: column; gap: 4px; }

.pe-labels {
  display: flex;
  justify-content: space-between;
  font-size: 0.75rem;
  color: #555;
}

.pe-bajo { color: #e63946; font-weight: bold; }

.pe-barra-fondo {
  height: 6px;
  background: #eee;
  border-radius: 4px;
  overflow: hidden;
}

.pe-barra-relleno {
  height: 100%;
  border-radius: 4px;
  transition: width 0.3s;
}

/* Stats */
.stats {
  display: flex;
  flex-direction: column;
  gap: 3px;
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
