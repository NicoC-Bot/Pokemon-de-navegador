<script setup>
import { ref } from 'vue'

const props = defineProps({
  entrenador: Object,
  capturados: Array,
})

const emit = defineEmits(['volver', 'actualizar-nombre'])

const editando = ref(false)
const nuevoNombre = ref('')

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

    </div>
  </div>
</template>

<style scoped>
.perfil {
  max-width: 600px;
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

.perfil-card {
  border: 2px solid #ccc;
  border-radius: 16px;
  overflow: hidden;
}

.perfil-header {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 24px;
  color: white;
}

.perfil-foto {
  font-size: 3.5rem;
  background: rgba(255,255,255,0.2);
  border-radius: 50%;
  width: 72px;
  height: 72px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.perfil-info {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.nombre-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 2.4rem;
}

.perfil-info h2 {
  margin: 0;
  font-size: 1.8rem;
  line-height: 2.4rem;
}

.input-nombre {
  font-size: 1.4rem;
  font-weight: bold;
  background: rgba(255,255,255,0.2);
  border: 2px solid rgba(255,255,255,0.6);
  border-radius: 8px;
  color: white;
  padding: 0 8px;
  outline: none;
  width: 180px;
  height: 2.4rem;
  box-sizing: border-box;
}

.perfil-clase {
  font-size: 0.95rem;
  opacity: 0.9;
  position: absolute;
  top: 2.8rem;
  left: 0;
}

.btn-editar {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 1rem;
  opacity: 0.8;
  padding: 0;
  transition: opacity 0.2s;
  line-height: 2.4rem;
}

.btn-editar:hover {
  opacity: 1;
}

.btn-confirmar {
  background: rgba(255,255,255,0.2);
  border: 2px solid rgba(255,255,255,0.6);
  border-radius: 6px;
  color: white;
  font-size: 1rem;
  padding: 0 10px;
  height: 2.4rem;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-confirmar:hover {
  background: rgba(255,255,255,0.35);
}

.perfil-datos {
  display: flex;
  gap: 0;
  border-bottom: 1px solid #eee;
}

.dato-fila {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 16px;
  border-right: 1px solid #eee;
}

.dato-fila:last-child {
  border-right: none;
}

.dato-label {
  font-size: 0.8rem;
  color: #888;
  text-transform: uppercase;
  margin-bottom: 4px;
}

.dato-valor {
  font-size: 1.1rem;
  font-weight: bold;
  color: #222;
}

.perfil-descripcion {
  padding: 16px 24px;
  border-bottom: 1px solid #eee;
}

.perfil-descripcion p {
  margin: 0;
  font-size: 0.88rem;
  color: #555;
  line-height: 1.5;
}

.perfil-stats {
  padding: 16px 24px 24px;
}

.perfil-stats h3 {
  font-size: 0.9rem;
  font-weight: bold;
  color: #666;
  text-transform: uppercase;
  margin: 0 0 12px 0;
}

.stats-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 6px;
}

.stat-fila {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 4px 8px;
  background: #f9f9f9;
  border-radius: 6px;
  font-size: 0.85rem;
}

.stat-nombre { color: #333; }
.stat-valor  { font-weight: bold; }
.positivo    { color: #2dc653; }
.negativo    { color: #e63946; }
.neutro      { color: #aaa; }
</style>
