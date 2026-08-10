<script setup>
import { ref, computed } from 'vue'
import { rarezas } from '../data/pokemonesExploracion.js'

const props = defineProps({
  equipo:     Array,
  capturados: Array,
})

const emit = defineEmits(['actualizar-equipo', 'volver'])

const POR_PAGINA = 20
const paginaCap  = ref(1)

const paginasCap = computed(() => Math.max(1, Math.ceil(props.capturados.length / POR_PAGINA)))

const capturadosPagina = computed(() => {
  const inicio = (paginaCap.value - 1) * POR_PAGINA
  return props.capturados.slice(inicio, inicio + POR_PAGINA)
})

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
    <button class="btn-volver" @click="emit('volver')">← Volver</button>

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
            v-for="pokemon in capturadosPagina"
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

        <!-- Paginación capturados -->
        <div v-if="paginasCap > 1" class="paginacion-cap">
          <button class="btn-pagina" :disabled="paginaCap <= 1" @click="paginaCap--">← Anterior</button>
          <span class="pagina-info">{{ paginaCap }} / {{ paginasCap }}</span>
          <button class="btn-pagina" :disabled="paginaCap >= paginasCap" @click="paginaCap++">Siguiente →</button>
        </div>

      </div>

    </div>


  </div>
</template>

<style scoped>
.team-view {
  padding: 28px 32px; /* relleno interior del contenedor principal */
  font-family: sans-serif; /* fuente sin serif para toda la vista */
}

h2 {
  font-size: 1.4rem; /* tamaño del título principal de la sección */
  margin-bottom: 4px; /* separación mínima bajo el título */
}

.subtitulo {
  color: #666; /* color gris del texto descriptivo */
  font-size: 0.9rem; /* tamaño pequeño del subtítulo */
  margin-bottom: 20px; /* espacio bajo el subtítulo antes del contenido */
}

.columnas {
  margin-bottom: 24px; /* separación inferior del bloque de columnas */
}

.col-titulo {
  font-size: 0.9rem; /* tamaño del título de la columna */
  font-weight: bold; /* negrita para el título de la columna */
  color: #333; /* color oscuro del título de la columna */
  margin-bottom: 10px; /* espacio bajo el título de la columna */
  display: flex; /* alinea título y contador en fila */
  align-items: center; /* centra verticalmente el título y contador */
  gap: 8px; /* separación entre el título y el contador */
}

.contador {
  font-size: 0.78rem; /* tamaño pequeño del badge contador */
  background: #f0f0f0; /* fondo gris claro del contador */
  color: #666; /* color gris del número del contador */
  padding: 2px 8px; /* relleno interno del badge contador */
  border-radius: 20px; /* forma de píldora para el badge */
  font-weight: normal; /* peso normal para el número del contador */
}

/* Capturados */
.sin-capturados {
  color: #aaa; /* color gris claro del mensaje vacío */
  font-size: 0.88rem; /* tamaño reducido del aviso sin capturas */
  padding: 24px; /* relleno del área de mensaje vacío */
  text-align: center; /* centra el texto de estado vacío */
}

.capturados-grid {
  display: grid; /* activa layout de grilla para las tarjetas */
  grid-template-columns: 1fr 1fr; /* dos columnas iguales para las tarjetas */
  gap: 12px; /* separación entre tarjetas capturadas */
}

.cap-card {
  border: 2px solid #ccc; /* borde gris de la tarjeta de capturado */
  border-radius: 10px; /* esquinas redondeadas de la tarjeta */
  overflow: hidden; /* oculta contenido que desborde la tarjeta */
}

.cap-header {
  display: flex; /* alinea info y badges en fila */
  justify-content: space-between; /* separa info y badges en extremos */
  align-items: flex-start; /* alinea contenido al inicio verticalmente */
  padding: 10px 12px; /* relleno interior del encabezado de tarjeta */
  color: white; /* texto blanco en el encabezado coloreado */
  gap: 6px; /* separación entre info y badges del header */
}

.cap-info {
  display: flex; /* apila nombre y elemento en columna */
  flex-direction: column; /* disposición vertical de nombre y elemento */
  gap: 1px; /* mínima separación entre nombre y elemento */
  min-width: 0; /* permite que el texto se recorte si es necesario */
}

.cap-nombre { font-weight: bold; /* negrita del nombre del pokémon */ font-size: 0.9rem; /* tamaño del nombre en la tarjeta */ }
.cap-elemento { font-size: 0.75rem; /* tamaño pequeño del tipo de elemento */ opacity: 0.85; /* leve transparencia del tipo de elemento */ }

.cap-badges {
  display: flex; /* apila los badges de nivel y rareza */
  flex-direction: column; /* badges en columna vertical */
  align-items: flex-end; /* alinea los badges a la derecha */
  gap: 4px; /* separación entre los badges */
  flex-shrink: 0; /* evita que los badges se compriman */
}

.nivel-badge {
  font-size: 0.68rem; /* tamaño pequeño del badge de nivel */
  font-weight: bold; /* negrita en el texto del nivel */
  padding: 3px 7px; /* relleno interno del badge de nivel */
  border-radius: 20px; /* forma redondeada del badge de nivel */
  background: rgba(0,0,0,0.25); /* fondo oscuro semitransparente del nivel */
  color: white; /* texto blanco sobre el fondo del nivel */
  white-space: nowrap; /* evita el salto de línea en el nivel */
}

.rareza-badge {
  font-size: 0.68rem; /* tamaño pequeño del badge de rareza */
  font-weight: bold; /* negrita en el texto de rareza */
  padding: 3px 7px; /* relleno interno del badge de rareza */
  border-radius: 20px; /* forma redondeada del badge de rareza */
  color: white; /* texto blanco sobre el color de rareza */
  white-space: nowrap; /* evita el salto de línea en la rareza */
}

.cap-stats {
  display: flex; /* apila las filas de estadísticas */
  flex-direction: column; /* estadísticas en disposición vertical */
  gap: 3px; /* separación mínima entre filas de stats */
  padding: 8px 10px; /* relleno del área de estadísticas */
}

.stat-fila {
  display: flex; /* nombre y valor de stat en fila */
  justify-content: space-between; /* separa nombre y valor del stat */
  font-size: 0.78rem; /* tamaño pequeño de las estadísticas */
  padding: 2px 5px; /* relleno interno de cada fila de stat */
  background: #f9f9f9; /* fondo gris claro de cada fila de stat */
  border-radius: 4px; /* esquinas suavizadas de la fila de stat */
}

.stat-nombre { color: #444; /* color oscuro del nombre de la estadística */ }
.stat-valor  { font-weight: bold; /* negrita para el valor de la estadística */ color: #222; /* color muy oscuro del valor de la estadística */ }

.cap-botones {
  display: flex; /* apila los botones de acción verticalmente */
  flex-direction: column; /* botones en columna dentro de la tarjeta */
  border-top: 1px solid #eee; /* línea separadora sobre los botones */
}

.btn-agregar,
.btn-eliminar {
  padding: 7px; /* relleno uniforme de los botones de acción */
  font-size: 0.78rem; /* tamaño pequeño del texto de los botones */
  font-weight: bold; /* negrita en el texto de los botones */
  border: none; /* elimina el borde predeterminado del botón */
  cursor: pointer; /* cursor de mano al pasar sobre el botón */
  transition: filter 0.2s; /* transición suave del brillo al hover */
  color: white; /* texto blanco en los botones de acción */
}

.agregado-aviso {
  text-align: center; /* texto centrado en el aviso de agregado */
  padding: 7px; /* relleno del aviso de pokémon en equipo */
  background: #edfff3; /* fondo verde claro del aviso de agregado */
  border-bottom: 1px solid #eee; /* línea inferior gris (sobreescrita después) */
  color: #1a9e3f; /* color verde del texto de confirmación */
  font-weight: bold; /* negrita en el aviso de agregado */
  font-size: 0.78rem; /* tamaño del texto del aviso de agregado */
  border-bottom: 2px solid #2dc653; /* línea inferior verde del aviso (final) */
}

.btn-agregar {
  background: #ccc; /* fondo gris cuando el equipo está lleno */
  border-bottom: 1px solid #eee; /* línea separadora bajo el botón agregar */
}

.btn-eliminar {
  background: #e63946; /* fondo rojo del botón eliminar del equipo */
}

.btn-agregar:not(:disabled):hover,
.btn-eliminar:not(:disabled):hover { filter: brightness(0.9); /* oscurece el botón al pasar el cursor */ }

.btn-agregar:disabled,
.btn-eliminar:disabled {
  cursor: not-allowed; /* cursor de prohibición cuando está desactivado */
  opacity: 0.35; /* alta transparencia cuando el botón está desactivado */
  background: #ddd; /* fondo gris claro del botón desactivado */
  color: #999; /* texto gris del botón desactivado */
}

/* Paginación capturados */
.paginacion-cap {
  display: flex; /* botones de paginación en fila */
  align-items: center; /* centra verticalmente los controles de página */
  justify-content: center; /* centra horizontalmente la paginación */
  gap: 12px; /* separación entre los controles de paginación */
  margin-top: 14px; /* separación superior de la barra de paginación */
}

.btn-pagina {
  padding: 6px 14px; /* relleno del botón de página anterior/siguiente */
  background: white; /* fondo blanco del botón de paginación */
  border: 1px solid #ccc; /* borde gris del botón de paginación */
  border-radius: 8px; /* esquinas redondeadas del botón de página */
  font-size: 0.82rem; /* tamaño del texto del botón de página */
  cursor: pointer; /* cursor de mano en el botón de página */
  transition: border-color 0.2s; /* transición suave del borde al hover */
}

.btn-pagina:hover:not(:disabled) {
  border-color: #888; /* borde más oscuro al pasar el cursor */
}

.btn-pagina:disabled {
  opacity: 0.35; /* alta transparencia en página desactivada */
  cursor: default; /* cursor normal en botón desactivado */
}

.pagina-info {
  font-size: 0.82rem; /* tamaño del indicador de página actual */
  color: #888; /* color gris del indicador de página */
}

/* Volver */
.btn-volver {
  display: block; /* el botón ocupa su propia línea */
  margin: 0 auto 20px; /* centra el botón y añade espacio inferior */
  padding: 8px 18px; /* relleno interno del botón volver */
  background: white; /* fondo blanco del botón volver */
  border: 2px solid #ccc; /* borde gris del botón volver */
  border-radius: 8px; /* esquinas redondeadas del botón volver */
  cursor: pointer; /* cursor de mano en el botón volver */
  font-size: 0.88rem; /* tamaño del texto del botón volver */
  color: #555; /* color gris del texto del botón volver */
  transition: border-color 0.2s, color 0.2s; /* transición suave de borde y color al hover */
}

.btn-volver:hover { border-color: #888; /* borde más oscuro al pasar el cursor */ color: #222; /* texto más oscuro al pasar el cursor */ }
</style>
