<script setup>
import { ref, onMounted } from 'vue'
import { obtenerPartidas } from '../api/partidas.js'

const props = defineProps({
  entrenador: Object,
})

const emit = defineEmits(['volver', 'guardar-partida'])

const nombrePartida          = ref('')
const guardado               = ref(false)
const cargando               = ref(true)
const partidas               = ref([])
const confirmarSobreescribir = ref(null)

onMounted(async () => {
  try {
    partidas.value = await obtenerPartidas()
  } catch (e) {
    console.error('Error al cargar partidas:', e)
  } finally {
    cargando.value = false
  }
})

function guardarNueva() {
  if (nombrePartida.value.trim() === '') return
  emit('guardar-partida', { nombre: nombrePartida.value.trim() })
  guardado.value = true
  nombrePartida.value = ''
}

function pedirConfirmacion(partida) {
  confirmarSobreescribir.value = partida
}

function cancelar() {
  confirmarSobreescribir.value = null
}

function sobreescribir() {
  emit('guardar-partida', { nombre: confirmarSobreescribir.value.nombre, id: confirmarSobreescribir.value.id })
  guardado.value = true
  confirmarSobreescribir.value = null
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
            v-model="nombrePartida"
            class="input-nombre"
            type="text"
            placeholder="Ej: Mi partida principal"
            @keyup.enter="guardarNueva"
          />
          <button class="btn-guardar" @click="guardarNueva">Guardar</button>
        </div>
      </div>

      <!-- Sobreescribir -->
      <div class="seccion seccion-sobreescribir">
        <h3 class="seccion-titulo">Sobreescribir existente</h3>
        <p class="seccion-sub">Reemplaza el progreso de una partida guardada.</p>

        <div v-if="cargando" class="partidas-vacio">Cargando...</div>

        <div v-else-if="partidas.length === 0" class="partidas-vacio">
          No hay partidas guardadas.
        </div>

        <div v-else class="partidas-lista">
          <div v-for="partida in partidas" :key="partida.id" class="partida-fila">
            <div class="partida-info">
              <span class="partida-nombre">{{ partida.nombre }}</span>
              <span class="partida-fecha">{{ partida.creada_en }}</span>
            </div>
            <button class="btn-sobreescribir" @click="pedirConfirmacion(partida)">
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
  <div v-if="confirmarSobreescribir" class="modal-overlay" @click.self="cancelar">
    <div class="modal">
      <h3>¿Sobreescribir partida?</h3>
      <p>
        El progreso guardado en <strong>{{ confirmarSobreescribir.nombre }}</strong>
        será reemplazado por el estado actual. Esta acción no se puede deshacer.
      </p>
      <div class="modal-acciones">
        <button class="btn-modal-cancelar" @click="cancelar">Cancelar</button>
        <button class="btn-modal-confirmar" @click="sobreescribir">Sobreescribir</button>
      </div>
    </div>
  </div>

</template>

<style scoped>
.guardar {
  max-width: 560px;
  margin: 0 auto;
  font-family: sans-serif;
}

.btn-volver {
  margin-bottom: 24px;
  padding: 8px 16px;
  background: white;
  border: 2px solid #ccc;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.9rem;
  color: #555;
  transition: border-color 0.2s;
}

.btn-volver:hover {
  border-color: #888;
  color: #222;
}

.guardar-card {
  border: 2px solid #e0e0e0;
  border-radius: 16px;
  overflow: hidden;
}

.guardar-card h2 {
  margin: 0;
  font-size: 1.4rem;
  padding: 24px 28px 0;
}

.seccion {
  padding: 20px 28px;
  border-bottom: 1px solid #eee;
}

.seccion:last-of-type {
  border-bottom: none;
}

.seccion-titulo {
  font-size: 0.85rem;
  font-weight: bold;
  color: #666;
  text-transform: uppercase;
  margin: 0 0 4px 0;
}

.seccion-sub {
  font-size: 0.82rem;
  color: #999;
  margin: 0 0 14px 0;
}

.guardar-form {
  display: flex;
  gap: 10px;
}

.input-nombre {
  flex: 1;
  padding: 10px 14px;
  font-size: 1rem;
  border: 2px solid #ccc;
  border-radius: 8px;
  outline: none;
  transition: border-color 0.2s;
}

.input-nombre:focus {
  border-color: #888;
}

.btn-guardar {
  padding: 10px 24px;
  background: #222;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 0.95rem;
  font-weight: bold;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-guardar:hover {
  background: #444;
}

/* Sobreescribir */
.seccion-sobreescribir {
  background: #fafafa;
}

.partidas-vacio {
  font-size: 0.88rem;
  color: #aaa;
  padding: 8px 0;
}

.partidas-lista {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.partida-fila {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 14px;
  background: white;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
}

.partida-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.partida-nombre {
  font-size: 0.9rem;
  font-weight: bold;
  color: #222;
}

.partida-fecha {
  font-size: 0.75rem;
  color: #aaa;
}

.btn-sobreescribir {
  padding: 6px 14px;
  background: none;
  border: 1px solid #ccc;
  border-radius: 6px;
  font-size: 0.82rem;
  color: #555;
  cursor: pointer;
  transition: border-color 0.2s, color 0.2s;
  white-space: nowrap;
}

.btn-sobreescribir:hover {
  border-color: #e63946;
  color: #e63946;
}

/* Éxito */
.guardar-exito {
  margin: 0 28px 20px;
  padding: 12px 16px;
  background: #f0faf0;
  border: 1px solid #2dc653;
  border-radius: 8px;
  color: #1a7a35;
  font-size: 0.9rem;
}

/* Modal */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}

.modal {
  background: white;
  border: 2px solid #e0e0e0;
  border-radius: 16px;
  padding: 28px 32px;
  max-width: 400px;
  width: 90%;
}

.modal h3 {
  margin: 0 0 12px 0;
  font-size: 1.1rem;
}

.modal p {
  margin: 0 0 24px 0;
  font-size: 0.9rem;
  color: #555;
  line-height: 1.5;
}

.modal p strong {
  color: #222;
}

.modal-acciones {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.btn-modal-cancelar {
  padding: 8px 20px;
  background: none;
  border: 1px solid #ccc;
  border-radius: 8px;
  color: #666;
  cursor: pointer;
  font-size: 0.9rem;
  transition: border-color 0.2s;
}

.btn-modal-cancelar:hover {
  border-color: #888;
  color: #222;
}

.btn-modal-confirmar {
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

.btn-modal-confirmar:hover {
  background: #c1121f;
}
</style>
