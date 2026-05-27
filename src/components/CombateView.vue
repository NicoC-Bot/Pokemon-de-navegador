<script setup>
import { ref, computed, nextTick } from 'vue'
import { pokemonesWild, rarezas } from '../data/pokemonesExploracion.js'

const props = defineProps({
  entrenador: Object,
  equipo:     Array,
  capturados: Array,
})
const emit = defineEmits(['volver'])

const modo = ref(null) // null | 'manual' | 'aleatorio' | 'combate'

// ── SELECCIÓN MANUAL ──────────────────────────────────────────────────
const equipoJugador  = ref(Array.from({ length: 6 }, () => null))
const equipoOponente = ref(Array.from({ length: 6 }, () => null))

function slotNumJugador(pokemon) {
  const i = equipoJugador.value.findIndex(p => p?.uid === pokemon.uid)
  return i === -1 ? null : i + 1
}
function slotNumOponente(pokemon) {
  const i = equipoOponente.value.findIndex(p => p?.id === pokemon.id)
  return i === -1 ? null : i + 1
}
function toggleJugador(pokemon) {
  const i = equipoJugador.value.findIndex(p => p?.uid === pokemon.uid)
  if (i !== -1) { equipoJugador.value[i] = null }
  else {
    const e = equipoJugador.value.findIndex(p => p === null)
    if (e !== -1) equipoJugador.value[e] = pokemon
  }
}
function toggleOponente(pokemon) {
  const i = equipoOponente.value.findIndex(p => p?.id === pokemon.id)
  if (i !== -1) { equipoOponente.value[i] = null }
  else {
    const e = equipoOponente.value.findIndex(p => p === null)
    if (e !== -1) equipoOponente.value[e] = pokemon
  }
}
function removerSlotJugador(i)  { equipoJugador.value[i]  = null }
function removerSlotOponente(i) { equipoOponente.value[i] = null }
function obtenerRareza(id) { return rarezas.find(r => r.id === id) ?? rarezas[0] }

const manualListo = computed(() =>
  equipoJugador.value.some(p => p !== null) &&
  equipoOponente.value.some(p => p !== null)
)
function entrarManual() {
  equipoJugador.value  = Array.from({ length: 6 }, (_, i) => props.equipo[i] ?? null)
  equipoOponente.value = Array.from({ length: 6 }, () => null)
  modo.value = 'manual'
}

// ── DUELO ALEATORIO ───────────────────────────────────────────────────
const aleatorioA = ref(null)
const aleatorioB = ref(null)
function generarAleatorio() {
  if (props.capturados.length < 2) return
  const pool = [...props.capturados].sort(() => Math.random() - 0.5)
  aleatorioA.value = pool[0]; aleatorioB.value = pool[1]
}
function entrarAleatorio() {
  aleatorioA.value = null; aleatorioB.value = null
  generarAleatorio(); modo.value = 'aleatorio'
}

// ── COMBATE ───────────────────────────────────────────────────────────
const estadosJ       = ref([])   // estado persistente de cada Pokémon del jugador
const estadosO       = ref([])   // estado persistente del equipo oponente
const indexA         = ref(0)
const indexB         = ref(0)
const estadoA        = computed(() => estadosJ.value[indexA.value] ?? null)
const estadoB        = computed(() => estadosO.value[indexB.value] ?? null)
const combatLog      = ref([])
const turnoNum       = ref(0)
const finalizado     = ref(false)
const ganador        = ref(null)
const logEl          = ref(null)
const subMenu         = ref(null)   // null | 'habilidades' | 'relevo'
const cooldownRelevo  = ref(0)
const esperandoRelevo = ref(false)  // true cuando el Pokémon activo cayó y hay que elegir sustituto

// Cola ATB: cada Pokémon acumula velocidad por tick; cuando llega a 100 actúa
const barraAccion = computed(() => {
  if (!estadoA.value || !estadoB.value || finalizado.value) return []
  const velA = Math.max(1, statEfectivo(estadoA.value, 'Velocidad'))
  const velB = Math.max(1, statEfectivo(estadoB.value, 'Velocidad'))
  const nA   = estadoA.value.pokemon.nombre
  const nB   = estadoB.value.pokemon.nombre
  const slots = []
  let gA = 0, gB = 0
  for (let tick = 0; slots.length < 10 && tick < 500; tick++) {
    gA += velA; gB += velB
    if (gA >= 100 && gB >= 100) {
      if (velA >= velB) {
        slots.push({ nombre: nA, equipo: 'jugador' })
        slots.push({ nombre: nB, equipo: 'oponente' })
      } else {
        slots.push({ nombre: nB, equipo: 'oponente' })
        slots.push({ nombre: nA, equipo: 'jugador' })
      }
      gA -= 100; gB -= 100
    } else if (gA >= 100) {
      slots.push({ nombre: nA, equipo: 'jugador' }); gA -= 100
    } else if (gB >= 100) {
      slots.push({ nombre: nB, equipo: 'oponente' }); gB -= 100
    }
  }
  return slots.slice(0, 10)
})

const relevosDisponibles = computed(() =>
  estadosJ.value
    .map((est, i) => ({ est, i }))
    .filter(({ est, i }) => i !== indexA.value && est.hpActual > 0)
)

// ── Helpers de combate ────────────────────────────────────────────────
function crearEstado(pokemon) {
  return { pokemon, hpActual: pokemon.stats.HP, cooldowns: {}, debuffs: [], esquiva: false, defendiendo: false }
}
function hpColor(hp, max) {
  const r = hp / max
  return r > 0.5 ? '#4caf50' : r > 0.25 ? '#ff9800' : '#f44336'
}
function hpPct(hp, max) { return Math.max(0, Math.round(hp / max * 100)) }

function statEfectivo(estado, nombre) {
  const base = estado.pokemon.stats[nombre] ?? 0
  const baja = estado.debuffs.filter(d => d.stat === nombre).reduce((s, d) => s + d.reduccion, 0)
  return Math.max(1, base - baja)
}

function calcularDaño(atacante, defensor, hab) {
  const atk = hab.tipo === 'especial'
    ? statEfectivo(atacante, 'Ataque Esp.')
    : statEfectivo(atacante, 'Ataque')
  const def = hab.tipo === 'especial'
    ? statEfectivo(defensor, 'Defensa Esp.')
    : statEfectivo(defensor, 'Defensa')

  let potencia = hab.potencia ?? 0
  if (hab.efecto?.tipo === 'condicion-hp' &&
      atacante.hpActual / atacante.pokemon.stats.HP <= hab.efecto.umbral) {
    potencia += hab.efecto.potenciaBonus
  }

  const ratio   = Math.max(0.5, Math.min(2.0, atk / Math.max(1, def)))
  const base    = Math.floor(potencia * (ratio * 0.3 + 0.1))
  const rng     = 0.85 + Math.random() * 0.15
  const critico = Math.random() < 0.1
  return { valor: Math.max(1, Math.floor(base * rng * (critico ? 1.5 : 1))), critico }
}

function aplicarEfecto(defensor, efecto) {
  if (!efecto || !['debuff','quemadura','paralisis'].includes(efecto.tipo)) return null
  if (Math.random() * 100 >= efecto.probabilidad) return null
  if (!efecto.acumulable) {
    defensor.debuffs = defensor.debuffs.filter(d => d.stat !== efecto.stat)
  } else {
    if (defensor.debuffs.filter(d => d.stat === efecto.stat).length >= (efecto.stacksMax ?? 1)) return null
  }
  defensor.debuffs.push({ stat: efecto.stat, reduccion: efecto.reduccion, turnosRestantes: efecto.turnos })
  return `  ${defensor.pokemon.nombre} pierde ${efecto.reduccion} en ${efecto.stat} (${efecto.turnos} turnos).`
}

function ejecutarAtaque(atacante, defensor, habIdx, tag = '') {
  const hab  = atacante.pokemon.habilidades?.[habIdx]
  if (!hab) return []
  const logs = []
  const nA = atacante.pokemon.nombre, nD = defensor.pokemon.nombre

  // Regeneración
  if (hab.tipo === 'estado' && hab.efecto?.tipo === 'regeneracion') {
    const cd = atacante.cooldowns[habIdx] ?? 0
    if (cd > 0) {
      const alt = atacante.pokemon.habilidades.findIndex((_, i) => i !== habIdx)
      return alt !== -1 ? ejecutarAtaque(atacante, defensor, alt, tag) : [`${tag}${nA} no puede actuar.`]
    }
    const cura = Math.floor(atacante.pokemon.stats.HP * hab.efecto.porcentaje / 100)
    atacante.hpActual = Math.min(atacante.pokemon.stats.HP, atacante.hpActual + cura)
    atacante.cooldowns[habIdx] = hab.efecto.cooldown
    logs.push(`${tag}${nA} usa ${hab.nombre} y recupera ${cura} HP.`)
    return logs
  }

  // Precisión
  if (hab.precision && Math.random() * 100 > hab.precision) {
    logs.push(`${tag}${nA} usa ${hab.nombre} → ¡Falló!`)
    return logs
  }

  // Esquiva del defensor
  if (defensor.esquiva) {
    defensor.esquiva = false
    logs.push(`${tag}${nA} usa ${hab.nombre} → ¡${nD} lo esquivó!`)
    return logs
  }

  // Daño
  const { valor, critico } = calcularDaño(atacante, defensor, hab)
  let dañoFinal = valor
  let escudoStr = ''
  if (defensor.defendiendo) {
    dañoFinal = Math.floor(valor / 2)
    defensor.defendiendo = false
    escudoStr = ' 🛡️'
  }
  defensor.hpActual = Math.max(0, defensor.hpActual - dañoFinal)
  logs.push(`${tag}${nA} usa ${hab.nombre} → ${dañoFinal} daño.${critico ? ' ¡Crítico!' : ''}${escudoStr}`)

  // Efecto secundario
  if (hab.efecto) {
    if (hab.efecto.tipo === 'esquiva') {
      if (Math.random() * 100 < hab.efecto.probabilidad) {
        atacante.esquiva = true
        logs.push(`  ${nA} está listo para esquivar.`)
      }
    } else if (hab.efecto.tipo !== 'condicion-hp') {
      const txt = aplicarEfecto(defensor, hab.efecto)
      if (txt) logs.push(txt)
    }
  }
  return logs
}

function tick(estado) {
  estado.debuffs = estado.debuffs
    .map(d => ({ ...d, turnosRestantes: d.turnosRestantes - 1 }))
    .filter(d => d.turnosRestantes > 0)
  for (const k in estado.cooldowns) {
    if (estado.cooldowns[k] > 0) estado.cooldowns[k]--
  }
  estado.esquiva = false
  estado.defendiendo = false
}

function elegirIA(estado) {
  const habs = estado.pokemon.habilidades ?? []
  const disp = habs.map((_, i) => i)
    .filter(i => !(habs[i].efecto?.tipo === 'regeneracion' && (estado.cooldowns[i] ?? 0) > 0))
  return disp.length > 0 ? disp[Math.floor(Math.random() * disp.length)] : 0
}

function scrollLog() {
  nextTick(() => { if (logEl.value) logEl.value.scrollTop = logEl.value.scrollHeight })
}

function revisarDerrota() {
  // devuelve true si el combate terminó
  if (estadoA.value.hpActual === 0) {
    combatLog.value.push(`💀 ${estadoA.value.pokemon.nombre} se debilitó.`)
    const tieneReserva = estadosJ.value.some((est, i) => i !== indexA.value && est.hpActual > 0)
    if (tieneReserva) {
      esperandoRelevo.value = true   // jugador elige sustituto manualmente
      return false
    } else {
      finalizado.value = true; ganador.value = 'oponente'
      combatLog.value.push('¡El equipo rival ganó el combate!')
      return true
    }
  }
  if (estadoB.value.hpActual === 0) {
    combatLog.value.push(`💀 ${estadoB.value.pokemon.nombre} se debilitó.`)
    indexB.value++
    if (indexB.value < estadosO.value.length) {
      combatLog.value.push(`↩  ${estadoB.value.pokemon.nombre} entra en combate.`)
    } else {
      finalizado.value = true; ganador.value = 'jugador'
      combatLog.value.push('¡Victoria! Derrotaste al equipo rival.')
      return true
    }
  }
  return false
}

function elegirRelevoPorDerrota(nuevoIndex) {
  indexA.value = nuevoIndex
  esperandoRelevo.value = false
  combatLog.value.push(`↩  ${estadoA.value.pokemon.nombre} entra en combate.`)
  scrollLog()
}

// Turno normal (jugador usa habilidad)
function ejecutarTurno(habIdx) {
  if (finalizado.value || esperandoRelevo.value) return
  turnoNum.value++
  combatLog.value.push(`— Turno ${turnoNum.value} —`)

  // El jugador actúa primero siempre (la velocidad afecta la frecuencia de turnos en el ATB, no quién va antes)
  combatLog.value.push(...ejecutarAtaque(estadoA.value, estadoB.value, habIdx, '🟢 '))

  // El enemigo actúa después, solo si sigue en pie
  if (estadoB.value.hpActual > 0) {
    const habIA = elegirIA(estadoB.value)
    combatLog.value.push(...ejecutarAtaque(estadoB.value, estadoA.value, habIA, '🔴 '))
  }

  tick(estadoA.value); tick(estadoB.value)
  if (cooldownRelevo.value > 0) cooldownRelevo.value--
  revisarDerrota()
  subMenu.value = null
  scrollLog()
}

// Defender: el jugador toma postura defensiva; el oponente ataca
function ejecutarDefender() {
  if (finalizado.value || esperandoRelevo.value) return
  turnoNum.value++
  combatLog.value.push(`— Turno ${turnoNum.value} —`)
  estadoA.value.defendiendo = true
  combatLog.value.push(`🛡️ ${estadoA.value.pokemon.nombre} adopta postura defensiva.`)
  if (estadoB.value.hpActual > 0) {
    const habIA = elegirIA(estadoB.value)
    combatLog.value.push(...ejecutarAtaque(estadoB.value, estadoA.value, habIA, '🔴 '))
  }
  tick(estadoA.value); tick(estadoB.value)
  if (cooldownRelevo.value > 0) cooldownRelevo.value--
  revisarDerrota()
  subMenu.value = null
  scrollLog()
}

// Relevo: el jugador cambia Pokémon; el oponente aún ataca ese turno
function ejecutarRelevo(nuevoIndex) {
  if (cooldownRelevo.value > 0 || finalizado.value || esperandoRelevo.value) return
  turnoNum.value++
  combatLog.value.push(`— Turno ${turnoNum.value} —`)
  const anterior = estadoA.value.pokemon.nombre
  indexA.value = nuevoIndex
  cooldownRelevo.value = 2
  combatLog.value.push(`🔄 Relevo: ${anterior} → ${estadoA.value.pokemon.nombre}.`)
  const habIA = elegirIA(estadoB.value)
  combatLog.value.push(...ejecutarAtaque(estadoB.value, estadoA.value, habIA, '🔴 '))
  tick(estadoA.value); tick(estadoB.value)
  revisarDerrota()
  subMenu.value = null
  scrollLog()
}

function iniciarCombate(teamsJ, teamsO) {
  const tj = teamsJ.filter(p => p !== null)
  const to = teamsO.filter(p => p !== null)
  estadosJ.value = tj.map(crearEstado)
  estadosO.value = to.map(crearEstado)
  indexA.value = 0; indexB.value = 0
  turnoNum.value = 0; finalizado.value = false; ganador.value = null
  cooldownRelevo.value = 0; subMenu.value = null; esperandoRelevo.value = false
  combatLog.value = [`⚔️  ${estadoA.value.pokemon.nombre} vs ${estadoB.value.pokemon.nombre} — ¡Comienza el combate!`]
  modo.value = 'combate'
}

function volver() {
  if (modo.value) modo.value = null
  else emit('volver')
}
</script>

<template>
  <div class="combate-view">

    <!-- ── Entrada ── -->
    <template v-if="modo === null">
      <h2>Combate</h2>
      <p class="subtitulo">¿Cómo quieres iniciar el duelo?</p>
      <div class="modos">
        <div class="modo-card" @click="entrarManual">
          <span class="modo-icono">⚔️</span>
          <h3>Seleccionar oponentes</h3>
          <p>Elige los Pokémon que participarán en el combate.</p>
        </div>
        <div class="modo-card" @click="entrarAleatorio">
          <span class="modo-icono">🎲</span>
          <h3>Duelo aleatorio</h3>
          <p>Dos Pokémon al azar de tu colección se enfrentan.</p>
        </div>
      </div>
      <button class="btn-volver" @click="emit('volver')">← Volver</button>
    </template>

    <!-- ── Selección manual ── -->
    <template v-else-if="modo === 'manual'">
      <h2>Seleccionar oponentes</h2>
      <div class="seleccion-layout">

        <div class="panel">
          <div class="panel-titulo">{{ entrenador.nombre }}</div>
          <div class="panel-slots">
            <div v-for="(slot, i) in equipoJugador" :key="'pj-'+i"
              class="team-slot" :class="{ lleno: slot !== null }"
              @click="slot && removerSlotJugador(i)">
              <template v-if="slot">
                <div class="slot-dot" :style="{ backgroundColor: slot.colorElemento }"></div>
                <span class="slot-texto">{{ slot.nombre }}</span>
              </template>
              <span v-else class="slot-num">{{ i + 1 }}</span>
            </div>
          </div>
          <div v-if="capturados.length === 0" class="grid-vacio">No tienes Pokémon capturados aún.</div>
          <div v-else class="poke-grid">
            <div v-for="pokemon in capturados" :key="pokemon.uid"
              class="poke-card" :class="{ seleccionado: slotNumJugador(pokemon) !== null }"
              @click="toggleJugador(pokemon)">
              <span v-if="slotNumJugador(pokemon) !== null" class="badge-slot">{{ slotNumJugador(pokemon) }}</span>
              <div class="card-barra" :style="{ backgroundColor: pokemon.colorElemento }"></div>
              <div class="card-body">
                <span class="card-nombre">{{ pokemon.nombre }}</span>
                <span class="card-elem">{{ pokemon.elemento }}</span>
                <span class="card-nivel">Nv.{{ pokemon.nivel }}</span>
              </div>
            </div>
          </div>
        </div>

        <div class="vs-col">VS</div>

        <div class="panel">
          <div class="panel-titulo">Oponente</div>
          <div class="panel-slots">
            <div v-for="(slot, i) in equipoOponente" :key="'po-'+i"
              class="team-slot" :class="{ lleno: slot !== null }"
              @click="slot && removerSlotOponente(i)">
              <template v-if="slot">
                <div class="slot-dot" :style="{ backgroundColor: slot.colorElemento }"></div>
                <span class="slot-texto">{{ slot.nombre }}</span>
              </template>
              <span v-else class="slot-num">{{ i + 1 }}</span>
            </div>
          </div>
          <div class="poke-grid">
            <div v-for="pokemon in pokemonesWild" :key="pokemon.id"
              class="poke-card" :class="{ seleccionado: slotNumOponente(pokemon) !== null }"
              @click="toggleOponente(pokemon)">
              <span v-if="slotNumOponente(pokemon) !== null" class="badge-slot">{{ slotNumOponente(pokemon) }}</span>
              <div class="card-barra" :style="{ backgroundColor: pokemon.colorElemento }"></div>
              <div class="card-body">
                <span class="card-nombre">{{ pokemon.nombre }}</span>
                <span class="card-elem">{{ pokemon.elemento }}</span>
                <span class="rareza-badge" :style="{ backgroundColor: obtenerRareza(pokemon.rareza).color }">
                  {{ obtenerRareza(pokemon.rareza).label }}
                </span>
              </div>
            </div>
          </div>
        </div>

      </div>
      <div class="pie">
        <button class="btn-volver" @click="volver">← Volver</button>
        <button class="btn-combate" :disabled="!manualListo"
          @click="iniciarCombate(equipoJugador, equipoOponente)">⚔️ Comenzar duelo</button>
      </div>
    </template>

    <!-- ── Duelo aleatorio ── -->
    <template v-else-if="modo === 'aleatorio'">
      <h2>Duelo aleatorio</h2>
      <p class="subtitulo">Combatientes seleccionados al azar.</p>
      <div v-if="capturados.length < 2" class="aviso">Necesitas al menos 2 Pokémon capturados.</div>
      <div v-else class="duelo-preview">
        <div class="duelo-card" :style="{ borderColor: aleatorioA.colorElemento }">
          <div class="duelo-header" :style="{ backgroundColor: aleatorioA.colorElemento }">
            <span>{{ aleatorioA.nombre }}</span>
            <span class="duelo-nivel">Nv.{{ aleatorioA.nivel }}</span>
          </div>
          <div class="duelo-body">
            <span class="duelo-elemento">{{ aleatorioA.elemento }}</span>
            <div class="duelo-stats">
              <span>HP {{ aleatorioA.hpActual ?? aleatorioA.stats.HP }}</span>
              <span>Atk {{ aleatorioA.stats.Ataque }}</span>
              <span>Spd {{ aleatorioA.stats.Velocidad }}</span>
            </div>
          </div>
        </div>
        <div class="vs-badge">VS</div>
        <div class="duelo-card" :style="{ borderColor: aleatorioB.colorElemento }">
          <div class="duelo-header" :style="{ backgroundColor: aleatorioB.colorElemento }">
            <span>{{ aleatorioB.nombre }}</span>
            <span class="duelo-nivel">Nv.{{ aleatorioB.nivel }}</span>
          </div>
          <div class="duelo-body">
            <span class="duelo-elemento">{{ aleatorioB.elemento }}</span>
            <div class="duelo-stats">
              <span>HP {{ aleatorioB.hpActual ?? aleatorioB.stats.HP }}</span>
              <span>Atk {{ aleatorioB.stats.Ataque }}</span>
              <span>Spd {{ aleatorioB.stats.Velocidad }}</span>
            </div>
          </div>
        </div>
      </div>
      <div class="pie">
        <button class="btn-volver" @click="volver">← Volver</button>
        <button class="btn-reroll" @click="generarAleatorio">🎲 Otro aleatorio</button>
        <button class="btn-combate" :disabled="!aleatorioA || !aleatorioB"
          @click="iniciarCombate([aleatorioA], [aleatorioB])">⚔️ Comenzar duelo</button>
      </div>
    </template>

    <!-- ── Combate activo ── -->
    <template v-else-if="modo === 'combate' && estadoA && estadoB">
      <div class="combate-layout">

        <!-- Barra de acción (orden de turnos ATB) -->
        <aside class="barra-accion">
          <div class="barra-titulo">Orden</div>
          <div
            v-for="(slot, i) in barraAccion"
            :key="i"
            class="barra-slot"
            :class="[slot.equipo, { 'barra-siguiente': i === 0 }]"
          >
            <span class="barra-dot" :class="slot.equipo"></span>
            <span class="barra-nombre">{{ slot.nombre }}</span>
          </div>
        </aside>

        <!-- Contenido principal -->
        <div class="combate-main">

          <!-- Arena: luchadores con HP -->
          <div class="arena">
            <div class="luchador">
              <div class="luchador-nombre" :style="{ color: estadoA.pokemon.colorElemento }">
                <span class="arena-tag arena-tag-propio">Tú</span>
                {{ estadoA.pokemon.nombre }}
              </div>
              <div class="hp-barra-wrap">
                <div class="hp-barra" :style="{
                  width: hpPct(estadoA.hpActual, estadoA.pokemon.stats.HP) + '%',
                  backgroundColor: hpColor(estadoA.hpActual, estadoA.pokemon.stats.HP),
                }"></div>
              </div>
              <div class="hp-texto">{{ estadoA.hpActual }} / {{ estadoA.pokemon.stats.HP }} HP</div>
              <div class="equipo-dots">
                <span v-for="(_, i) in estadosJ" :key="i" class="dot"
                  :class="(i < indexA || (i === indexA && estadoA.hpActual === 0)) ? 'dot-fainted' : 'dot-vivo'">
                </span>
              </div>
              <div v-if="estadoA.debuffs.length" class="debuffs">
                <span v-for="(d, i) in estadoA.debuffs" :key="i" class="debuff-tag">
                  -{{ d.reduccion }} {{ d.stat }}
                </span>
              </div>
            </div>

            <div class="arena-vs">
              <div class="turno-num">T.{{ turnoNum }}</div>
              VS
            </div>

            <div class="luchador luchador-right">
              <div class="luchador-nombre" :style="{ color: estadoB.pokemon.colorElemento }">
                {{ estadoB.pokemon.nombre }}
                <span class="arena-tag arena-tag-rival">Rival</span>
              </div>
              <div class="hp-barra-wrap">
                <div class="hp-barra" :style="{
                  width: hpPct(estadoB.hpActual, estadoB.pokemon.stats.HP) + '%',
                  backgroundColor: hpColor(estadoB.hpActual, estadoB.pokemon.stats.HP),
                }"></div>
              </div>
              <div class="hp-texto">{{ estadoB.hpActual }} / {{ estadoB.pokemon.stats.HP }} HP</div>
              <div class="equipo-dots equipo-dots-right">
                <span v-for="(_, i) in estadosO" :key="i" class="dot"
                  :class="(i < indexB || (i === indexB && estadoB.hpActual === 0)) ? 'dot-fainted' : 'dot-vivo'">
                </span>
              </div>
              <div v-if="estadoB.debuffs.length" class="debuffs debuffs-right">
                <span v-for="(d, i) in estadoB.debuffs" :key="i" class="debuff-tag">
                  -{{ d.reduccion }} {{ d.stat }}
                </span>
              </div>
            </div>
          </div>

          <!-- Log de combate -->
          <div class="combat-log" ref="logEl">
            <p v-for="(linea, i) in combatLog" :key="i"
              :class="{ 'log-separador': linea.startsWith('—') }">{{ linea }}</p>
          </div>

          <!-- Acciones -->
          <div v-if="!finalizado">

            <!-- Relevo obligatorio: el Pokémon activo cayó, el jugador elige sustituto -->
            <div v-if="esperandoRelevo" class="submenu relevo-obligatorio">
              <div class="relevo-titulo">⚠️ Elige tu próximo Pokémon</div>
              <div class="relevo-grid">
                <div
                  v-for="item in relevosDisponibles"
                  :key="item.i"
                  class="relevo-card"
                  @click="elegirRelevoPorDerrota(item.i)"
                >
                  <div class="relevo-dot" :style="{ backgroundColor: item.est.pokemon.colorElemento }"></div>
                  <span class="relevo-nombre">{{ item.est.pokemon.nombre }}</span>
                  <span class="relevo-hp">{{ item.est.hpActual }}/{{ item.est.pokemon.stats.HP }}</span>
                </div>
              </div>
            </div>

            <!-- Menú principal: 4 opciones -->
            <div v-else-if="subMenu === null" class="acciones-grid">
              <div class="accion-btn" @click="ejecutarTurno(0)">
                <span class="accion-icono">⚔️</span>
                <span class="accion-label">Ataque</span>
              </div>
              <div class="accion-btn" @click="subMenu = 'habilidades'">
                <span class="accion-icono">✨</span>
                <span class="accion-label">Habilidades</span>
              </div>
              <div class="accion-btn"
                :class="{ deshabilitado: cooldownRelevo > 0 || !relevosDisponibles.length }"
                @click="cooldownRelevo === 0 && relevosDisponibles.length && (subMenu = 'relevo')">
                <span class="accion-icono">🔄</span>
                <span class="accion-label">Relevo</span>
                <span v-if="cooldownRelevo > 0" class="accion-cd">CD {{ cooldownRelevo }}</span>
              </div>
              <div class="accion-btn" @click="ejecutarDefender">
                <span class="accion-icono">🛡️</span>
                <span class="accion-label">Defender</span>
              </div>
            </div>

            <!-- Submenú: Habilidades -->
            <div v-else-if="subMenu === 'habilidades'" class="submenu">
              <button class="btn-volver-sub" @click="subMenu = null">← Volver</button>
              <div class="habilidades-grid">
                <button
                  v-for="(hab, i) in estadoA.pokemon.habilidades"
                  :key="i"
                  class="btn-hab"
                  :disabled="(estadoA.cooldowns[i] ?? 0) > 0"
                  :title="hab.descripcion"
                  @click="ejecutarTurno(i)"
                >
                  <span class="hab-nombre">{{ hab.nombre }}</span>
                  <div class="hab-meta">
                    <span class="hab-tipo" :class="'tipo-' + hab.tipo">{{ hab.tipo }}</span>
                    <span v-if="hab.potencia" class="hab-pot">{{ hab.potencia }}</span>
                  </div>
                  <span v-if="(estadoA.cooldowns[i] ?? 0) > 0" class="cd-badge">CD {{ estadoA.cooldowns[i] }}</span>
                </button>
              </div>
            </div>

            <!-- Submenú: Relevo táctico -->
            <div v-else-if="subMenu === 'relevo'" class="submenu">
              <button class="btn-volver-sub" @click="subMenu = null">← Volver</button>
              <div class="relevo-grid">
                <div
                  v-for="item in relevosDisponibles"
                  :key="item.i"
                  class="relevo-card"
                  @click="ejecutarRelevo(item.i)"
                >
                  <div class="relevo-dot" :style="{ backgroundColor: item.est.pokemon.colorElemento }"></div>
                  <span class="relevo-nombre">{{ item.est.pokemon.nombre }}</span>
                  <span class="relevo-hp">{{ item.est.hpActual }}/{{ item.est.pokemon.stats.HP }}</span>
                </div>
              </div>
            </div>

          </div>

          <!-- Resultado -->
          <div v-if="finalizado" class="resultado-combate">
            <div class="resultado-texto"
              :class="ganador === 'jugador' ? 'resultado-victoria' : 'resultado-derrota'">
              {{ ganador === 'jugador' ? '¡Victoria!' : 'Derrota...' }}
            </div>
            <button class="btn-volver" @click="volver">← Volver al menú de combate</button>
          </div>

          <!-- Abandonar (rojo, centrado, al fondo) -->
          <div v-if="!finalizado" class="abandonar-wrap">
            <button class="btn-abandonar" @click="volver">Abandonar combate</button>
          </div>

        </div>
      </div>
    </template>

  </div>
</template>

<style scoped>
.combate-view { padding: 28px 32px; font-family: sans-serif; }

h2 { font-size: 1.4rem; margin-bottom: 4px; }
.subtitulo { color: #666; font-size: 0.9rem; margin-bottom: 28px; }

/* ── Entrada ── */
.modos { display: flex; justify-content: center; gap: 24px; margin-bottom: 32px; }
.modo-card {
  width: 220px; border: 2px solid #e0e0e0; border-radius: 16px; padding: 28px 20px;
  display: flex; flex-direction: column; align-items: center; gap: 8px; text-align: center;
  cursor: pointer; transition: border-color 0.2s, box-shadow 0.2s, transform 0.15s;
}
.modo-card:hover { border-color: #888; box-shadow: 0 6px 18px rgba(0,0,0,0.1); transform: translateY(-2px); }
.modo-icono { font-size: 2.4rem; }
.modo-card h3 { font-size: 1rem; margin: 0; }
.modo-card p  { font-size: 0.8rem; color: #777; margin: 0; }

/* ── Selección ── */
.seleccion-layout { display: flex; gap: 12px; align-items: flex-start; margin-bottom: 16px; }
.panel { flex: 1; min-width: 0; }
.panel-titulo { font-size: 0.75rem; font-weight: bold; text-transform: uppercase; color: #888; margin-bottom: 8px; }
.panel-slots { display: flex; gap: 4px; margin-bottom: 14px; }
.team-slot {
  flex: 1; height: 50px; border: 2px dashed #d0d0d0; border-radius: 6px;
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  gap: 3px; overflow: hidden; cursor: default; transition: border-color 0.15s, background 0.15s; min-width: 0;
}
.team-slot.lleno { border-style: solid; border-color: #999; cursor: pointer; }
.team-slot.lleno:hover { border-color: #e05555; background: #fff5f5; }
.slot-dot { width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; }
.slot-texto { font-size: 0.6rem; font-weight: bold; text-align: center; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: calc(100% - 6px); }
.slot-num { font-size: 0.78rem; color: #ccc; }
.vs-col { flex-shrink: 0; font-size: 1.1rem; font-weight: bold; color: #bbb; padding-top: 50px; }

/* ── Grid Pokémon ── */
.poke-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(135px, 1fr)); gap: 10px; padding: 6px 10px 4px 2px; }
.poke-card { position: relative; border: 2px solid #e0e0e0; border-radius: 8px; overflow: visible; cursor: pointer; transition: border-color 0.15s, box-shadow 0.15s; }
.poke-card:hover { border-color: #aaa; }
.poke-card.seleccionado { border-color: #4a90d9; box-shadow: 0 0 0 2px rgba(74,144,217,0.25); }
.badge-slot { position: absolute; top: -8px; right: -8px; background: #4a90d9; color: white; font-size: 0.65rem; font-weight: bold; width: 18px; height: 18px; border-radius: 50%; display: flex; align-items: center; justify-content: center; z-index: 2; border: 2px solid white; box-shadow: 0 1px 4px rgba(0,0,0,0.25); }
.card-barra { height: 5px; border-radius: 6px 6px 0 0; }
.card-body  { padding: 7px 9px 8px; }
.card-nombre { display: block; font-weight: bold; font-size: 0.84rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.card-elem   { display: block; font-size: 0.72rem; color: #888; margin-top: 2px; }
.card-nivel  { display: block; font-size: 0.72rem; color: #aaa; margin-top: 1px; }
.rareza-badge { display: inline-block; font-size: 0.58rem; font-weight: bold; padding: 2px 6px; border-radius: 8px; color: white; margin-top: 3px; }
.grid-vacio { color: #aaa; font-size: 0.85rem; text-align: center; padding: 24px 0; border: 2px dashed #e0e0e0; border-radius: 8px; }

/* ── Duelo preview ── */
.duelo-preview { display: flex; align-items: center; justify-content: center; gap: 24px; margin: 24px 0; }
.duelo-card { width: 200px; border: 2px solid #ddd; border-radius: 14px; overflow: hidden; }
.duelo-header { display: flex; justify-content: space-between; align-items: center; padding: 10px 14px; color: white; font-weight: bold; font-size: 0.95rem; }
.duelo-nivel { font-size: 0.72rem; opacity: 0.9; }
.duelo-body { padding: 10px 14px; display: flex; flex-direction: column; gap: 6px; }
.duelo-elemento { font-size: 0.82rem; color: #555; }
.duelo-stats { display: flex; gap: 8px; font-size: 0.75rem; color: #888; }
.vs-badge { font-size: 1.1rem; font-weight: bold; color: #bbb; flex-shrink: 0; }

/* ── Layout combate ── */
.combate-layout { display: flex; gap: 14px; align-items: flex-start; }

/* ── Barra de acción (ATB) ── */
.barra-accion {
  width: 130px; flex-shrink: 0;
  background: #f5f5f5; border: 1px solid #e0e0e0; border-radius: 10px;
  padding: 10px 8px;
}
.barra-titulo {
  font-size: 0.65rem; font-weight: bold; text-transform: uppercase;
  color: #aaa; letter-spacing: 1px; margin-bottom: 8px; text-align: center;
}
.barra-slot {
  display: flex; align-items: center; gap: 6px;
  padding: 5px 7px; border-radius: 6px; font-size: 0.73rem;
  margin-bottom: 3px; transition: background 0.2s;
}
.barra-slot.jugador  { background: rgba(76,175,80,0.12); }
.barra-slot.oponente { background: rgba(244,67,54,0.10); }
.barra-siguiente { font-weight: bold; }
.barra-siguiente.jugador  { outline: 1px solid #4caf50; }
.barra-siguiente.oponente { outline: 1px solid #f44336; }
.barra-dot { width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; }
.barra-dot.jugador  { background: #4caf50; }
.barra-dot.oponente { background: #f44336; }
.barra-nombre { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

/* ── Main combate ── */
.combate-main { flex: 1; min-width: 0; }

/* ── Arena ── */
.arena { display: flex; align-items: flex-start; gap: 16px; background: #f9f9f9; border: 1px solid #e8e8e8; border-radius: 12px; padding: 18px 20px; margin-bottom: 14px; }
.arena-vs { flex-shrink: 0; display: flex; flex-direction: column; align-items: center; gap: 4px; font-size: 1.1rem; font-weight: bold; color: #bbb; padding-top: 4px; }
.turno-num { font-size: 0.65rem; color: #aaa; font-weight: normal; letter-spacing: 0.5px; }
.luchador { flex: 1; }
.luchador-right { text-align: right; }
.luchador-nombre { font-size: 1rem; font-weight: bold; margin-bottom: 7px; display: flex; align-items: center; gap: 6px; }
.luchador-right .luchador-nombre { justify-content: flex-end; }
.arena-tag { font-size: 0.58rem; font-weight: bold; padding: 1px 6px; border-radius: 8px; color: white; flex-shrink: 0; }
.arena-tag-propio { background: #4caf50; }
.arena-tag-rival  { background: #f44336; }
.hp-barra-wrap { height: 8px; background: #e0e0e0; border-radius: 4px; overflow: hidden; margin-bottom: 4px; }
.hp-barra { height: 100%; border-radius: 4px; transition: width 0.35s ease, background-color 0.35s ease; }
.hp-texto { font-size: 0.7rem; color: #999; margin-bottom: 7px; }
.equipo-dots { display: flex; gap: 4px; margin-bottom: 6px; }
.equipo-dots-right { justify-content: flex-end; }
.dot { width: 8px; height: 8px; border-radius: 50%; }
.dot-vivo    { background: #4caf50; }
.dot-fainted { background: #ddd; }
.debuffs       { display: flex; flex-wrap: wrap; gap: 3px; }
.debuffs-right { justify-content: flex-end; }
.debuff-tag { font-size: 0.6rem; background: #fee2e2; color: #b91c1c; padding: 1px 5px; border-radius: 6px; font-weight: bold; }

/* ── Log ── */
.combat-log {
  background: #111; color: #ccc; border-radius: 8px; padding: 10px 14px;
  font-size: 0.76rem; font-family: monospace; line-height: 1.65;
  max-height: 160px; overflow-y: auto; margin-bottom: 14px;
}
.combat-log p { margin: 0; }
.log-separador { color: #555; border-top: 1px solid #2a2a2a; padding-top: 5px; margin-top: 3px; }

/* ── Acciones: menú principal (2×2) ── */
.acciones-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 10px; }
.accion-btn {
  border: 2px solid #e0e0e0; border-radius: 10px; padding: 12px 10px;
  display: flex; flex-direction: column; align-items: center; gap: 4px;
  cursor: pointer; transition: border-color 0.15s, background 0.15s;
  position: relative; user-select: none;
}
.accion-btn:hover { border-color: #888; background: #f5f5f5; }
.accion-btn.deshabilitado { opacity: 0.4; cursor: not-allowed; pointer-events: none; }
.accion-icono { font-size: 1.4rem; }
.accion-label { font-size: 0.82rem; font-weight: bold; }
.accion-cd { position: absolute; top: 5px; right: 7px; font-size: 0.58rem; color: #e53935; font-weight: bold; }

/* ── Submenús ── */
.submenu { margin-bottom: 10px; }
.btn-volver-sub {
  padding: 5px 12px; background: white; border: 1px solid #ccc; border-radius: 6px;
  cursor: pointer; font-size: 0.8rem; color: #666; margin-bottom: 8px;
  transition: border-color 0.15s;
}
.btn-volver-sub:hover { border-color: #888; }

.habilidades-grid { display: flex; gap: 8px; flex-wrap: wrap; }
.btn-hab {
  flex: 1; min-width: 130px; padding: 10px 12px; background: white;
  border: 2px solid #e0e0e0; border-radius: 10px; cursor: pointer;
  display: flex; flex-direction: column; gap: 4px; align-items: flex-start;
  transition: border-color 0.15s, background 0.15s; position: relative; text-align: left;
}
.btn-hab:hover:not(:disabled) { border-color: #888; background: #f5f5f5; }
.btn-hab:disabled { opacity: 0.4; cursor: not-allowed; }
.hab-nombre { font-weight: bold; font-size: 0.88rem; }
.hab-meta   { display: flex; align-items: center; gap: 6px; }
.hab-tipo   { font-size: 0.6rem; font-weight: bold; padding: 1px 5px; border-radius: 6px; color: white; }
.tipo-fisico   { background: #c06a2a; }
.tipo-especial { background: #5a4fcf; }
.tipo-estado   { background: #777; }
.hab-pot { font-size: 0.65rem; color: #aaa; }
.cd-badge { position: absolute; top: 6px; right: 8px; font-size: 0.6rem; color: #e53935; font-weight: bold; }

.relevo-obligatorio { border: 2px solid #c62828; border-radius: 10px; padding: 10px; }
.relevo-titulo { font-size: 0.85rem; font-weight: bold; color: #c62828; margin-bottom: 8px; }
.relevo-grid { display: flex; gap: 8px; flex-wrap: wrap; }
.relevo-card {
  display: flex; align-items: center; gap: 7px;
  border: 2px solid #e0e0e0; border-radius: 8px; padding: 8px 12px;
  cursor: pointer; transition: border-color 0.15s, background 0.15s; flex: 1; min-width: 120px;
}
.relevo-card:hover { border-color: #888; background: #f5f5f5; }
.relevo-dot  { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.relevo-nombre { font-weight: bold; font-size: 0.82rem; flex: 1; }
.relevo-hp { font-size: 0.7rem; color: #888; }

/* ── Resultado ── */
.resultado-combate { display: flex; flex-direction: column; align-items: center; gap: 14px; padding: 24px 0 8px; }
.resultado-texto { font-size: 1.8rem; font-weight: bold; }
.resultado-victoria { color: #2e7d32; }
.resultado-derrota  { color: #c62828; }

/* ── Abandonar ── */
.abandonar-wrap { display: flex; justify-content: center; margin-top: 20px; }
.btn-abandonar {
  padding: 9px 28px; background: #c62828; color: white;
  border: none; border-radius: 8px; cursor: pointer;
  font-size: 0.88rem; font-weight: bold; transition: background 0.2s;
}
.btn-abandonar:hover { background: #b71c1c; }

/* ── Aviso ── */
.aviso { text-align: center; color: #aaa; font-size: 0.88rem; padding: 32px 0; }

/* ── Botones generales ── */
.pie { display: flex; gap: 10px; align-items: center; }
.btn-volver { padding: 8px 18px; background: white; border: 2px solid #ccc; border-radius: 8px; cursor: pointer; font-size: 0.88rem; color: #555; transition: border-color 0.2s; }
.btn-volver:hover { border-color: #888; color: #222; }
.btn-combate { padding: 9px 20px; background: #222; color: white; border: none; border-radius: 8px; font-size: 0.88rem; font-weight: bold; cursor: pointer; transition: background 0.2s; }
.btn-combate:hover:not(:disabled) { background: #444; }
.btn-combate:disabled { background: #ccc; cursor: not-allowed; }
.btn-reroll { padding: 8px 16px; background: white; border: 2px solid #888; border-radius: 8px; cursor: pointer; font-size: 0.85rem; color: #444; transition: border-color 0.2s; }
.btn-reroll:hover { border-color: #444; }
</style>
