<script setup>
import { ref, onMounted } from 'vue'
import { obtenerPartidas, eliminarPartida } from '../api/partidas.js'
import { clases } from '../data/clases.js'

const claseEmoji = Object.fromEntries(
  clases.map(c => [c.id, c.label.split(' ')[0]])
)

const emit = defineEmits(['nueva-partida', 'cargar-partida'])

const partidas          = ref([])
const cargando          = ref(true)
const confirmarEliminar = ref(null)
const pagina            = ref(1)
const paginas           = ref(1)

async function cargarPagina(p) {
  cargando.value = true
  try {
    const data     = await obtenerPartidas(p)
    partidas.value = data.partidas
    pagina.value   = data.pagina
    paginas.value  = data.paginas
  } catch (e) {
    console.error('Error al cargar partidas:', e)
  } finally {
    cargando.value = false
  }
}

onMounted(() => cargarPagina(1))

function pedirConfirmacion(partida) {
  confirmarEliminar.value = partida
}

function cancelarEliminar() {
  confirmarEliminar.value = null
}

async function eliminar() {
  try {
    await eliminarPartida(confirmarEliminar.value.id)
    await cargarPagina(pagina.value)
  } catch (e) {
    console.error('Error al eliminar partida:', e)
  }
  confirmarEliminar.value = null
}

function seleccionarPartida(partida) {
  emit('cargar-partida', partida)
}
</script>

<template>
  <div class="start-screen">

    <div class="start-hero">
      <div class="start-logo">⚔️</div>
      <h1>Pokémon Adventure</h1>
      <p class="start-subtitulo">Tu aventura te espera</p>
    </div>

    <div class="start-opciones">

      <!-- Nueva partida -->
      <div class="opcion-card opcion-nueva">
        <span class="opcion-icono">✨</span>
        <div class="opcion-texto">
          <h2>Nueva partida</h2>
          <p>Crea un nuevo entrenador y elige tu compañero inicial.</p>
        </div>
        <button class="btn-nueva" @click="emit('nueva-partida')">Comenzar</button>
      </div>

      <!-- Cargar partida -->
      <div class="opcion-card opcion-cargar">
        <div class="cargar-header">
          <span class="opcion-icono">📂</span>
          <div class="opcion-texto">
            <h2>Cargar partida</h2>
            <p>Continúa desde donde lo dejaste.</p>
          </div>
        </div>

        <div class="partidas-lista">

          <!-- Cargando -->
          <div v-if="cargando" class="partidas-vacio">
            <span>Cargando...</span>
          </div>

          <!-- Sin partidas -->
          <div v-else-if="partidas.length === 0" class="partidas-vacio">
            <span>No hay partidas guardadas</span>
          </div>

          <!-- Lista de partidas -->
          <div
            v-for="partida in partidas"
            :key="partida.id"
            class="partida-item"
          >
            <div class="partida-info">
              <span class="partida-nombre">{{ partida.nombre }}</span>
              <span class="partida-meta">
                <span class="partida-clase">{{ claseEmoji[partida.clase_id] }}</span>
                {{ partida.entrenador_nombre }}
              </span>
            </div>
            <div class="partida-acciones">
              <button class="btn-cargar" @click="seleccionarPartida(partida)">Cargar</button>
              <button class="btn-eliminar" @click="pedirConfirmacion(partida)">🗑️</button>
            </div>
          </div>

          <!-- Paginación -->
          <div v-if="paginas > 1" class="paginacion">
            <button class="btn-pagina" :disabled="pagina <= 1" @click="cargarPagina(pagina - 1)">← Anterior</button>
            <span class="pagina-info">{{ pagina }} / {{ paginas }}</span>
            <button class="btn-pagina" :disabled="pagina >= paginas" @click="cargarPagina(pagina + 1)">Siguiente →</button>
          </div>

        </div>
      </div>

    </div>

  </div>

  <!-- Modal de confirmación -->
  <div v-if="confirmarEliminar" class="modal-overlay" @click.self="cancelarEliminar">
    <div class="modal">
      <h3>¿Eliminar partida?</h3>
      <p>Estás a punto de eliminar <strong>{{ confirmarEliminar.nombre }}</strong>. Esta acción no se puede deshacer.</p>
      <div class="modal-acciones">
        <button class="btn-modal-cancelar" @click="cancelarEliminar">Cancelar</button>
        <button class="btn-modal-eliminar" @click="eliminar">Eliminar</button>
      </div>
    </div>
  </div>

</template>

<style scoped>
.start-screen {
  min-height: 100vh; /* ocupa al menos toda la altura de la ventana */
  display: flex; /* activa diseño flexbox para centrar el contenido */
  flex-direction: column; /* apila hero y opciones en columna vertical */
  align-items: center; /* centra horizontalmente los hijos */
  justify-content: center; /* centra verticalmente los hijos */
  background: #111; /* fondo casi negro de la pantalla de inicio */
  font-family: sans-serif; /* tipografía sans-serif por defecto */
  padding: 32px 16px; /* espaciado interno vertical y horizontal */
  gap: 48px; /* separación entre el hero y el bloque de opciones */
}

/* Hero */
.start-hero {
  text-align: center; /* centra el logo, título y subtítulo */
  color: white; /* color de texto del bloque hero */
}

.start-logo {
  font-size: 4rem; /* tamaño grande del emoji de espada */
  margin-bottom: 12px; /* separa el logo del título principal */
}

.start-hero h1 {
  font-size: 2.4rem; /* tamaño del título "Pokémon Adventure" */
  margin: 0 0 8px 0; /* separa el título del subtítulo */
}

.start-subtitulo {
  color: #aaa; /* color gris claro del subtítulo */
  font-size: 1rem; /* tamaño de letra del subtítulo */
  margin: 0; /* elimina los márgenes del subtítulo */
}

/* Opciones */
.start-opciones {
  display: flex; /* activa flexbox para las cards de opción */
  flex-direction: column; /* apila la card de nueva y cargar en columna */
  gap: 16px; /* separación entre las dos cards de opción */
  width: 100%; /* ocupa todo el ancho disponible */
  max-width: 560px; /* ancho máximo del contenedor de opciones */
}

.opcion-card {
  background: #1e1e1e; /* fondo oscuro de la card */
  border: 2px solid #333; /* borde gris oscuro de la card */
  border-radius: 16px; /* esquinas muy redondeadas de la card */
  padding: 24px; /* relleno interno de la card */
  color: white; /* color de texto dentro de la card */
  transition: border-color 0.2s; /* animación suave del borde al hover */
}

.opcion-card:hover {
  border-color: #555; /* borde más claro al pasar el cursor sobre la card */
}

/* Nueva partida */
.opcion-nueva {
  display: flex; /* alinea icono, texto y botón en fila */
  align-items: center; /* centra verticalmente icono, texto y botón */
  gap: 16px; /* separación entre icono, texto y botón nueva partida */
}

.opcion-icono {
  font-size: 2rem; /* tamaño del emoji de icono de la card */
  flex-shrink: 0; /* impide que el icono se encoja en el flex */
}

.opcion-texto {
  flex: 1; /* ocupa el espacio restante entre icono y botón */
}

.opcion-texto h2 {
  margin: 0 0 4px 0; /* separa el título de la descripción de la card */
  font-size: 1.2rem; /* tamaño del título de cada card de opción */
}

.opcion-texto p {
  margin: 0; /* elimina márgenes del párrafo descriptivo */
  font-size: 0.85rem; /* tamaño reducido de la descripción de la card */
  color: #aaa; /* color gris de la descripción de la card */
}

.btn-nueva {
  padding: 10px 24px; /* relleno interno del botón "Comenzar" */
  background: white; /* fondo blanco del botón nueva partida */
  color: #111; /* texto oscuro sobre el fondo blanco */
  border: none; /* sin borde en el botón nueva partida */
  border-radius: 10px; /* esquinas redondeadas del botón nueva partida */
  font-size: 0.95rem; /* tamaño de letra del botón nueva partida */
  font-weight: bold; /* texto en negrita del botón nueva partida */
  cursor: pointer; /* cursor de mano sobre el botón */
  transition: background 0.2s, transform 0.1s; /* animación de fondo y escala al hover */
  flex-shrink: 0; /* impide que el botón se encoja en el flex */
}

.btn-nueva:hover {
  background: #ddd; /* fondo gris claro al pasar el cursor */
  transform: scale(1.02); /* ligero agrandamiento del botón al hover */
}

/* Cargar partida */
.opcion-cargar {
  display: flex; /* organiza cabecera y lista de partidas */
  flex-direction: column; /* apila header y lista de partidas verticalmente */
  gap: 16px; /* separación entre la cabecera y la lista de partidas */
}

.cargar-header {
  display: flex; /* alinea icono y texto en fila horizontal */
  align-items: center; /* centra verticalmente icono y texto de cabecera */
  gap: 16px; /* separación entre icono y texto de la cabecera */
}

/* Lista de partidas */
.partidas-lista {
  display: flex; /* organiza las filas de partidas guardadas */
  flex-direction: column; /* apila cada partida verticalmente */
  gap: 8px; /* separación entre cada fila de partida */
}

.partidas-vacio {
  text-align: center; /* centra el texto del área vacía */
  color: #555; /* color gris oscuro del mensaje sin partidas */
  font-size: 0.9rem; /* tamaño del mensaje "sin partidas" o "cargando" */
  padding: 16px; /* relleno interno del área vacía */
  border: 2px dashed #333; /* borde punteado del área vacía */
  border-radius: 10px; /* esquinas redondeadas del área vacía */
}

.partida-item {
  display: flex; /* alinea info y botones de acción en fila */
  align-items: center; /* centra verticalmente info y botones */
  justify-content: space-between; /* separa info y acciones a los extremos */
  background: #2a2a2a; /* fondo oscuro de cada fila de partida */
  border: 1px solid #333; /* borde sutil de la fila de partida */
  border-radius: 10px; /* esquinas redondeadas de la fila de partida */
  padding: 12px 16px; /* relleno interno de la fila de partida */
  transition: border-color 0.2s; /* animación del borde al pasar el cursor */
}

.partida-item:hover {
  border-color: #555; /* borde más claro al pasar el cursor sobre la partida */
}

.partida-info {
  display: flex; /* apila nombre y metadatos de la partida */
  flex-direction: column; /* organiza nombre y meta en columna */
  gap: 2px; /* separación mínima entre nombre y metadatos */
}

.partida-nombre {
  font-size: 0.95rem; /* tamaño del nombre de la partida guardada */
  font-weight: bold; /* nombre de la partida en negrita */
}

.partida-meta {
  font-size: 0.78rem; /* tamaño reducido de los metadatos de la partida */
  color: #777; /* color gris de los metadatos de partida */
  display: flex; /* alinea emoji de clase y nombre del entrenador */
  align-items: center; /* centra verticalmente clase y nombre del entrenador */
  gap: 4px; /* separación entre emoji de clase y nombre del entrenador */
}

.partida-clase {
  font-size: 0.9rem; /* tamaño del emoji de clase del entrenador */
}

.partida-acciones {
  display: flex; /* alinea los botones de acción en fila */
  align-items: center; /* centra verticalmente los botones de acción */
  gap: 8px; /* separación entre el botón cargar y el botón eliminar */
}

.btn-cargar {
  padding: 6px 16px; /* relleno interno del botón cargar partida */
  background: #333; /* fondo oscuro del botón cargar partida */
  color: white; /* texto blanco del botón cargar partida */
  border: 1px solid #555; /* borde gris del botón cargar partida */
  border-radius: 8px; /* esquinas redondeadas del botón cargar */
  font-size: 0.85rem; /* tamaño de letra del botón cargar */
  cursor: pointer; /* cursor de mano sobre el botón cargar */
  transition: background 0.2s; /* animación de fondo del botón cargar */
}

.btn-cargar:hover {
  background: #444; /* fondo más claro al pasar el cursor sobre cargar */
}

.btn-eliminar {
  background: none; /* sin fondo en el botón eliminar en estado normal */
  border: 1px solid #444; /* borde gris del botón eliminar */
  border-radius: 8px; /* esquinas redondeadas del botón eliminar */
  color: #e63946; /* color rojo del icono de papelera */
  font-size: 1rem; /* tamaño del emoji de papelera */
  padding: 6px 10px; /* relleno interno del botón eliminar */
  cursor: pointer; /* cursor de mano sobre el botón eliminar */
  transition: background 0.2s, border-color 0.2s; /* animación de fondo y borde al hover */
}

.btn-eliminar:hover {
  background: rgba(230, 57, 70, 0.15); /* fondo rojizo sutil al pasar sobre eliminar */
  border-color: #e63946; /* borde rojo al pasar el cursor sobre eliminar */
}

/* Paginación */
.paginacion {
  display: flex; /* alinea botones y contador de página en fila */
  align-items: center; /* centra verticalmente los elementos de paginación */
  justify-content: center; /* centra horizontalmente la barra de paginación */
  gap: 12px; /* separación entre botones anterior, contador y siguiente */
  margin-top: 4px; /* pequeño margen superior de la barra de paginación */
}

.btn-pagina {
  padding: 6px 14px; /* relleno interno de los botones de página */
  background: #2a2a2a; /* fondo oscuro de los botones de página */
  color: white; /* texto blanco de los botones de página */
  border: 1px solid #444; /* borde gris de los botones de página */
  border-radius: 8px; /* esquinas redondeadas de los botones de página */
  font-size: 0.82rem; /* tamaño de letra de los botones de página */
  cursor: pointer; /* cursor de mano sobre los botones de página */
  transition: background 0.2s, border-color 0.2s; /* animación de fondo y borde al hover */
}

.btn-pagina:hover:not(:disabled) {
  background: #3a3a3a; /* fondo más claro al pasar sobre botón de página activo */
  border-color: #666; /* borde más claro al pasar sobre botón de página activo */
}

.btn-pagina:disabled {
  opacity: 0.35; /* opacidad reducida en el botón de página deshabilitado */
  cursor: default; /* cursor normal en el botón de página deshabilitado */
}

.pagina-info {
  font-size: 0.82rem; /* tamaño del texto contador "X / Y" de páginas */
  color: #888; /* color gris del contador de página actual */
}

/* Modal */
.modal-overlay {
  position: fixed; /* fijo respecto a la ventana, cubre toda la pantalla */
  inset: 0; /* expande el overlay a los cuatro bordes de la ventana */
  background: rgba(0, 0, 0, 0.7); /* fondo negro semitransparente del overlay */
  display: flex; /* centra el modal con flexbox */
  align-items: center; /* centra el modal verticalmente en la pantalla */
  justify-content: center; /* centra el modal horizontalmente en la pantalla */
  z-index: 100; /* se apila por encima de todos los demás elementos */
}

.modal {
  background: #1e1e1e; /* fondo oscuro del cuadro de diálogo */
  border: 2px solid #444; /* borde gris del cuadro de diálogo */
  border-radius: 16px; /* esquinas muy redondeadas del modal */
  padding: 28px 32px; /* relleno interno del cuadro de confirmación */
  max-width: 400px; /* ancho máximo del modal de confirmación */
  width: 90%; /* ancho adaptable al viewport en pantallas pequeñas */
  color: white; /* color de texto dentro del modal */
}

.modal h3 {
  margin: 0 0 12px 0; /* separa el título del texto descriptivo del modal */
  font-size: 1.2rem; /* tamaño del título del modal */
}

.modal p {
  margin: 0 0 24px 0; /* separa el texto descriptivo de los botones del modal */
  font-size: 0.9rem; /* tamaño del texto descriptivo del modal */
  color: #aaa; /* color gris del texto descriptivo del modal */
  line-height: 1.5; /* interlineado del texto del modal */
}

.modal p strong {
  color: white; /* nombre de la partida en blanco sobre el texto gris */
}

.modal-acciones {
  display: flex; /* alinea los botones cancelar y eliminar en fila */
  justify-content: flex-end; /* alinea los botones a la derecha del modal */
  gap: 10px; /* separación entre el botón cancelar y el botón eliminar */
}

.btn-modal-cancelar {
  padding: 8px 20px; /* relleno interno del botón cancelar del modal */
  background: none; /* sin fondo en el botón cancelar */
  border: 1px solid #555; /* borde gris del botón cancelar */
  border-radius: 8px; /* esquinas redondeadas del botón cancelar */
  color: #aaa; /* color gris del texto del botón cancelar */
  cursor: pointer; /* cursor de mano sobre el botón cancelar */
  font-size: 0.9rem; /* tamaño de letra del botón cancelar */
  transition: border-color 0.2s, color 0.2s; /* animación de borde y color al hover */
}

.btn-modal-cancelar:hover {
  border-color: #aaa; /* borde más claro al pasar el cursor sobre cancelar */
  color: white; /* texto blanco al hacer hover en el botón cancelar */
}

.btn-modal-eliminar {
  padding: 8px 20px; /* relleno interno del botón eliminar del modal */
  background: #e63946; /* fondo rojo del botón confirmar eliminación */
  border: none; /* sin borde en el botón eliminar del modal */
  border-radius: 8px; /* esquinas redondeadas del botón eliminar del modal */
  color: white; /* texto blanco del botón eliminar del modal */
  cursor: pointer; /* cursor de mano sobre el botón eliminar */
  font-size: 0.9rem; /* tamaño de letra del botón eliminar del modal */
  font-weight: bold; /* texto en negrita del botón eliminar */
  transition: background 0.2s; /* animación de fondo del botón eliminar al hover */
}

.btn-modal-eliminar:hover {
  background: #c1121f; /* rojo más oscuro al pasar el cursor sobre eliminar */
}
</style>
