<script setup>
import { ref, onMounted } from 'vue'
import { obtenerPartidas, eliminarPartida } from '../api/partidas.js'

const emit = defineEmits(['nueva-partida', 'cargar-partida'])

const partidas        = ref([])
const cargando        = ref(true)
const confirmarEliminar = ref(null)

onMounted(async () => {
  try {
    partidas.value = await obtenerPartidas()
  } catch (e) {
    console.error('Error al cargar partidas:', e)
  } finally {
    cargando.value = false
  }
})

function pedirConfirmacion(partida) {
  confirmarEliminar.value = partida
}

function cancelarEliminar() {
  confirmarEliminar.value = null
}

async function eliminar() {
  try {
    await eliminarPartida(confirmarEliminar.value.id)
    partidas.value = partidas.value.filter(p => p.id !== confirmarEliminar.value.id)
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
              <span class="partida-fecha">{{ partida.creada_en }}</span>
            </div>
            <div class="partida-acciones">
              <button class="btn-cargar" @click="seleccionarPartida(partida)">Cargar</button>
              <button class="btn-eliminar" @click="pedirConfirmacion(partida)">🗑️</button>
            </div>
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
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: #111;
  font-family: sans-serif;
  padding: 32px 16px;
  gap: 48px;
}

/* Hero */
.start-hero {
  text-align: center;
  color: white;
}

.start-logo {
  font-size: 4rem;
  margin-bottom: 12px;
}

.start-hero h1 {
  font-size: 2.4rem;
  margin: 0 0 8px 0;
}

.start-subtitulo {
  color: #aaa;
  font-size: 1rem;
  margin: 0;
}

/* Opciones */
.start-opciones {
  display: flex;
  flex-direction: column;
  gap: 16px;
  width: 100%;
  max-width: 560px;
}

.opcion-card {
  background: #1e1e1e;
  border: 2px solid #333;
  border-radius: 16px;
  padding: 24px;
  color: white;
  transition: border-color 0.2s;
}

.opcion-card:hover {
  border-color: #555;
}

/* Nueva partida */
.opcion-nueva {
  display: flex;
  align-items: center;
  gap: 16px;
}

.opcion-icono {
  font-size: 2rem;
  flex-shrink: 0;
}

.opcion-texto {
  flex: 1;
}

.opcion-texto h2 {
  margin: 0 0 4px 0;
  font-size: 1.2rem;
}

.opcion-texto p {
  margin: 0;
  font-size: 0.85rem;
  color: #aaa;
}

.btn-nueva {
  padding: 10px 24px;
  background: white;
  color: #111;
  border: none;
  border-radius: 10px;
  font-size: 0.95rem;
  font-weight: bold;
  cursor: pointer;
  transition: background 0.2s, transform 0.1s;
  flex-shrink: 0;
}

.btn-nueva:hover {
  background: #ddd;
  transform: scale(1.02);
}

/* Cargar partida */
.opcion-cargar {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.cargar-header {
  display: flex;
  align-items: center;
  gap: 16px;
}

/* Lista de partidas */
.partidas-lista {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.partidas-vacio {
  text-align: center;
  color: #555;
  font-size: 0.9rem;
  padding: 16px;
  border: 2px dashed #333;
  border-radius: 10px;
}

.partida-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #2a2a2a;
  border: 1px solid #333;
  border-radius: 10px;
  padding: 12px 16px;
  transition: border-color 0.2s;
}

.partida-item:hover {
  border-color: #555;
}

.partida-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.partida-nombre {
  font-size: 0.95rem;
  font-weight: bold;
}

.partida-fecha {
  font-size: 0.78rem;
  color: #777;
}

.partida-acciones {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-cargar {
  padding: 6px 16px;
  background: #333;
  color: white;
  border: 1px solid #555;
  border-radius: 8px;
  font-size: 0.85rem;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-cargar:hover {
  background: #444;
}

.btn-eliminar {
  background: none;
  border: 1px solid #444;
  border-radius: 8px;
  color: #e63946;
  font-size: 1rem;
  padding: 6px 10px;
  cursor: pointer;
  transition: background 0.2s, border-color 0.2s;
}

.btn-eliminar:hover {
  background: rgba(230, 57, 70, 0.15);
  border-color: #e63946;
}

/* Modal */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}

.modal {
  background: #1e1e1e;
  border: 2px solid #444;
  border-radius: 16px;
  padding: 28px 32px;
  max-width: 400px;
  width: 90%;
  color: white;
}

.modal h3 {
  margin: 0 0 12px 0;
  font-size: 1.2rem;
}

.modal p {
  margin: 0 0 24px 0;
  font-size: 0.9rem;
  color: #aaa;
  line-height: 1.5;
}

.modal p strong {
  color: white;
}

.modal-acciones {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.btn-modal-cancelar {
  padding: 8px 20px;
  background: none;
  border: 1px solid #555;
  border-radius: 8px;
  color: #aaa;
  cursor: pointer;
  font-size: 0.9rem;
  transition: border-color 0.2s, color 0.2s;
}

.btn-modal-cancelar:hover {
  border-color: #aaa;
  color: white;
}

.btn-modal-eliminar {
  padding: 8px 20px;
  background: #e63946;
  border: none;
  border-radius: 8px;
  color: white;
  cursor: pointer;
  font-size: 0.9rem;
  font-weight: bold;
  transition: background 0.2s;
}

.btn-modal-eliminar:hover {
  background: #c1121f;
}
</style>
