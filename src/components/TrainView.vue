<script setup>
import { ref, computed } from 'vue'
import { calcularGananciaEntrenamiento, xpParaNivel } from '../utils/calcularStats.js'

const props = defineProps({
  pokemon:    Object,
  claseStats: Array,
})

const emit = defineEmits(['actualizar', 'volver'])

const stats      = ref({ ...props.pokemon.stats })
const nivel      = ref(props.pokemon.nivel)
const xp         = ref(props.pokemon.xp ?? 0)
const pe         = ref(props.pokemon.pe)
const haycambios = ref(false)
const confirmado = ref(false)
const subiNivel  = ref(false)
const contadores = ref(
  Object.fromEntries(Object.keys(props.pokemon.stats).map(k => [k, 0]))
)

const xpNecesaria   = computed(() => xpParaNivel(nivel.value))
const xpPorcentaje  = computed(() => Math.min(100, (xp.value / xpNecesaria.value) * 100))

function ganancia() {
  return calcularGananciaEntrenamiento(nivel.value)
}

function puedeEntrenar(valorStat) {
  return valorStat < 150 && pe.value >= ganancia()
}

function entrenar(nombreStat) {
  if (!puedeEntrenar(stats.value[nombreStat])) return

  confirmado.value = false
  stats.value[nombreStat] += ganancia()
  pe.value -= ganancia()
  contadores.value[nombreStat]++
  haycambios.value = true
}

function disminuir(nombreStat) {
  if (contadores.value[nombreStat] <= 0) return

  confirmado.value = false
  stats.value[nombreStat] -= ganancia()
  pe.value += ganancia()
  contadores.value[nombreStat]--
  haycambios.value = Object.values(contadores.value).some(c => c > 0)
}

function confirmar() {
  const xpGanada = Object.values(contadores.value).reduce((s, c) => s + c, 0) * ganancia()
  let xpActual   = xp.value + xpGanada
  subiNivel.value = false

  while (xpActual >= xpParaNivel(nivel.value)) {
    xpActual -= xpParaNivel(nivel.value)
    nivel.value++
    for (const k in stats.value) {
      stats.value[k] = Math.min(150, stats.value[k] + 2)
    }
    subiNivel.value = true
  }

  xp.value = xpActual

  emit('actualizar', {
    stats: { ...stats.value },
    pe:    pe.value,
    nivel: nivel.value,
    xp:    xp.value,
  })
  confirmado.value = true
  haycambios.value = false
  for (const k in contadores.value) {
    contadores.value[k] = 0
  }
}

function obtenerBonus(nombreStat) {
  const stat = props.claseStats?.find(s => s.nombre === nombreStat)
  return stat ? stat.valor : 0
}

function volver() {
  emit('volver')
}
</script>

<template>
  <div class="train-view">

    <!-- Header del Pokémon -->
    <div class="pokemon-header" :style="{ backgroundColor: pokemon.colorElemento, borderColor: pokemon.colorElemento }">
      <div class="pokemon-info">
        <span class="pokemon-nombre">{{ pokemon.nombre }}</span>
        <span class="pokemon-elemento">{{ pokemon.elemento }}</span>
      </div>
      <div class="pokemon-meta">
        <div class="meta-item">
          <span class="meta-label">Nivel</span>
          <span class="meta-valor">{{ nivel }}</span>
        </div>
        <div class="meta-item">
          <span class="meta-label">PE restantes</span>
          <span class="meta-valor" :class="{ 'pe-bajo': pe <= 20 }">{{ pe }}</span>
        </div>
        <div class="meta-item">
          <span class="meta-label">Ganancia actual</span>
          <span class="meta-valor">+{{ ganancia() }} por entrenamiento</span>
        </div>
      </div>
      <div class="xp-barra-wrap">
        <div class="xp-labels">
          <span>EXP</span>
          <span>{{ xp }} / {{ xpNecesaria }}</span>
        </div>
        <div class="xp-barra-fondo">
          <div class="xp-barra-relleno" :style="{ width: xpPorcentaje + '%' }"></div>
        </div>
      </div>
    </div>

    <!-- Tabla de stats -->
    <div class="stats-tabla">

      <div class="fila-header">
        <span>Stat</span>
        <span>Valor actual</span>
        <span>Bono</span>
        <span>Tope</span>
        <span>Entrenamientos</span>
      </div>

      <div v-for="(valor, nombreStat) in stats" class="fila-stat">
        <span class="stat-nombre">{{ nombreStat }}</span>

        <div class="stat-barra-wrap">
          <div
            class="stat-barra"
            :style="{
              width: (valor / 150 * 100) + '%',
              backgroundColor: pokemon.colorElemento
            }"
          ></div>
          <span class="stat-valor">{{ valor }}</span>
        </div>

        <span
          class="stat-bonus"
          :class="obtenerBonus(nombreStat) > 0 ? 'positivo' : obtenerBonus(nombreStat) < 0 ? 'negativo' : 'neutro'"
        >
          {{ obtenerBonus(nombreStat) > 0 ? '+' + obtenerBonus(nombreStat) : obtenerBonus(nombreStat) === 0 ? '—' : obtenerBonus(nombreStat) }}%
        </span>

        <span class="stat-tope" :class="{ alcanzado: valor >= 150 }">150</span>

        <div class="acciones-stat">
          <button
            class="btn-disminuir"
            :disabled="contadores[nombreStat] === 0"
            @click="disminuir(nombreStat)"
          >−</button>
          <span class="stat-contador" :class="{ activo: contadores[nombreStat] > 0 }">
            {{ contadores[nombreStat] }}x
          </span>
          <button
            class="btn-entrenar"
            :disabled="!puedeEntrenar(valor)"
            :style="puedeEntrenar(valor) ? { backgroundColor: pokemon.colorElemento } : {}"
            @click="entrenar(nombreStat)"
          >
            {{ valor >= 150 ? 'Tope' : pe < ganancia() ? 'Sin PE' : '+' }}
          </button>
        </div>
      </div>

    </div>

    <p v-if="pe === 0 && !confirmado" class="aviso-pe">
      Este Pokémon ha agotado sus puntos de entrenamiento.
    </p>

    <Transition name="fade">
      <div v-if="confirmado" class="aviso-completado" :class="{ 'nivel-up': subiNivel }">
        <template v-if="subiNivel">⬆ ¡Subiste al nivel {{ nivel }}! Todos los stats +2</template>
        <template v-else>✓ ¡Entrenamiento completado!</template>
      </div>
    </Transition>

    <div class="acciones">
      <button class="btn-volver" @click="volver">← Volver</button>
      <button
        class="btn-confirmar"
        :disabled="!haycambios"
        :style="haycambios ? { backgroundColor: pokemon.colorElemento } : {}"
        @click="confirmar"
      >
        Confirmar entrenamiento
      </button>
    </div>

  </div>
</template>

<style scoped>
.train-view {
  padding: 32px;
  font-family: sans-serif;
  max-width: 700px;
}

/* Header */
.pokemon-header {
  border: 2px solid #ccc;
  border-radius: 14px;
  padding: 20px 24px 16px;
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 32px;
  gap: 16px;
  color: white;
}

.xp-barra-wrap {
  width: 100%;
  flex-basis: 100%;
}

.xp-labels {
  display: flex;
  justify-content: space-between;
  font-size: 0.72rem;
  opacity: 0.85;
  margin-bottom: 4px;
}

.xp-barra-fondo {
  height: 6px;
  background: rgba(255,255,255,0.25);
  border-radius: 4px;
  overflow: hidden;
}

.xp-barra-relleno {
  height: 100%;
  background: rgba(255,255,255,0.85);
  border-radius: 4px;
  transition: width 0.4s ease;
}

.pokemon-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.pokemon-nombre {
  font-size: 1.5rem;
  font-weight: bold;
}

.pokemon-elemento {
  font-size: 0.9rem;
  opacity: 0.85;
}

.pokemon-meta {
  display: flex;
  gap: 24px;
}

.meta-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.meta-label {
  font-size: 0.75rem;
  opacity: 0.8;
  text-transform: uppercase;
}

.meta-valor {
  font-size: 1.1rem;
  font-weight: bold;
}

.pe-bajo {
  color: #ffe0e0;
}

/* Tabla */
.stats-tabla {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.fila-header {
  display: grid;
  grid-template-columns: 1.5fr 3fr 0.7fr 0.5fr 1.6fr;
  font-size: 0.78rem;
  font-weight: bold;
  color: #999;
  text-transform: uppercase;
  padding: 0 8px;
}

.fila-stat {
  display: grid;
  grid-template-columns: 1.5fr 3fr 0.7fr 0.5fr 1.6fr;
  align-items: center;
  gap: 12px;
  padding: 10px 8px;
  background: #f9f9f9;
  border-radius: 8px;
}

.stat-nombre {
  font-size: 0.9rem;
  color: #333;
  font-weight: bold;
}

.stat-bonus {
  font-size: 0.82rem;
  font-weight: bold;
  text-align: center;
}

.positivo { color: #2dc653; }
.negativo { color: #e63946; }
.neutro   { color: #bbb; }

.stat-barra-wrap {
  display: flex;
  align-items: center;
  gap: 10px;
}

.stat-barra {
  height: 8px;
  border-radius: 4px;
  flex: 1;
  transition: width 0.3s ease;
}

.stat-valor {
  font-size: 0.9rem;
  font-weight: bold;
  min-width: 28px;
  text-align: right;
}

.stat-tope {
  font-size: 0.8rem;
  color: #aaa;
  text-align: center;
}

.stat-tope.alcanzado {
  color: #2dc653;
  font-weight: bold;
}

.acciones-stat {
  display: flex;
  align-items: center;
  gap: 6px;
}

.btn-disminuir {
  width: 28px;
  height: 28px;
  font-size: 1rem;
  line-height: 1;
  color: #555;
  background: white;
  border: 2px solid #ccc;
  border-radius: 6px;
  cursor: pointer;
  transition: border-color 0.2s;
  flex-shrink: 0;
}

.btn-disminuir:not(:disabled):hover {
  border-color: #e63946;
  color: #e63946;
}

.btn-disminuir:disabled {
  cursor: not-allowed;
  opacity: 0.35;
}

.stat-contador {
  font-size: 0.82rem;
  font-weight: bold;
  color: #bbb;
  min-width: 22px;
  text-align: center;
}

.stat-contador.activo {
  color: #444;
}

.btn-entrenar {
  padding: 6px 10px;
  font-size: 0.9rem;
  font-weight: bold;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  background-color: #ccc;
  transition: filter 0.2s;
  flex-shrink: 0;
}

.btn-entrenar:not(:disabled):hover {
  filter: brightness(0.9);
}

.btn-entrenar:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

.aviso-pe {
  margin-top: 24px;
  text-align: center;
  color: #e63946;
  font-size: 0.9rem;
}

.aviso-completado {
  margin-top: 24px;
  padding: 14px 20px;
  background: #edfff3;
  border: 2px solid #2dc653;
  border-radius: 10px;
  color: #1a9e3f;
  font-weight: bold;
  font-size: 0.95rem;
  text-align: center;
}

.aviso-completado.nivel-up {
  background: #fff8e0;
  border-color: #f4c430;
  color: #a07800;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s, transform 0.3s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}

.acciones {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 32px;
}

.btn-volver {
  padding: 10px 20px;
  background: white;
  border: 2px solid #ccc;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.9rem;
  color: #555;
  transition: border-color 0.2s;
}

.btn-volver:hover {
  border-color: #888;
  color: #222;
}

.btn-confirmar {
  padding: 10px 28px;
  font-size: 0.95rem;
  font-weight: bold;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  background: #ccc;
  transition: filter 0.2s, transform 0.1s;
}

.btn-confirmar:not(:disabled):hover {
  filter: brightness(0.9);
  transform: scale(1.02);
}

.btn-confirmar:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}
</style>
