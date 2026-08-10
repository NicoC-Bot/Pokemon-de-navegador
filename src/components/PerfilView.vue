<script setup>
import { ref, onMounted } from 'vue'
import { obtenerEstadisticas } from '../api/partidas.js'

const props = defineProps({
  entrenador: Object,
  capturados: Array,
  partidaId:  Number,
})

const emit = defineEmits(['volver', 'actualizar-nombre'])

const editando    = ref(false)
const nuevoNombre = ref('')
const stats       = ref(null)

onMounted(async () => {
  if (!props.partidaId) return
  try {
    stats.value = await obtenerEstadisticas(props.partidaId)
  } catch (e) {
    console.error('Error al cargar estadísticas:', e)
  }
})

function activarEdicion() {
  nuevoNombre.value = props.entrenador.nombre
  editando.value = true
}

function confirmarNombre() {
  if (nuevoNombre.value.trim() === '') return
  emit('actualizar-nombre', nuevoNombre.value.trim())
  editando.value = false
}
</script>

<template>
  <div class="perfil">

    <button class="btn-volver" @click="emit('volver')">← Volver</button>

    <div class="perfil-card" :style="{ borderColor: entrenador.clase.color }">

      <!-- Header -->
      <div class="perfil-header" :style="{ backgroundColor: entrenador.clase.color }">
        <div class="perfil-foto">🧢</div>
        <div class="perfil-info">
          <div class="nombre-wrap">
            <h2 v-if="!editando">{{ entrenador.nombre }}</h2>
            <input
              v-else
              v-model="nuevoNombre"
              class="input-nombre"
              @keyup.enter="confirmarNombre"
              @keyup.escape="editando = false"
              autofocus
            />
            <button v-if="!editando" class="btn-editar" @click="activarEdicion">✏️</button>
            <button v-else class="btn-confirmar" @click="confirmarNombre">✓</button>
          </div>
          <span class="perfil-clase">{{ entrenador.clase.label }}</span>
        </div>
      </div>

      <!-- Datos generales -->
      <div class="perfil-datos">
        <div class="dato-fila">
          <span class="dato-label">Elemento</span>
          <span class="dato-valor">{{ entrenador.clase.label }}</span>
        </div>
        <div class="dato-fila">
          <span class="dato-label">Compañeros</span>
          <span class="dato-valor">{{ capturados.length }}</span>
        </div>
      </div>

      <!-- Descripción de la clase -->
      <div class="perfil-descripcion">
        <p>{{ entrenador.clase.descripcion }}</p>
      </div>

      <!-- Bufos de la clase -->
      <div class="perfil-stats">
        <h3>Bonos de clase</h3>
        <div class="stats-grid">
          <div v-for="stat in entrenador.clase.stats" class="stat-fila">
            <span class="stat-nombre">{{ stat.nombre }}</span>
            <span
              class="stat-valor"
              :class="stat.valor > 0 ? 'positivo' : stat.valor < 0 ? 'negativo' : 'neutro'"
            >
              {{ stat.valor > 0 ? '+' + stat.valor : stat.valor === 0 ? '—' : stat.valor }}%
            </span>
          </div>
        </div>
      </div>

      <!-- Historial de batallas -->
      <div v-if="stats" class="perfil-batallas">
        <h3>Historial de batallas</h3>
        <div class="batallas-grid">
          <div class="batalla-dato">
            <span class="batalla-label">Total</span>
            <span class="batalla-valor">{{ stats.total_batallas }}</span>
          </div>
          <div class="batalla-dato">
            <span class="batalla-label">Victorias</span>
            <span class="batalla-valor positivo">{{ stats.victorias }}</span>
          </div>
          <div class="batalla-dato">
            <span class="batalla-label">Derrotas</span>
            <span class="batalla-valor negativo">{{ stats.derrotas }}</span>
          </div>
          <div class="batalla-dato">
            <span class="batalla-label">Huidas</span>
            <span class="batalla-valor neutro">{{ stats.huidas }}</span>
          </div>
          <div class="batalla-dato">
            <span class="batalla-label">Turnos prom.</span>
            <span class="batalla-valor">{{ stats.turnos_promedio ?? '—' }}</span>
          </div>
        </div>
      </div>

    </div>
  </div>
</template>

<style scoped>
.perfil {
  max-width: 600px; /* ancho máximo del contenedor de perfil */
  margin: 0 auto; /* centra horizontalmente el perfil */
  font-family: sans-serif; /* fuente sans-serif para la vista de perfil */
}

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

.perfil-card {
  border: 2px solid #ccc; /* borde de la tarjeta principal del perfil */
  border-radius: 16px; /* esquinas muy redondeadas de la tarjeta */
  overflow: hidden; /* oculta el contenido que desborde la tarjeta */
}

.perfil-header {
  display: flex; /* foto e info del entrenador en fila */
  align-items: center; /* centra verticalmente foto e info */
  gap: 20px; /* separación entre foto y datos del perfil */
  padding: 24px; /* relleno del encabezado del perfil */
  color: white; /* texto blanco sobre el color de clase */
}

.perfil-foto {
  font-size: 3.5rem; /* tamaño grande del emoji de foto de perfil */
  background: rgba(255,255,255,0.2); /* fondo blanco semitransparente del avatar */
  border-radius: 50%; /* forma circular del contenedor del avatar */
  width: 72px; /* ancho fijo del círculo del avatar */
  height: 72px; /* alto fijo del círculo del avatar */
  display: flex; /* centra el emoji dentro del círculo */
  align-items: center; /* centra verticalmente el emoji */
  justify-content: center; /* centra horizontalmente el emoji */
  flex-shrink: 0; /* evita que el avatar se comprima */
}

.perfil-info {
  position: relative; /* permite posicionar la clase en absoluto */
  display: flex; /* nombre y clase en disposición flexible */
  flex-direction: column; /* nombre y clase apilados verticalmente */
  justify-content: center; /* centra verticalmente el nombre */
}

.nombre-wrap {
  display: flex; /* nombre y botón de edición en fila */
  align-items: center; /* alinea verticalmente nombre y botón */
  gap: 8px; /* separación entre nombre y botón editar */
  height: 2.4rem; /* altura fija del área del nombre */
}

.perfil-info h2 {
  margin: 0; /* elimina el margen predeterminado del nombre */
  font-size: 1.8rem; /* tamaño grande del nombre del entrenador */
  line-height: 2.4rem; /* altura de línea alineada con el contenedor */
}

.input-nombre {
  font-size: 1.4rem; /* tamaño del texto en el campo de edición */
  font-weight: bold; /* negrita en el nombre editado */
  background: rgba(255,255,255,0.2); /* fondo semitransparente del campo de nombre */
  border: 2px solid rgba(255,255,255,0.6); /* borde blanco semitransparente del campo */
  border-radius: 8px; /* esquinas redondeadas del campo de nombre */
  color: white; /* texto blanco en el campo de nombre */
  padding: 0 8px; /* relleno horizontal del campo de nombre */
  outline: none; /* elimina el contorno de foco del campo */
  width: 180px; /* ancho fijo del campo de edición de nombre */
  height: 2.4rem; /* altura del campo alineada con el nombre */
  box-sizing: border-box; /* el padding no desborda el ancho fijo */
}

.perfil-clase {
  font-size: 0.95rem; /* tamaño del subtítulo de clase del entrenador */
  opacity: 0.9; /* leve transparencia del nombre de la clase */
  position: absolute; /* posiciona la clase bajo el nombre */
  top: 2.8rem; /* desplaza la clase debajo del área del nombre */
  left: 0; /* alinea la clase al borde izquierdo */
}

.btn-editar {
  background: none; /* botón sin fondo en el encabezado */
  border: none; /* sin borde en el botón de edición */
  cursor: pointer; /* cursor de mano en el botón editar */
  font-size: 1rem; /* tamaño del icono de edición */
  opacity: 0.8; /* leve transparencia del botón editar */
  padding: 0; /* sin relleno en el botón editar */
  transition: opacity 0.2s; /* transición suave de opacidad al hover */
  line-height: 2.4rem; /* altura de línea alineada con el nombre */
}

.btn-editar:hover {
  opacity: 1; /* opacidad completa al pasar el cursor */
}

.btn-confirmar {
  background: rgba(255,255,255,0.2); /* fondo semitransparente del botón confirmar */
  border: 2px solid rgba(255,255,255,0.6); /* borde blanco semitransparente del confirmar */
  border-radius: 6px; /* esquinas redondeadas del botón confirmar */
  color: white; /* texto blanco del botón confirmar */
  font-size: 1rem; /* tamaño del símbolo del botón confirmar */
  padding: 0 10px; /* relleno horizontal del botón confirmar */
  height: 2.4rem; /* altura alineada con el campo de nombre */
  cursor: pointer; /* cursor de mano en el botón confirmar */
  transition: background 0.2s; /* transición suave del fondo al hover */
}

.btn-confirmar:hover {
  background: rgba(255,255,255,0.35); /* fondo más claro al pasar el cursor */
}

.perfil-datos {
  display: flex; /* datos generales en fila horizontal */
  gap: 0; /* sin espacio entre los datos generales */
  border-bottom: 1px solid #eee; /* línea separadora bajo los datos */
}

.dato-fila {
  flex: 1; /* cada dato ocupa igual espacio disponible */
  display: flex; /* etiqueta y valor del dato en columna */
  flex-direction: column; /* disposición vertical de etiqueta y valor */
  align-items: center; /* centra horizontalmente etiqueta y valor */
  padding: 16px; /* relleno de cada celda de dato */
  border-right: 1px solid #eee; /* separador vertical entre datos */
}

.dato-fila:last-child {
  border-right: none; /* elimina el separador del último dato */
}

.dato-label {
  font-size: 0.8rem; /* tamaño pequeño de la etiqueta del dato */
  color: #888; /* color gris de la etiqueta del dato */
  text-transform: uppercase; /* etiqueta del dato en mayúsculas */
  margin-bottom: 4px; /* separación entre etiqueta y valor */
}

.dato-valor {
  font-size: 1.1rem; /* tamaño destacado del valor del dato */
  font-weight: bold; /* negrita para el valor del dato */
  color: #222; /* color oscuro del valor del dato */
}

.perfil-descripcion {
  padding: 16px 24px; /* relleno de la sección de descripción */
  border-bottom: 1px solid #eee; /* línea separadora bajo la descripción */
}

.perfil-descripcion p {
  margin: 0; /* elimina el margen predeterminado del párrafo */
  font-size: 0.88rem; /* tamaño pequeño del texto de descripción */
  color: #555; /* color gris oscuro de la descripción */
  line-height: 1.5; /* interlineado cómodo para la descripción */
}

.perfil-stats {
  padding: 16px 24px 24px; /* relleno de la sección de bonos de clase */
}

.perfil-stats h3 {
  font-size: 0.9rem; /* tamaño del título de bonos de clase */
  font-weight: bold; /* negrita en el título de bonos */
  color: #666; /* color gris del título de bonos */
  text-transform: uppercase; /* título de bonos en mayúsculas */
  margin: 0 0 12px 0; /* espacio inferior bajo el título de bonos */
}

.stats-grid {
  display: grid; /* activa grilla para los bonos de clase */
  grid-template-columns: 1fr 1fr 1fr; /* tres columnas iguales para los bonos */
  gap: 6px; /* separación entre celdas de bonos */
}

.stat-fila {
  display: flex; /* nombre y valor del bono en fila */
  justify-content: space-between; /* separa nombre y valor del bono */
  align-items: center; /* centra verticalmente nombre y valor */
  padding: 4px 8px; /* relleno de cada fila de bono */
  background: #f9f9f9; /* fondo gris claro de la fila de bono */
  border-radius: 6px; /* esquinas redondeadas de la fila de bono */
  font-size: 0.85rem; /* tamaño del texto de los bonos de clase */
}

.stat-nombre { color: #333; /* color oscuro del nombre del bono */ }
.stat-valor  { font-weight: bold; /* negrita para el valor del bono */ }
.positivo    { color: #2dc653; /* color verde para valores positivos */ }
.negativo    { color: #e63946; /* color rojo para valores negativos */ }
.neutro      { color: #aaa; /* color gris para valores neutros */ }

/* Historial de batallas */
.perfil-batallas {
  padding: 16px 24px 24px; /* relleno de la sección de historial */
  border-top: 1px solid #eee; /* línea separadora sobre el historial */
}

.perfil-batallas h3 {
  font-size: 0.9rem; /* tamaño del título del historial */
  font-weight: bold; /* negrita en el título del historial */
  color: #666; /* color gris del título del historial */
  text-transform: uppercase; /* título del historial en mayúsculas */
  margin: 0 0 12px 0; /* espacio inferior bajo el título del historial */
}

.batallas-grid {
  display: grid; /* activa grilla para los datos de batallas */
  grid-template-columns: repeat(5, 1fr); /* cinco columnas iguales para batallas */
  gap: 6px; /* separación entre celdas del historial */
}

.batalla-dato {
  display: flex; /* etiqueta y valor de batalla en columna */
  flex-direction: column; /* disposición vertical dentro de la celda */
  align-items: center; /* centra el contenido de la celda */
  padding: 10px 8px; /* relleno de cada celda de batalla */
  background: #f9f9f9; /* fondo gris claro de la celda de batalla */
  border-radius: 8px; /* esquinas redondeadas de la celda */
  gap: 4px; /* separación entre etiqueta y valor */
}

.batalla-label {
  font-size: 0.75rem; /* tamaño pequeño de la etiqueta de batalla */
  color: #888; /* color gris de la etiqueta de batalla */
  text-transform: uppercase; /* etiqueta de batalla en mayúsculas */
}

.batalla-valor {
  font-size: 1.2rem; /* tamaño destacado del número de batallas */
  font-weight: bold; /* negrita para el número de batallas */
  color: #222; /* color oscuro del número de batallas */
}
</style>
