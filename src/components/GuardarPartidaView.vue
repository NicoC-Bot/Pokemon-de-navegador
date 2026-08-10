<script setup>
import { ref } from 'vue'

const props = defineProps({
  entrenador:    Object,
  partidaId:     Number,
  nombrePartida: String,
})

const emit = defineEmits(['volver', 'guardar-partida'])

const nombreNueva            = ref('')
const guardado               = ref(false)
const confirmarSobreescribir = ref(false)

function guardarNueva() {
  if (nombreNueva.value.trim() === '') return
  emit('guardar-partida', { nombre: nombreNueva.value.trim() })
  guardado.value = true
  nombreNueva.value = ''
}

function sobreescribir() {
  emit('guardar-partida', { nombre: props.nombrePartida, id: props.partidaId })
  guardado.value = true
  confirmarSobreescribir.value = false
}
</script>

<template>
  <div class="guardar">

    <button class="btn-volver" @click="emit('volver')">← Volver</button>

    <div class="guardar-card">
      <h2>Guardar partida</h2>

      <!-- Nueva partida -->
      <div class="seccion">
        <h3 class="seccion-titulo">Nueva partida</h3>
        <p class="seccion-sub">Crea un nuevo guardado con el estado actual.</p>
        <div class="guardar-form">
          <input
            v-model="nombreNueva"
            class="input-nombre"
            type="text"
            placeholder="Ej: Mi partida principal"
            @keyup.enter="guardarNueva"
          />
          <button class="btn-guardar" @click="guardarNueva">Guardar</button>
        </div>
      </div>

      <!-- Sobreescribir partida actual -->
      <div v-if="partidaId" class="seccion seccion-sobreescribir">
        <h3 class="seccion-titulo">Sobreescribir existente</h3>
        <p class="seccion-sub">Reemplaza el progreso de la partida actual.</p>
        <div class="partidas-lista">
          <div class="partida-fila">
            <span class="partida-nombre">{{ nombrePartida }}</span>
            <button class="btn-sobreescribir" @click="confirmarSobreescribir = true">
              Sobreescribir
            </button>
          </div>
        </div>
      </div>

      <div v-if="guardado" class="guardar-exito">
        ✅ Partida guardada correctamente.
      </div>
    </div>

  </div>

  <!-- Modal de confirmación -->
  <div v-if="confirmarSobreescribir" class="modal-overlay" @click.self="confirmarSobreescribir = false">
    <div class="modal">
      <h3>¿Sobreescribir partida?</h3>
      <p>
        El progreso guardado en <strong>{{ nombrePartida }}</strong>
        será reemplazado por el estado actual. Esta acción no se puede deshacer.
      </p>
      <div class="modal-acciones">
        <button class="btn-modal-cancelar" @click="confirmarSobreescribir = false">Cancelar</button>
        <button class="btn-modal-confirmar" @click="sobreescribir">Sobreescribir</button>
      </div>
    </div>
  </div>

</template>

<style scoped>
.guardar {
  max-width: 560px; /* ancho máximo del formulario de guardado */
  margin: 0 auto; /* centra el contenedor horizontalmente */
  font-family: sans-serif; /* fuente genérica para el componente */
}

.btn-volver {
  display: block; /* convierte en bloque para centrar con margin */
  margin: 0 auto 20px; /* centra y separa del contenido inferior */
  padding: 8px 18px; /* relleno interno del botón */
  background: white; /* fondo blanco del botón volver */
  border: 2px solid #ccc; /* borde gris claro del botón */
  border-radius: 8px; /* esquinas redondeadas del botón */
  cursor: pointer; /* cursor de mano al interactuar */
  font-size: 0.88rem; /* tamaño de texto ligeramente reducido */
  color: #555; /* color gris medio del texto */
  transition: border-color 0.2s, color 0.2s; /* animación suave de borde y color */
}

.btn-volver:hover { border-color: #888; color: #222; } /* oscurece borde y texto al hover */

.guardar-card {
  border: 2px solid #e0e0e0; /* borde gris claro de la tarjeta principal */
  border-radius: 16px; /* esquinas muy redondeadas de la tarjeta */
  overflow: hidden; /* recorta el contenido a los bordes redondeados */
}

.guardar-card h2 {
  margin: 0; /* elimina margen por defecto del título */
  font-size: 1.4rem; /* tamaño grande del título principal */
  padding: 24px 28px 0; /* espacio superior y lateral, sin relleno inferior */
}

.seccion {
  padding: 20px 28px; /* relleno interno de cada sección */
  border-bottom: 1px solid #eee; /* línea divisora sutil entre secciones */
}

.seccion:last-of-type {
  border-bottom: none; /* elimina el divisor en la última sección */
}

.seccion-titulo {
  font-size: 0.85rem; /* texto pequeño estilo etiqueta */
  font-weight: bold; /* negrita para destacar el título de sección */
  color: #666; /* color gris para texto de etiqueta */
  text-transform: uppercase; /* convierte el texto a mayúsculas */
  margin: 0 0 4px 0; /* margen inferior mínimo bajo el título */
}

.seccion-sub {
  font-size: 0.82rem; /* texto descriptivo pequeño */
  color: #999; /* gris claro para descripción secundaria */
  margin: 0 0 14px 0; /* separación inferior antes del formulario */
}

.guardar-form {
  display: flex; /* alinea input y botón en fila */
  gap: 10px; /* espacio entre el input y el botón guardar */
}

.input-nombre {
  flex: 1; /* el input ocupa todo el espacio disponible */
  padding: 10px 14px; /* relleno interno del campo de texto */
  font-size: 1rem; /* tamaño de texto del input */
  border: 2px solid #ccc; /* borde gris del campo de texto */
  border-radius: 8px; /* esquinas redondeadas del input */
  outline: none; /* elimina el outline nativo del navegador */
  transition: border-color 0.2s; /* animación del borde al enfocar */
}

.input-nombre:focus {
  border-color: #888; /* borde más oscuro al enfocar el campo */
}

.btn-guardar {
  padding: 10px 24px; /* relleno generoso del botón guardar */
  background: #222; /* fondo oscuro del botón principal */
  color: white; /* texto blanco sobre fondo oscuro */
  border: none; /* sin borde visible en el botón */
  border-radius: 8px; /* esquinas redondeadas del botón */
  font-size: 0.95rem; /* tamaño del texto del botón */
  font-weight: bold; /* negrita para reforzar la acción */
  cursor: pointer; /* cursor de mano al interactuar */
  transition: background 0.2s; /* animación suave del fondo al hover */
}

.btn-guardar:hover {
  background: #444; /* fondo más claro al pasar el cursor */
}

/* Sobreescribir */
.seccion-sobreescribir {
  background: #fafafa; /* fondo levemente gris para diferenciar la sección */
}

.partidas-vacio {
  font-size: 0.88rem; /* texto pequeño del mensaje vacío */
  color: #aaa; /* gris muy claro para el estado vacío */
  padding: 8px 0; /* espacio vertical del aviso vacío */
}

.partidas-lista {
  display: flex; /* apila las filas de partidas en columna */
  flex-direction: column; /* dirección vertical de la lista */
  gap: 8px; /* separación entre filas de partida */
}

.partida-fila {
  display: flex; /* alinea nombre y botón en fila */
  align-items: center; /* centra verticalmente los elementos */
  justify-content: space-between; /* nombre a la izquierda, botón a la derecha */
  padding: 10px 14px; /* relleno interno de la fila de partida */
  background: white; /* fondo blanco de cada fila */
  border: 1px solid #e0e0e0; /* borde sutil de la fila */
  border-radius: 8px; /* esquinas redondeadas de la fila */
}

.partida-info {
  display: flex; /* agrupa nombre y fecha en columna */
  flex-direction: column; /* apila nombre encima de la fecha */
  gap: 2px; /* separación mínima entre nombre y fecha */
}

.partida-nombre {
  font-size: 0.9rem; /* tamaño del nombre de la partida guardada */
  font-weight: bold; /* negrita para destacar el nombre */
  color: #222; /* color oscuro del nombre de la partida */
}

.partida-fecha {
  font-size: 0.75rem; /* texto muy pequeño para la fecha */
  color: #aaa; /* gris claro para el texto de fecha */
}

.btn-sobreescribir {
  padding: 6px 14px; /* relleno compacto del botón */
  background: none; /* sin fondo, solo borde visible */
  border: 1px solid #ccc; /* borde gris claro del botón */
  border-radius: 6px; /* esquinas redondeadas del botón */
  font-size: 0.82rem; /* texto pequeño del botón */
  color: #555; /* color gris del texto */
  cursor: pointer; /* cursor de mano al interactuar */
  transition: border-color 0.2s, color 0.2s; /* animación suave de borde y color al hover */
  white-space: nowrap; /* evita que el texto del botón salte de línea */
}

.btn-sobreescribir:hover {
  border-color: #e63946; /* borde rojo de advertencia al hover */
  color: #e63946; /* texto rojo de advertencia al hover */
}

/* Éxito */
.guardar-exito {
  margin: 0 28px 20px; /* márgenes laterales y separación inferior */
  padding: 12px 16px; /* relleno interno del aviso de éxito */
  background: #f0faf0; /* fondo verde muy claro del aviso de guardado */
  border: 1px solid #2dc653; /* borde verde del mensaje de éxito */
  border-radius: 8px; /* esquinas redondeadas del aviso */
  color: #1a7a35; /* texto verde oscuro del mensaje */
  font-size: 0.9rem; /* tamaño del texto del aviso */
}

/* Modal */
.modal-overlay {
  position: fixed; /* cubre toda la pantalla sin importar el scroll */
  inset: 0; /* se extiende hasta los cuatro bordes de la ventana */
  background: rgba(0, 0, 0, 0.5); /* fondo semitransparente oscuro */
  display: flex; /* centra el modal con flexbox */
  align-items: center; /* centra el modal verticalmente */
  justify-content: center; /* centra el modal horizontalmente */
  z-index: 100; /* se superpone sobre el resto del contenido */
}

.modal {
  background: white; /* fondo blanco del cuadro de diálogo */
  border: 2px solid #e0e0e0; /* borde sutil del modal */
  border-radius: 16px; /* esquinas muy redondeadas del modal */
  padding: 28px 32px; /* relleno generoso del contenido del modal */
  max-width: 400px; /* ancho máximo del cuadro de confirmación */
  width: 90%; /* ancho adaptable en pantallas pequeñas */
}

.modal h3 {
  margin: 0 0 12px 0; /* separación inferior del título del modal */
  font-size: 1.1rem; /* tamaño del título de confirmación */
}

.modal p {
  margin: 0 0 24px 0; /* separación inferior del párrafo explicativo */
  font-size: 0.9rem; /* texto descriptivo de tamaño medio */
  color: #555; /* gris para el texto secundario */
  line-height: 1.5; /* interlineado cómodo para leer */
}

.modal p strong {
  color: #222; /* oscurece el nombre de la partida destacado */
}

.modal-acciones {
  display: flex; /* alinea los botones en fila */
  justify-content: flex-end; /* alinea los botones al extremo derecho */
  gap: 10px; /* separación entre los botones del modal */
}

.btn-modal-cancelar {
  padding: 8px 20px; /* relleno del botón cancelar */
  background: none; /* sin fondo, solo borde visible */
  border: 1px solid #ccc; /* borde gris claro del botón */
  border-radius: 8px; /* esquinas redondeadas del botón */
  color: #666; /* color gris del texto del botón */
  cursor: pointer; /* cursor de mano al interactuar */
  font-size: 0.9rem; /* tamaño del texto del botón */
  transition: border-color 0.2s; /* animación del borde al hover */
}

.btn-modal-cancelar:hover {
  border-color: #888; /* borde más oscuro al pasar el cursor */
  color: #222; /* texto más oscuro al hover */
}

.btn-modal-confirmar {
  padding: 8px 20px; /* relleno del botón de confirmación destructiva */
  background: #e63946; /* fondo rojo para acción destructiva */
  border: none; /* sin borde visible en el botón */
  border-radius: 8px; /* esquinas redondeadas del botón */
  color: white; /* texto blanco sobre fondo rojo */
  cursor: pointer; /* cursor de mano al interactuar */
  font-size: 0.9rem; /* tamaño del texto del botón */
  font-weight: bold; /* negrita para enfatizar la acción destructiva */
  transition: background 0.2s; /* animación suave del fondo al hover */
}

.btn-modal-confirmar:hover {
  background: #c1121f; /* rojo más oscuro al pasar el cursor */
}
</style>
