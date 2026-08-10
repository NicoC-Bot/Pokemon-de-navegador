<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { rarezas, materiales, pokemonesWild } from '../data/pokemonesExploracion.js'

const props = defineProps({
  capturaCooldownHasta: Number,
  capturasDisponibles:  Number,
})

const emit = defineEmits(['volver', 'capturar', 'actualizar-capturas', 'agregar-material'])

const MAX_CAPTURAS = 3
const COOLDOWN_MS  = 3 * 60 * 60 * 1000

const resultado      = ref(null)
const capturado      = ref(false)
const recogido       = ref(false)
const tiempoRestante = ref(
  props.capturaCooldownHasta ? Math.max(0, props.capturaCooldownHasta - Date.now()) : 0
)
const explorarKey    = ref(0)

let intervalo = null

onMounted(() => {
  if (!props.capturaCooldownHasta) return
  if (props.capturaCooldownHasta > Date.now()) {
    iniciarContador()
  } else {
    // El timer ya venció mientras el componente no estaba activo — resetear de inmediato
    emit('actualizar-capturas', { cooldownHasta: null, capturasDisponibles: MAX_CAPTURAS })
  }
})

onUnmounted(() => { if (intervalo) clearInterval(intervalo) })

function obtenerRareza(id) {
  return rarezas.find(r => r.id === id)
}

function enCooldown() {
  return props.capturaCooldownHasta !== null && tiempoRestante.value > 0
}

function iniciarContador() {
  if (intervalo) clearInterval(intervalo)
  intervalo = setInterval(() => {
    tiempoRestante.value = Math.max(0, tiempoRestante.value - 1000)
    if (tiempoRestante.value <= 0) {
      clearInterval(intervalo)
      emit('actualizar-capturas', { cooldownHasta: null, capturasDisponibles: MAX_CAPTURAS })
    }
  }, 1000)
}

function capturar() {
  if (props.capturasDisponibles <= 0 || enCooldown()) return
  emit('capturar', resultado.value.pokemon)
  capturado.value = true
  const nuevas = props.capturasDisponibles - 1
  if (nuevas <= 0) {
    const nuevoCooldown = Date.now() + COOLDOWN_MS
    emit('actualizar-capturas', { cooldownHasta: nuevoCooldown, capturasDisponibles: 0 })
    tiempoRestante.value = COOLDOWN_MS
    setTimeout(() => iniciarContador(), 50)
  } else {
    emit('actualizar-capturas', { cooldownHasta: null, capturasDisponibles: nuevas })
  }
}

function recoger() {
  emit('agregar-material', resultado.value.material)
  recogido.value = true
}

function explorar() {
  capturado.value = false
  recogido.value  = false
  explorarKey.value++

  const rng          = Math.floor(Math.random() * 100) + 1
  const calificados  = pokemonesWild.filter(p => rng >= obtenerRareza(p.rareza).umbral)

  if (calificados.length === 0) {
    const rngPool = Math.random() * 100
    let pool
    if (rngPool < 25) {
      pool = materiales.filter(m => m.tipo === 'curativo-elemental')
    } else if (rngPool < 30) {
      pool = materiales.filter(m => m.tipo === 'ascension')
    } else {
      pool = materiales.filter(m => m.tipo === 'curativo' || m.tipo === 'general')
    }
    const material = pool[Math.floor(Math.random() * pool.length)]
    resultado.value = { tipo: 'material', material }
    return
  }

  const maxUmbral  = Math.max(...calificados.map(p => obtenerRareza(p.rareza).umbral))
  const mejores    = calificados.filter(p => obtenerRareza(p.rareza).umbral === maxUmbral)
  const encontrado = mejores[Math.floor(Math.random() * mejores.length)]
  resultado.value  = { tipo: 'pokemon', pokemon: encontrado }
}

function formatearTiempo(ms) {
  const s = Math.ceil(ms / 1000)
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  const sec = s % 60
  if (h > 0) return h + 'h ' + m + 'm ' + sec + 's'
  if (m > 0) return m + 'm ' + sec + 's'
  return sec + 's'
}

</script>

<template>
  <div class="explore-view">
    <button class="btn-volver" @click="emit('volver')">← Volver</button>

    <!-- Header -->
    <div class="header">
      <h2>Explorar</h2>
      <p class="subtitulo">Busca Pokémon salvajes o recoge materiales del entorno.</p>

      <div class="capturas-info">
        <span v-if="enCooldown()" class="capturas-agotadas">
          ⏳ Capturas disponibles en: <strong>{{ formatearTiempo(tiempoRestante) }}</strong>
        </span>
        <span v-else class="capturas-disponibles">
          Capturas disponibles:
          <span v-for="i in MAX_CAPTURAS" :key="i" class="bolita" :class="{ usada: i > capturasDisponibles }">●</span>
        </span>
      </div>
    </div>

    <!-- Zona de resultado (altura fija) -->
    <div class="zona-resultado">
      <Transition name="fade" mode="out-in">

        <!-- Sin resultado -->
        <div v-if="resultado === null" :key="'inicial'" class="estado-inicial">
          <span class="zona-icono">🌲</span>
          <p>La zona está tranquila. ¿Te adentras?</p>
        </div>

        <!-- Encuentro Pokémon -->
        <div v-else-if="resultado.tipo === 'pokemon'" :key="'pokemon-' + explorarKey" class="encuentro">
          <p class="encuentro-titulo">¡Apareció un Pokémon salvaje!</p>
          <div class="pokemon-card" :style="{ borderColor: resultado.pokemon.colorElemento }">
            <div class="pokemon-header" :style="{ backgroundColor: resultado.pokemon.colorElemento }">
              <div class="pokemon-info">
                <span class="pokemon-nombre">{{ resultado.pokemon.nombre }}</span>
                <span class="pokemon-elemento">{{ resultado.pokemon.elemento }}</span>
              </div>
              <span class="rareza-badge" :style="{ backgroundColor: obtenerRareza(resultado.pokemon.rareza).color }">
                {{ obtenerRareza(resultado.pokemon.rareza).label }}
              </span>
            </div>
            <p class="pokemon-desc">{{ resultado.pokemon.descripcion }}</p>
            <div class="pokemon-stats">
              <div v-for="(valor, nombre) in resultado.pokemon.stats" class="stat-fila">
                <span class="stat-nombre">{{ nombre }}</span>
                <span class="stat-valor">{{ valor }}</span>
              </div>
            </div>

            <div class="captura-accion">
              <button
                v-if="!capturado"
                class="btn-capturar"
                :disabled="capturasDisponibles <= 0 || enCooldown()"
                :style="capturasDisponibles > 0 && !enCooldown() ? { backgroundColor: resultado.pokemon.colorElemento } : {}"
                @click="capturar"
              >
                {{ enCooldown() ? 'Sin capturas' : '¡Capturar!' }}
              </button>
              <div v-else class="capturado-aviso">✓ ¡{{ resultado.pokemon.nombre }} fue capturado!</div>
            </div>
          </div>
        </div>

        <!-- Material encontrado -->
        <div v-else :key="'material-' + explorarKey" class="material-encontrado">
          <p class="encuentro-titulo">No encontraste ningún Pokémon...</p>
          <div class="material-card">
            <span class="material-icono">{{ resultado.material.icono }}</span>
            <div class="material-info">
              <span class="material-nombre">{{ resultado.material.nombre }}</span>
              <span class="material-desc">{{ resultado.material.descripcion }}</span>
            </div>
          </div>
          <div class="recoger-accion">
            <button v-if="!recogido" class="btn-recoger" @click="recoger">Recoger</button>
            <div v-else class="recogido-aviso">✓ ¡{{ resultado.material.nombre }} recogido!</div>
          </div>
        </div>

      </Transition>
    </div>

    <!-- Botones fijos -->
    <div class="botones">
      <button class="btn-explorar" @click="explorar">
        {{ resultado === null ? 'Explorar zona' : 'Explorar de nuevo' }}
      </button>
    </div>

  </div>
</template>

<style scoped>
.explore-view {
  padding: 20px 28px; /* relleno interno del contenedor principal */
  font-family: sans-serif; /* fuente genérica del componente */
  max-width: 480px; /* ancho máximo de la vista de exploración */
  display: flex; /* organiza las secciones en columna */
  flex-direction: column; /* dirección vertical del layout */
  gap: 0; /* sin separación automática entre secciones */
}

/* Header */
.header {
  margin-bottom: 14px; /* separación inferior del encabezado */
}

h2 {
  font-size: 1.4rem; /* tamaño del título Explorar */
  margin-bottom: 2px; /* separación mínima entre título y subtítulo */
}

.subtitulo {
  color: #666; /* gris para el texto descriptivo del encabezado */
  font-size: 0.88rem; /* texto pequeño del subtítulo */
  margin-bottom: 8px; /* separación inferior antes de la info de capturas */
}

.capturas-info {
  font-size: 0.82rem; /* texto pequeño del indicador de capturas */
  color: #555; /* gris medio para el contador de capturas */
}

.capturas-disponibles {
  display: flex; /* alinea el texto y las bolitas en fila */
  align-items: center; /* centra verticalmente el texto y los iconos */
  gap: 6px; /* separación entre el texto y las bolitas */
}

.bolita {
  font-size: 1rem; /* tamaño del símbolo de bola de captura */
  color: #2dc653; /* verde para captura disponible */
  transition: color 0.2s; /* transición suave al cambiar a estado usado */
}

.bolita.usada { color: #ddd; } /* gris para bola de captura ya usada */

.capturas-agotadas {
  color: #e63946; /* rojo para el aviso de capturas agotadas */
}

/* Zona resultado - altura fija */
.zona-resultado {
  min-height: 220px; /* altura mínima para evitar saltos de layout */
  display: flex; /* centra el contenido del resultado */
  align-items: center; /* centra verticalmente el resultado */
  justify-content: center; /* centra horizontalmente el resultado */
  margin-bottom: 14px; /* separación inferior antes de los botones */
}

.zona-resultado > * {
  width: 100%; /* hijo ocupa todo el ancho de la zona */
}

/* Estado inicial */
.estado-inicial {
  text-align: center; /* centra el icono y el texto de bienvenida */
  color: #aaa; /* gris claro para el estado vacío inicial */
}

.zona-icono {
  font-size: 2.4rem; /* tamaño grande del icono del entorno */
  display: block; /* bloque para aplicar margen inferior */
  margin-bottom: 8px; /* separación entre icono y texto descriptivo */
}

/* Encuentro */
.encuentro-titulo {
  font-size: 0.9rem; /* tamaño del mensaje de encuentro */
  font-weight: bold; /* negrita para el anuncio del encuentro */
  margin-bottom: 8px; /* separación inferior antes de la tarjeta */
  color: #333; /* color oscuro del título de encuentro */
}

/* Card Pokémon */
.pokemon-card {
  border: 2px solid #ccc; /* borde de color dinámico según el elemento */
  border-radius: 14px; /* esquinas redondeadas de la tarjeta */
  overflow: hidden; /* recorta el header coloreado a los bordes */
}

.pokemon-header {
  display: flex; /* alinea info y rareza en fila */
  justify-content: space-between; /* info a la izquierda, rareza a la derecha */
  align-items: center; /* centra verticalmente los elementos */
  padding: 14px 16px; /* relleno del encabezado coloreado */
  color: white; /* texto blanco sobre fondo de color del elemento */
}

.pokemon-info {
  display: flex; /* apila nombre y elemento en columna */
  flex-direction: column; /* dirección vertical de la información */
  gap: 2px; /* separación mínima entre nombre y tipo de elemento */
}

.pokemon-nombre { font-size: 1.2rem; font-weight: bold; } /* nombre grande en negrita */
.pokemon-elemento { font-size: 0.82rem; opacity: 0.9; } /* tipo de elemento semitransparente */

.rareza-badge {
  font-size: 0.72rem; /* texto muy pequeño de la etiqueta de rareza */
  font-weight: bold; /* negrita para la etiqueta de rareza */
  padding: 4px 10px; /* relleno interno del badge */
  border-radius: 20px; /* forma de pastilla del badge */
  color: white; /* texto blanco sobre color de rareza */
  white-space: nowrap; /* evita que el texto del badge salte de línea */
}

.pokemon-desc {
  font-size: 0.82rem; /* texto pequeño de la descripción del Pokémon */
  color: #555; /* gris para el texto descriptivo */
  padding: 10px 14px; /* relleno lateral de la descripción */
  margin: 0; /* elimina margen por defecto del párrafo */
}

.pokemon-stats {
  display: flex; /* apila las filas de estadísticas */
  flex-direction: column; /* dirección vertical de las stats */
  gap: 4px; /* separación entre filas de estadística */
  padding: 0 14px 14px; /* relleno lateral e inferior de las stats */
}

.stat-fila {
  display: flex; /* alinea nombre y valor del stat en fila */
  justify-content: space-between; /* nombre a la izquierda, valor a la derecha */
  font-size: 0.82rem; /* texto pequeño de las estadísticas */
  padding: 3px 6px; /* relleno interno de cada fila de stat */
  background: #f9f9f9; /* fondo muy claro de cada fila de stat */
  border-radius: 4px; /* esquinas ligeramente redondeadas */
}

.stat-nombre { color: #444; } /* color gris oscuro del nombre del stat */
.stat-valor  { font-weight: bold; color: #222; } /* valor en negrita con color oscuro */

.captura-accion { padding: 10px 14px 14px; } /* relleno del área del botón capturar */

.btn-capturar {
  width: 100%; /* botón ocupa todo el ancho disponible */
  padding: 10px; /* relleno interno del botón */
  color: white; /* texto blanco del botón */
  border: none; /* sin borde visible */
  border-radius: 8px; /* esquinas redondeadas del botón */
  font-size: 0.9rem; /* tamaño del texto del botón */
  font-weight: bold; /* negrita para enfatizar la acción */
  cursor: pointer; /* cursor de mano al interactuar */
  background: #ccc; /* fondo gris por defecto sin color de elemento */
  transition: filter 0.2s; /* transición suave de brillo al hover */
}

.btn-capturar:not(:disabled):hover { filter: brightness(0.9); } /* oscurece al hover si está activo */
.btn-capturar:disabled { cursor: not-allowed; opacity: 0.5; } /* semi-opaco sin capturas disponibles */

.capturado-aviso {
  text-align: center; /* centra el mensaje de captura exitosa */
  padding: 10px; /* relleno del aviso de éxito */
  background: #edfff3; /* fondo verde claro de confirmación */
  border: 2px solid #2dc653; /* borde verde del aviso de captura */
  border-radius: 8px; /* esquinas redondeadas del aviso */
  color: #1a9e3f; /* texto verde oscuro del mensaje */
  font-weight: bold; /* negrita del texto confirmatorio */
  font-size: 0.9rem; /* tamaño del texto del aviso */
}

/* Material */
.material-card {
  display: flex; /* alinea icono e información en fila */
  align-items: center; /* centra verticalmente icono e info */
  gap: 14px; /* separación entre el icono y la descripción */
  padding: 16px 20px; /* relleno interno de la tarjeta de material */
  border: 2px solid #e0e0e0; /* borde gris de la tarjeta */
  border-radius: 14px; /* esquinas redondeadas de la tarjeta */
}

.material-icono { font-size: 2rem; flex-shrink: 0; } /* icono grande sin reducirse */

.material-info { display: flex; flex-direction: column; gap: 4px; } /* info apilada en columna */
.material-nombre { font-weight: bold; font-size: 1rem; color: #222; } /* nombre en negrita y oscuro */
.material-desc { font-size: 0.85rem; color: #666; } /* descripción pequeña y gris */

.recoger-accion { margin-top: 10px; } /* separación superior del botón recoger */

.btn-recoger {
  width: 100%; /* botón ocupa todo el ancho disponible */
  padding: 10px; /* relleno interno del botón */
  background: #2d8c4e; /* verde para acción de recoger material */
  color: white; /* texto blanco del botón */
  border: none; /* sin borde visible */
  border-radius: 8px; /* esquinas redondeadas del botón */
  font-size: 0.9rem; /* tamaño del texto del botón */
  font-weight: bold; /* negrita para enfatizar la acción */
  cursor: pointer; /* cursor de mano al interactuar */
  transition: filter 0.2s; /* transición suave de brillo al hover */
}

.btn-recoger:hover { filter: brightness(0.9); } /* oscurece ligeramente al pasar el cursor */

.recogido-aviso {
  text-align: center; /* centra el mensaje de material recogido */
  padding: 10px; /* relleno del aviso de recogida exitosa */
  background: #edfff3; /* fondo verde claro de éxito */
  border: 2px solid #2dc653; /* borde verde del aviso de recogida */
  border-radius: 8px; /* esquinas redondeadas del aviso */
  color: #1a9e3f; /* texto verde oscuro del mensaje */
  font-weight: bold; /* negrita del texto confirmatorio */
  font-size: 0.9rem; /* tamaño del texto del aviso */
}

/* Botones fijos */
.botones {
  display: flex; /* apila los botones en columna */
  flex-direction: column; /* dirección vertical del grupo de botones */
  gap: 8px; /* separación entre botones del grupo */
}

.btn-explorar {
  padding: 10px; /* relleno interno del botón explorar */
  background: #222; /* fondo oscuro del botón principal */
  color: white; /* texto blanco del botón */
  border: none; /* sin borde visible */
  border-radius: 10px; /* esquinas muy redondeadas del botón */
  font-size: 0.9rem; /* tamaño del texto del botón */
  font-weight: bold; /* negrita del botón de acción principal */
  cursor: pointer; /* cursor de mano al interactuar */
  transition: background 0.2s; /* animación del fondo al hover */
}

.btn-explorar:hover { background: #444; } /* fondo más claro al pasar el cursor */

.btn-volver {
  display: block; /* bloque para centrar con margen automático */
  margin: 0 auto 20px; /* centra y añade separación inferior */
  padding: 8px 18px; /* relleno interno del botón */
  background: white; /* fondo blanco del botón volver */
  border: 2px solid #ccc; /* borde gris claro */
  border-radius: 8px; /* esquinas redondeadas */
  cursor: pointer; /* cursor de mano al interactuar */
  font-size: 0.88rem; /* tamaño del texto ligeramente reducido */
  color: #555; /* color gris del texto */
  transition: border-color 0.2s, color 0.2s; /* animación suave de borde y color */
}

.btn-volver:hover { border-color: #888; color: #222; } /* oscurece borde y texto al hover */

/* Transición */
.fade-enter-active,
.fade-leave-active { transition: opacity 0.2s, transform 0.2s; } /* duración de la transición de entrada/salida */
.fade-enter-from,
.fade-leave-to { opacity: 0; transform: translateY(6px); } /* estado inicial y final del fade */
</style>
