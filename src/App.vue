<script setup>
import { ref } from 'vue'
import TrainerCreate from './components/TrainerCreate.vue'
import StarterSelection from './components/StarterSelection.vue'
import ConfirmStarter from './components/ConfirmStarter.vue'
import MainHub from './components/MainHub.vue'
import { prepararPokemon } from './utils/calcularStats.js'

const entrenador      = ref(null)
const compañero       = ref(null)
const juegoIniciado   = ref(false)
const equipo          = ref([])
const ultimoDescanso  = ref(null) // timestamp de cuando terminó el último descanso
const descansandoHasta = ref(null)
const peDescanso      = ref(0)

function recibirEntrenador(datos) {
  entrenador.value = datos
}

function recibirCompañero(pokemon) {
  compañero.value = pokemon
}

function confirmarInicio() {
  const pokemonListo = prepararPokemon(compañero.value, entrenador.value.clase)
  equipo.value = [pokemonListo]
  juegoIniciado.value = true
}

function actualizarPokemon({ index, datos }) {
  equipo.value[index] = { ...equipo.value[index], ...datos }
}

function iniciarDescanso({ minutos, pe }) {
  descansandoHasta.value = Date.now() + minutos * 60 * 1000
  peDescanso.value       = pe
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
    :ultimo-descanso="ultimoDescanso"
    :descansando-hasta="descansandoHasta"
    :pe-descanso="peDescanso"
    @actualizar-pokemon="actualizarPokemon"
    @iniciar-descanso="iniciarDescanso"
    @completar-descanso="completarDescanso"
  />
</template>
