<script setup>
import { ref } from 'vue'
import TrainerCreate from './components/TrainerCreate.vue'
import StarterSelection from './components/StarterSelection.vue'
import ConfirmStarter from './components/ConfirmStarter.vue'
import MainHub from './components/MainHub.vue'
import { prepararPokemon } from './utils/calcularStats.js'
import { materiales } from './data/pokemonesExploracion.js'

const entrenador       = ref(null)
const compañero        = ref(null)
const juegoIniciado    = ref(false)
const equipo           = ref([])
const capturados           = ref([])
const ultimoDescanso       = ref(null)
const descansandoHasta     = ref(null)
const peDescanso           = ref(0)
const capturaCooldownHasta = ref(null)
const capturasDisponibles  = ref(3)
const inventario           = ref(Object.fromEntries(materiales.map(m => [m.id, 0])))

const INVENTARIO_MAX = 2000

function totalInventario() {
  return Object.values(inventario.value).reduce((s, n) => s + n, 0)
}

function agregarMaterial(material) {
  if (totalInventario() >= INVENTARIO_MAX) return
  inventario.value = { ...inventario.value, [material.id]: (inventario.value[material.id] ?? 0) + 1 }
}

function recibirEntrenador(datos) {
  entrenador.value = datos
}

function recibirCompañero(pokemon) {
  compañero.value = pokemon
}

function confirmarInicio() {
  const pokemonListo = prepararPokemon(compañero.value, entrenador.value.clase)
  equipo.value      = [pokemonListo]
  capturados.value  = [pokemonListo]
  juegoIniciado.value = true
}

function actualizarPokemon({ index, datos }) {
  const actualizado = { ...equipo.value[index], ...datos }
  equipo.value[index] = actualizado
  const i = capturados.value.findIndex(p => p.uid === actualizado.uid)
  if (i !== -1) capturados.value[i] = actualizado
}

function capturarPokemon(pokemon) {
  const pokemonListo = prepararPokemon(pokemon, entrenador.value.clase)
  capturados.value = [...capturados.value, pokemonListo]
  if (equipo.value.length < 6) {
    equipo.value = [...equipo.value, pokemonListo]
  }
}

function actualizarEquipo(nuevoEquipo) {
  equipo.value = nuevoEquipo
}

function actualizarCapturas({ cooldownHasta, capturasDisponibles: nuevas }) {
  capturaCooldownHasta.value = cooldownHasta
  capturasDisponibles.value  = nuevas
}

function iniciarDescanso({ minutos, pe }) {
  descansandoHasta.value = Date.now() + minutos * 60 * 1000
  peDescanso.value       = pe
}

function usarMaterial({ pokemonUid, materialId, cantidad = 1 }) {
  const stockActual = inventario.value[materialId] ?? 0
  if (stockActual < cantidad) return
  inventario.value = { ...inventario.value, [materialId]: stockActual - cantidad }

  const mat = materiales.find(m => m.id === materialId)
  const actualizar = p => {
    if (p.uid !== pokemonUid) return p
    if (mat.tipo === 'curativo' || mat.tipo === 'curativo-elemental') {
      return { ...p, hpActual: Math.min(p.stats.HP, (p.hpActual ?? p.stats.HP) + mat.hpRecuperado) }
    }
    if (mat.tipo === 'ascension' && (p.nivelAscension ?? 0) < 2) {
      return { ...p, nivelAscension: (p.nivelAscension ?? 0) + 1 }
    }
    return p
  }

  equipo.value    = equipo.value.map(actualizar)
  capturados.value = capturados.value.map(actualizar)
}

function completarDescanso() {
  equipo.value = equipo.value.map(p => ({
    ...p,
    pe: Math.min(100, p.pe + peDescanso.value)
  }))
  ultimoDescanso.value   = Date.now()
  descansandoHasta.value = null
  peDescanso.value       = 0
}
</script>

<template>
  <TrainerCreate
    v-if="entrenador === null"
    @entrenador-creado="recibirEntrenador"
  />
  <StarterSelection
    v-else-if="compañero === null"
    :entrenador="entrenador"
    @compañero-elegido="recibirCompañero"
  />
  <ConfirmStarter
    v-else-if="!juegoIniciado"
    :entrenador="entrenador"
    :compañero="compañero"
    @confirmar="confirmarInicio"
    @volver="compañero = null"
  />
  <MainHub
    v-else
    :entrenador="entrenador"
    :equipo="equipo"
    :capturados="capturados"
    :inventario="inventario"
    :ultimo-descanso="ultimoDescanso"
    :descansando-hasta="descansandoHasta"
    :pe-descanso="peDescanso"
    :captura-cooldown-hasta="capturaCooldownHasta"
    :capturas-disponibles="capturasDisponibles"
    @actualizar-pokemon="actualizarPokemon"
    @capturar-pokemon="capturarPokemon"
    @actualizar-equipo="actualizarEquipo"
    @actualizar-capturas="actualizarCapturas"
    @iniciar-descanso="iniciarDescanso"
    @completar-descanso="completarDescanso"
    @agregar-material="agregarMaterial"
    @usar-material="usarMaterial"
  />
</template>
