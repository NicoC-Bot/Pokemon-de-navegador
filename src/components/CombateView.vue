<script setup>
import { ref, computed, nextTick } from 'vue'
import { pokemonesWild, rarezas } from '../data/pokemonesExploracion.js'
import { proyectarCola, consumirTurno, gaugeAlEntrar } from '../utils/atb.js'
import { registrarBatalla } from '../api/batallas.js'

const props = defineProps({
  entrenador: Object,
  equipo:     Array,
  capturados: Array,
  partidaId:  Number,
})
const emit = defineEmits(['volver', 'actualizar-hp'])

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
const subMenu           = ref(null)   // null | 'habilidades' | 'relevo'
const cooldownRelevo    = ref(0)
const esperandoRelevo   = ref(false)  // true cuando el Pokémon activo cayó y hay que elegir sustituto
const esperandoEnemigoAct = ref(false) // true mientras el enemigo ejecuta su turno automático
const gaugeA = ref(0)  // gauge ATB acumulado del Pokémon del jugador
const gaugeB = ref(0)  // gauge ATB acumulado del Pokémon enemigo

// Cola ATB: proyecta los próximos 10 turnos desde el estado actual de los gauges
const barraAccion = computed(() => {
  if (!estadoA.value || !estadoB.value || finalizado.value) return []
  return proyectarCola({
    gaugeA: gaugeA.value,
    velA:   Math.max(1, statEfectivo(estadoA.value, 'Velocidad')),
    nombreA: estadoA.value.pokemon.nombre,
    gaugeB: gaugeB.value,
    velB:   Math.max(1, statEfectivo(estadoB.value, 'Velocidad')),
    nombreB: estadoB.value.pokemon.nombre,
  })
})

// Avanza los gauges hasta que el equipo indicado actúa y consume su turno
function consumirAccion(equipo) {
  const { gaugeA: nA, gaugeB: nB } = consumirTurno({
    gaugeA: gaugeA.value,
    velA:   Math.max(1, statEfectivo(estadoA.value, 'Velocidad')),
    gaugeB: gaugeB.value,
    velB:   Math.max(1, statEfectivo(estadoB.value, 'Velocidad')),
    equipo,
  })
  gaugeA.value = nA
  gaugeB.value = nB
}

const relevosDisponibles = computed(() =>
  estadosJ.value
    .map((est, i) => ({ est, i }))
    .filter(({ est, i }) => i !== indexA.value && est.hpActual > 0)
)

// ── Registro de batalla ───────────────────────────────────────────────
const participantesBatalla = ref([])
const turnosBatalla        = ref([])

function _agregarParticipante(estado, equipo) {
  const nombre = estado.pokemon.nombre
  if (participantesBatalla.value.some(p => p.pokemon_nombre === nombre && p.equipo === equipo)) return
  participantesBatalla.value.push({
    pokemon_nombre: nombre,
    pokemon_uid:    estado.pokemon.uid ?? null,
    equipo,
  })
}

async function _enviarBatalla(estado, resultado) {
  try {
    await registrarBatalla({
      partida_id:     props.partidaId ?? null,
      estado,
      resultado,
      turnos_totales: turnoNum.value,
      participantes:  participantesBatalla.value,
      turnos:         turnosBatalla.value,
    })
  } catch (e) {
    console.error('No se pudo registrar la batalla:', e)
  }
}

// ── Helpers de combate ────────────────────────────────────────────────
function crearEstado(pokemon) {
  return { pokemon, hpActual: pokemon.hpActual ?? pokemon.stats.HP, cooldowns: {}, debuffs: [], esquiva: false, defendiendo: false }
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
      _enviarBatalla('terminado', 'derrota')
      return true
    }
  }
  if (estadoB.value && estadoB.value.hpActual === 0) {
    combatLog.value.push(`💀 ${estadoB.value.pokemon.nombre} se debilitó.`)
    if (indexB.value + 1 < estadosO.value.length) {
      indexB.value++
      gaugeB.value = gaugeAlEntrar(
        Math.max(1, statEfectivo(estadoB.value, 'Velocidad')),
        Math.max(1, statEfectivo(estadoA.value, 'Velocidad')),
        gaugeA.value,
      )
      _agregarParticipante(estadoB.value, 'oponente')
      combatLog.value.push(`↩  ${estadoB.value.pokemon.nombre} entra en combate.`)
    } else {
      finalizado.value = true; ganador.value = 'jugador'
      combatLog.value.push('¡Victoria! Derrotaste al equipo rival.')
      _enviarBatalla('terminado', 'victoria')
      return true
    }
  }
  return false
}

function elegirRelevoPorDerrota(nuevoIndex) {
  indexA.value = nuevoIndex
  gaugeA.value = gaugeAlEntrar(
    Math.max(1, statEfectivo(estadoA.value, 'Velocidad')),
    Math.max(1, statEfectivo(estadoB.value, 'Velocidad')),
    gaugeB.value,
  )
  _agregarParticipante(estadoA.value, 'jugador')
  esperandoRelevo.value = false
  combatLog.value.push(`↩  ${estadoA.value.pokemon.nombre} entra en combate.`)
  scrollLog()
  // Si al enemigo le toca actuar primero según la cola, lo disparamos automáticamente
  if (!finalizado.value && barraAccion.value[0]?.equipo === 'oponente') {
    dispararTurnoEnemigo()
  }
}

function dispararTurnoEnemigo() {
  esperandoEnemigoAct.value = true
  setTimeout(() => {
    if (finalizado.value || !estadoB.value || estadoB.value.hpActual === 0) {
      esperandoEnemigoAct.value = false
      return
    }
    consumirAccion('oponente')
    const habIA         = elegirIA(estadoB.value)
    const _habEnemigo   = estadoB.value.pokemon.habilidades?.[habIA]
    const _nombreAtac   = estadoB.value.pokemon.nombre
    const _nombreObj    = estadoA.value.pokemon.nombre
    const _hpAntesA     = estadoA.value.hpActual
    combatLog.value.push(...ejecutarAtaque(estadoB.value, estadoA.value, habIA, '🔴 '))
    turnosBatalla.value.push({
      numero_turno:     turnoNum.value,
      participante:     _nombreAtac,
      equipo_participante: 'oponente',
      tipo_accion:      'habilidad',
      habilidad_nombre: _habEnemigo?.nombre ?? null,
      dano_causado:     Math.max(0, _hpAntesA - estadoA.value.hpActual) || null,
      objetivo:         _nombreObj,
      equipo_objetivo:  'jugador',
    })
    tick(estadoB.value)
    revisarDerrota()
    scrollLog()
    // Si al enemigo le toca de nuevo, actúa en otro turno automático
    if (!finalizado.value && !esperandoRelevo.value && barraAccion.value[0]?.equipo === 'oponente') {
      dispararTurnoEnemigo()
    } else {
      esperandoEnemigoAct.value = false
    }
  }, 700)
}

function _verificarTurnoEnemigo() {
  if (!estadoB.value || estadoB.value.hpActual > 0) {
    // Enemigo vivo (o finalizado): comprobar si le toca actuar
    if (estadoB.value && barraAccion.value[0]?.equipo === 'oponente') {
      dispararTurnoEnemigo()
    }
  } else {
    // Enemigo derrotado: procesar y comprobar si el nuevo rival actúa primero
    tick(estadoB.value)
    revisarDerrota()
    scrollLog()
    if (!finalizado.value && !esperandoRelevo.value && barraAccion.value[0]?.equipo === 'oponente') {
      dispararTurnoEnemigo()
    }
  }
}

// Turno normal (jugador usa habilidad)
function ejecutarTurno(habIdx) {
  if (finalizado.value || esperandoRelevo.value || esperandoEnemigoAct.value) return
  consumirAccion('jugador')
  turnoNum.value++
  combatLog.value.push(`— Turno ${turnoNum.value} —`)

  const _habJug     = estadoA.value.pokemon.habilidades?.[habIdx]
  const _nombreObj  = estadoB.value.pokemon.nombre
  const _hpAntesB   = estadoB.value.hpActual
  combatLog.value.push(...ejecutarAtaque(estadoA.value, estadoB.value, habIdx, '🟢 '))
  turnosBatalla.value.push({
    numero_turno:     turnoNum.value,
    participante:     estadoA.value.pokemon.nombre,
    equipo_participante: 'jugador',
    tipo_accion:      'habilidad',
    habilidad_nombre: _habJug?.nombre ?? null,
    dano_causado:     Math.max(0, _hpAntesB - estadoB.value.hpActual) || null,
    objetivo:         _nombreObj,
    equipo_objetivo:  'oponente',
  })
  tick(estadoA.value)
  if (cooldownRelevo.value > 0) cooldownRelevo.value--
  subMenu.value = null
  scrollLog()
  _verificarTurnoEnemigo()
}

// Defender: el jugador toma postura defensiva; el oponente actúa solo si le toca
function ejecutarDefender() {
  if (finalizado.value || esperandoRelevo.value || esperandoEnemigoAct.value) return
  consumirAccion('jugador')
  turnoNum.value++
  combatLog.value.push(`— Turno ${turnoNum.value} —`)
  estadoA.value.defendiendo = true
  combatLog.value.push(`🛡️ ${estadoA.value.pokemon.nombre} adopta postura defensiva.`)
  turnosBatalla.value.push({
    numero_turno:        turnoNum.value,
    participante:        estadoA.value.pokemon.nombre,
    equipo_participante: 'jugador',
    tipo_accion:         'defender',
    habilidad_nombre:    null,
    dano_causado:        null,
    objetivo:            null,
    equipo_objetivo:     null,
  })
  tick(estadoA.value)
  if (cooldownRelevo.value > 0) cooldownRelevo.value--
  subMenu.value = null
  scrollLog()
  _verificarTurnoEnemigo()
}

// Relevo: el jugador cambia Pokémon; el oponente NO ataca durante el relevo
function ejecutarRelevo(nuevoIndex) {
  if (cooldownRelevo.value > 0 || finalizado.value || esperandoRelevo.value || esperandoEnemigoAct.value) return
  turnoNum.value++
  combatLog.value.push(`— Turno ${turnoNum.value} —`)
  const anterior = estadoA.value.pokemon.nombre
  turnosBatalla.value.push({
    numero_turno:        turnoNum.value,
    participante:        anterior,
    equipo_participante: 'jugador',
    tipo_accion:         'relevo',
    habilidad_nombre:    null,
    dano_causado:        null,
    objetivo:            null,
    equipo_objetivo:     null,
  })
  indexA.value = nuevoIndex
  gaugeA.value = gaugeAlEntrar(
    Math.max(1, statEfectivo(estadoA.value, 'Velocidad')),
    Math.max(1, statEfectivo(estadoB.value, 'Velocidad')),
    gaugeB.value,
  )
  _agregarParticipante(estadoA.value, 'jugador')
  cooldownRelevo.value = 2
  combatLog.value.push(`🔄 Relevo: ${anterior} → ${estadoA.value.pokemon.nombre}.`)
  tick(estadoA.value); tick(estadoB.value)
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
  cooldownRelevo.value = 0; subMenu.value = null; esperandoRelevo.value = false; esperandoEnemigoAct.value = false
  gaugeA.value = 0; gaugeB.value = 0
  participantesBatalla.value = []; turnosBatalla.value = []
  estadosJ.value.forEach(est => _agregarParticipante(est, 'jugador'))
  estadosO.value.forEach(est => _agregarParticipante(est, 'oponente'))
  combatLog.value = [`⚔️  ${estadoA.value.pokemon.nombre} vs ${estadoB.value.pokemon.nombre} — ¡Comienza el combate!`]
  modo.value = 'combate'
  // Si el enemigo es más rápido y le toca primero, actúa automáticamente
  nextTick(() => {
    if (barraAccion.value[0]?.equipo === 'oponente') {
      dispararTurnoEnemigo()
    }
  })
}

function volver() {
  if (modo.value === 'combate' && !finalizado.value) {
    _enviarBatalla('abandono', null)
  }
  if (modo.value) modo.value = null
  else {
    const hpData = estadosJ.value.map(est => ({ uid: est.pokemon.uid, hpActual: est.hpActual }))
    emit('actualizar-hp', hpData)
    emit('volver')
  }
}
</script>

<template>
  <div class="combate-view">
    <button class="btn-volver" @click="volver">← Volver</button>

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
          <div class="barra-titulo">Orden de turnos</div>
          <div
            v-for="(slot, i) in barraAccion"
            :key="i"
            class="barra-slot"
            :class="[slot.equipo, { 'barra-actual': i === 0 }]"
            :style="{ opacity: i === 0 ? 1 : Math.max(0.25, 1 - i * 0.09) }"
          >
            <span class="barra-num">{{ i === 0 ? '▶' : i + 1 }}</span>
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

            <!-- Turno del rival -->
            <div v-else-if="esperandoEnemigoAct" class="turno-enemigo">🔴 El rival está actuando...</div>

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
                  :class="'tipo-' + hab.tipo"
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
            <button class="btn-volver-resultado" @click="volver">← Volver al menú de combate</button>
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
.combate-view { padding: 28px 32px; font-family: sans-serif; } /* espaciado interno del componente; tipografía base */

h2 { font-size: 1.4rem; margin-bottom: 4px; } /* tamaño y separación del título de sección */
.subtitulo { color: #666; font-size: 0.9rem; margin-bottom: 28px; } /* texto secundario atenuado bajo el título */

/* ── Entrada ── */
.modos { display: flex; justify-content: center; gap: 24px; margin-bottom: 32px; } /* contenedor horizontal centrado de las tarjetas de modo */
.modo-card {
  width: 220px; border: 2px solid #e0e0e0; border-radius: 16px; padding: 28px 20px; /* tamaño, borde redondeado y espaciado interno de la tarjeta */
  display: flex; flex-direction: column; align-items: center; gap: 8px; text-align: center; /* apila contenido centrado verticalmente */
  cursor: pointer; transition: border-color 0.2s, box-shadow 0.2s, transform 0.15s; /* cursor de puntero y transición suave al pasar el cursor */
}
.modo-card:hover { border-color: #888; box-shadow: 0 6px 18px rgba(0,0,0,0.1); transform: translateY(-2px); } /* resalta la tarjeta al pasar el cursor */
.modo-icono { font-size: 2.4rem; } /* emoji de ícono grande en la tarjeta de modo */
.modo-card h3 { font-size: 1rem; margin: 0; } /* título de la tarjeta sin margen extra */
.modo-card p  { font-size: 0.8rem; color: #777; margin: 0; } /* descripción pequeña y atenuada en la tarjeta */

/* ── Selección ── */
.seleccion-layout { display: flex; gap: 12px; align-items: flex-start; margin-bottom: 16px; } /* layout horizontal de paneles jugador y oponente */
.panel { flex: 1; min-width: 0; } /* panel ocupa espacio disponible sin desbordarse */
.panel-titulo { font-size: 0.75rem; font-weight: bold; text-transform: uppercase; color: #888; margin-bottom: 8px; } /* etiqueta de panel en mayúsculas y color atenuado */
.panel-slots { display: flex; gap: 4px; margin-bottom: 14px; } /* fila de slots del equipo seleccionado */
.team-slot {
  flex: 1; height: 50px; border: 2px dashed #d0d0d0; border-radius: 6px; /* slot de equipo: altura fija con borde punteado */
  display: flex; flex-direction: column; align-items: center; justify-content: center; /* centra el contenido dentro del slot */
  gap: 3px; overflow: hidden; cursor: default; transition: border-color 0.15s, background 0.15s; min-width: 0; /* ajusta desbordamiento y transición al llenarse */
}
.team-slot.lleno { border-style: solid; border-color: #999; cursor: pointer; } /* slot ocupado: borde sólido y cursor interactivo */
.team-slot.lleno:hover { border-color: #e05555; background: #fff5f5; } /* indica que el slot puede eliminarse al pasar el cursor */
.slot-dot { width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; } /* punto de color del elemento del Pokémon en el slot */
.slot-texto { font-size: 0.6rem; font-weight: bold; text-align: center; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: calc(100% - 6px); } /* nombre del Pokémon truncado dentro del slot */
.slot-num { font-size: 0.78rem; color: #ccc; } /* número de slot vacío en gris claro */
.vs-col { flex-shrink: 0; font-size: 1.1rem; font-weight: bold; color: #bbb; padding-top: 50px; } /* separador "VS" centrado entre los dos paneles */

/* ── Grid Pokémon ── */
.poke-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(135px, 1fr)); gap: 10px; padding: 6px 10px 4px 2px; } /* grilla responsiva de tarjetas de Pokémon */
.poke-card { position: relative; border: 2px solid #e0e0e0; border-radius: 8px; overflow: visible; cursor: pointer; transition: border-color 0.15s, box-shadow 0.15s; } /* tarjeta de Pokémon seleccionable con borde suave */
.poke-card:hover { border-color: #aaa; } /* oscurece el borde al pasar el cursor */
.poke-card.seleccionado { border-color: #4a90d9; box-shadow: 0 0 0 2px rgba(74,144,217,0.25); } /* resalta la tarjeta cuando el Pokémon está en el equipo */
.badge-slot { position: absolute; top: -8px; right: -8px; background: #4a90d9; color: white; font-size: 0.65rem; font-weight: bold; width: 18px; height: 18px; border-radius: 50%; display: flex; align-items: center; justify-content: center; z-index: 2; border: 2px solid white; box-shadow: 0 1px 4px rgba(0,0,0,0.25); } /* badge circular con número de slot encima de la tarjeta */
.card-barra { height: 5px; border-radius: 6px 6px 0 0; } /* franja de color del elemento en la parte superior */
.card-body  { padding: 7px 9px 8px; } /* espaciado interno del cuerpo de la tarjeta */
.card-nombre { display: block; font-weight: bold; font-size: 0.84rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; } /* nombre del Pokémon en negrita, truncado si es largo */
.card-elem   { display: block; font-size: 0.72rem; color: #888; margin-top: 2px; } /* tipo de elemento en gris pequeño */
.card-nivel  { display: block; font-size: 0.72rem; color: #aaa; margin-top: 1px; } /* nivel del Pokémon en gris claro */
.rareza-badge { display: inline-block; font-size: 0.58rem; font-weight: bold; padding: 2px 6px; border-radius: 8px; color: white; margin-top: 3px; } /* badge de rareza con fondo de color */
.grid-vacio { color: #aaa; font-size: 0.85rem; text-align: center; padding: 24px 0; border: 2px dashed #e0e0e0; border-radius: 8px; } /* mensaje cuando no hay Pokémon capturados */

/* ── Duelo preview ── */
.duelo-preview { display: flex; align-items: center; justify-content: center; gap: 24px; margin: 24px 0; } /* vista previa de los dos combatientes aleatorios */
.duelo-card { width: 200px; border: 2px solid #ddd; border-radius: 14px; overflow: hidden; } /* tarjeta individual del combatiente en el duelo */
.duelo-header { display: flex; justify-content: space-between; align-items: center; padding: 10px 14px; color: white; font-weight: bold; font-size: 0.95rem; } /* cabecera con nombre y nivel sobre fondo de color */
.duelo-nivel { font-size: 0.72rem; opacity: 0.9; } /* nivel del Pokémon ligeramente transparente */
.duelo-body { padding: 10px 14px; display: flex; flex-direction: column; gap: 6px; } /* cuerpo de la tarjeta con elemento y stats */
.duelo-elemento { font-size: 0.82rem; color: #555; } /* nombre del elemento en gris oscuro */
.duelo-stats { display: flex; gap: 8px; font-size: 0.75rem; color: #888; } /* fila de stats resumidos HP, Atk, Spd */
.vs-badge { font-size: 1.1rem; font-weight: bold; color: #bbb; flex-shrink: 0; } /* separador "VS" entre las dos tarjetas de duelo */

/* ── Layout combate ── */
.combate-layout { display: flex; gap: 14px; align-items: flex-start; } /* layout principal del combate: sidebar ATB + arena */

/* ── Barra de acción (ATB) ── */
.barra-accion {
  width: 140px; flex-shrink: 0; /* ancho fijo del panel ATB, no se encoge */
  background: #f5f5f5; border: 1px solid #e0e0e0; border-radius: 10px; /* fondo claro con borde y esquinas redondeadas */
  padding: 10px 8px; /* espacio interno del panel de orden de turnos */
}
.barra-titulo {
  font-size: 0.65rem; font-weight: bold; text-transform: uppercase; /* texto "Orden de turnos" en mayúsculas y negrita */
  color: #aaa; letter-spacing: 1px; margin-bottom: 8px; text-align: center; /* color atenuado, espaciado entre letras, centrado */
}
.barra-slot {
  display: flex; align-items: center; gap: 6px; /* fila con punto de color, número y nombre */
  padding: 4px 7px; border-radius: 6px; font-size: 0.72rem; color: #555; /* espaciado y estilo de texto de cada entrada de turno */
  margin-bottom: 2px; transition: opacity 0.3s; /* separación entre entradas y transición de opacidad */
}
.barra-slot.jugador  { background: rgba(76,175,80,0.10); } /* fondo verde suave para el turno del jugador */
.barra-slot.oponente { background: rgba(244,67,54,0.08); } /* fondo rojo suave para el turno del oponente */
.barra-actual { padding: 7px 9px !important; font-size: 0.82rem !important; font-weight: bold; } /* destaca el turno activo: más grande y en negrita */
.barra-actual.jugador  { background: rgba(76,175,80,0.2) !important; outline: 2px solid #4caf50; color: #2e7d32; } /* turno activo del jugador: verde con contorno */
.barra-actual.oponente { background: rgba(244,67,54,0.18) !important; outline: 2px solid #f44336; color: #b71c1c; } /* turno activo del oponente: rojo con contorno */
.barra-num { font-size: 0.6rem; color: #bbb; width: 14px; text-align: center; flex-shrink: 0; font-weight: bold; } /* número de posición en la cola ATB */
.barra-actual .barra-num { font-size: 0.68rem; color: inherit; } /* número del turno activo hereda el color del equipo */
.barra-dot { width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; } /* indicador circular de equipo en la cola ATB */
.barra-dot.jugador  { background: #4caf50; } /* punto verde para Pokémon del jugador */
.barra-dot.oponente { background: #f44336; } /* punto rojo para Pokémon del oponente */
.barra-nombre { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; flex: 1; } /* nombre truncado del Pokémon en el turno */

/* ── Main combate ── */
.combate-main { flex: 1; min-width: 0; } /* área principal del combate, ocupa espacio restante */

/* ── Arena ── */
.arena { display: flex; align-items: flex-start; gap: 16px; background: #f9f9f9; border: 1px solid #e8e8e8; border-radius: 12px; padding: 18px 20px; margin-bottom: 14px; } /* zona de combate con HP de ambos luchadores */
.arena-vs { flex-shrink: 0; display: flex; flex-direction: column; align-items: center; gap: 4px; font-size: 1.1rem; font-weight: bold; color: #bbb; padding-top: 4px; } /* separador "VS" y número de turno al centro */
.turno-num { font-size: 0.65rem; color: #aaa; font-weight: normal; letter-spacing: 0.5px; } /* contador de turno actual encima del VS */
.luchador { flex: 1; } /* panel del luchador ocupa la mitad de la arena */
.luchador-right { text-align: right; } /* luchador rival alineado a la derecha */
.luchador-nombre { font-size: 1rem; font-weight: bold; margin-bottom: 7px; display: flex; align-items: center; gap: 6px; } /* nombre del Pokémon en negrita con tag de equipo */
.luchador-right .luchador-nombre { justify-content: flex-end; } /* nombre del rival empujado al extremo derecho */
.arena-tag { font-size: 0.58rem; font-weight: bold; padding: 1px 6px; border-radius: 8px; color: white; flex-shrink: 0; } /* etiqueta "Tú"/"Rival" junto al nombre */
.arena-tag-propio { background: #4caf50; } /* etiqueta verde para el Pokémon del jugador */
.arena-tag-rival  { background: #f44336; } /* etiqueta roja para el Pokémon enemigo */
.hp-barra-wrap { height: 8px; background: #e0e0e0; border-radius: 4px; overflow: hidden; margin-bottom: 4px; } /* contenedor gris de la barra de HP */
.hp-barra { height: 100%; border-radius: 4px; transition: width 0.35s ease, background-color 0.35s ease; } /* relleno de HP con animación suave al recibir daño */
.hp-texto { font-size: 0.7rem; color: #999; margin-bottom: 7px; } /* valores numéricos de HP actuales */
.equipo-dots { display: flex; gap: 4px; margin-bottom: 6px; } /* fila de puntos que representan el equipo completo */
.equipo-dots-right { justify-content: flex-end; } /* puntos del equipo rival alineados a la derecha */
.dot { width: 8px; height: 8px; border-radius: 50%; } /* punto circular de estado de cada Pokémon */
.dot-vivo    { background: #4caf50; } /* verde indica que el Pokémon sigue en pie */
.dot-fainted { background: #ddd; } /* gris indica que el Pokémon se debilitó */
.debuffs       { display: flex; flex-wrap: wrap; gap: 3px; } /* fila de etiquetas de debuff activos del jugador */
.debuffs-right { justify-content: flex-end; } /* debuffs del rival alineados al extremo derecho */
.debuff-tag { font-size: 0.6rem; background: #fee2e2; color: #b91c1c; padding: 1px 5px; border-radius: 6px; font-weight: bold; } /* etiqueta roja con la penalización de stat activa */

/* ── Log ── */
.combat-log {
  background: #111; color: #ccc; border-radius: 8px; padding: 10px 14px; /* fondo oscuro tipo terminal para el log */
  font-size: 0.76rem; font-family: monospace; line-height: 1.65; /* fuente monoespaciada y líneas cómodas de leer */
  max-height: 160px; overflow-y: auto; margin-bottom: 14px; /* altura máxima con scroll vertical para el historial */
}
.combat-log p { margin: 0; } /* elimina margen entre líneas del log */
.log-separador { color: #555; border-top: 1px solid #2a2a2a; padding-top: 5px; margin-top: 3px; } /* línea divisoria entre turnos en el log */

.turno-enemigo { text-align: center; padding: 14px; color: #e63946; font-weight: bold; font-size: 0.95rem; } /* aviso rojo mientras el rival ejecuta su turno */

/* ── Acciones: menú principal (2×2) ── */
.acciones-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 10px; } /* grilla 2x2 del menú principal de acciones */
.accion-btn {
  border: 2px solid #e0e0e0; border-radius: 10px; padding: 12px 10px; /* borde y relleno de los botones de acción */
  display: flex; flex-direction: column; align-items: center; gap: 4px; /* ícono y etiqueta apilados verticalmente */
  cursor: pointer; transition: border-color 0.15s, background 0.15s; /* interactivo con transición suave al pasar el cursor */
  position: relative; user-select: none; /* posición relativa para el badge de cooldown */
}
.accion-btn:hover { border-color: #888; background: #f5f5f5; } /* resalta el botón de acción al pasar el cursor */
.accion-btn.deshabilitado { opacity: 0.4; cursor: not-allowed; pointer-events: none; } /* atenúa y bloquea el botón cuando no está disponible */
.accion-icono { font-size: 1.4rem; } /* emoji grande del tipo de acción */
.accion-label { font-size: 0.82rem; font-weight: bold; } /* etiqueta del botón en negrita */
.accion-cd { position: absolute; top: 5px; right: 7px; font-size: 0.58rem; color: #e53935; font-weight: bold; } /* indicador de cooldown en esquina superior derecha */

/* ── Submenús ── */
.submenu { margin-bottom: 10px; } /* separación inferior del submenú activo */
.btn-volver-sub {
  padding: 5px 12px; background: white; border: 1px solid #ccc; border-radius: 6px; /* botón "Volver" dentro de submenús */
  cursor: pointer; font-size: 0.8rem; color: #666; margin-bottom: 8px; /* texto pequeño gris con separación al contenido */
  transition: border-color 0.15s; /* suaviza el cambio de borde al pasar el cursor */
}
.btn-volver-sub:hover { border-color: #888; } /* oscurece el borde al pasar el cursor */

.habilidades-grid { display: flex; gap: 8px; flex-wrap: wrap; } /* fila envolvente de botones de habilidades */
.btn-hab {
  flex: 1; min-width: 130px; padding: 10px 12px; background: white; /* botón expansible con mínimo ancho para la habilidad */
  border: 2px solid #e0e0e0; border-radius: 10px; cursor: pointer; /* borde redondeado e interactivo */
  display: flex; flex-direction: column; gap: 4px; align-items: flex-start; /* nombre y metadatos apilados a la izquierda */
  transition: border-color 0.15s, background 0.15s; position: relative; text-align: left; /* transición suave y texto alineado a la izquierda */
}
.btn-hab:hover:not(:disabled) { border-color: #888; background: #f5f5f5; } /* resalta la habilidad al pasar el cursor */
.btn-hab:disabled { opacity: 0.4; cursor: not-allowed; } /* atenúa habilidad en cooldown */
.hab-nombre { font-weight: bold; font-size: 0.88rem; } /* nombre de la habilidad en negrita */
.btn-hab.tipo-fisico   .hab-nombre { color: #c06a2a; } /* nombre naranja para habilidades físicas */
.btn-hab.tipo-especial .hab-nombre { color: #5a4fcf; } /* nombre morado para habilidades especiales */
.btn-hab.tipo-estado   .hab-nombre { color: #555; } /* nombre gris para habilidades de estado */
.hab-meta   { display: flex; align-items: center; gap: 6px; } /* fila con tipo y potencia de la habilidad */
.hab-tipo   { font-size: 0.6rem; font-weight: bold; padding: 1px 5px; border-radius: 6px; color: white; } /* etiqueta de tipo de habilidad con fondo de color */
.tipo-fisico   { background: #c06a2a; } /* fondo naranja para tipo físico */
.tipo-especial { background: #5a4fcf; } /* fondo morado para tipo especial */
.tipo-estado   { background: #777; } /* fondo gris para tipo estado */
.hab-pot { font-size: 0.65rem; color: #aaa; } /* potencia numérica en gris claro */
.cd-badge { position: absolute; top: 6px; right: 8px; font-size: 0.6rem; color: #e53935; font-weight: bold; } /* badge rojo de cooldown sobre el botón de habilidad */

.relevo-obligatorio { border: 2px solid #c62828; border-radius: 10px; padding: 10px; } /* panel de relevo forzado con borde rojo de urgencia */
.relevo-titulo { font-size: 0.85rem; font-weight: bold; color: #c62828; margin-bottom: 8px; } /* aviso rojo de relevo forzado */
.relevo-grid { display: flex; gap: 8px; flex-wrap: wrap; } /* grilla de opciones de Pokémon para el relevo */
.relevo-card {
  display: flex; align-items: center; gap: 7px; /* punto de color, nombre y HP alineados */
  border: 2px solid #e0e0e0; border-radius: 8px; padding: 8px 12px; /* tarjeta del Pokémon disponible para relevar */
  cursor: pointer; transition: border-color 0.15s, background 0.15s; flex: 1; min-width: 120px; /* interactivo y expansible con mínimo ancho */
}
.relevo-card:hover { border-color: #888; background: #f5f5f5; } /* resalta el Pokémon de relevo al pasar el cursor */
.relevo-dot  { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; } /* punto de color del elemento del sustituto */
.relevo-nombre { font-weight: bold; font-size: 0.82rem; flex: 1; } /* nombre del Pokémon disponible para entrar */
.relevo-hp { font-size: 0.7rem; color: #888; } /* HP restante del Pokémon de relevo */

/* ── Resultado ── */
.resultado-combate { display: flex; flex-direction: column; align-items: center; gap: 14px; padding: 24px 0 8px; } /* pantalla final centrada de victoria o derrota */
.resultado-texto { font-size: 1.8rem; font-weight: bold; } /* texto grande del resultado del combate */
.resultado-victoria { color: #2e7d32; } /* color verde para mensaje de victoria */
.resultado-derrota  { color: #c62828; } /* color rojo para mensaje de derrota */

/* ── Abandonar ── */
.abandonar-wrap { display: flex; justify-content: center; margin-top: 20px; } /* centra el botón de abandonar al pie del combate */
.btn-abandonar {
  padding: 9px 28px; background: #c62828; color: white; /* botón rojo de abandonar con texto blanco */
  border: none; border-radius: 8px; cursor: pointer; /* sin borde, esquinas redondeadas, cursor puntero */
  font-size: 0.88rem; font-weight: bold; transition: background 0.2s; /* texto en negrita con transición de fondo */
}
.btn-abandonar:hover { background: #b71c1c; } /* rojo más oscuro al pasar el cursor */

/* ── Aviso ── */
.aviso { text-align: center; color: #aaa; font-size: 0.88rem; padding: 32px 0; } /* mensaje de aviso centrado y atenuado */

/* ── Botones generales ── */
.pie { display: flex; gap: 10px; align-items: center; } /* fila de botones al pie de sección */
.btn-volver {
  display: block; /* ocupa toda la línea como elemento bloque */
  margin: 0 auto 20px; /* centrado horizontalmente con margen inferior */
  padding: 8px 18px; /* relleno del botón de volver */
  background: white; /* fondo blanco del botón */
  border: 2px solid #ccc; /* borde gris claro */
  border-radius: 8px; /* esquinas redondeadas */
  cursor: pointer; /* indica que es clickeable */
  font-size: 0.88rem; /* tamaño de fuente pequeño */
  color: #555; /* color de texto gris oscuro */
  transition: border-color 0.2s, color 0.2s; /* transición suave de borde y color */
}
.btn-volver:hover { border-color: #888; color: #222; } /* oscurece borde y texto al pasar el cursor */
.btn-volver-resultado {
  padding: 8px 18px; background: white; border: 2px solid #ccc; border-radius: 8px; /* botón de volver en pantalla de resultado */
  cursor: pointer; font-size: 0.88rem; color: #555; transition: border-color 0.2s, color 0.2s; /* interactivo con transición de borde y texto */
}
.btn-volver-resultado:hover { border-color: #888; color: #222; } /* oscurece al pasar el cursor en resultado */
.btn-combate { padding: 9px 20px; background: #222; color: white; border: none; border-radius: 8px; font-size: 0.88rem; font-weight: bold; cursor: pointer; transition: background 0.2s; } /* botón principal negro para comenzar el duelo */
.btn-combate:hover:not(:disabled) { background: #444; } /* fondo más claro al pasar el cursor */
.btn-combate:disabled { background: #ccc; cursor: not-allowed; } /* deshabilitado cuando no hay combatientes listos */
.btn-reroll { padding: 8px 16px; background: white; border: 2px solid #888; border-radius: 8px; cursor: pointer; font-size: 0.85rem; color: #444; transition: border-color 0.2s; } /* botón de generar nuevo aleatorio */
.btn-reroll:hover { border-color: #444; } /* borde más oscuro al pasar el cursor */
</style>
