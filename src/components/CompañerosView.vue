<script setup>
import { ref } from 'vue'
import { rarezas, materiales, habilidadesAscension, COSTO_ASCENSION } from '../data/pokemonesExploracion.js'

const props = defineProps({
  equipo:     Array,
  capturados: Array,
  inventario: Object,
})

const emit = defineEmits(['volver', 'usar-material'])

const materialesCurativos  = materiales.filter(m => m.tipo === 'curativo')
const materialesAscension  = materiales.filter(m => m.tipo === 'ascension')
const materialesElementales = materiales.filter(m => m.tipo === 'curativo-elemental')

function obtenerRareza(id) {
  return rarezas.find(r => r.id === id) ?? rarezas[0]
}

function materialDeElemento(elemento) {
  return materialesAscension.find(m => m.elemento === elemento)
}

function alimentoElemental(elemento) {
  return materialesElementales.find(m => m.elemento === elemento)
}

function hpPorcentaje(pokemon) {
  return Math.min(100, ((pokemon.hpActual ?? pokemon.stats.HP) / pokemon.stats.HP) * 100)
}

function puedeAscender(pokemon) {
  const mat = materialDeElemento(pokemon.elemento)
  if (!mat) return false
  if ((pokemon.nivelAscension ?? 0) >= 2) return false
  return (props.inventario[mat.id] ?? 0) >= COSTO_ASCENSION
}

const expandidas = ref({})

function toggleHabilidad(pokemonUid, habId) {
  const key = pokemonUid + '-' + habId
  expandidas.value[key] = !expandidas.value[key]
}

function estaExpandida(pokemonUid, habId) {
  return !!expandidas.value[pokemonUid + '-' + habId]
}

function curar(pokemon, material) {
  emit('usar-material', { pokemonUid: pokemon.uid, materialId: material.id, cantidad: 1 })
}

function ascender(pokemon) {
  const mat = materialDeElemento(pokemon.elemento)
  if (!mat) return
  emit('usar-material', { pokemonUid: pokemon.uid, materialId: mat.id, cantidad: COSTO_ASCENSION })
}
</script>

<template>
  <div class="compañeros-view">
    <button class="btn-volver" @click="emit('volver')">← Volver</button>

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
        <!-- Header -->
        <div class="card-header" :style="{ backgroundColor: pokemon.colorElemento }">
          <div class="card-info">
            <span class="card-nombre">{{ pokemon.nombre }}</span>
            <span class="card-elemento">{{ pokemon.elemento }}</span>
          </div>
          <div class="card-badges">
            <span class="nivel-badge">Nv. {{ pokemon.nivel }}</span>
            <span class="ascension-badge">✦ {{ pokemon.nivelAscension ?? 0 }} / 2</span>
            <span class="rareza-badge" :style="{ backgroundColor: obtenerRareza(pokemon.rareza).color }">
              {{ obtenerRareza(pokemon.rareza).label }}
            </span>
          </div>
        </div>

        <div class="card-body">

          <!-- HP -->
          <div class="seccion">
            <div class="seccion-titulo">Salud</div>
            <div class="hp-labels">
              <span>HP</span>
              <span :class="{ 'hp-bajo': (pokemon.hpActual ?? pokemon.stats.HP) <= Math.floor(pokemon.stats.HP * 0.25) }">
                {{ pokemon.hpActual ?? pokemon.stats.HP }} / {{ pokemon.stats.HP }}
              </span>
            </div>
            <div class="barra-fondo">
              <div
                class="barra-relleno"
                :style="{ width: hpPorcentaje(pokemon) + '%', backgroundColor: pokemon.colorElemento }"
              ></div>
            </div>

            <div class="curativos">
              <button
                v-for="mat in materialesCurativos"
                :key="mat.id"
                class="btn-curar"
                :disabled="(inventario[mat.id] ?? 0) === 0 || (pokemon.hpActual ?? pokemon.stats.HP) >= pokemon.stats.HP"
                @click="curar(pokemon, mat)"
              >
                {{ mat.icono }} +{{ mat.hpRecuperado }} <span class="mat-count">({{ inventario[mat.id] ?? 0 }})</span>
              </button>
            </div>

            <div v-if="alimentoElemental(pokemon.elemento)" class="curativos-elementales">
              <div class="elemental-label">Alimento elemental</div>
              <button
                class="btn-curar btn-elemental"
                :style="{ borderColor: pokemon.colorElemento, color: pokemon.colorElemento }"
                :disabled="(inventario[alimentoElemental(pokemon.elemento).id] ?? 0) === 0 || (pokemon.hpActual ?? pokemon.stats.HP) >= pokemon.stats.HP"
                @click="curar(pokemon, alimentoElemental(pokemon.elemento))"
              >
                {{ alimentoElemental(pokemon.elemento).icono }} +{{ alimentoElemental(pokemon.elemento).hpRecuperado }}
                <span class="mat-count">({{ inventario[alimentoElemental(pokemon.elemento).id] ?? 0 }})</span>
              </button>
            </div>
          </div>

          <!-- Ascensión -->
          <div class="seccion">
            <div class="seccion-titulo">Ascensión</div>

            <div class="habilidades">
              <div
                v-for="hab in habilidadesAscension"
                :key="hab.nivel"
                class="habilidad"
                :class="{ desbloqueada: (pokemon.nivelAscension ?? 0) >= hab.nivel }"
              >
                <span class="hab-icono">{{ (pokemon.nivelAscension ?? 0) >= hab.nivel ? '✦' : '○' }}</span>
                <div class="hab-info">
                  <span class="hab-nombre">{{ hab.nombre }}</span>
                  <span class="hab-desc">{{ hab.descripcion }}</span>
                </div>
              </div>
            </div>

            <div v-if="(pokemon.nivelAscension ?? 0) < 2" class="ascension-accion">
              <div v-if="materialDeElemento(pokemon.elemento)" class="mat-requerido">
                <span>{{ materialDeElemento(pokemon.elemento).icono }} {{ materialDeElemento(pokemon.elemento).nombre }}</span>
                <span class="mat-disponible" :class="{ insuficiente: (inventario[materialDeElemento(pokemon.elemento).id] ?? 0) < COSTO_ASCENSION }">
                  {{ inventario[materialDeElemento(pokemon.elemento).id] ?? 0 }} / {{ COSTO_ASCENSION }}
                </span>
              </div>
              <button
                class="btn-ascender"
                :style="puedeAscender(pokemon) ? { backgroundColor: pokemon.colorElemento } : {}"
                :disabled="!puedeAscender(pokemon)"
                @click="ascender(pokemon)"
              >
                Ascender
              </button>
            </div>
            <div v-else class="ascension-completa">✦ Ascensión completa</div>
          </div>

          <!-- Habilidades de combate -->
          <div class="seccion">
            <div class="seccion-titulo">Habilidades de combate</div>

            <div v-if="pokemon.habilidades && pokemon.habilidades.length" class="habs-combate">
              <div v-for="hab in pokemon.habilidades" :key="hab.id" class="hab-combate">
                <button
                  class="hab-header"
                  :style="{ borderColor: pokemon.colorElemento }"
                  @click="toggleHabilidad(pokemon.uid, hab.id)"
                >
                  <div class="hab-meta">
                    <span class="hab-nombre-combate">{{ hab.nombre }}</span>
                    <span class="hab-tipo" :class="'tipo-' + hab.tipo">{{ hab.tipo }}</span>
                    <span v-if="hab.potencia" class="hab-potencia">p.{{ hab.potencia }}</span>
                  </div>
                  <span class="hab-chevron">{{ estaExpandida(pokemon.uid, hab.id) ? '▲' : '▼' }}</span>
                </button>
                <div v-if="estaExpandida(pokemon.uid, hab.id)" class="hab-descripcion">
                  {{ hab.descripcion }}
                </div>
              </div>
            </div>
            <div v-else class="sin-habilidades">Sin habilidades de combate.</div>
          </div>

        </div>
      </div>
    </div>


  </div>
</template>

<style scoped>
.compañeros-view {
  padding: 28px 32px;
  font-family: sans-serif;
}

h2 { font-size: 1.4rem; margin-bottom: 4px; }

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

/* Header */
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 10px 12px;
  color: white;
  gap: 6px;
}

.card-info { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.card-nombre  { font-weight: bold; font-size: 0.95rem; }
.card-elemento { font-size: 0.75rem; opacity: 0.85; }

.card-badges {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 3px;
  flex-shrink: 0;
}

.nivel-badge,
.ascension-badge,
.rareza-badge {
  font-size: 0.65rem;
  font-weight: bold;
  padding: 2px 6px;
  border-radius: 20px;
  white-space: nowrap;
  color: white;
}

.nivel-badge     { background: rgba(0,0,0,0.25); }
.ascension-badge { background: rgba(0,0,0,0.2); }

/* Body */
.card-body {
  padding: 10px 12px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.seccion { display: flex; flex-direction: column; gap: 6px; }

.seccion-titulo {
  font-size: 0.72rem;
  font-weight: bold;
  text-transform: uppercase;
  color: #999;
}

/* HP */
.hp-labels {
  display: flex;
  justify-content: space-between;
  font-size: 0.75rem;
  color: #555;
}

.hp-bajo { color: #e63946; font-weight: bold; }

.barra-fondo {
  height: 6px;
  background: #eee;
  border-radius: 4px;
  overflow: hidden;
}

.barra-relleno {
  height: 100%;
  border-radius: 4px;
  transition: width 0.3s;
}

/* Botones curar */
.curativos {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-top: 2px;
}

.btn-curar {
  padding: 4px 8px;
  font-size: 0.72rem;
  font-weight: bold;
  border: 2px solid #2dc653;
  border-radius: 6px;
  background: white;
  color: #1a9e3f;
  cursor: pointer;
  transition: background 0.15s;
}

.btn-curar:not(:disabled):hover { background: #edfff3; }

.btn-curar:disabled {
  cursor: not-allowed;
  opacity: 0.35;
  border-color: #ddd;
  color: #999;
}

.mat-count { opacity: 0.7; }

/* Alimento elemental */
.curativos-elementales {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-top: 4px;
}

.elemental-label {
  font-size: 0.65rem;
  font-weight: bold;
  text-transform: uppercase;
  color: #aaa;
}

.btn-elemental {
  border-color: #aaa;
  color: #555;
  background: #fafafa;
}

.btn-elemental:not(:disabled):hover { background: #f0f0f0; }

/* Habilidades */
.habilidades { display: flex; flex-direction: column; gap: 5px; }

.habilidad {
  display: flex;
  align-items: flex-start;
  gap: 6px;
  opacity: 0.4;
}

.habilidad.desbloqueada { opacity: 1; }

.hab-icono { font-size: 0.8rem; margin-top: 2px; flex-shrink: 0; }

.hab-info { display: flex; flex-direction: column; gap: 1px; }
.hab-nombre { font-size: 0.78rem; font-weight: bold; color: #222; }
.hab-desc   { font-size: 0.7rem; color: #888; }

/* Ascensión acción */
.ascension-accion { display: flex; flex-direction: column; gap: 5px; }

.mat-requerido {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.75rem;
  color: #555;
  padding: 4px 8px;
  background: #f9f9f9;
  border-radius: 6px;
}

.mat-disponible { font-weight: bold; color: #2dc653; }
.mat-disponible.insuficiente { color: #e63946; }

.btn-ascender {
  width: 100%;
  padding: 7px;
  font-size: 0.8rem;
  font-weight: bold;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  background: #ccc;
  transition: filter 0.2s;
}

.btn-ascender:not(:disabled):hover { filter: brightness(0.9); }
.btn-ascender:disabled { cursor: not-allowed; opacity: 0.5; }

.ascension-completa {
  text-align: center;
  font-size: 0.78rem;
  font-weight: bold;
  color: #c8970a;
  padding: 4px;
}

/* Habilidades de combate */
.habs-combate { display: flex; flex-direction: column; gap: 5px; }

.hab-combate { display: flex; flex-direction: column; }

.hab-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 5px 8px;
  background: #f9f9f9;
  border: 1.5px solid #ddd;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  width: 100%;
  transition: background 0.15s;
}

.hab-header:hover { background: #f0f0f0; }

.hab-meta { display: flex; align-items: center; gap: 5px; flex-wrap: wrap; }

.hab-nombre-combate { font-size: 0.78rem; font-weight: bold; color: #222; }

.hab-tipo {
  font-size: 0.62rem;
  font-weight: bold;
  padding: 1px 5px;
  border-radius: 10px;
  color: white;
}

.tipo-fisico   { background: #a0784a; }
.tipo-especial { background: #1a6db5; }
.tipo-estado   { background: #2d8c4e; }

.hab-potencia {
  font-size: 0.65rem;
  color: #888;
  margin-left: 2px;
}

.hab-chevron { font-size: 0.6rem; color: #aaa; flex-shrink: 0; }

.hab-descripcion {
  font-size: 0.72rem;
  color: #555;
  padding: 6px 8px;
  background: #fafafa;
  border: 1.5px solid #eee;
  border-top: none;
  border-radius: 0 0 6px 6px;
}

.sin-habilidades { font-size: 0.75rem; color: #aaa; }

/* Volver */
.btn-volver {
  display: block;
  margin: 0 auto 20px;
  padding: 8px 18px;
  background: white;
  border: 2px solid #ccc;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.88rem;
  color: #555;
  transition: border-color 0.2s, color 0.2s;
}

.btn-volver:hover { border-color: #888; color: #222; }
</style>
