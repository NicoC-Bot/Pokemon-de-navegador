<script setup>
import { ref } from 'vue'
import StartScreen from './components/StartScreen.vue'
import TrainerCreate from './components/TrainerCreate.vue'
import StarterSelection from './components/StarterSelection.vue'
import ConfirmStarter from './components/ConfirmStarter.vue'
import MainHub from './components/MainHub.vue'
import { prepararPokemon } from './utils/calcularStats.js'
import { materiales, pokemonesWild } from './data/pokemonesExploracion.js'
import { clases } from './data/clases.js'
import { obtenerPartidaCompleta, guardarPartida as apiGuardarPartida, actualizarPartida as apiActualizarPartida } from './api/partidas.js'

const enStartScreen    = ref(true)
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

function actualizarNombre(nuevoNombre) {
  entrenador.value = { ...entrenador.value, nombre: nuevoNombre }
}

async function cargarPartida(partida) {
  try {
    const datos = await obtenerPartidaCompleta(partida.id)

    const mapPokemon = p => {
      const base = pokemonesWild.find(pw => pw.nombre === p.nombre) ?? {}
      return {
        uid:            p.uid,
        nombre:         p.nombre,
        elemento:       p.elemento,
        colorElemento:  base.colorElemento ?? '#888888',
        descripcion:    base.descripcion   ?? '',
        habilidades:    base.habilidades   ?? [],
        rareza:         p.rareza,
        nivel:          p.nivel,
        nivelAscension: p.nivel_ascension,
        hpActual:       p.hp_actual,
        pe:             p.pe,
        stats:          p.stats,
        statsBase:      base.stats         ?? p.stats,
        xp:             0,
        id:             base.id            ?? '',
      }
    }

    const todosCapturados = datos.pokemon.map(mapPokemon)
    const equipoOrdenado  = datos.pokemon
      .filter(p => p.en_equipo)
      .sort((a, b) => a.slot_equipo - b.slot_equipo)
      .map(mapPokemon)

    const inventarioRestaurado = Object.fromEntries(materiales.map(m => [m.id, 0]))
    for (const inv of datos.inventario) {
      inventarioRestaurado[inv.material_id] = inv.cantidad
    }

    entrenador.value          = { nombre: datos.estado.entrenador_nombre, clase: clases.find(c => c.id === datos.estado.clase_id) }
    compañero.value           = equipoOrdenado[0] ?? null
    equipo.value              = equipoOrdenado
    capturados.value          = todosCapturados
    inventario.value          = inventarioRestaurado
    ultimoDescanso.value      = datos.estado.ultimo_descanso
    descansandoHasta.value    = datos.estado.descansando_hasta
    peDescanso.value          = datos.estado.pe_descanso
    capturaCooldownHasta.value= datos.estado.captura_cooldown_hasta
    capturasDisponibles.value = datos.estado.capturas_disponibles
    juegoIniciado.value       = true
    enStartScreen.value       = false
  } catch (e) {
    console.error('Error al cargar partida:', e)
  }
}

async function guardarPartida(datos) {
  try {
    const pokemonArray = capturados.value.map(p => {
      const slotEquipo = equipo.value.findIndex(e => e.uid === p.uid)
      return {
        uid:             p.uid,
        nombre:          p.nombre,
        elemento:        p.elemento,
        rareza:          p.rareza,
        nivel:           p.nivel ?? 1,
        nivel_ascension: p.nivelAscension ?? 0,
        hp_actual:       p.hpActual ?? p.stats.HP,
        pe:              p.pe ?? 100,
        stats:           p.stats,
        en_equipo:       slotEquipo !== -1,
        slot_equipo:     slotEquipo !== -1 ? slotEquipo : null,
      }
    })

    const inventarioArray = Object.entries(inventario.value)
      .filter(([, cantidad]) => cantidad > 0)
      .map(([material_id, cantidad]) => ({ material_id, cantidad }))

    const estado = {
      entrenador_nombre:      entrenador.value.nombre,
      clase_id:               entrenador.value.clase.id,
      ultimo_descanso:        ultimoDescanso.value,
      descansando_hasta:      descansandoHasta.value,
      pe_descanso:            peDescanso.value,
      captura_cooldown_hasta: capturaCooldownHasta.value,
      capturas_disponibles:   capturasDisponibles.value,
    }

    if (datos.id) {
      await apiActualizarPartida(datos.id, datos.nombre, estado, pokemonArray, inventarioArray)
    } else {
      await apiGuardarPartida(datos.nombre, estado, pokemonArray, inventarioArray)
    }
  } catch (e) {
    console.error('Error al guardar partida:', e)
  }
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
  <StartScreen
    v-if="enStartScreen"
    @nueva-partida="enStartScreen = false"
    @cargar-partida="cargarPartida"
  />
  <TrainerCreate
    v-else-if="entrenador === null"
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
    @actualizar-nombre="actualizarNombre"
    @guardar-partida="guardarPartida"
  />
</template>
